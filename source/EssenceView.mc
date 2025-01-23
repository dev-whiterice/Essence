import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class EssenceView extends WatchUi.WatchFace {
  var dw = 0;
  var dh = 0;
  const graphLength = 60;
  var heartMin = 2000;
  var heartMax = 0;
  var heartNow = 0;
  var heartRateZones;
  const arrayColours = [
    Graphics.COLOR_WHITE,
    Graphics.COLOR_RED,
    Graphics.COLOR_DK_RED,
    Graphics.COLOR_YELLOW,
    Graphics.COLOR_ORANGE,
    Graphics.COLOR_LT_GRAY,
    Graphics.COLOR_DK_GRAY,
    Graphics.COLOR_BLUE,
    Graphics.COLOR_GREEN,
    Graphics.COLOR_DK_GREEN,
    Graphics.COLOR_DK_BLUE,
    Graphics.COLOR_PURPLE,
    Graphics.COLOR_PINK,
  ];

  function initialize() {
    WatchFace.initialize();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));

    dw = dc.getWidth();
    dh = dc.getHeight();

    defineBoundingBoxes(dc);

    heartRateZones = Toybox.UserProfile.getHeartRateZones(
      Toybox.UserProfile.getCurrentSport()
    );
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

    var bboxTopLeft = [
      [0, dh / 6],
      [dw / 3, dh / 6 + dh / 6],
    ];

    var bboxTopCenter = [
      [dw / 3, dh / 6],
      [dw / 3 + dw / 3, dh / 6 + dh / 6],
    ];

    var bboxTopRight = [
      [dw / 3 + dw / 3, dh / 6],
      [dw, dh / 6 + dh / 6],
    ];

    var bboxBottomLeft = [
      [0, dh / 1.5],
      [dw / 3, dh / 1.5 + dh / 6],
    ];

    var bboxBottomCenter = [
      [dw / 3, dh / 1.5],
      [dw / 3 + dw / 3, dh / 1.5 + dh / 6],
    ];

    var bboxBottomRight = [
      [dw / 3 + dw / 3, dh / 1.5],
      [dw, dh / 1.5 + dh / 6],
    ];

    // var bboxBottom = [
    //   [dw / 3, dh - dh / 6],
    //   [dw / 3 + dw / 3, dh],
    // ];

    // var bboxCentral = [
    //   [0, dh / 2.9],
    //   [dw, dh / 3 + dh / 3.2],
    // ];

    boundingBoxes = [
      {
        "label" => "Weather",
        "bounds" => bboxTop,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_CURRENT_WEATHER,
      },
      {
        "label" => "Calendar",
        "bounds" => bboxTopLeft,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_CALENDAR_EVENTS,
      },
      {
        "label" => "Notification",
        "bounds" => bboxTopCenter,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT,
      },
      {
        "label" => "Sunrise",
        "bounds" => bboxTopRight,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_SUNRISE,
      },

      {
        "label" => "Altitude",
        "bounds" => bboxBottomLeft,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_ALTITUDE,
      },
      {
        "label" => "HeartRate",
        "bounds" => bboxBottomCenter,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_HEART_RATE,
      },
      {
        "label" => "Pressure",
        "bounds" => bboxBottomRight,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE,
      },
      // {
      //   "label" => "Battery",
      //   "bounds" => bboxBottom,
      //   "value" => "",
      //   "complicationId" => Complications.COMPLICATION_TYPE_BATTERY,
      // },
      // {
      //   "label" => "Time",
      //   "bounds" => bboxCentral,
      //   "value" => "",
      //   "complicationId" => Complications.COMPLICATION_TYPE_CALENDAR_EVENTS,
      // },
    ];
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  // Update the view
  function onUpdate(dc as Dc) as Void {
    drawWeather(dc);
    drawCalendar(dc);
    drawNotification(dc);
    drawSunEvent(dc);
    drawDate(dc);
    drawTime(dc);
    drawIcons(dc);
    drawAltitude(dc);
    drawHeartRate(dc);
    drawPressure(dc);
    drawBattery(dc);

    View.onUpdate(dc);

    drawHRgraph(dc);
    // drawBoundingBoxes(dc);
  }

  function drawTime(dc as Dc) as Void {
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

    var view = View.findDrawableById("TimeData") as Text;
    view.setText(timeString);
  }

  function drawWeather(dc as Dc) as Void {
    var view = View.findDrawableById("WeatherData") as Text;
    view.setText(getWeather());
  }

  function drawCalendar(dc as Dc) as Void {
    var view = View.findDrawableById("CalendarData") as Text;
    view.setText(getCalender());
  }

  function drawSunEvent(dc as Dc) as Void {
    var sunEvent = getSunEvent();
    var view = View.findDrawableById("SunEventLabel") as Text;
    view.setText(sunEvent["label"]);
    view = View.findDrawableById("SunEventData") as Text;
    view.setText(sunEvent["value"]);
  }

  function drawNotification(dc as Dc) as Void {
    var view = View.findDrawableById("NotificationData") as Text;
    view.setText(getNotification());
  }

  function drawDate(dc as Dc) as Void {
    var view = View.findDrawableById("DateData") as Text;
    view.setText(getDate());
  }

  function drawAltitude(dc as Dc) as Void {
    var view = View.findDrawableById("AltitudeData") as Text;
    view.setText(getAltitude());
  }

  function drawHeartRate(dc as Dc) as Void {
    var view = View.findDrawableById("HeartRateData") as Text;
    view.setText(getHeartrate());
  }

  function drawPressure(dc as Dc) as Void {
    var view = View.findDrawableById("PressureData") as Text;
    view.setText(getPressure());
  }

  function drawBattery(dc as Dc) as Void {
    var view = View.findDrawableById("BatteryData") as Text;
    view.setText(getBattery());
  }

  function drawIcons(dc) {
    var settings = System.getDeviceSettings().phoneConnected;
    var systemIcons = "";
    if (settings) {
      systemIcons = "V";
    }

    settings = System.getDeviceSettings().alarmCount;
    if (settings > 0) {
      systemIcons += "R";
    }

    if (systemIcons.length() > 0) {
      var view = View.findDrawableById("SystemIcons") as Text;
      view.setText(systemIcons);
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
      var value = boundingBoxes[i]["value"];
      var label = boundingBoxes[i]["label"];
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

  function drawHRgraph(dc) {
    var curHeartMin = 0;
    var curHeartMax = 0;
    var maxSecs = 14400;
    var sample = SensorHistory.getHeartRateHistory({
      // :period => historyDuration,
      :period => maxSecs,
      :order => SensorHistory.ORDER_NEWEST_FIRST,
    });
    if (sample != null) {
      var heart = sample.next();
      if (heart.data != null) {
        heartNow = heart.data;
      }

      curHeartMin = heartMin;
      curHeartMax = heartMax;
      heartMin = 1000;
      heartMax = 0;

      // var maxSecs = graphLength * 60;
      // if (maxSecs < 900) {
      //   maxSecs = 900;
      // } // 900sec = 15min
      // else if (maxSecs > 14355) {
      //   maxSecs = 14355;
      // } // 14400sec = 4hrs

      var totHeight = 30;
      var totWidth = 70;
      var binPixels = 1;

      var totBins = Math.ceil(totWidth / binPixels).toNumber();
      var binWidthSecs = Math.floor(
        (binPixels * maxSecs) / totWidth
      ).toNumber();

      var heartSecs;
      var heartValue = 0;
      var secsBin = 0;
      var lastHeartSecs = sample.getNewestSampleTime().value();
      var heartBinMax;
      var heartBinMin;

      var finished = false;

      for (var i = 0; i < totBins; ++i) {
        heartBinMax = 0;
        heartBinMin = 0;

        if (!finished) {
          if (secsBin > 0 && heartValue != null) {
            heartBinMax = heartValue;
            heartBinMin = heartValue;
          }
          while (!finished && secsBin < binWidthSecs) {
            heart = sample.next();
            if (heart != null) {
              heartValue = heart.data;
              if (heartValue != null) {
                if (heartBinMax == 0) {
                  heartBinMax = heartValue;
                  heartBinMin = heartValue;
                } else {
                  if (heartValue > heartBinMax) {
                    heartBinMax = heartValue;
                  }

                  if (heartValue < heartBinMin) {
                    heartBinMin = heartValue;
                  }
                }
              }
              heartSecs = lastHeartSecs - heart.when.value();
              lastHeartSecs = heart.when.value();
              secsBin += heartSecs;
            } else {
              finished = true;
            }
          }

          if (secsBin >= binWidthSecs) {
            secsBin -= binWidthSecs;
          }

          // only plot bar if we have valid values
          if (heartBinMax > 0 && heartBinMax >= heartBinMin) {
            if (curHeartMax > 0 && curHeartMax > curHeartMin) {
              var heartBinMid = (heartBinMax + heartBinMin) / 2;
              var height =
                ((heartBinMid - curHeartMin * 0.9) /
                  (curHeartMax - curHeartMin * 0.9)) *
                totHeight;
              var xVal = (dw - totWidth) / 2 + totWidth - i * binPixels - 2;
              var yVal = dh / 2 + 71 + totHeight - height;

              dc.setColor(
                arrayColours[getHRColour(heartBinMid)],
                Graphics.COLOR_TRANSPARENT
              );

              dc.fillRectangle(xVal, yVal, binPixels, height);
            }

            if (heartBinMin < heartMin) {
              heartMin = heartBinMin;
            }
            if (heartBinMax > heartMax) {
              heartMax = heartBinMax;
            }
          }
        }
      }
    }
  }

  function getHRColour(heartrate) {
    if (heartrate == null || heartrate < heartRateZones[0] / 2) {
      return 0;
    } else if (
      heartrate >= heartRateZones[0] / 2 &&
      heartrate < heartRateZones[1]
    ) {
      return 1;
    } else if (
      heartrate >= heartRateZones[1] &&
      heartrate < heartRateZones[2]
    ) {
      return 2;
    } else if (
      heartrate >= heartRateZones[1] &&
      heartrate < heartRateZones[2]
    ) {
      return 3;
    } else if (
      heartrate >= heartRateZones[2] &&
      heartrate < heartRateZones[3]
    ) {
      return 4;
    } else if (
      heartrate >= heartRateZones[3] &&
      heartrate < heartRateZones[4]
    ) {
      return 5;
    } else {
      return 6;
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
