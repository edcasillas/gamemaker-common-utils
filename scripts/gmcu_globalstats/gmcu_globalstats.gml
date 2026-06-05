/**
 * Defensive facade over a consumer-installed GlobalStats.io client.
 *
 * The consumer owns oGlobalStatsIOController, the gs_* client scripts,
 * credentials, GTD identifiers, persistence, and event handling.
 */
function gmcu_globalstats_is_available() {
	return instance_exists(oGlobalStatsIOController);
}

function gmcu_globalstats_request_leaderboard(_gtd, _num_entries = 10) {
	if (!gmcu_globalstats_is_available()) {
		log_warn("[GMCU GlobalStats] Controller is not available.");
		return false;
	}

	_num_entries = clamp(floor(_num_entries), 1, 100);

	try {
		return gs_get_gtd_leaderboard(_gtd, _num_entries);
	} catch (_exception) {
		log_exception(_exception, "gmcu_globalstats_request_leaderboard");
		return false;
	}
}

function gmcu_globalstats_share(_player_id, _player_name, _values) {
	if (!gmcu_globalstats_is_available()) {
		log_warn("[GMCU GlobalStats] Controller is not available.");
		return false;
	}

	try {
		return gs_share(_player_id, _player_name, _values);
	} catch (_exception) {
		log_exception(_exception, "gmcu_globalstats_share");
		return false;
	}
}

function gmcu_globalstats_request_rank_section(_gtd, _player_id = undefined) {
	if (!gmcu_globalstats_is_available()) {
		log_warn("[GMCU GlobalStats] Controller is not available.");
		return false;
	}

	if (is_undefined(_player_id)) {
		_player_id = oGlobalStatsIOController.playerID;
	}

	if (is_undefined(_player_id)) {
		log_warn("[GMCU GlobalStats] Player ID is not available.");
		return false;
	}

	try {
		return gs_getRankSection(_player_id, _gtd);
	} catch (_exception) {
		log_exception(_exception, "gmcu_globalstats_request_rank_section");
		return false;
	}
}
