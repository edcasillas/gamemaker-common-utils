# Agent Rules

## Mandatory Mobile Blocking Contract

- Keep the blocking implementation in an editable `.js` source file. The `.yy`
  injection contains only its synchronous `<script src>` reference; never embed
  the implementation in serialized metadata or add `async`/`defer` to its load.

- CRITICAL: `gmcu_disable_mobile` belongs to the HTML template, never to the
  game runtime. Show the warning before the runner loads; a mobile visitor
  must not see the game's loading bar before being told the game is unsupported.
- Never implement blocking through GML, an extension Init function, a room
  event, `GameMaker_Init`, or a callback waiting for game assets or runtime
  readiness. Background analytics initialization must not delay the warning.
- Keep the blocking extension optional and self-contained. Consumers choose
  whether to import it. General HTML5 helpers must not activate it implicitly,
  and consumers must not have to recreate its template injection.
- Validate with an unavailable or deliberately delayed runner, unchanged desktop
  behavior, and a fresh consumer HTML5 export on mobile. Invoking the blocker
  after startup in a unit test does not establish correct timing.
- Preserve this contract during refactors and resource moves. Changing it
  requires an explicit user decision; violating it is a regression.

The implementation and integration instructions belong to the
[HTML5 Helpers documentation](docs/modules/html5-helpers.md#mandatory-timing-contract).
