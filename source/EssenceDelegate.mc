using Toybox.WatchUi as Ui;
using Toybox.Complications as Complications;

class EssenceDelegate extends Ui.WatchFaceDelegate {
  function initialize() {
    WatchFaceDelegate.initialize();
  }

  public function onPress(clickEvent) {
    var co_ords = clickEvent.getCoordinates();
    var complicationId = checkBoundingBoxes(co_ords);
    if (complicationId) {
      var thisComplication = new Complications.Id(complicationId);
      if (thisComplication) {
        Complications.exitTo(thisComplication);
      }
      return true;
    }
    return false;
  }
}
