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
  var virtualPointerKeys = new Map(); // Original virtual button by pointer ID across pointer capture.
  var lastError = 'No copy attempt yet'; // Browser diagnostic shown when a copy fails.
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
  }
  /** Forget virtual-control gestures that are canceled before release.
   * @param {PointerEvent} event Browser pointer cancellation or capture loss.
   */
  function forgetVirtualPointer(event) {
    virtualPointerKeys.delete(event.pointerId);
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

    if (!canvas || (event.target !== canvas && !canvas.contains(event.target))) {
      return;
    }

    var rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) {
      return;
    }

    var guiX = (event.clientX - rect.left) * pendingCopy.guiWidth / rect.width;
    var guiY = (event.clientY - rect.top) * pendingCopy.guiHeight / rect.height;
    if (guiX < pendingCopy.x - pendingCopy.width / 2 || guiX > pendingCopy.x + pendingCopy.width / 2 ||
        guiY < pendingCopy.y - pendingCopy.height / 2 || guiY > pendingCopy.y + pendingCopy.height / 2) {
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
        allowVirtualControllerA: options.allowVirtualControllerA
      };
      return true;
    } catch (error) {
      pendingCopy = null;
      return false;
    }
  };
  document.addEventListener('pointerdown', pointerDown, true);
  document.addEventListener('pointerup', pointerUp, true);
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
})();
