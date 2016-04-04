App.Helpers.PlayerHelpers = {

  calcMinPixelsPerSec: function(waveHeight, mapHeight, pixelRatio) {
    var availablePixels, height, duration,
      pixelsPerSec, maxCanvasWidth, maxCanvasArea;

      if (!pixelRatio) {
        pixelRatio = this.getDevicePixelRatio();
      }

      if (VZ.browser.chrome) {
        maxCanvasWidth = 32767;
        maxCanvasArea  = 16384 * 16384;
      } else if (VZ.browser.safari && !VZ.os.ios) {
        maxCanvasWidth = 32767;
        maxCanvasArea  = 16384 * 16384;
      } else if (VZ.browser.safari && VZ.os.ios) {
        maxCanvasWidth = 8192;
        maxCanvasArea  = 8192 * 8192;
      } else if (VZ.browser.gecko) {
        maxCanvasWidth = 32767;
        maxCanvasArea  = 22528 * 22528;
      } else if (VZ.browser.ie) {
        maxCanvasWidth = 8192;
        maxCanvasArea  = 8192 * 8192;
      } else {
        maxCanvasWidth = 4096;
        maxCanvasArea  = 4096 * 4096;
      }
      height          = this.waveHeight + this.mapHeight,
      duration        = this.model.attributes.track.duration; // in secs
      availablePixels = Math.min(maxCanvasWidth, maxCanvasArea / height);
      pixelsPerSec    = availablePixels / duration / pixelRatio;
      pixelsPerSec    = Math.min(50, Math.max(1, Math.floor(pixelsPerSec)));
      return pixelsPerSec;
  },

  getDevicePixelRatio: function() {
    var ratio = 1;
    // To account for zoom, change to use deviceXDPI instead of systemXDPI
    if (window.screen.systemXDPI !== undefined && window.screen.logicalXDPI       !== undefined && window.screen.systemXDPI > window.screen.logicalXDPI) {
      // Only allow for values > 1
      ratio = window.screen.systemXDPI / window.screen.logicalXDPI;
    } else if (window.devicePixelRatio !== undefined) {
      ratio = window.devicePixelRatio;
    }
    return ratio;
  }

};
