var existingOnLoad = window.onload;

// Wait for the DOM to be fully loaded
window.onload = function () {
  // Function to detect if the user is on a mobile device
  function isMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  }

  /*
  We're going to hide the canvas, but let the game initialize in the background so it can process potential analytics.
  */
  if (existingOnLoad) existingOnLoad();

  if(!isMobileDevice()) return;

  // If it's a mobile device, replace the canvas with a div
  // Find the game canvas element
  var gameDiv = document.getElementById('gm4html5_div_id');
  if(!gameDiv) {
    console.error("gameDiv not found");
    return;
  }

  // Create a new div for the mobile message
  var mobileMessage = document.createElement('div');
  mobileMessage.id = 'mobile-message';
  mobileMessage.className = 'mainBody';
  mobileMessage.innerHTML = `
    <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background-color: white;">
      <div style="text-align: center;">
        <p style="font-size: 50px;">⚠️</p>
        <p style="font-size: 18px; color: black;">
          This game is not designed to be played on mobile. Sorry for the inconvenience.
        </p>
        <form>
          <input type="button" value="Go back!" onclick="history.back()" style="padding: 10px 20px; font-size: 16px;">
        </form>
      </div>
    </div>
  `;

  // Insert the div before the canvas
  gameDiv.parentNode.insertBefore(mobileMessage, gameDiv);

  // Hide the canvas so the game doesn't run
  gameDiv.style.display = 'none';
}
