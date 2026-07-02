// ============================================================================
// EssenceView.mc
// Main watch face view: layout management, data rendering, graph drawing.
// ============================================================================

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time.Gregorian;

class EssenceView extends WatchUi.WatchFace {
  // --------------------------------------------------------------------------
  // Fields
  // --------------------------------------------------------------------------

  // Display dimensions — populated in onLayout from the Dc object
  var dw = 0;
  var dh = 0;

  // Graph layout parameters — adjusted per screen resolution in onLayout.
  // Defaults target the standard 390×390 round display.
  var graphWidthFactor = 1;
  var graphVertOffset = 69;

  // Background drawable — allocated once at init to avoid per-frame allocation
  var bGrondFillerWhite;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  function initialize() {
    WatchFace.initialize();
    bGrondFillerWhite = new Rez.Drawables.bGrondFillerWhite();
  }

  // Called once on first show, and again whenever `redrawLayout` is set true
  // (e.g. after a settings change). Reads all user properties and rebuilds
  // the layout from scratch.
  function onLayout(dc as Dc) as Void {
    dw = dc.getWidth();
    dh = dc.getHeight();

    // Read all user-configurable properties
    batterySave = getApp().getProperty("BatterySave");
    showGraph = getApp().getProperty("ShowGraph");
    graphSize = getApp().getProperty("GraphSize");
    darkMode = getApp().getProperty("DarkMode");

    // GraphSize may be null on first install before the property is written
    if (graphSize == null) {
      graphSize = 0;
    }

    // Per-resolution graph tuning
    if (dh == 454) {
      graphVertOffset = 128;
      graphWidthFactor = 1.5;
    } else if (dh == 260) {
      graphVertOffset = 61;
      graphWidthFactor = 0.9;
    }

    // Bounding boxes must be recalculated here because graphSize affects
    // which touch zones are active (large graph collapses three zones)
    defineBoundingBoxes(dc);

    if (!batterySave) {
      // Full layout: choose dark or light theme
      setLayout(
        darkMode ? Rez.Layouts.WatchFace(dc) : Rez.Layouts.WatchFaceLight(dc)
      );
      loadLayout(); // read field assignments from properties into fieldLayout[]
      drawLabels(dc); // populate static label text views
    } else {
      // Battery-save layout: minimal display, no data fields or graph
      setLayout(
        darkMode
          ? Rez.Layouts.BatterySave(dc)
          : Rez.Layouts.BatterySaveLight(dc)
      );
    }
  }

  function onShow() as Void {}

  // Main render entry point — called every second in normal mode,
  // every minute in low-power mode.
  //
  // Drawing order matters: View.onUpdate() flushes the layout drawables to
  // the display, so the graph (drawn with raw DC calls) must come AFTER to
  // avoid being overwritten by the layout flush.
  function onUpdate(dc as Dc) as Void {
    // Rebuild layout if flagged by onSettingsChanged()
    if (redrawLayout) {
      onLayout(dc);
      redrawLayout = false;
    }

    if (!batterySave) {
      drawData(dc); // populate complication / sensor data text views
    }

    drawDate(dc); // always rendered regardless of battery-save mode
    drawTime(dc);
    drawIcons(dc);

    View.onUpdate(dc); // flush layout drawables to the display

    // Graph is painted on top of the flushed layout via raw DC primitives
    if (!batterySave && showGraph > 0) {
      drawGraph(dc);
    }

    // drawBoundingBoxes(dc);  // uncomment to debug tap zones
  }

  function onHide() as Void {}
  function onExitSleep() as Void {}
  function onEnterSleep() as Void {}

  // --------------------------------------------------------------------------
  // Drawing helpers
  // --------------------------------------------------------------------------

  // Populate the static label text views (field titles).
  // Fields covered by the active graph area are blanked to make room:
  //   - graphSize 0 (small):  hides center-lower label only (index 5)
  //   - graphSize 1 (large):  hides all three lower field labels (4, 5, 6)
  function drawLabels(dc) {
    var view;
    for (var i = 0; i < fieldLayout.size(); i = i + 1) {
      view = View.findDrawableById(fieldLayout[i]["id"] + "Label") as Text;

      var hiddenByGraph =
        (i == 5 && showGraph > 0 && graphSize == 0) ||
        ((i == 4 || i == 5 || i == 6) && showGraph > 0 && graphSize == 1);

      if (hiddenByGraph) {
        view.setText("");
      } else {
        view.setText(
          WatchUi.loadResource(fieldCatalog[fieldLayout[i]["data"]]["label"]) as
            String
        );
      }
    }

    // Graph label (only visible when a graph type is active)
    if (showGraph > 0) {
      view = View.findDrawableById("FieldGraphLabel") as Text;
      view.setText(
        WatchUi.loadResource(graphCatalog[showGraph]["label"]) as String
      );
    }
  }

  // Populate data text views with fresh complication / sensor values.
  // Mirrors the same hide logic as drawLabels for graph-covered fields.
  function drawData(dc) {
    var view;
    var fun;

    for (var i = 0; i < fieldLayout.size(); i = i + 1) {
      view = View.findDrawableById(fieldLayout[i]["id"] + "Data") as Text;

      var hiddenByGraph =
        (i == 5 && showGraph > 0 && graphSize == 0) ||
        ((i == 4 || i == 5 || i == 6) && showGraph > 0 && graphSize == 1);

      if (hiddenByGraph) {
        view.setText("");
      } else if (fieldLayout[i]["data"].equals(4)) {
        // SunEvent (catalog index 4) is a special case: its getter returns
        // both a value and a dynamic label (Sunrise/Sunset), so we must
        // update both text views in a single call.
        var sunEvent = getSunEvent();
        view.setText(sunEvent["value"]);
        var labelView =
          View.findDrawableById(fieldLayout[i]["id"] + "Label") as Text;
        labelView.setText(sunEvent["label"]);
      } else {
        // Generic case: dispatch to the getter function via its stored symbol
        fun = method(fieldCatalog[fieldLayout[i]["data"]]["getter"]);
        view.setText(fun.invoke());
      }
    }

    // Graph current-value readout (shown inline next to the graph)
    if (showGraph > 0) {
      view = View.findDrawableById("FieldGraphData") as Text;
      fun = method(graphCatalog[showGraph]["getter"]);
      view.setText(fun.invoke());
    }
  }

  function drawDate(dc) {
    var view = View.findDrawableById("FieldDate") as Text;
    view.setText(getDate());
  }

  function drawTime(dc as Dc) {
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    var timeFormat = "$1$:$2$";

    if (!System.getDeviceSettings().is24Hour) {
      // 12-hour mode: fold PM hours down without zero-padding
      if (hours > 12) {
        hours = hours - 12;
      }
    } else if (getApp().getProperty("UseMilitaryFormat")) {
      // Military format: no colon separator, hours always zero-padded
      timeFormat = "$1$$2$";
      hours = hours.format("%02d");
    }

    var view = View.findDrawableById("FieldTime") as Text;
    view.setText(
      Lang.format(timeFormat, [hours, clockTime.min.format("%02d")])
    );
  }

  // Build the status icon string from active device flags and set it on the
  // icon text view. Icons are encoded in a custom font:
  //   char 127 → Do Not Disturb
  //   'V'      → Bluetooth connected
  //   'R'      → Alarm active
  function drawIcons(dc) {
    var icons = "";
    var settings = System.getDeviceSettings();

    if (settings.doNotDisturb) {
      icons += (127).toChar().toString();
    }
    if (settings.phoneConnected) {
      icons += "V";
    }
    if (settings.alarmCount > 0) {
      icons += "R";
    }

    if (icons.length() > 0) {
      var view = View.findDrawableById("FieldIcons") as Text;
      view.setText(icons);
    }
  }

  // Draw the sensor history bar chart using raw DC primitives.
  //
  // Strategy: fetch up to `maxSecs` of sensor history, bucket the samples
  // into 1-pixel-wide time bins (newest = rightmost), then draw a bar for
  // each bin whose height is proportional to the normalised average value.
  //
  // Normalisation formula:
  //   norm = (midpoint - curMin * scale) / (curMax - curMin * scale)
  // The `scale` factor (< 1.0) compresses the effective floor so that
  // low values still produce a visible bar rather than collapsing to zero.
  //
  // Performance design (all hot-path costs moved outside the loop):
  //   - catalog fields cached before loop  → no per-bin dict lookups
  //   - scaledMin / denom pre-computed     → no per-bin float multiplications
  //   - xBase / yBase pre-computed         → no per-bin coordinate arithmetic
  //   - dc.setColor() called once          → colour is constant for all bins
  //   - norm and barHeight computed once   → were duplicated in original code
  //   - explicit bounds guard              → replaces try/catch in hot path
  function drawGraph(dc) {
    // Cache the entire catalog entry to avoid repeated dict lookups per bin
    var catalog = graphCatalog[showGraph];
    if (catalog["iterator"] == null) {
      return; // this graph type has no history data source
    }

    // --- Fetch sensor history ------------------------------------------------

    var maxSecs = 14400; // 4 hours of data

    var getSensorHistory = new Lang.Method(
      Toybox.SensorHistory,
      catalog["iterator"]
    );
    var sample = getSensorHistory.invoke({
      :period => maxSecs,
      :order => SensorHistory.ORDER_NEWEST_FIRST,
    });

    if (sample == null) {
      return;
    }

    var curMin = sample.getMin();
    var curMax = sample.getMax();
    var sampleData = sample.next(); // prime the iterator with the first sample

    // Guard: no data, or degenerate range (division by zero in normalisation)
    if (sampleData == null || curMin == null || curMax == null) {
      return;
    }
    if (curMin == 0 || curMax == 0 || curMax <= curMin) {
      return;
    }

    // --- Pre-compute layout constants ----------------------------------------

    var totWidth = (graphSize == 1 ? 180 : 70) * graphWidthFactor;
    var totHeight = 30;
    var binPixels = 1; // each time-bucket is 1 pixel wide

    var totBins = Math.ceil(totWidth / binPixels).toNumber();
    var binWidthSecs = Math.floor((binPixels * maxSecs) / totWidth).toNumber();

    // Normalisation constants — computed once, reused every iteration
    var scale = catalog["scale"];
    var scaledMin = curMin * scale;
    var denom = curMax - scaledMin;

    // Pixel offsets invariant across all bins
    // xBase: right edge of the graph; bins are plotted right-to-left (newest first)
    // yBase: bottom baseline of the graph area
    var xBase = (dw - totWidth) / 2 + totWidth - 2;
    var yBase = dh / 2 + graphVertOffset + totHeight;

    // Set bar colour once — it is constant for the entire graph render
    dc.setColor(catalog["colorDark"], Graphics.COLOR_TRANSPARENT);

    // --- Render loop ---------------------------------------------------------

    var graphValue = 0; // last known sample value (carried across bin boundaries)
    var secsBin = 0; // accumulated seconds placed in the current bin
    var lastGraphSecs = sample.getNewestSampleTime().value();
    var graphBinMax;
    var graphBinMin;
    var graphSecs;
    var finished = false;

    for (var i = 0; i < totBins; ++i) {
      graphBinMax = 0;
      graphBinMin = 0;

      if (finished) {
        continue; // iterator exhausted; leave remaining bins empty
      }

      // If there is leftover time from the previous bin, seed this bin
      // with the last known value so there are no visual gaps
      if (secsBin > 0 && graphValue != null) {
        graphBinMax = graphValue;
        graphBinMin = graphValue;
      }

      // Consume samples until this bin has accumulated binWidthSecs of data
      while (!finished && secsBin < binWidthSecs) {
        sampleData = sample.next();
        if (sampleData == null) {
          finished = true;
          break;
        }

        graphValue = sampleData.data;
        if (graphValue != null) {
          if (graphBinMax == 0) {
            // First valid value in this bin — initialise min and max
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
      }

      // Carry the remainder into the next bin
      if (secsBin >= binWidthSecs) {
        secsBin -= binWidthSecs;
      }

      // Draw the bar only if this bin has at least one valid reading
      if (graphBinMax > 0 && graphBinMax >= graphBinMin) {
        // Normalise the midpoint of [binMin, binMax] to [0..1], scale to pixels.
        // Computed once per bin — was duplicated twice in the original code.
        var norm = ((graphBinMax + graphBinMin) / 2 - scaledMin) / denom;
        var barHeight = norm * totHeight;
        var x = xBase - i * binPixels;
        var y = yBase - barHeight;

        // Explicit bounds guard — replaces the original try/catch in the hot path
        if (barHeight > 0 && y >= 0 && x >= 0 && x < dw) {
          dc.fillRectangle(x, y, binPixels, barHeight);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // Layout helpers
  // --------------------------------------------------------------------------

  // Build the bounding-box registry used by EssenceDelegate for tap handling.
  // Each entry covers one field zone. When graphSize == 1, the three lower
  // side zones are collapsed to zero-size so taps there pass through silently.
  function defineBoundingBoxes(dc) {
    // Coordinate format: [ [xMin, yMin], [xMax, yMax] ]
    //
    //   [xMin,yMin] --------+
    //       |               |
    //       +-------- [xMax,yMax]

    var col = dw / 3; // one column = one third of display width
    var row = dh / 6; // one row    = one sixth of display height
    var rowB = dh / 1.5; // lower section Y start (two thirds down)

    var bboxTop = [
      [col, 0],
      [col * 2, row],
    ];

    var bboxUpperLeft = [
      [0, row],
      [col, row * 2],
    ];
    var bboxUpperCenter = [
      [col, row],
      [col * 2, row * 2],
    ];
    var bboxUpperRight = [
      [col * 2, row],
      [dw, row * 2],
    ];

    var bboxLowerLeft = [
      [0, rowB],
      [col, rowB + row],
    ];
    var bboxLowerCenter = [
      [col, rowB],
      [col * 2, rowB + row],
    ];
    var bboxLowerRight = [
      [col * 2, rowB],
      [dw, rowB + row],
    ];

    var bboxBottom = [
      [col, dh - row],
      [col * 2, dh],
    ];

    // Large-graph mode: collapse the side lower zones; widen the center zone
    // to span the entire graph touch area for complication tap-through.
    // Gated on showGraph too — with no graph active the three lower fields
    // are still drawn individually (see drawLabels/drawData), so their tap
    // zones must stay separate even when GraphSize is set to Large.
    if (showGraph > 0 && graphSize == 1) {
      bboxLowerLeft = [
        [0, 0],
        [0, 0],
      ];
      bboxLowerCenter = [
        [0, rowB],
        [dw, rowB + row],
      ];
      bboxLowerRight = [
        [0, 0],
        [0, 0],
      ];
    }

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
        "bounds" => bboxBottom,
        "value" => "",
        "complicationId" => Complications.COMPLICATION_TYPE_BATTERY,
      },
    ];
  }

  // --------------------------------------------------------------------------
  // Data getters
  //
  // Naming convention: each getter returns a display string; "--" on failure.
  // Fallback priority (where applicable):
  //   1. Complications API  (most power-efficient, system-managed)
  //   2. Activity API       (live activity session data)
  //   3. SensorHistory API  (on-device historic samples)
  // --------------------------------------------------------------------------

  function getEmpty() {
    return "";
  }

  // Today's low/high temperature from the Weather complication (e.g. "12/24")
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

  // Next calendar event label from the Complications API
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

  // Next sunrise or sunset time, with a dynamic label showing which is next.
  // Returns a dict { "label" => String, "value" => String } so the caller
  // can update both the label and the value text view in a single call.
  function getSunEvent() {
    var fallback = {
      "label" => WatchUi.loadResource($.Rez.Strings.SunEvent) as String,
      "value" => "--",
    };

    if (!(Toybox has :Position)) {
      return fallback;
    }

    var positionInfo = Toybox.Position.getInfo();
    if (positionInfo.position == null) {
      return fallback;
    }

    if (!(Toybox has :Weather)) {
      return fallback;
    }

    var now = Time.now();
    var sunrise = Toybox.Weather.getSunrise(positionInfo.position, now);
    var sunset = Toybox.Weather.getSunset(positionInfo.position, now);
    if (sunrise == null || sunset == null) {
      return fallback;
    }

    // Between sunrise and sunset → show time of next sunset; otherwise → next sunrise
    if (now.compare(sunrise) > 0 && now.compare(sunset) < 0) {
      var t = Gregorian.info(sunset, Time.FORMAT_MEDIUM);
      return {
        "label" => WatchUi.loadResource($.Rez.Strings.SunEventSet) as String,
        "value" => Lang.format("$1$:$2$", [t.hour, t.min.format("%02d")]),
      };
    } else {
      var t = Gregorian.info(sunrise, Time.FORMAT_MEDIUM);
      return {
        "label" => WatchUi.loadResource($.Rez.Strings.SunEventRise) as String,
        "value" => Lang.format("$1$:$2$", [t.hour, t.min.format("%02d")]),
      };
    }
  }

  // Localised short day name + day-of-month (e.g. "thu, 15").
  // Supports English (default), Italian, and Spanish.
  function getDate() {
    var now = Time.now();
    var clockTime = Gregorian.info(now, Time.FORMAT_SHORT); // provides day_of_week index
    var medium = Gregorian.info(now, Time.FORMAT_MEDIUM); // provides named day / month
    var settings = System.getDeviceSettings();

    var days = ["", "sun", "mon", "tue", "wed", "thu", "fri", "sat"];
    if (settings.systemLanguage.equals(System.LANGUAGE_ITA)) {
      days = ["", "dom", "lun", "mar", "mer", "gio", "ven", "sab"];
    } else if (settings.systemLanguage.equals(System.LANGUAGE_SPA)) {
      days = ["", "dom", "lun", "mar", "mie", "jue", "vie", "sab"];
    }

    return Lang.format("$1$, $2$", [
      days[clockTime.day_of_week],
      medium.day,
    ]).toLower();
  }

  // Unread notification count
  function getNotifications() {
    if (Toybox.System.getDeviceSettings() has :notificationCount) {
      return Toybox.System.getDeviceSettings().notificationCount.toString();
    }
    return "--";
  }

  // Battery percentage. Fallback: Complications → SystemStats.
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
    if (data == null && Toybox has :System) {
      if (Toybox.System.getSystemStats() has :battery) {
        data = Toybox.System.getSystemStats().battery;
      }
    }
    return data != null ? data.format("%d") : "--";
  }

  // Estimated days of battery charge remaining (not available on all devices)
  function getBatteryDays() {
    if (Toybox has :System) {
      if (Toybox.System.getSystemStats() has :batteryInDays) {
        var data = Toybox.System.getSystemStats().batteryInDays;
        if (data != null) {
          return data.format("%d");
        }
      }
    }
    return "--";
  }

  // Solar charging intensity 0-100 (solar-capable watches only)
  function getSolarIntensity() {
    if (Toybox has :System) {
      if (Toybox.System.getSystemStats() has :solarIntensity) {
        var data = Toybox.System.getSystemStats().solarIntensity;
        if (data != null) {
          return data.format("%d");
        }
      }
    }
    return "--";
  }

  // Altitude in metres, rounded. Fallback: Complications → Activity → SensorHistory.
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
    if (data == null && Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :altitude) {
        data = Toybox.Activity.getActivityInfo().altitude;
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
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Ambient temperature in °C, rounded. Fallback: Complications → SensorHistory.
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
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Body Battery level 0-100. Fallback: Complications → SensorHistory.
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
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Stress level 0-100. Fallback: Complications → SensorHistory.
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
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Heart rate in bpm. Fallback: Complications → Activity → SensorHistory.
  // The SensorHistory path filters out INVALID_HR_SAMPLE sentinel values.
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
    if (data == null && Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :currentHeartRate) {
        data = Toybox.Activity.getActivityInfo().currentHeartRate;
      }
    }
    if (data == null && Toybox has :SensorHistory) {
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
    return data != null ? Lang.format("$1$", [data]) : "--";
  }

  // Active calories burned. Fallback: Complications → Activity.
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
    if (data == null && Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :calories) {
        data = Toybox.Activity.getActivityInfo().calories;
      }
    }
    return data != null ? Lang.format("$1$", [data]) : "--";
  }

  // Step count. Fallback: Complications → ActivityMonitor.
  // Note: some Complications implementations return steps as a Float
  // (e.g. 8.5 meaning 8500 steps); we convert that back to an integer.
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

    if (data instanceof Toybox.Lang.Float) {
      data = (data * 1000).toNumber();
    }

    data = data.toString();
    if (data.length() > 4) {
      data = data.substring(0, 2) + '.' + data.substring(2, 3) + 'k';
    }

    return data;
  }

  // Floors climbed today. Fallback: Complications → ActivityMonitor.
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
    return data != null ? Lang.format("$1$", [data]) : "--";
  }

  // Sea-level pressure in hPa, rounded. Fallback: Complications → Activity → SensorHistory.
  // The raw API value is in Pascals; divide by 100 to convert to hPa.
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
    if (data == null && Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :meanSeaLevelPressure) {
        data = Toybox.Activity.getActivityInfo().meanSeaLevelPressure;
      }
    }
    if (data == null && Toybox has :SensorHistory) {
      if (Toybox.SensorHistory has :getPressureHistory) {
        var iterator = Toybox.SensorHistory.getPressureHistory({});
        var sample = iterator.next();
        if (sample != null) {
          data = sample.data;
        } else {
          return "--";
        }
      }
    }
    if (data == null) {
      return "--";
    }
    return (data / 100 + 0.5).toNumber().toString();
  }

  // --------------------------------------------------------------------------
  // Debug helpers (not called in production — see onUpdate)
  // --------------------------------------------------------------------------

  // Render tap bounding boxes and their field IDs on screen.
  // To activate: uncomment `drawBoundingBoxes(dc)` in onUpdate().
  function drawBoundingBoxes(dc) {
    dc.setPenWidth(1);
    var font = Graphics.FONT_SYSTEM_TINY;

    for (var i = 0; i < boundingBoxes.size(); i = i + 1) {
      var x1 = boundingBoxes[i]["bounds"][0][0];
      var y1 = boundingBoxes[i]["bounds"][0][1];
      var x2 = boundingBoxes[i]["bounds"][1][0];
      var y2 = boundingBoxes[i]["bounds"][1][1];
      var cx = x1 + (x2 - x1) / 2;
      var cy = y1 + (y2 - y1) / 2;

      // Diagonal cross + rectangle outline
      dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_PURPLE);
      dc.drawLine(x1, y1, x2, y2);
      dc.drawLine(x1, y2, x2, y1);
      dc.drawRectangle(x1, y1, x2 - x1, y2 - y1);

      // Field ID label centred in the zone
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        cx,
        cy - dc.getFontHeight(font),
        font,
        boundingBoxes[i]["id"],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        cx,
        cy,
        font,
        boundingBoxes[i]["value"],
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }
  }
}
