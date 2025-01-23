import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Complications;

function getWeather() {
  if (Toybox has :Weather) {
    var data = Toybox.Weather.getCurrentConditions();
    return (
      (data.lowTemperature + 0.5).toNumber().toString() +
      "/" +
      (data.highTemperature + 0.5).toNumber().toString()
    );
  }

  return "--";
}

function getCalender() {
  if (Toybox has :Complications) {
    var comp = Complications.getComplication(
      new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS)
    );
    if (comp.value != null) {
      return comp.value;
    }
  }

  return "--";
}

function getSunEvent() {
  if (Toybox has :Position) {
    var positionInfo = Toybox.Position.getInfo();
    if (positionInfo.position == null) {
      return {
        "label" => WatchUi.loadResource($.Rez.Strings.SunEventLabel) as String,
        "value" => "--",
      };
    }
    if (Toybox has :Weather) {
      var time = Time.now();
      var sunrise = Toybox.Weather.getSunrise(positionInfo.position, time);
      var sunset = Toybox.Weather.getSunset(positionInfo.position, time);
      if (sunrise == null || sunset == null) {
        return {
          "label" => WatchUi.loadResource($.Rez.Strings.SunEventLabel) as
          String,
          "value" => "--",
        };
      }

      if (time.compare(sunrise) > 0 && time.compare(sunset) < 0) {
        time = Gregorian.info(sunset, Time.FORMAT_MEDIUM);
        return {
          "label" => WatchUi.loadResource($.Rez.Strings.SunEventLabelSunset) as
          String,
          "value" => Lang.format("$1$:$2$", [
            time.hour,
            time.min.format("%02d"),
          ]),
        };
      } else {
        time = Gregorian.info(sunrise, Time.FORMAT_MEDIUM);
        return {
          "label" => WatchUi.loadResource($.Rez.Strings.SunEventLabelSunrise) as
          String,
          "value" => Lang.format("$1$:$2$", [
            time.hour,
            time.min.format("%02d"),
          ]),
        };
      }
    }
    return {
      "label" => WatchUi.loadResource($.Rez.Strings.SunEventLabel) as String,
      "value" => "--",
    };
  }

  return "--";
}

function getDate() {
  var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
  return Lang.format("$1$, $2$", [now.day_of_week, now.day]).toLower();
}

function getNotification() {
  if (Toybox.System.getDeviceSettings() has :notificationCount) {
    return Toybox.System.getDeviceSettings().notificationCount.toString();
  }

  return "--";
}

function getBattery() {
  var data = null;
  if (Toybox has :Complications) {
    var comp = Complications.getComplication(
      new Complications.Id(Complications.COMPLICATION_TYPE_BATTERY)
    );
    if (comp.value != null) {
      data = comp.value;
    }
  }
  if (data == null) {
    if (Toybox has :System) {
      if (Toybox.System.getSystemStats() has :battery) {
        data = Toybox.System.getSystemStats().battery;
      }
    }
  }
  if (data == null) {
    return "--";
  }
  return data.format("%d");
}

function getAltitude() {
  var data = null;
  if (Toybox has :Complications) {
    var comp = Complications.getComplication(
      new Complications.Id(Complications.COMPLICATION_TYPE_ALTITUDE)
    );
    if (comp.value != null) {
      data = comp.value;
    }
  }
  if (data == null) {
    if (Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :altitude) {
        data = Toybox.Activity.getActivityInfo().altitude;
      }
    }
  }
  if (data == null) {
    var iterator = Toybox.SensorHistory.getElevationHistory({});
    var sample = iterator.next();
    if (sample.data != null) {
      data = sample.data;
    } else {
      return "--";
    }
  }

  if (data == null) {
    return "--";
  }
  data = (data + 0.5).toNumber().toString();
  return data;
}

function getHeartrate() {
  var data = null;
  if (Toybox has :Complications) {
    var comp = Complications.getComplication(
      new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE)
    );
    if (comp.value != null) {
      data = comp.value;
    }
  }
  if (data == "--") {
    if (Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :currentHeartRate) {
        data = Toybox.Activity.getActivityInfo().currentHeartRate;
      }
    }
  }
  if (data == "--") {
    if (Toybox has :SensorHistory) {
      if (Toybox.SensorHistory has :getHeartRateHistory) {
        var iterator = Toybox.SensorHistory.getHeartRateHistory({});
        var sample = iterator.next();
        if (
          sample.data != null &&
          sample.data != Toybox.ActivityMonitor.INVALID_HR_SAMPLE
        ) {
          data = sample.data;
        } else {
          return "--";
        }
      }
    }
  }

  if (data == null) {
    return "--";
  }
  return Lang.format("$1$", [data]);
}

function getPressure() {
  var data = null;
  if (Toybox has :Complications) {
    var comp = Complications.getComplication(
      new Complications.Id(Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE)
    );
    if (comp.value != null) {
      data = comp.value;
    }
  }
  if (data == null) {
    if (Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :meanSeaLevelPressure) {
        data = Toybox.Activity.getActivityInfo().meanSeaLevelPressure;
      }
    }
  }
  if (data == null) {
    if (Toybox has :SensorHistory) {
      if (Toybox.SensorHistory has :getStressHistory) {
        var iterator = Toybox.SensorHistory.getPressureHistory({});
        var sample = iterator.next();
        if (sample != null) {
          data = sample.data;
        } else {
          return "--";
        }
      }
    }
  }

  if (data == null) {
    return "--";
  }
  data = data / 100;
  data = (data + 0.5).toNumber().toString();
  return Lang.format("$1$", [data]);
}
