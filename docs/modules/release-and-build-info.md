# Release and Build Info

This module separates export, testing, versioning, and publication by design.
An export is never published automatically: test the exact artifact first,
then invoke `deploy` explicitly.

## CLI

Run the shared tool from a consumer repository:

```sh
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  export --config itch-deploy/itch-config.json --platform html --serve
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  serve-html --config itch-deploy/itch-config.json --open
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  stop-html --config itch-deploy/itch-config.json
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  status --config itch-deploy/itch-config.json
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  version --config itch-deploy/itch-config.json --platform html
python3 vendor/gamemaker-common-utils/tools/release/gmcu_release.py \
  deploy --config itch-deploy/itch-config.json --platform html
```

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

`deploy` asks for confirmation that the exact export was tested. Automation
must pass `--yes-tested`. It reads the latest channel version from
`butler status`, falls back to the consumer's versioned state file, writes
`options.ini` and `buildnumber.txt`, then calls `butler push`.

Install and authenticate Butler before using `status` or `deploy`:

```sh
butler login
butler status username/project
```

The CLI searches `PATH`, `~/bin/butler`, and the macOS itch app's managed
Butler installation. A consumer may override this with `tools.butler`.

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
`options.ini`, `buildnumber.txt`, `config.jsonc`, and the HTML server defaults.
Advanced projects may override those fields, but ordinary consumers should not
repeat conventions.

## GameMaker API

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
