import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class EssenceApp extends Application.AppBase {
  var essenceView;
  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {}

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {}

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    essenceView = new EssenceView();
    if (Toybox has :Complications) {
      return [essenceView, new EssenceDelegate()];
    } else {
      return [essenceView];
    }
  }

  function onSettingsChanged() as Void {
    loadLayout();
    essenceView.changedLayout();
  }
}

function getApp() as EssenceApp {
  return Application.getApp() as EssenceApp;
}
