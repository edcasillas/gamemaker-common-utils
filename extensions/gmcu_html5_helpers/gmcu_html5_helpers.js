/**
 * Returns whether the browser user agent identifies a mobile device.
 */
function gmcuHtml5IsMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
        navigator.userAgent
    );
}

/**
 * Replaces the GameMaker canvas with a consumer-provided blocking message.
 */
function gmcuHtml5BlockCanvas(message) {
    var gameDiv = document.getElementById("gm4html5_div_id");
    if (gameDiv) {
        var messageDiv = document.createElement("div");
        messageDiv.id = "disabler-message";
        messageDiv.className = "mainBody";
        messageDiv.innerHTML = `
        <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background-color: white;">
            <div style="text-align: center;">
            <p style="font-size: 50px;">⚠️</p>
            <p style="font-size: 18px; color: black;"> ` + message + ` </p>
            <form>
                <input type="button" value="Go back!" onclick="history.back()" style="padding: 10px 20px; font-size: 16px;">
            </form>
            </div>
        </div>
        `;

        gameDiv.parentNode.insertBefore(messageDiv, gameDiv);
        gameDiv.style.display = "none";
    } else {
        console.error("Game canvas was not found.");
    }

    var id = window.setTimeout(function() {}, 0);
    while (id--) {
        window.clearTimeout(id);
        window.clearInterval(id);
    }

    console.log("Game canvas disabled, and all events and timers cleared.");
}

/**
 * Generates a UUID through the secure-context browser Crypto API.
 */
function gmcuHtml5GenerateUuid() {
    return crypto.randomUUID();
}

/**
 * Writes a debug message using the browser's native console severity.
 */
function gmcuHtml5ConsoleDebug(message) {
    console.debug(String(message));
}

/**
 * Writes an informational message using the browser's native console severity.
 */
function gmcuHtml5ConsoleInfo(message) {
    console.info(String(message));
}

/**
 * Writes a warning using the browser's native console severity.
 */
function gmcuHtml5ConsoleWarn(message) {
    console.warn(String(message));
}

/**
 * Writes an error using the browser's native console severity.
 */
function gmcuHtml5ConsoleError(message) {
    console.error(String(message));
}
