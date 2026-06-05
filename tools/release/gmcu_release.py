#!/usr/bin/env python3
"""Build, test, version, and publish GameMaker exports."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import time
import webbrowser
from pathlib import Path


VERSION_RE = re.compile(r"^(?P<year>\d{4})\.(?P<month>\d{2})\.(?P<platform>\d+)\.(?P<count>\d+)$")
STATUS_ROW_RE = re.compile(r"^\|\s*(?P<channel>[^|]+?)\s*\|.*\|\s*(?P<version>[^|]+?)\s*\|$")


class ReleaseError(RuntimeError):
    pass


def load_config(path: str) -> tuple[dict, Path]:
    config_path = Path(path).expanduser().resolve()
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ReleaseError(f"Config file not found: {config_path}") from exc
    except json.JSONDecodeError as exc:
        raise ReleaseError(f"Invalid JSON in {config_path}: {exc}") from exc
    base = config_path.parent
    platforms = config.get("platforms", ["html"])
    if isinstance(platforms, list):
        config["platforms"] = {
            name: {
                "id": index + 1,
                "channel": name,
                "build_path": f"../Builds/{name}",
                "options_ini": f"../Builds/{name}/options.ini",
                "buildnumber_file": (
                    f"../Builds/{name}/html5game/buildnumber.txt"
                    if name == "html"
                    else f"../Builds/{name}/buildnumber.txt"
                ),
                "gm_target": "html5" if name == "html" else name,
                "gm_runtime": "vm",
                "gm_config": "Default",
            }
            for index, name in enumerate(platforms)
        }
    config.setdefault("project", str(next(base.parent.glob("*.yyp"), "")))
    config.setdefault("version_state", "config.jsonc")
    config.setdefault("server_state", ".gmcu-release/html-server.json")
    config.setdefault(
        "html",
        {
            "platform": "html",
            "directory": "../Builds/html",
            "entrypoint": "index.html",
            "port": 8000,
        },
    )
    if "itch" not in config:
        config["itch"] = {
            "username": config.pop("username"),
            "project": config.pop("project_name", config.get("project_slug", config.get("itch_project"))),
        }
        if not config["itch"]["project"]:
            config["itch"]["project"] = config_path.stem
    return config, base


def resolve(base: Path, value: str) -> Path:
    path = Path(value).expanduser()
    return path.resolve() if path.is_absolute() else (base / path).resolve()


def require_command(command: str) -> str:
    path = shutil.which(command)
    if not path:
        raise ReleaseError(f"Required command not found in PATH: {command}")
    return path


def find_butler(config: dict) -> str:
    configured = config.get("tools", {}).get("butler")
    if configured:
        path = Path(configured).expanduser()
        if path.is_file():
            return str(path)
        found = shutil.which(configured)
        if found:
            return found
        raise ReleaseError(f"Configured Butler executable not found: {configured}")
    found = shutil.which("butler")
    if found:
        return found
    home_install = Path.home() / "bin" / "butler"
    if home_install.is_file():
        return str(home_install)
    broth = Path.home() / "Library/Application Support/itch/broth/butler"
    chosen = broth / ".chosen-version"
    if chosen.is_file():
        app_install = broth / "versions" / chosen.read_text(encoding="utf-8").strip() / "butler"
        if app_install.is_file():
            return str(app_install)
    raise ReleaseError("Butler not found in PATH, ~/bin, or the itch app installation")


def platform_config(config: dict, name: str) -> dict:
    try:
        platform = config["platforms"][name]
    except KeyError as exc:
        supported = ", ".join(sorted(config.get("platforms", {})))
        raise ReleaseError(f"Unknown platform '{name}'. Supported: {supported}") from exc
    required = ("id", "channel", "build_path", "options_ini", "buildnumber_file", "gm_target")
    missing = [key for key in required if key not in platform]
    if missing:
        raise ReleaseError(f"Platform '{name}' is missing: {', '.join(missing)}")
    return platform


def run(command: list[str], *, capture: bool = False, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(command, text=True, capture_output=capture, check=check)


def butler_status(config: dict) -> str:
    itch = config["itch"]
    butler = find_butler(config)
    command = [butler, "status", f"{itch['username']}/{itch['project']}"]
    try:
        return run(command, capture=True).stdout
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "stderr", "") or str(exc)
        raise ReleaseError(f"Butler status failed: {detail.strip()}") from exc


def parse_status_versions(output: str) -> dict[str, str]:
    versions: dict[str, str] = {}
    for line in output.splitlines():
        match = STATUS_ROW_RE.match(line)
        if not match:
            continue
        channel = match.group("channel").strip()
        version = match.group("version").strip()
        if channel.upper() != "CHANNEL" and VERSION_RE.match(version):
            versions[channel] = version
    return versions


def load_state(config: dict, base: Path) -> tuple[dict, Path]:
    state_path = resolve(base, config["version_state"])
    if not state_path.exists():
        return {"build_counts": {}}, state_path
    try:
        return json.loads(state_path.read_text(encoding="utf-8")), state_path
    except json.JSONDecodeError as exc:
        raise ReleaseError(f"Invalid version state in {state_path}: {exc}") from exc


def next_version(config: dict, base: Path, platform_name: str, now: dt.datetime | None = None) -> tuple[str, dict, Path]:
    platform = platform_config(config, platform_name)
    now = now or dt.datetime.now()
    month_key = f"{now.year}-{now.month:02}"
    state, state_path = load_state(config, base)
    local_count = int(state.setdefault("build_counts", {}).setdefault(platform_name, {}).get(month_key, 0))
    remote_count = 0
    try:
        remote = parse_status_versions(butler_status(config)).get(platform["channel"])
        if remote:
            match = VERSION_RE.match(remote)
            if match and int(match.group("platform")) == int(platform["id"]):
                if f"{match.group('year')}-{match.group('month')}" == month_key:
                    remote_count = int(match.group("count"))
    except ReleaseError as exc:
        print(f"Warning: {exc}; using local version state.", file=sys.stderr)
    count = max(local_count, remote_count) + 1
    state["build_counts"][platform_name][month_key] = count
    version = f"{now.year}.{now.month:02}.{int(platform['id'])}.{count}"
    return version, state, state_path


def update_options_ini(path: Path, version: str) -> None:
    if not path.is_file():
        raise ReleaseError(f"options.ini not found: {path}")
    year, month, platform_id, count = version.split(".")
    replacements = {
        "MajorVersion": year,
        "MinorVersion": str(int(month)),
        "BuildVersion": platform_id,
        "RevisionVersion": count,
    }
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    found: set[str] = set()
    for index, line in enumerate(lines):
        key = line.split("=", 1)[0]
        if key in replacements:
            newline = "\n" if line.endswith("\n") else ""
            lines[index] = f"{key}={replacements[key]}{newline}"
            found.add(key)
    missing = set(replacements) - found
    if missing:
        raise ReleaseError(f"Missing version fields in {path}: {', '.join(sorted(missing))}")
    path.write_text("".join(lines), encoding="utf-8")


def generate_version(config: dict, base: Path, platform_name: str) -> str:
    platform = platform_config(config, platform_name)
    version, state, state_path = next_version(config, base, platform_name)
    options_ini = resolve(base, platform["options_ini"])
    buildnumber = resolve(base, platform["buildnumber_file"])
    buildnumber.parent.mkdir(parents=True, exist_ok=True)
    state_path.parent.mkdir(parents=True, exist_ok=True)
    update_options_ini(options_ini, version)
    buildnumber.write_text(version, encoding="utf-8")
    state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"Generated version: {version}")
    return version


def export_build(config: dict, base: Path, platform_name: str, serve: bool) -> None:
    platform = platform_config(config, platform_name)
    project = resolve(base, config["project"])
    output = resolve(base, platform["build_path"])
    output.parent.mkdir(parents=True, exist_ok=True)
    if platform.get("export_command"):
        values = {
            "project": str(project),
            "output": str(output),
            "platform": platform_name,
            "target": platform["gm_target"],
            "runtime": platform.get("gm_runtime", "vm"),
            "config": platform.get("gm_config", "Default"),
            "toolchain": platform.get("gm_toolchain", ""),
        }
        command = [str(part).format(**values) for part in platform["export_command"]]
    else:
        tools = config.get("tools", {})
        gm_cli = tools.get("gm_cli")
        command = [gm_cli] if gm_cli else [require_command("npx"), "@gamemaker/gm-cli@latest"]
        command += [
            "package",
            str(project),
            f"--target={platform['gm_target']}",
            f"--runtime={platform.get('gm_runtime', 'vm')}",
            f"--config={platform.get('gm_config', 'Default')}",
            f"--output={output}",
        ]
        if platform.get("gm_toolchain"):
            command.append(f"--toolchain={platform['gm_toolchain']}")
        if platform.get("gm_toolchain_options"):
            command.append(f"--toolchain-options={json.dumps(platform['gm_toolchain_options'])}")
    print("Exporting with:", " ".join(command))
    try:
        run(command)
    except subprocess.CalledProcessError as exc:
        hint = ""
        if platform["gm_target"] == "html5" and not platform.get("export_command"):
            hint = (
                " gm-cli 2.1.0 does not support HTML5 packaging; configure an "
                "explicit export_command or export from GameMaker and use serve-html."
            )
        raise ReleaseError(f"Export command failed with exit code {exc.returncode}.{hint}") from exc
    if serve:
        if platform_name != config["html"]["platform"]:
            raise ReleaseError("--serve is only valid for the configured HTML platform")
        serve_html(config, base, None, True)


def server_state_path(config: dict, base: Path) -> Path:
    return resolve(base, config.get("server_state", ".gmcu-release/html-server.json"))


def read_server_state(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None


def pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except (OSError, ProcessLookupError):
        return False


def port_available(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("0.0.0.0", port))
            return True
        except OSError:
            return False


def lan_ip() -> str | None:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        try:
            sock.connect(("8.8.8.8", 80))
            return sock.getsockname()[0]
        except OSError:
            return None


def print_server_urls(port: int) -> str:
    local_url = f"http://localhost:{port}"
    print(f"Local URL: {local_url}")
    address = lan_ip()
    if address:
        print(f"LAN URL:   http://{address}:{port}")
    else:
        print("LAN URL:   unavailable")
    return local_url


def serve_html(config: dict, base: Path, port_override: int | None, open_browser: bool) -> None:
    html = config["html"]
    directory = resolve(base, html["directory"])
    entrypoint = directory / html.get("entrypoint", "index.html")
    port = port_override or int(html.get("port", 8000))
    if not entrypoint.is_file():
        raise ReleaseError(f"HTML entrypoint not found: {entrypoint}")
    state_path = server_state_path(config, base)
    state = read_server_state(state_path)
    if state and pid_alive(int(state["pid"])):
        if Path(state["directory"]) != directory or int(state["port"]) != port:
            raise ReleaseError("A different Common Utils HTML server is already registered for this project")
        local_url = print_server_urls(port)
        if open_browser:
            webbrowser.open(local_url)
        return
    if state_path.exists():
        state_path.unlink()
    if not port_available(port):
        raise ReleaseError(f"Port {port} is already in use by another process")
    python = require_command("python3")
    state_path.parent.mkdir(parents=True, exist_ok=True)
    log_path = state_path.with_suffix(".log")
    log_file = log_path.open("a", encoding="utf-8")
    process = subprocess.Popen(
        [python, "-m", "http.server", "--bind", "0.0.0.0", "--directory", str(directory), str(port)],
        stdout=log_file,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    time.sleep(0.5)
    if process.poll() is not None:
        raise ReleaseError(f"HTML server failed to start; inspect {log_path}")
    state_path.write_text(
        json.dumps({"pid": process.pid, "directory": str(directory), "port": port}, indent=2) + "\n",
        encoding="utf-8",
    )
    local_url = print_server_urls(port)
    print(f"Server PID: {process.pid}")
    print(f"Log: {log_path}")
    if open_browser:
        webbrowser.open(local_url)


def stop_html(config: dict, base: Path) -> None:
    state_path = server_state_path(config, base)
    state = read_server_state(state_path)
    if not state:
        print("No managed HTML server is registered.")
        return
    pid = int(state["pid"])
    if pid_alive(pid):
        os.kill(pid, signal.SIGTERM)
        print(f"Stopped HTML server PID {pid}.")
    else:
        print(f"Removed stale HTML server state for PID {pid}.")
    state_path.unlink(missing_ok=True)


def confirm_tested(yes_tested: bool) -> None:
    if yes_tested:
        return
    if not sys.stdin.isatty():
        raise ReleaseError("Non-interactive deploy requires --yes-tested")
    answer = input("Has this exact exported build been tested? Type 'yes' to deploy: ")
    if answer.strip().lower() != "yes":
        raise ReleaseError("Deployment cancelled; test the export before publishing")


def deploy(config: dict, base: Path, platform_name: str, yes_tested: bool) -> None:
    confirm_tested(yes_tested)
    platform = platform_config(config, platform_name)
    build_path = resolve(base, platform["build_path"])
    if not build_path.exists():
        raise ReleaseError(f"Export not found: {build_path}")
    version = generate_version(config, base, platform_name)
    itch = config["itch"]
    butler = find_butler(config)
    target = f"{itch['username']}/{itch['project']}:{platform['channel']}"
    run([butler, "push", str(build_path), target, "--userversion", version])
    print(f"Deployment successful: {target} v{version}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("status", "version", "export", "serve-html", "stop-html", "deploy"):
        sub = subparsers.add_parser(name)
        sub.add_argument("--config", required=True)
        if name in ("version", "export", "deploy"):
            sub.add_argument("--platform", required=True)
        if name == "export":
            sub.add_argument("--serve", action="store_true")
        if name == "serve-html":
            sub.add_argument("--port", type=int)
            sub.add_argument("--open", action="store_true")
        if name == "deploy":
            sub.add_argument("--yes-tested", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        config, base = load_config(args.config)
        if args.command == "status":
            print(butler_status(config), end="")
        elif args.command == "version":
            generate_version(config, base, args.platform)
        elif args.command == "export":
            export_build(config, base, args.platform, args.serve)
        elif args.command == "serve-html":
            serve_html(config, base, args.port, args.open)
        elif args.command == "stop-html":
            stop_html(config, base)
        elif args.command == "deploy":
            deploy(config, base, args.platform, args.yes_tested)
    except ReleaseError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
