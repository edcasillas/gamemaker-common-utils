/** Capture browser text without focusing an editable element on mobile. */
var gmcuTextInput = { active: false, queue: [], installed: false };

/** Start capturing keyboard and paste events for the active textbox.
 * @returns {number} GameMaker extension success sentinel.
 */
function gmcu_text_capture_begin() {
  var capture = gmcuTextInput;
  capture.active = true;
  capture.queue = [];

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
  function finish(ok, text) {
    gmcuTextInput.queue.push({
      kind: 'clipboard',
      action: action,
      owner: owner,
      token: token,
      ok: ok,
      value: text || ''
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

  if (!navigator.clipboard) {
    finish(false, '');
    return 0;
  }

  var request;
  try {
    request = navigator.clipboard.readText();
  } catch (error) {
    finish(false, '');
    return 0;
  }

  Promise.resolve(request).then(
    function (text) { finish(true, text); },
    function () { finish(false, ''); }
  );
  return 0;
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
