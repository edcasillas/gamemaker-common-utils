/** Show the mobile warning before the browser reaches the game runner script. */
(function () {
  var mobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
    || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (!mobile || document.getElementById('mobile-message')) return;

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

  // Hide gameplay while allowing runtime initialization and analytics.
  gameDiv.style.display = 'none';
})();
