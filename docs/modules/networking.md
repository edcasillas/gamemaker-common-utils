# Networking

`Networking` owns reusable helpers for GameMaker networking callbacks and
response data. Its first helper is `gmcu_HttpResponseData`, a small wrapper
around the DS map provided by GameMaker's Async HTTP Event.

## Public API

| API | Type | Description |
| --- | --- | --- |
| `new gmcu_HttpResponseData(_async_load)` | Constructor | Extracts the standard Async HTTP callback fields into a readable struct. |

## Constructor

### `new gmcu_HttpResponseData(_async_load)`

Creates a readable struct from the DS map that GameMaker stores in the built-in
global `async_load` variable while an Async HTTP Event is running.

#### Parameter

| Name | Type | Description |
| --- | --- | --- |
| `_async_load` | `Id.DsMap` | Async HTTP callback map, usually passed as `async_load` from an Async HTTP Event. |

#### Returned Fields

| Field | Description | Evidence |
| --- | --- | --- |
| `id` | Async request id returned by the original HTTP function call. | Official manual |
| `status` | Callback state reported by GameMaker. HTTP callbacks use `< 0` for error, `0` for completed, and `1` while downloading. | Official manual |
| `result` | Response payload returned by the callback. | Official manual |
| `http_status` | HTTP status code reported for completed requests when available. | Official manual |
| `url` | URL field extracted from the callback map when present. Consumers may use it, but the current Common Utils documentation treats it as empirically observed until a direct manual citation is found for that key. | Empirical |

## Usage

Async HTTP Event:

```gml
if (async_load[? "id"] != request_id) exit;

var _response = new gmcu_HttpResponseData(async_load);
if (_response.status < 0) {
    show_debug_message("HTTP request failed: " + string(_response.result));
    exit;
}

if (_response.status == 0 && _response.http_status == 200) {
    var _response_body = _response.result;
    show_debug_message("HTTP response: " + _response_body);
}
```

## External References

These GameMaker manual pages were used to document the Async HTTP callback
shape and the source of `_async_load`:

- [`http_request`](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Asynchronous_Functions/HTTP/http_request.htm)
- [`HTTP`](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Asynchronous_Functions/HTTP/HTTP.htm)
- [`Async HTTP Event`](https://manual.gamemaker.io/monthly/en/The_Asset_Editors/Object_Properties/Async_Events/HTTP.htm)
- [`async_load`](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Overview/Variables/Builtin_Global_Variables/async_load.htm)
- [`http_get`](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Asynchronous_Functions/HTTP/http_get.htm)
- [`http_post_string`](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Asynchronous_Functions/HTTP/http_post_string.htm)

## Dependencies

`Networking` currently has no module dependencies.
