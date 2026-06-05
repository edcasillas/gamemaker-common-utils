function gmcu_build_info_init(_options = {}) {
    global.gmcu_build_info = {
        author: variable_struct_get(_options, "author"),
        copyright_start_year: variable_struct_get(_options, "copyright_start_year"),
        version_prefix: variable_struct_exists(_options, "version_prefix")
            ? string(_options.version_prefix) : "v",
        separator: variable_struct_exists(_options, "separator")
            ? string(_options.separator) : " | ",
        build_file: variable_struct_exists(_options, "build_file")
            ? string(_options.build_file) : "buildnumber.txt"
    };

    global.gmcu_build_info.version = gmcu_build_info_get_version();
    return global.gmcu_build_info;
}

function gmcu_build_info_get_version() {
    var _build_file = "buildnumber.txt";
    if (variable_global_exists("gmcu_build_info")) {
        _build_file = global.gmcu_build_info.build_file;
    }
    if (!file_exists(_build_file)) {
        return GM_version + "-dev";
    }
    var _file = file_text_open_read(_build_file);
    var _version = file_text_read_string(_file);
    file_text_close(_file);
    return _version;
}

function gmcu_build_info_get_text() {
    if (!variable_global_exists("gmcu_build_info")) {
        gmcu_build_info_init();
    }
    var _config = global.gmcu_build_info;
    var _text = _config.version_prefix + string(_config.version);
    if (!is_undefined(_config.author) && string_length(string(_config.author)) > 0) {
        _text += _config.separator + string(_config.author);
        if (!is_undefined(_config.copyright_start_year)) {
            _text += " " + string(_config.copyright_start_year) + "-" + string(current_year);
        }
    }
    return _text;
}
