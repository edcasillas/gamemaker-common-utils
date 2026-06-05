function gmcuHtml5IsMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
        navigator.userAgent
    );
}

function gmcuHtml5BlockCanvas(message) {
    var gameDiv = document.getElementById("gm4html5_div_id");
    if (!gameDiv || !gameDiv.parentNode) {
        console.error("[GMCU HTML5] Game canvas container was not found.");
        return false;
    }

    var existingMessage = document.getElementById("gmcu-html5-block-message");
    if (existingMessage) {
        existingMessage.remove();
    }

    var messageContainer = document.createElement("div");
    messageContainer.id = "gmcu-html5-block-message";
    messageContainer.className = "mainBody";
    messageContainer.style.display = "flex";
    messageContainer.style.justifyContent = "center";
    messageContainer.style.alignItems = "center";
    messageContainer.style.minHeight = "100vh";
    messageContainer.style.backgroundColor = "white";
    messageContainer.style.color = "black";

    var content = document.createElement("div");
    content.style.maxWidth = "36rem";
    content.style.padding = "2rem";
    content.style.textAlign = "center";

    var warning = document.createElement("p");
    warning.textContent = "!";
    warning.style.fontSize = "3rem";
    warning.style.fontWeight = "bold";
    warning.style.margin = "0 0 1rem";

    var text = document.createElement("p");
    text.textContent = String(message);
    text.style.fontSize = "1.125rem";
    text.style.lineHeight = "1.5";

    var backButton = document.createElement("button");
    backButton.type = "button";
    backButton.textContent = "Go back";
    backButton.style.padding = "0.625rem 1.25rem";
    backButton.style.fontSize = "1rem";
    backButton.addEventListener("click", function () {
        history.back();
    });

    content.appendChild(warning);
    content.appendChild(text);
    content.appendChild(backButton);
    messageContainer.appendChild(content);
    gameDiv.parentNode.insertBefore(messageContainer, gameDiv);
    gameDiv.style.display = "none";

    return true;
}

function gmcuHtml5ConsoleError(message) {
    console.error(String(message));
}
