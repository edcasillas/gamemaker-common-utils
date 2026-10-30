/* Clipboard bridge for canvas controls, using WebKit's documented gesture fallback. */
(function () {
  var canvas = document.getElementById('canvas'); // GameMaker canvas receiving trusted pointer gestures.
  var copyField = document.createElement('input'); // Temporary selectable element for synchronous copy.
  copyField.type = 'text';
  copyField.setAttribute('aria-hidden', 'true');
  copyField.setAttribute('tabindex', '-1');
  copyField.style.position = 'fixed';
  copyField.style.opacity = '0';

  var pendingCopy = null; // Text and GUI bounds prepared by the host's draw event.
  var recentCopy = null; // Trusted gesture result consumed by GameMaker's later release callback.
  var pendingPaste = null; // Textbox identity and PASTE key bounds prepared by the keyboard draw event.
  var recentPaste = null; // Trusted paste request consumed by GameMaker's later key callback.
  var virtualPointerKeys = new Map(); // Original virtual button by pointer ID across pointer capture.
  var lastError = 'No copy attempt yet'; // Browser diagnostic shown when a copy fails.

  /** Return the current Permissions Policy decision for clipboard reads.
   * @returns {boolean|null} True, false, or null when the browser cannot report it.
   */
  function clipboardReadPolicy() {
    var policy = document.permissionsPolicy || document.featurePolicy;
    if (!policy || typeof policy.allowsFeature !== 'function') {
      return null;
    }

    try {
      return policy.allowsFeature('clipboard-read');
    } catch (error) {
      return null;
    }
  }

  /** Describe the browser context relevant to clipboard-read failures.
   * @returns {string} Diagnostic key/value list.
   */
  function clipboardReadContext() {
    return 'secureContext=' + Boolean(window.isSecureContext) +
      ', navigatorClipboard=' + Boolean(navigator.clipboard) +
      ', readText=' + Boolean(navigator.clipboard && typeof navigator.clipboard.readText === 'function') +
      ', permissionsPolicy=' + String(clipboardReadPolicy()) +
      ', topLevel=' + Boolean(window.top === window) +
      ', origin=' + String(window.location && window.location.origin || '') +
      ', userAgent=' + String(navigator.userAgent || '');
  }

  /** Describe why programmatic clipboard reads are unavailable.
   * @returns {string} Empty when readText can be attempted, otherwise a diagnostic.
   */
  function pasteReadDiagnostic() {
    var policyAllowsRead = clipboardReadPolicy();
    var context = clipboardReadContext();

    if (!window.isSecureContext) {
      return 'Clipboard read requires a secure context (' + context + ')';
    }

    if (!navigator.clipboard || typeof navigator.clipboard.readText !== 'function') {
      return 'Clipboard readText API unavailable (' + context + ')';
    }

    if (policyAllowsRead === false) {
      return 'Permissions Policy blocks clipboard-read (' + context + ')';
    }

    return '';
  }
  /** Copy text synchronously through the DOM fallback during a trusted browser event.
   * @param {string} text Text supplied by the host.
   * @returns {{ok: boolean, error: string}} Browser result and diagnostic.
   */
  function write(text) {
    var result = { ok: false, error: '' };
    try {
      copyField.value = String(text);
      document.body.appendChild(copyField);
      copyField.focus();
      copyField.setSelectionRange(0, copyField.value.length);
      if (typeof document.execCommand !== 'function') {
        result.error = 'execCommand unavailable';
      } else if (!document.execCommand('copy')) {
        result.error = 'execCommand returned false';
      } else {
        result.ok = true;
      }
    } catch (error) {
      result.error = (error && error.name ? error.name + ': ' : '') + String(error && error.message || error);
    } finally {
      copyField.remove();
    }
    if (!result.ok) {
      lastError = result.error + ' (secureContext=' + Boolean(window.isSecureContext) +
        ', asyncClipboard=' + Boolean(navigator.clipboard) + ')';
    } else {
      lastError = '';
    }
    return result;
  }
  /** Store a completed result for the matching GameMaker copy request.
   * @param {string} text Prepared host value.
   */
  function rememberCopy(text) {
    var result = write(text);
    recentCopy = { text: text, ok: result.ok, error: result.error, time: Date.now() };
  }
  /** Return whether a trusted canvas pointer is inside prepared GUI bounds.
   * @param {PointerEvent} event Browser pointer event.
   * @param {object} prepared GUI bounds and dimensions.
   * @returns {boolean} Whether the pointer targets the prepared control.
   */
  function hitsCanvasBounds(event, prepared) {
    if (!canvas || (event.target !== canvas && !canvas.contains(event.target))) {
      return false;
    }

    var rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) {
      return false;
    }

    var guiX = (event.clientX - rect.left) * prepared.guiWidth / rect.width;
    var guiY = (event.clientY - rect.top) * prepared.guiHeight / rect.height;
    return guiX >= prepared.x - prepared.width / 2 && guiX <= prepared.x + prepared.width / 2
      && guiY >= prepared.y - prepared.height / 2 && guiY <= prepared.y + prepared.height / 2;
  }
  /** Read the clipboard during the trusted event and queue the asynchronous result.
   * @param {object} prepared Textbox owner, token, and target bounds.
   */
  function readPaste(prepared) {
    var generation = gmcuTextInput.generation;
    recentPaste = { owner: prepared.owner, token: prepared.token, time: Date.now() };

    function finish(ok, text, error) {
      if (!gmcuTextInput.active || generation !== gmcuTextInput.generation) {
        return;
      }

      gmcuTextInput.queue.push({
        kind: 'clipboard',
        action: 'paste',
        owner: prepared.owner,
        token: prepared.token,
        ok: ok,
        value: text || '',
        error: error || ''
      });
    }

    var unavailableReason = pasteReadDiagnostic();
    if (unavailableReason) {
      finish(false, '', unavailableReason);
      return;
    }

    var request;
    try {
      request = navigator.clipboard.readText();
    } catch (error) {
      finish(false, '', (error && error.name ? error.name + ': ' : '') + String(error && error.message || error));
      return;
    }

    Promise.resolve(request).then(
      function (text) { finish(true, text, ''); },
      function (error) {
        var failure = (error && error.name ? error.name + ': ' : '') + String(error && error.message || error);
        finish(false, '', failure + ' (' + clipboardReadContext() + ')');
      }
    );
  }
  /** Record which virtual-control button starts a trusted pointer gesture.
   * @param {PointerEvent} event Browser pointer press before pointer capture.
   */
  function pointerDown(event) {
    if (!event.isTrusted || !event.isPrimary || (event.button != null && event.button !== 0)) {
      return;
    }

    var button = event.target && event.target.closest && event.target.closest('#hvc-controls [data-key]');
    if (button) {
      virtualPointerKeys.set(event.pointerId, button.dataset.key);
    }

    if (!pendingPaste) {
      return;
    }

    if (button && button.dataset.key === '0' && pendingPaste.allowVirtualControllerA) {
      readPaste(pendingPaste);
      return;
    }

    if (hitsCanvasBounds(event, pendingPaste)) {
      readPaste(pendingPaste);
    }
  }
  /** Forget virtual-control gestures that are canceled before release.
   * @param {PointerEvent} event Browser pointer cancellation or capture loss.
   */
  function forgetVirtualPointer(event) {
    virtualPointerKeys.delete(event.pointerId);
  }
  /** Copy during the trusted physical Enter key event for an armed control.
   * @param {KeyboardEvent} event Browser keyboard event.
   */
  function keyDown(event) {
    if (!event.isTrusted || event.repeat || event.key !== 'Enter' || !pendingCopy ||
        !pendingCopy.text || !pendingCopy.allowKeyboardEnter) {
      return;
    }

    rememberCopy(pendingCopy.text);
  }
  /** Copy on a trusted canvas target or an armed virtual-controller A release.
   * @param {PointerEvent} event Browser pointer release.
   */
  function pointerUp(event) {
    var virtualKey = virtualPointerKeys.get(event.pointerId);
    virtualPointerKeys.delete(event.pointerId);
    if (!event.isTrusted || !event.isPrimary || (event.button != null && event.button !== 0) || !pendingCopy || !pendingCopy.text) {
      return;
    }

    var virtualRegion = event.target && event.target.closest && event.target.closest('#hvc-controls .vc-region');
    if (virtualRegion && virtualKey === '0') {
      if (!pendingCopy.allowVirtualControllerA) {
        return;
      }

      rememberCopy(pendingCopy.text);
      return;
    }

    if (!hitsCanvasBounds(event, pendingCopy)) {
      return;
    }

    rememberCopy(pendingCopy.text);
  }
  /** Prepare host copy text and gesture targets.
   * @param {string} text Text to copy.
   * @param {string} optionsJson JSON bounds and virtual-controller eligibility.
   * @returns {boolean} Whether the prepared data is valid.
   */
  window.gmcu_text_clipboard_prepare = function (text, optionsJson) {
    try {
      var options = JSON.parse(optionsJson);
      var bounds = options.bounds;
      if (!Array.isArray(bounds) || bounds.length !== 6 || !bounds.every(Number.isFinite) ||
          typeof options.allowVirtualControllerA !== 'boolean') {
        return false;
      }

      if (!pendingCopy || pendingCopy.text !== String(text)) {
        recentCopy = null;
      }

      pendingCopy = {
        text: String(text),
        x: bounds[0],
        y: bounds[1],
        width: bounds[2],
        height: bounds[3],
        guiWidth: bounds[4],
        guiHeight: bounds[5],
        allowVirtualControllerA: options.allowVirtualControllerA,
        allowKeyboardEnter: options.allowKeyboardEnter === true
      };
      return true;
    } catch (error) {
      pendingCopy = null;
      return false;
    }
  };
  /** Prepare the active PASTE key for a trusted browser gesture.
   * @param {string} owner Active textbox instance ID.
   * @param {string} optionsJson JSON bounds and virtual-controller eligibility.
   * @param {number} token Clipboard request token expected by the textbox.
   * @returns {boolean} Whether the prepared data is valid.
   */
  window.gmcu_text_clipboard_prepare_paste = function (owner, optionsJson, token) {
    try {
      var options = JSON.parse(optionsJson);
      var bounds = options.bounds;
      if (!Array.isArray(bounds) || bounds.length !== 6 || !bounds.every(Number.isFinite) ||
          typeof options.allowVirtualControllerA !== 'boolean') {
        return false;
      }

      pendingPaste = {
        owner: String(owner),
        token: token,
        x: bounds[0],
        y: bounds[1],
        width: bounds[2],
        height: bounds[3],
        guiWidth: bounds[4],
        guiHeight: bounds[5],
        allowVirtualControllerA: options.allowVirtualControllerA
      };
      return true;
    } catch (error) {
      pendingPaste = null;
      return false;
    }
  };
  /** Consume a trusted paste request before GameMaker starts a duplicate read.
   * @param {string} owner Active textbox instance ID.
   * @param {number} token Clipboard request token.
   * @returns {boolean} Whether the trusted request is already running.
   */
  window.gmcu_text_clipboard_consume_paste = function (owner, token) {
    if (recentPaste && recentPaste.owner === String(owner) && recentPaste.token === token && Date.now() - recentPaste.time < 1200) {
      recentPaste = null;
      return true;
    }

    return false;
  };
  /** Discard prepared paste state when text editing ends. */
  window.gmcu_text_clipboard_clear_paste = function () {
    pendingPaste = null;
    recentPaste = null;
  };
  document.addEventListener('pointerdown', pointerDown, true);
  document.addEventListener('pointerup', pointerUp, true);
  document.addEventListener('keydown', keyDown, true);
  document.addEventListener('pointercancel', forgetVirtualPointer, true);
  document.addEventListener('lostpointercapture', forgetVirtualPointer, true);
  window.gmcu_text_clipboard_write = function (text) {
    if (recentCopy && recentCopy.text === String(text) && Date.now() - recentCopy.time < 1200) {
      var result = recentCopy;
      recentCopy = null;
      if (!result.ok) {
        lastError = result.error + ' (secureContext=' + Boolean(window.isSecureContext) +
          ', asyncClipboard=' + Boolean(navigator.clipboard) + ')';
      }

      return result.ok;
    }
    lastError = 'No trusted canvas or virtual-controller A event reached the COPY target (secureContext=' +
      Boolean(window.isSecureContext) + ', asyncClipboard=' + Boolean(navigator.clipboard) + ')';
    return false;
  };
  window.gmcu_text_clipboard_last_error = function () {
    return lastError;
  };
  /** Return whether the page can attempt a programmatic clipboard read. */
  window.gmcu_text_clipboard_can_read = function () {
    return pasteReadDiagnostic() === '';
  };
  /** Return the current clipboard-read capability diagnostic. */
  window.gmcu_text_clipboard_read_diagnostic = function () {
    return pasteReadDiagnostic();
  };
})();
