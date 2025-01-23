import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class EssenceApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {}

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {}

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    if (Toybox has :Complications) {
      return [new EssenceView(), new EssenceDelegate()];
    } else {
      return [new EssenceView()];
    }
  }
}

function getApp() as EssenceApp {
  return Application.getApp() as EssenceApp;
}
