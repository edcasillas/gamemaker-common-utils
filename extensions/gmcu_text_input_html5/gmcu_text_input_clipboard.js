/* Clipboard bridge for canvas controls, using WebKit's documented gesture fallback. */
(function () {
  var canvas = document.getElementById('canvas');
  var copyField = document.createElement('input');
  copyField.type = 'text';
  copyField.setAttribute('aria-hidden', 'true');
  copyField.setAttribute('tabindex', '-1');
  copyField.style.position = 'fixed';
  copyField.style.opacity = '0';

  var pendingCopy = null;
  var recentCopy = null;
  var lastError = 'No copy attempt yet';
  /** Copies through the DOM selection fallback during the trusted browser event. */
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
  /** Copies the prepared value when a trusted pointer release hits its GUI bounds. */
  function pointerUp(event) {
    if (!event.isPrimary || (event.button != null && event.button !== 0) || !pendingCopy || !pendingCopy.text) return;
    var rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    var guiX = (event.clientX - rect.left) * pendingCopy.guiWidth / rect.width;
    var guiY = (event.clientY - rect.top) * pendingCopy.guiHeight / rect.height;
    if (guiX < pendingCopy.x - pendingCopy.width / 2 || guiX > pendingCopy.x + pendingCopy.width / 2 ||
        guiY < pendingCopy.y - pendingCopy.height / 2 || guiY > pendingCopy.y + pendingCopy.height / 2) return;
    var result = write(pendingCopy.text);
    recentCopy = { text: pendingCopy.text, ok: result.ok, error: result.error, time: Date.now() };
  }
  window.gmcu_text_clipboard_prepare = function (text, geometry) {
    try {
      var values = JSON.parse(geometry);
      if (values.length !== 6 || !values.every(Number.isFinite)) return false;
      if (!pendingCopy || pendingCopy.text !== String(text)) recentCopy = null;
      pendingCopy = { text: String(text), x: values[0], y: values[1], width: values[2], height: values[3], guiWidth: values[4], guiHeight: values[5] };
      return true;
    } catch (error) { pendingCopy = null; return false; }
  };
  if (canvas) canvas.addEventListener('pointerup', pointerUp);
  window.gmcu_text_clipboard_write = function (text) {
    if (recentCopy && recentCopy.text === String(text) && Date.now() - recentCopy.time < 1200) {
      var result = recentCopy;
      recentCopy = null;
      if (!result.ok) lastError = result.error + ' (secureContext=' + Boolean(window.isSecureContext) +
        ', asyncClipboard=' + Boolean(navigator.clipboard) + ')';
      return result.ok;
    }
    lastError = 'No trusted canvas pointer event reached the COPY target (secureContext=' +
      Boolean(window.isSecureContext) + ', asyncClipboard=' + Boolean(navigator.clipboard) + ')';
    return false;
  };
  window.gmcu_text_clipboard_last_error = function () { return lastError; };
})();
