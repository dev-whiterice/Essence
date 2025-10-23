import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time.Gregorian;

class EssenceView extends WatchUi.WatchFace {
  var dw = 0;
  var dh = 0;

  var graphWidthFactor = 1;
  var graphVertOffset = 69;

  var bGrondFillerWhite;

  function initialize() {
    WatchFace.initialize();
    bGrondFillerWhite = new Rez.Drawables.bGrondFillerWhite();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    dw = dc.getWidth();
    dh = dc.getHeight();
    batterySave = getApp().getProperty("BatterySave");
    showGraph = getApp().getProperty("ShowGraph");
    graphSize = getApp().getProperty("GraphSize");
    if (graphSize == null) {
      graphSize = 0;
    }
    darkMode = getApp().getProperty("DarkMode");

    defineBoundingBoxes(dc);

    if (dh == 454) {
      graphVertOffset = 128;
      graphWidthFactor = 1.5;
    }

    if (dh == 260) {
      graphVertOffset = 61;
      graphWidthFactor = 0.9;
    }

    if (batterySave == false) {
      if (darkMode == true) {
        setLayout(Rez.Layouts.WatchFace(dc));
      } else {
        setLayout(Rez.Layouts.WatchFaceLight(dc));
      }
      loadLayout();
      drawLabels(dc);
    } else {
      if (darkMode == true) {
        setLayout(Rez.Layouts.BatterySave(dc));
      } else {
        setLayout(Rez.Layouts.BatterySaveLight(dc));
      }
    }
  }

  function drawLabels(dc) {
    var view;
    for (var i = 0; i < fieldLayout.size(); i = i + 1) {
      if (i == 5 && showGraph > 0 && graphSize == 0) {
        view = View.findDrawableById(fieldLayout[i]["id"] + "Label") as Text;
        view.setText("");
      } else if (
        (i == 4 || i == 5 || i == 6) &&
        showGraph > 0 &&
        graphSize == 1
      ) {
        view = View.findDrawableById(fieldLayout[i]["id"] + "Label") as Text;
        view.setText("");
      } else {
        view = View.findDrawableById(fieldLayout[i]["id"] + "Label") as Text;
        view.setText(
          WatchUi.loadResource(fieldCatalog[fieldLayout[i]["data"]]["label"]) as
            String
        );
      }
    }

    if (showGraph > 0) {
      view = View.findDrawableById("FieldGraphLabel") as Text;
      view.setText(
        WatchUi.loadResource(graphCatalog[showGraph]["label"]) as String
      );
    }
  }

  function defineBoundingBoxes(dc) {
    // "bounds" format is an array as follows [  [x1,y1] , [x2,y2] ]
    //
    //   [x1,y1] --------------+
    //      |                  |
    //      |                  |
    //      +---------------[x2,y2]
    //

    var bboxTop = [
      [dw / 3, 0],
      [dw / 3 + dw / 3, dh / 6],
    ];

    var bboxUpperLeft = [
      [0, dh / 6],
      [dw / 3, dh / 6 + dh / 6],
    ];

    var bboxUpperCenter = [
      [dw / 3, dh / 6],
      [dw / 3 + dw / 3, dh / 6 + dh / 6],
    ];

    var bboxUpperRight = [
      [dw / 3 + dw / 3, dh / 6],
      [dw, dh / 6 + dh / 6],
    ];

    var bboxLowerLeft = [
      [0, dh / 1.5],
      [dw / 3, dh / 1.5 + dh / 6],
    ];

    var bboxLowerCenter = [
      [dw / 3, dh / 1.5],
      [dw / 3 + dw / 3, dh / 1.5 + dh / 6],
    ];

    var bboxLowerRight = [
      [dw / 3 + dw / 3, dh / 1.5],
      [dw, dh / 1.5 + dh / 6],
    ];

    if (graphSize == 1) {
      bboxLowerLeft = [
        [0, 0],
        [0, 0],
      ];
      bboxLowerCenter = [
        [0, dh / 1.5],
        [dw, dh / 1.5 + dh / 6],
      ];
      bboxLowerRight = [
        [0, 0],
        [0, 0],
      ];
    }

    var bboxLower = [
      [dw / 3, dh - dh / 6],
      [dw / 3 + dw / 3, dh],
    ];

    boundingBoxes = [
      {
        "id" => "FieldTop",
        "bounds" => bboxTop,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_CURRENT_WEATHER,
      },
      {
        "id" => "FieldUpperLeft",
        "bounds" => bboxUpperLeft,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_CALENDAR_EVENTS,
      },
      {
        "id" => "FieldUpperCenter",
        "bounds" => bboxUpperCenter,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT,
      },
      {
        "id" => "FieldUpperRight",
        "bounds" => bboxUpperRight,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_SUNRISE,
      },

      {
        "id" => "FieldLowerLeft",
        "bounds" => bboxLowerLeft,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_ALTITUDE,
      },
      {
        "id" => "FieldLowerCenter",
        "bounds" => bboxLowerCenter,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_HEART_RATE,
      },
      {
        "id" => "FieldLowerRight",
        "bounds" => bboxLowerRight,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE,
      },
      {
        "id" => "FieldBottom",
        "bounds" => bboxLower,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_BATTERY,
      },
    ];
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  // Update the view
  function onUpdate(dc as Dc) as Void {
    if (redrawLayout) {
      onLayout(dc);
      redrawLayout = false;
    }

    if (batterySave == false) {
      drawData(dc);
    }

    drawDate(dc);
    drawTime(dc);
    drawIcons(dc);

    View.onUpdate(dc);

    if (batterySave == false) {
      if (showGraph > 0) {
        drawGraph(dc);
      }
    }
    // drawBoundingBoxes(dc);
  }

  function drawData(dc) {
    var view;
    var fun;
    for (var i = 0; i < fieldLayout.size(); i = i + 1) {
      if (i == 5 && showGraph > 0 && graphSize == 0) {
        view = View.findDrawableById(fieldLayout[i]["id"] + "Data") as Text;
        view.setText("");
      } else if (
        (i == 4 || i == 5 || i == 6) &&
        showGraph > 0 &&
        graphSize == 1
      ) {
        view = View.findDrawableById(fieldLayout[i]["id"] + "Data") as Text;
        view.setText("");
      } else {
        view = View.findDrawableById(fieldLayout[i]["id"] + "Data") as Text;

        if (fieldLayout[i]["data"].equals(4)) {
          // SunEvent exception
          var sunEvent = getSunEvent();
          view.setText(sunEvent["value"]);

          view = View.findDrawableById(fieldLayout[i]["id"] + "Label") as Text;
          view.setText(sunEvent["label"]);
        } else {
          fun = fieldCatalog[fieldLayout[i]["data"]]["getter"];
          fun = method(fun);
          view.setText(fun.invoke());
        }
      }
    }

    if (showGraph > 0) {
      view = View.findDrawableById("FieldGraphData") as Text;
      fun = graphCatalog[showGraph]["getter"];
      fun = method(fun);
      view.setText(fun.invoke());
    }
  }

  function drawDate(dc) {
    var view = View.findDrawableById("FieldDate") as Text;
    view.setText(getDate());
  }

  function drawTime(dc as Dc) {
    var timeFormat = "$1$:$2$";
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    if (!System.getDeviceSettings().is24Hour) {
      if (hours > 12) {
        hours = hours - 12;
      }
    } else {
      if (Application.getApp().getProperty("UseMilitaryFormat")) {
        timeFormat = "$1$$2$";
        hours = hours.format("%02d");
      }
    }
    var timeString = Lang.format(timeFormat, [
      hours,
      clockTime.min.format("%02d"),
    ]);

    var view = View.findDrawableById("FieldTime") as Text;
    view.setText(timeString);
  }

  function getEmpty() {
    return "";
  }

  function getWeather() {
    if (Toybox has :Weather) {
      var data = Toybox.Weather.getCurrentConditions();
      if (data == null) {
        return "--";
      }
      return (
        (data.lowTemperature + 0.5).toNumber().toString() +
        "/" +
        (data.highTemperature + 0.5).toNumber().toString()
      );
    }

    return "--";
  }

  function getCalendar() {
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
          "label" => WatchUi.loadResource($.Rez.Strings.SunEvent) as String,
          "value" => "--",
        };
      }
      if (Toybox has :Weather) {
        var time = Time.now();
        var sunrise = Toybox.Weather.getSunrise(positionInfo.position, time);
        var sunset = Toybox.Weather.getSunset(positionInfo.position, time);
        if (sunrise == null || sunset == null) {
          return {
            "label" => WatchUi.loadResource($.Rez.Strings.SunEvent) as String,
            "value" => "--",
          };
        }

        if (time.compare(sunrise) > 0 && time.compare(sunset) < 0) {
          time = Gregorian.info(sunset, Time.FORMAT_MEDIUM);
          return {
            "label" => WatchUi.loadResource($.Rez.Strings.SunEventSet) as
            String,
            "value" => Lang.format("$1$:$2$", [
              time.hour,
              time.min.format("%02d"),
            ]),
          };
        } else {
          time = Gregorian.info(sunrise, Time.FORMAT_MEDIUM);
          return {
            "label" => WatchUi.loadResource($.Rez.Strings.SunEventRise) as
            String,
            "value" => Lang.format("$1$:$2$", [
              time.hour,
              time.min.format("%02d"),
            ]),
          };
        }
      }
      return {
        "label" => WatchUi.loadResource($.Rez.Strings.SunEvent) as String,
        "value" => "--",
      };
    }

    return "--";
  }

  function getDate() {
    // var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    // return Lang.format("$1$, $2$", [now.day_of_week, now.day]).toLower();

    var now = Time.now();
    var clockTime = Gregorian.info(now, Time.FORMAT_SHORT);
    var days = ["", "sun", "mon", "tue", "wed", "thu", "fri", "sat"];

    var mySettings = System.getDeviceSettings();

    if (mySettings.systemLanguage.equals(System.LANGUAGE_ITA)) {
      days = ["", "dom", "lun", "mar", "mer", "gio", "ven", "sab"];
    }
    if (mySettings.systemLanguage.equals(System.LANGUAGE_SPA)) {
      days = ["", "dom", "lun", "mar", "mie", "jue", "vie", "sab"];
    }

    now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    return Lang.format("$1$, $2$", [
      days[clockTime.day_of_week],
      now.day,
    ]).toLower();
  }

  function getNotifications() {
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

  function getBatteryDays() {
    var data = null;
    if (Toybox has :System) {
      if (Toybox.System.getSystemStats() has :batteryInDays) {
        data = Toybox.System.getSystemStats().batteryInDays;
      }
    }
    if (data == null) {
      return "--";
    }
    return data.format("%d");
  }

  function getSolarIntensity() {
    var data = null;
    if (Toybox has :System) {
      if (Toybox.System.getSystemStats() has :solarIntensity) {
        data = Toybox.System.getSystemStats().solarIntensity;
      }
    }
    if (data == null) {
      return "--";
    }
    return data.format("%d");
  }

  function getAltimeter() {
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

  function getTemperature() {
    var data = null;
    if (Toybox has :Complications) {
      var comp = Complications.getComplication(
        new Complications.Id(
          Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE
        )
      );
      if (comp.value != null) {
        data = comp.value;
      }
    }
    if (data == null) {
      var iterator = Toybox.SensorHistory.getTemperatureHistory({});
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

  function getBodyBattery() {
    var data = null;
    if (Toybox has :Complications) {
      var comp = Complications.getComplication(
        new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY)
      );
      if (comp.value != null) {
        data = comp.value;
      }
    }
    if (data == null) {
      var iterator = Toybox.SensorHistory.getBodyBatteryHistory({});
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

  function getStress() {
    var data = null;
    if (Toybox has :Complications) {
      var comp = Complications.getComplication(
        new Complications.Id(Complications.COMPLICATION_TYPE_STRESS)
      );
      if (comp.value != null) {
        data = comp.value;
      }
    }
    if (data == null) {
      var iterator = Toybox.SensorHistory.getStressHistory({});
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

  function getHeartRate() {
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

  function getCalories() {
    var data = null;
    if (Toybox has :Complications) {
      var comp = Complications.getComplication(
        new Complications.Id(Complications.COMPLICATION_TYPE_CALORIES)
      );
      if (comp.value != null) {
        data = comp.value;
      }
    }
    if (data == "--") {
      if (Toybox has :Activity) {
        if (Toybox.Activity.getActivityInfo() has :calories) {
          data = Toybox.Activity.getActivityInfo().calories;
        }
      }
    }

    if (data == null) {
      return "--";
    }
    return Lang.format("$1$", [data]);
  }

  function getSteps() {
    var data = null;
    if (Toybox has :Complications) {
      var comp = Complications.getComplication(
        new Complications.Id(Complications.COMPLICATION_TYPE_STEPS)
      );
      if (comp.value != null) {
        data = comp.value;
      }
    }
    if (data == null || data == "--") {
      if (Toybox has :Activity) {
        data = Toybox.Activity.ActivityMonitor.getInfo().steps;
      }
    }

    if (data == null) {
      return "--";
    }

    // return Lang.format("$1$", [data]);
    return data.toString();
  }

  function getFloors() {
    var data = null;
    if (Toybox has :Complications) {
      var comp = Complications.getComplication(
        new Complications.Id(Complications.COMPLICATION_TYPE_FLOORS_CLIMBED)
      );
      if (comp.value != null) {
        data = comp.value;
      }
    }
    if (data == null || data == "--") {
      if (Toybox has :Activity) {
        data = Toybox.Activity.ActivityMonitor.getInfo().floorsClimbed;
      }
    }

    if (data == null) {
      return "--";
    }
    return Lang.format("$1$", [data]);
  }

  function getBarometer() {
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

  function drawIcons(dc) {
    var FieldIcons = "";

    var settings = System.getDeviceSettings().doNotDisturb;
    if (settings) {
      FieldIcons += (127).toChar().toString();
    }
    settings = System.getDeviceSettings().phoneConnected;
    if (settings) {
      FieldIcons += "V";
    }
    settings = System.getDeviceSettings().alarmCount;
    if (settings > 0) {
      FieldIcons += "R";
    }

    if (FieldIcons.length() > 0) {
      var view = View.findDrawableById("FieldIcons") as Text;
      view.setText(FieldIcons);
    }
  }

  // debug by drawing bounding boxes and labels
  function drawBoundingBoxes(dc) {
    dc.setPenWidth(1);

    for (var i = 0; i < boundingBoxes.size(); i = i + 1) {
      var x1 = boundingBoxes[i]["bounds"][0][0];
      var y1 = boundingBoxes[i]["bounds"][0][1];
      var x2 = boundingBoxes[i]["bounds"][1][0];
      var y2 = boundingBoxes[i]["bounds"][1][1];

      // draw a cross and a box
      dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_PURPLE);
      dc.drawLine(x1, y1, x2, y2);
      dc.drawLine(x1, y2, x2, y1);
      dc.drawRectangle(x1, y1, x2 - x1, y2 - y1);

      // draw the complication label and value
      var value = boundingBoxes[i]["id"];
      var label = boundingBoxes[i]["id"];
      var font = Graphics.FONT_SYSTEM_TINY;

      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x1 + (x2 - x1) / 2,
        y1 + (y2 - y1) / 2 - dc.getFontHeight(font),
        font,
        label.toString(),
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        x1 + (x2 - x1) / 2,
        y1 + (y2 - y1) / 2,
        font,
        value.toString(),
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }
  }

  function drawGraph(dc) {
    if (graphCatalog[showGraph]["iterator"] == null) {
      return;
    }

    var curMin = 0;
    var curMax = 0;
    var maxSecs = 14400;

    var getSensorHistory = new Lang.Method(
      Toybox.SensorHistory,
      graphCatalog[showGraph]["iterator"]
    );

    var sample = getSensorHistory.invoke({
      :period => maxSecs,
      :order => SensorHistory.ORDER_NEWEST_FIRST,
    });

    if (sample != null) {
      var graphMin = sample.getMin();
      var graphMax = sample.getMax();
      var sampleData = sample.next();
      if (sampleData == null) {
        return;
      }

      if (sampleData == null) {
        return;
      }
      if (graphMin == null) {
        return;
      }
      if (graphMax == null) {
        return;
      }
      if (sampleData == 0) {
        return;
      }
      if (graphMin == 0) {
        return;
      }
      if (graphMax == 0) {
        return;
      }
      curMin = graphMin;
      curMax = graphMax;
      graphMin = 1000;
      graphMax = 0;

      var totHeight = 30;
      var totWidth = 70;
      if (graphSize == 1) {
        totWidth = 180;
      }
      totWidth = totWidth * graphWidthFactor;
      var binPixels = 1;

      var totBins = Math.ceil(totWidth / binPixels).toNumber();
      var binWidthSecs = Math.floor(
        (binPixels * maxSecs) / totWidth
      ).toNumber();

      var graphSecs;
      var graphValue = 0;
      var secsBin = 0;
      var lastGraphSecs = sample.getNewestSampleTime().value();
      var graphBinMax;
      var graphBinMin;

      var finished = false;

      for (var i = 0; i < totBins; ++i) {
        graphBinMax = 0;
        graphBinMin = 0;

        if (!finished) {
          if (secsBin > 0 && graphValue != null) {
            graphBinMax = graphValue;
            graphBinMin = graphValue;
          }
          while (!finished && secsBin < binWidthSecs) {
            sampleData = sample.next();
            if (sampleData != null) {
              graphValue = sampleData.data;

              if (graphValue != null) {
                if (graphBinMax == 0) {
                  graphBinMax = graphValue;
                  graphBinMin = graphValue;
                } else {
                  if (graphValue > graphBinMax) {
                    graphBinMax = graphValue;
                  }

                  if (graphValue < graphBinMin) {
                    graphBinMin = graphValue;
                  }
                }
              }
              graphSecs = lastGraphSecs - sampleData.when.value();
              lastGraphSecs = sampleData.when.value();
              secsBin += graphSecs;
            } else {
              finished = true;
            }
          }

          if (secsBin >= binWidthSecs) {
            secsBin -= binWidthSecs;
          }

          // only plot bar if we have valid values
          if (graphBinMax > 0 && graphBinMax >= graphBinMin) {
            if (curMax > 0 && curMax > curMin) {
              var heartBinMid = (graphBinMax + graphBinMin) / 2;
              var height =
                ((heartBinMid - curMin * graphCatalog[showGraph]["scale"]) /
                  (curMax - curMin * graphCatalog[showGraph]["scale"])) *
                totHeight;

              var xVal = (dw - totWidth) / 2 + totWidth - i * binPixels - 2;
              var yVal = dh / 2 + graphVertOffset + totHeight - height;

              dc.setColor(
                graphCatalog[showGraph]["colorDark"],
                Graphics.COLOR_TRANSPARENT
              );

              try {
                dc.fillRectangle(xVal, yVal, binPixels, height);
              } catch (ex) {}
              dc.setColor(
                graphCatalog[showGraph]["color"],
                Graphics.COLOR_TRANSPARENT
              );
              try {
                dc.fillRectangle(xVal, yVal, binPixels, 2 * binPixels);
              } catch (ex) {}
            }

            if (graphBinMin < graphMin) {
              graphMin = graphBinMin;
            }
            if (graphBinMax > graphMax) {
              graphMax = graphBinMax;
            }
          }
        }
      }
    }
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {}

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {}
}
