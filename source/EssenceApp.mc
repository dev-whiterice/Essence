// ============================================================================
// EssenceApp.mc
// Application entry point.
// Instantiates the view (and delegate when Complications are available),
// and propagates settings-change events to the view layer.
// ============================================================================

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class EssenceApp extends Application.AppBase {

  // Retained so subclasses or future code can reference the live view instance.
  var essenceView;

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state as Dictionary?) as Void {}

  function onStop(state as Dictionary?) as Void {}

  // Build and return the initial view stack.
  // The tap delegate (EssenceDelegate) is only attached when the device
  // supports the Complications API; on older firmware the watch face is
  // display-only and ignores touch input.
  function getInitialView() as [Views] or [Views, InputDelegates] {
    essenceView = new EssenceView();
    if (Toybox has :Complications) {
      return [essenceView, new EssenceDelegate()];
    } else {
      return [essenceView];
    }
  }

  // Called by the system whenever the user changes a watch face setting.
  // Rather than rebuilding the layout here (which may be called off the
  // render thread), we set a flag and let the next onUpdate() handle it.
  function onSettingsChanged() as Void {
    redrawLayout = true;
    WatchUi.requestUpdate();
  }

  // Return the settings UI shown when the user long-presses on the face
  // or opens settings from the Garmin Connect app.
  public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
    return [new $.EssenceSettingsMenu(), new $.EssenceSettingsMenuDelegate()];
  }
}

// Module-level convenience accessor used throughout the codebase instead of
// the verbose Application.getApp() cast.
function getApp() as EssenceApp {
  return Application.getApp() as EssenceApp;
}
