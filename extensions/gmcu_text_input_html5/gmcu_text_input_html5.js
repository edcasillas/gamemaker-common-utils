/** Capture browser text without focusing an editable element on mobile. */
var gmcuTextInput = { active: false, queue: [], installed: false, generation: 0 };

/** Start capturing keyboard and paste events for the active textbox.
 * @returns {number} GameMaker extension success sentinel.
 */
function gmcu_text_capture_begin() {
  var capture = gmcuTextInput;
  capture.active = true;
  capture.queue = [];
  capture.generation++;

  if (capture.installed) {
    return 0;
  }

  capture.installed = true;
  window.addEventListener('keydown', function (event) {
    if (!capture.active || event.isComposing) {
      return;
    }

    if (event.ctrlKey || event.metaKey) {
      if (event.key.toLowerCase() === 'c') {
        return;
      }

      // Paste data arrives through the browser's paste event, without read permission.
      if (event.key.toLowerCase() === 'v' && !event.repeat) {
        capture.queue.push({ kind: 'shortcut', value: 'PASTE' });
      }

      return;
    }

    if (event.key === 'Enter' || event.key === 'Escape') {
      event.preventDefault();
      if (!event.repeat) {
        capture.queue.push({ kind: 'action', value: event.key === 'Enter' ? 'DONE' : 'CANCEL' });
      }

      return;
    }

    if (event.key.length === 1) {
      event.preventDefault();
      if (!event.repeat) {
        capture.queue.push({ kind: 'char', value: event.key });
      }
    }
  }, true);

  window.addEventListener('paste', function (event) {
    if (!capture.active) {
      return;
    }

    if (!event.clipboardData) {
      return;
    }

    event.preventDefault();
    capture.queue.push({ kind: 'paste', value: event.clipboardData.getData('text/plain') });
  }, true);

  return 0;
}

/** End capture and discard queued gestures.
 * @returns {number} GameMaker extension success sentinel.
 */
function gmcu_text_capture_end() {
  gmcuTextInput.active = false;
  gmcuTextInput.queue = [];
  gmcuTextInput.generation++;
  if (typeof window.gmcu_text_clipboard_clear_paste === 'function') {
    window.gmcu_text_clipboard_clear_paste();
  }

  return 0;
}

/** Drain input once per active textbox Step event.
 * @returns {string} JSON array of queued input events.
 */
function gmcu_text_capture_poll() {
  var queued = gmcuTextInput.queue;
  gmcuTextInput.queue = [];
  return JSON.stringify(queued);
}

/** Request clipboard access; responses identify the initiating field and session.
 * @param {string} action Clipboard operation.
 * @param {string} value Copy text or prepared host text.
 * @param {string} owner Field ID or prepared copy options.
 * @param {number} token Clipboard request token.
 * @returns {number} Immediate bridge result; asynchronous reads enqueue a response.
 */
function gmcu_text_clipboard(action, value, owner, token) {
  var generation = gmcuTextInput.generation;

  function finish(ok, text, error) {
    if (action === 'paste' && (!gmcuTextInput.active || generation !== gmcuTextInput.generation)) {
      return;
    }

    gmcuTextInput.queue.push({
      kind: 'clipboard',
      action: action,
      owner: owner,
      token: token,
      ok: ok,
      value: text || '',
      error: error || ''
    });
  }

  if (action === 'prepare_copy') {
    var prepare = window.gmcu_text_clipboard_prepare;
    if (typeof prepare !== 'function') {
      return 0;
    }

    try {
      return prepare(value, owner) ? 1 : 0;
    } catch (error) {
      return 0;
    }
  }

  if (action === 'prepare_paste') {
    var preparePaste = window.gmcu_text_clipboard_prepare_paste;
    if (typeof preparePaste !== 'function') {
      return 0;
    }

    try {
      return preparePaste(value, owner, token) ? 1 : 0;
    } catch (error) {
      return 0;
    }
  }

  if (action === 'copy') {
    var bridge = window.gmcu_text_clipboard_write;
    if (typeof bridge !== 'function') {
      return 0;
    }

    try {
      return bridge(value) ? 1 : 0;
    } catch (error) {
      return 0;
    }
  }

  var consumePaste = window.gmcu_text_clipboard_consume_paste;
  if (action === 'paste' && typeof consumePaste === 'function' && consumePaste(owner, token)) {
    return 0;
  }

  if (!gmcu_text_clipboard_can_read()) {
    finish(false, '', gmcu_text_clipboard_read_diagnostic());
    return 0;
  }

  var request;
  try {
    request = navigator.clipboard.readText();
  } catch (error) {
    finish(false, '', (error && error.name ? error.name + ': ' : '') + String(error && error.message || error));
    return 0;
  }

  Promise.resolve(request).then(
    function (text) { finish(true, text); },
    function (error) {
      finish(false, '', (error && error.name ? error.name + ': ' : '') + String(error && error.message || error));
    }
  );
  return 0;
}

/** Return whether this page can attempt programmatic clipboard reads.
 * @returns {number} One when PASTE may be offered, otherwise zero.
 */
function gmcu_text_clipboard_can_read() {
  var canRead = window.gmcu_text_clipboard_can_read;
  if (typeof canRead === 'function') {
    return canRead() ? 1 : 0;
  }

  return window.isSecureContext && navigator.clipboard &&
    typeof navigator.clipboard.readText === 'function' ? 1 : 0;
}

/** Return the browser diagnostic explaining clipboard-read availability.
 * @returns {string} Empty when reads can be attempted, otherwise details.
 */
function gmcu_text_clipboard_read_diagnostic() {
  var diagnostic = window.gmcu_text_clipboard_read_diagnostic;
  if (typeof diagnostic === 'function') {
    return diagnostic();
  }

  return 'Common Utils clipboard capability bridge is unavailable' +
    ' (secureContext=' + Boolean(window.isSecureContext) +
    ', navigatorClipboard=' + Boolean(navigator.clipboard) +
    ', readText=' + Boolean(navigator.clipboard && typeof navigator.clipboard.readText === 'function') +
    ', userAgent=' + String(navigator.userAgent || '') + ')';
}

/** Track canvas gestures without observing touches on surrounding HTML controls. */
var gmcuTextPointer = null;
var gmcuTextCanvas = document.getElementById('canvas');
if (gmcuTextCanvas) {
  ['pointermove', 'pointerdown'].forEach(function (type) {
    gmcuTextCanvas.addEventListener(type, function (event) {
      if (event.isPrimary) {
        gmcuTextPointer = { x: event.clientX, y: event.clientY };
      }
    });
  });
}

/** Return scaled GUI coordinates or an empty array before the first canvas gesture.
 * @param {number} width GUI width.
 * @param {number} height GUI height.
 * @returns {string} JSON coordinate pair or empty array.
 */
function gmcu_text_pointer_gui(width, height) {
  if (!gmcuTextPointer || !gmcuTextCanvas) {
    return '[]';
  }

  var bounds = gmcuTextCanvas.getBoundingClientRect();
  return JSON.stringify([
    (gmcuTextPointer.x - bounds.left) * width / bounds.width,
    (gmcuTextPointer.y - bounds.top) * height / bounds.height
  ]);
}
