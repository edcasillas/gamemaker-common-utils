import datetime as dt
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import gmcu_release


STATUS = """\
+---------+-----------+----------------------------+-------------+
| CHANNEL |  UPLOAD   |           BUILD            |   VERSION   |
+---------+-----------+----------------------------+-------------+
| html    | #11928736 | #1121577 (from #1120261)   | 2024.11.1.3 |
+---------+-----------+----------------------------+-------------+
"""


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.config = {
            "itch": {"username": "edu", "project": "fantasma"},
            "version_state": "state.json",
            "html": {
                "platform": "html",
                "directory": "Builds/html",
                "entrypoint": "index.html",
                "port": 8000,
            },
            "platforms": {
                "html": {
                    "id": 1,
                    "channel": "html",
                    "build_path": "Builds/html",
                    "options_ini": "Builds/html/options.ini",
                    "buildnumber_file": "Builds/html/html5game/buildnumber.txt",
                    "gm_target": "html5",
                }
            },
        }

    def tearDown(self):
        self.temp.cleanup()

    def test_parse_butler_status(self):
        self.assertEqual({"html": "2024.11.1.3"}, gmcu_release.parse_status_versions(STATUS))

    def test_minimal_consumer_config_expands_conventions(self):
        (self.base / "Game.yyp").write_text("{}", encoding="utf-8")
        config_path = self.base / "itch-config.json"
        config_path.write_text(
            json.dumps(
                {
                    "username": "studio",
                    "project_name": "game",
                    "platforms": ["html", "windows"],
                }
            ),
            encoding="utf-8",
        )
        config, base = gmcu_release.load_config(str(config_path))
        self.assertEqual("studio", config["itch"]["username"])
        self.assertEqual("game", config["itch"]["project"])
        self.assertEqual(1, config["platforms"]["html"]["id"])
        self.assertEqual(2, config["platforms"]["windows"]["id"])
        self.assertEqual("Builds/html", config["platforms"]["html"]["build_path"])
        self.assertEqual("itch-deploy/config.jsonc", config["version_state"])
        self.assertEqual(str((self.base / "Game.yyp").resolve()), config["project"])
        self.assertEqual(config_path.parent.resolve(), base)

    @mock.patch.object(gmcu_release, "butler_status", return_value=STATUS)
    def test_next_version_uses_remote_counter(self, _status):
        version, state, _ = gmcu_release.next_version(
            self.config, self.base, "html", dt.datetime(2024, 11, 20)
        )
        self.assertEqual("2024.11.1.4", version)
        self.assertEqual(4, state["build_counts"]["html"]["2024-11"])

    @mock.patch.object(gmcu_release, "butler_status", side_effect=gmcu_release.ReleaseError("offline"))
    def test_next_version_falls_back_to_local_state(self, _status):
        (self.base / "state.json").write_text(
            json.dumps({"build_counts": {"html": {"2026-06": 7}}}), encoding="utf-8"
        )
        version, _, _ = gmcu_release.next_version(
            self.config, self.base, "html", dt.datetime(2026, 6, 5)
        )
        self.assertEqual("2026.06.1.8", version)

    def test_update_options_ini(self):
        path = self.base / "options.ini"
        path.write_text(
            "MajorVersion=1\nMinorVersion=0\nBuildVersion=0\nRevisionVersion=0\n",
            encoding="utf-8",
        )
        gmcu_release.update_options_ini(path, "2026.06.3.9")
        self.assertEqual(
            "MajorVersion=2026\nMinorVersion=6\nBuildVersion=3\nRevisionVersion=9\n",
            path.read_text(encoding="utf-8"),
        )

    def test_update_source_version_changes_only_target_field(self):
        path = self.base / "options_html5.yy"
        path.write_text(
            '{\n  "option_html5_version":"1.0.0.0",\n  "resourceVersion":"2.0",\n}\n',
            encoding="utf-8",
        )
        gmcu_release.update_source_version(
            path, "option_html5_version", "2026.06.1.9"
        )
        self.assertEqual(
            '{\n  "option_html5_version":"2026.06.1.9",\n  "resourceVersion":"2.0",\n}\n',
            path.read_text(encoding="utf-8"),
        )

    def test_restore_files_reverts_changes_and_removes_new_files(self):
        existing = self.base / "existing.txt"
        created = self.base / "created.txt"
        existing.write_text("before", encoding="utf-8")
        snapshot = gmcu_release.snapshot_files([existing, created])
        existing.write_text("after", encoding="utf-8")
        created.write_text("new", encoding="utf-8")
        gmcu_release.restore_files(snapshot)
        self.assertEqual("before", existing.read_text(encoding="utf-8"))
        self.assertFalse(created.exists())

    @mock.patch.object(gmcu_release, "git_run")
    def test_require_clean_main_rejects_other_branch(self, git_run):
        git_run.return_value.stdout = "feature\n"
        with self.assertRaisesRegex(gmcu_release.ReleaseError, "requires branch 'main'"):
            gmcu_release.require_clean_main(self.base)

    @mock.patch.object(gmcu_release, "git_run")
    def test_require_clean_main_rejects_dirty_tree(self, git_run):
        git_run.side_effect = [
            mock.Mock(stdout="main\n"),
            mock.Mock(stdout=" M README.md\n"),
        ]
        with self.assertRaisesRegex(gmcu_release.ReleaseError, "clean Git working tree"):
            gmcu_release.require_clean_main(self.base)

    @mock.patch.object(gmcu_release, "git_run")
    def test_commit_release_stages_only_release_metadata(self, git_run):
        state = self.base / "itch-deploy" / "config.jsonc"
        source = self.base / "options" / "html5" / "options_html5.yy"
        gmcu_release.commit_release(self.base, "2026.06.1.9", state, source)
        self.assertEqual(
            [
                mock.call(
                    self.base,
                    [
                        "add",
                        "--",
                        "itch-deploy/config.jsonc",
                        "options/html5/options_html5.yy",
                    ],
                ),
                mock.call(self.base, ["commit", "-m", "Release v2026.06.1.9"]),
                mock.call(self.base, ["tag", "releases/v2026.06.1.9"]),
            ],
            git_run.call_args_list,
        )

    def test_noninteractive_deploy_requires_confirmation(self):
        with mock.patch.object(gmcu_release.sys.stdin, "isatty", return_value=False):
            with self.assertRaises(gmcu_release.ReleaseError):
                gmcu_release.confirm_tested(False)

    @mock.patch.object(gmcu_release, "port_available", side_effect=[False, False, True])
    def test_select_port_uses_next_available_port(self, _available):
        self.assertEqual(8002, gmcu_release.select_port(8000))

    @mock.patch.object(gmcu_release, "input", side_effect=["1", "3"])
    @mock.patch.object(gmcu_release, "serve_html")
    @mock.patch.object(gmcu_release, "html_server_running", return_value=False)
    def test_menu_offers_serve_when_html_build_exists(
        self, _running, serve_html, _input
    ):
        html = self.base / "Builds" / "html"
        html.mkdir(parents=True)
        (html / "index.html").write_text("ok", encoding="utf-8")
        gmcu_release.interactive_menu(self.config, self.base)
        serve_html.assert_called_once_with(self.config, self.base, None, True)

    @mock.patch.object(gmcu_release, "input", side_effect=["1", "3"])
    @mock.patch.object(gmcu_release, "stop_html")
    @mock.patch.object(gmcu_release, "html_server_running", return_value=True)
    def test_menu_offers_stop_when_server_is_running(
        self, _running, stop_html, _input
    ):
        gmcu_release.interactive_menu(self.config, self.base)
        stop_html.assert_called_once_with(self.config, self.base)

    @mock.patch.object(gmcu_release, "input", side_effect=["2"])
    @mock.patch.object(gmcu_release, "html_server_running", return_value=False)
    def test_menu_exits_when_html_build_is_missing(self, _running, _input):
        gmcu_release.interactive_menu(self.config, self.base)

    @mock.patch.object(gmcu_release, "run")
    @mock.patch.object(gmcu_release, "require_command", return_value="/usr/bin/npx")
    def test_export_build_invokes_gm_cli_without_versioning(self, _command, run_command):
        self.config["project"] = "Game.yyp"
        gmcu_release.export_build(self.config, self.base, "html", False)
        command = run_command.call_args.args[0]
        self.assertEqual("/usr/bin/npx", command[0])
        self.assertIn("package", command)
        self.assertIn("--target=html5", command)
        self.assertIn(f"--output={(self.base / 'Builds/html').resolve()}", command)

    @mock.patch.object(gmcu_release, "run")
    def test_export_build_supports_consumer_export_command(self, run_command):
        self.config["project"] = "Game.yyp"
        self.config["platforms"]["html"]["export_command"] = [
            "exporter",
            "--project={project}",
            "--output={output}",
        ]
        gmcu_release.export_build(self.config, self.base, "html", False)
        self.assertEqual(
            [
                "exporter",
                f"--project={(self.base / 'Game.yyp').resolve()}",
                f"--output={(self.base / 'Builds/html').resolve()}",
            ],
            run_command.call_args.args[0],
        )

    @mock.patch.object(gmcu_release, "commit_release")
    @mock.patch.object(gmcu_release, "find_butler", return_value="/usr/bin/butler")
    @mock.patch.object(gmcu_release, "generate_version")
    @mock.patch.object(gmcu_release, "confirm_release", return_value=True)
    @mock.patch.object(gmcu_release, "require_clean_main")
    @mock.patch.object(gmcu_release, "run")
    def test_interactive_deploy_validates_uploads_commits_and_skips_push_prompt(
        self,
        run_command,
        require_clean,
        _confirm,
        generate_version,
        _butler,
        commit_release,
    ):
        build = self.base / "Builds" / "html"
        build.mkdir(parents=True)
        state = self.base / "state.json"
        source = self.base / "options" / "html5" / "options_html5.yy"
        generate_version.return_value = ("2026.06.1.9", state, source)
        gmcu_release.deploy(
            self.config,
            self.base,
            "html",
            False,
            simple_confirm=True,
            push_prompt=False,
        )
        require_clean.assert_called_once_with(self.base)
        run_command.assert_called_once_with(
            [
                "/usr/bin/butler",
                "push",
                str(build.resolve()),
                "edu/fantasma:html",
                "--userversion",
                "2026.06.1.9",
            ]
        )
        commit_release.assert_called_once_with(
            self.base, "2026.06.1.9", state, source
        )


if __name__ == "__main__":
    unittest.main()
