/**
 * Creates a readable struct from GameMaker's Async HTTP Event callback map.
 *
 * `_async_load` should be the DS map provided by GameMaker in the built-in
 * global variable `async_load` while handling an Async HTTP Event callback
 * triggered by functions such as `http_request()`, `http_get()`, or
 * `http_post_string()`.
 *
 * Returned fields:
 * - `id`: async request id returned by the original HTTP call
 * - `status`: GameMaker callback status (`< 0` error, `0` completed, `1` downloading)
 * - `result`: response body or callback result payload
 * - `url`: callback URL field when GameMaker includes it
 * - `http_status`: HTTP status code reported by the server when available
 *
 * @param {Id.DsMap} _async_load Async HTTP callback map from GameMaker.
 * @constructor
 */
function gmcu_HttpResponseData(_async_load) constructor {
	id = ds_map_find_value(_async_load, "id");
	status = ds_map_find_value(_async_load, "status");
	result = ds_map_find_value(_async_load, "result");
	url = ds_map_find_value(_async_load, "url");
	http_status = ds_map_find_value(_async_load, "http_status");
}
