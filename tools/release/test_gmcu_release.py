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
        config_path = self.base / "itch-deploy" / "itch-config.json"
        config_path.parent.mkdir()
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
        self.assertEqual("../Builds/html", config["platforms"]["html"]["build_path"])
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

    def test_noninteractive_deploy_requires_confirmation(self):
        with mock.patch.object(gmcu_release.sys.stdin, "isatty", return_value=False):
            with self.assertRaises(gmcu_release.ReleaseError):
                gmcu_release.confirm_tested(False)

    @mock.patch.object(gmcu_release, "port_available", side_effect=[False, False, True])
    def test_select_port_uses_next_available_port(self, _available):
        self.assertEqual(8002, gmcu_release.select_port(8000))

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


if __name__ == "__main__":
    unittest.main()
