# Release and Build Info

This module separates export, testing, versioning, and publication by design.
Consumers use a double-click menu for normal work and retain the detailed CLI
for automation and diagnosis.

## Consumer Setup

1. Vendor Common Utils at `vendor/gamemaker-common-utils`.
2. Copy `tools/release/Release.command` to the consumer repository root.
3. Make the copied launcher executable.
4. Add a root `itch-config.json`.

The launcher needs no project-specific edits. Double-click it to serve or stop
an HTML build, or to publish a tested artifact.

## CLI Usage

```sh
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  menu
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  serve-html --open
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  stop-html
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  status
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  version --platform html
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  deploy --platform html
```

All commands default to root `itch-config.json`. `--config` remains available
for non-conventional layouts.

`export` uses `gm-cli package` by default. As of gm-cli 2.1.0, the official CLI
reports that HTML5 target support is still coming soon. Consumers may provide a
platform-specific `export_command` array using `{project}`, `{output}`,
`{platform}`, `{target}`, `{runtime}`, `{config}`, and `{toolchain}`
placeholders. Otherwise, export HTML from GameMaker and use `serve-html`.

`--serve` is valid only for the configured HTML platform and starts the same
background server as `serve-html`. The server listens on all interfaces and
prints localhost and LAN URLs. If the preferred port is occupied, it selects
the next available port automatically and verifies that `index.html` responds
before registering the server. An explicit `--port` remains strict and fails
when occupied. State and logs go under the consumer-defined `server_state`
path; commit neither file.

`deploy` requires branch `main` and a clean working tree. It asks for
confirmation that the exact export was tested; automation must pass
`--yes-tested`. It reads the latest channel version from `butler status`, falls
back to the consumer's versioned state file, updates generated version files
and the selected GameMaker target's `option_<target>_version`, then calls
`butler push`. After a successful upload it commits only the version state and
target options file, creates `releases/v<version>`, and separately asks whether
to push the commit and tag.

If Git bookkeeping fails after upload, the tool does not attempt to undo the
itch.io release. It prints the commands needed to complete the commit and tag.

Install and authenticate Butler before using `status` or `deploy`:

```sh
butler login
butler status username/project
```

The CLI searches `PATH`, `~/bin/butler`, and the macOS itch app's managed
Butler installation. A consumer may override this with `tools.butler`.

## Resources

- `tools/release/gmcu_release.py`: Export, serve, version, status, and deploy
  CLI.
- `tools/release/Release.command`: Reusable zero-argument consumer launcher.
- `scripts/gmcu_build_info`: Runtime build metadata API.
- `objects/gmcu_o_build_info_label`: Optional bottom-right build label.

## Dependencies

- [`Core`](core.md): Supplies build configuration policy to runtime resources.
- External tools such as `gm-cli` and Butler are required only for the
  corresponding CLI commands.

## Consumer Configuration

The normal consumer file is intentionally small:

```json
{
  "username": "studio",
  "project_name": "game",
  "platforms": ["html", "windows"]
}
```

Platform order supplies stable IDs starting at `1`. Common Utils infers the
consumer `.yyp`, `Builds/<platform>`, matching itch channel names,
`options.ini`, `buildnumber.txt`, `itch-deploy/config.jsonc`, and the HTML
server defaults. Advanced projects may override those fields, but ordinary
consumers should not repeat conventions.

## API

Import or symlink:

- `scripts/gmcu_build_info`
- `objects/gmcu_o_build_info_label`

Initialize before analytics or UI creation:

```gml
gmcu_build_info_init({
    author: "Studio Name",
    copyright_start_year: 2024
});
global.build_number = gmcu_build_info_get_version();
```

Optional fields are `version_prefix`, `separator`, and `build_file`. Missing
`buildnumber.txt` falls back to `GM_version + "-dev"`.

The shared label preserves Fantasma's bottom-right black background and white
text. Consumer-specific author and date values are supplied at initialization.

## Contributing

Consumer repositories retain build paths, export artifacts, itch.io
destinations, version state, credentials, and presentation values.
