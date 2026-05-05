// ============================================================================
// EssenceDelegate.mc
// Touch input handler for the watch face.
//
// Registered as the WatchFaceDelegate only when Complications are available
// (see EssenceApp.getInitialView). Its sole responsibility is to intercept
// screen taps and launch the complication app associated with the tapped zone.
// ============================================================================

using Toybox.WatchUi as Ui;
using Toybox.Complications as Complications;

class EssenceDelegate extends Ui.WatchFaceDelegate {

  function initialize() {
    WatchFaceDelegate.initialize();
  }

  // Called on every tap / press event.
  //
  // Flow:
  //   1. Bail out immediately in battery-save mode (no interactive zones).
  //   2. Hit-test the tap coordinate against the bounding-box registry.
  //   3. If a zone with a valid complication is hit, call Complications.exitTo()
  //      to launch the associated complication app.
  //   4. Return true if we consumed the event, false to let the system handle it.
  public function onPress(clickEvent) {
    if (batterySave == false) {
      var co_ords        = clickEvent.getCoordinates();
      var complicationId = checkBoundingBoxes(co_ords);

      if (complicationId) {
        var thisComplication = new Complications.Id(complicationId);
        if (thisComplication) {
          Complications.exitTo(thisComplication);
        }
        return true;
      }
    }
    return false;
  }
}
