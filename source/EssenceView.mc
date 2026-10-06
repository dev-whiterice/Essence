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
  // Defaults target the 280×280 round display (default resources/ folder).
  var graphWidthFactor = 1;
  var graphVertOffset = 69;

  // Background drawable — allocated once at init to avoid per-frame allocation
  var bGrondFillerWhite;

  // True on screens with burn-in protection (AMOLED), read once at init
  var requiresBurnIn = false;

  // Off-white used instead of pure white for dark-theme text on AMOLED:
  // ~21% less emitted light (less OLED wear and power) for a ~9% drop in
  // perceived lightness
  const AMOLED_WHITE = 0xe6e6e6;

  // Graphics.COLOR_BLUE (0x00AAFF) scaled by the same 90% as AMOLED_WHITE,
  // keeping the hue
  const AMOLED_BLUE = 0x0099e6;

  // True while an AMOLED device is in low-power (always-on) mode.
  // Set in onEnterSleep/onExitSleep; selects sleepLayout in onUpdate.
  var amoledSleep = false;

  // True when the minimal BatterySave layout is active (user setting or
  // AMOLED sleep) — skips data fields and graph.
  var minimalLayout = false;

  // Both layouts are built once in onLayout and then swapped by selectLayout()
  // on sleep enter/exit, so waking up costs a setLayout() call instead of a
  // full rebuild (properties, labels, bounding boxes).
  // awakeLayout follows the user settings (full or BatterySave, light or dark);
  // sleepLayout is the dark minimal layout used in AMOLED sleep (null on MIP).
  var awakeLayout = null;
  var sleepLayout = null;
  var sleepLayoutActive = false;

  // Graph geometry — derived in onLayout from the resolution and graph size.
  // The graph is made of 1-pixel-wide time bins, newest at the right edge.
  const GRAPH_PERIOD = 14400; // seconds of history shown (4 hours)
  const GRAPH_HEIGHT = 30;
  var graphBins = 0;
  var graphBinSecs = 0;
  var graphXBase = 0; // x of the newest (rightmost) bin
  var graphYBase = 0; // baseline y of the bars

  // Graph cache: one bar height per bin (newest first), rebuilt by
  // computeGraph() at most once a minute and drawn every frame by drawGraph().
  // null means "must be computed" (first frame, or after a settings change).
  var graphBars = null;
  var graphMinute = -1; // Time.now() in minutes when graphBars was computed

  // Set on wake: the first frame draws the cached graph and the refresh is
  // deferred to the next frame (one second later), keeping the wake-up frame
  // cheap. The cache is at most a few bins behind, which is not noticeable.
  var deferGraphRefresh = false;

  // Pixel-shift offsets [dx, dy] cycled once per minute during AMOLED sleep,
  // so the same pixels are not kept lit continuously (burn-in prevention)
  var burnInOffsets = [
    [0, 0],
    [2, 2],
    [4, 0],
    [2, -2],
    [0, -4],
    [-2, -2],
    [-4, 0],
    [-2, 2],
  ];

  // Drawables shifted during AMOLED sleep and their layout base positions [x, y]
  var shiftedViews = [];
  var shiftedBase = [];

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  function initialize() {
    WatchFace.initialize();
    bGrondFillerWhite = new Rez.Drawables.bGrondFillerWhite();

    var settings = System.getDeviceSettings();
    if (settings has :requiresBurnInProtection) {
      requiresBurnIn = settings.requiresBurnInProtection;
    }
  }

  // Called once on first show, and again whenever `redrawLayout` is set true
  // (after a settings change). Reads all user properties and rebuilds both
  // layouts from scratch. Sleep enter/exit does not come through here: it only
  // swaps the prebuilt layouts (see selectLayout).
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

    // Per-resolution graph tuning (416 and 466 are scaled from 454, keeping
    // the graph baseline at ~85% of the display height)
    if (dh == 466) {
      graphVertOffset = 132;
      graphWidthFactor = 1.54;
    } else if (dh == 454) {
      graphVertOffset = 128;
      graphWidthFactor = 1.5;
    } else if (dh == 416) {
      graphVertOffset = 115;
      graphWidthFactor = 1.37;
    } else if (dh == 260) {
      graphVertOffset = 61;
      graphWidthFactor = 0.9;
    }

    var graphWidth = (graphSize == 1 ? 180 : 70) * graphWidthFactor;
    graphBins = Math.ceil(graphWidth).toNumber();
    graphBinSecs = Math.floor(GRAPH_PERIOD / graphWidth).toNumber();
    graphXBase = (dw - graphWidth) / 2 + graphWidth - 2;
    graphYBase = dh / 2 + graphVertOffset + GRAPH_HEIGHT;

    // Graph type or size may have changed
    graphBars = null;

    // Bounding boxes must be recalculated here because graphSize affects
    // which touch zones are active (large graph collapses three zones)
    defineBoundingBoxes(dc);

    // Each builder configures its drawables through findDrawableById, which
    // only sees the layout currently set — so they run one after the other
    // and selectLayout() picks the one to show at the end
    sleepLayout = requiresBurnIn ? buildSleepLayout(dc) : null;
    awakeLayout = buildAwakeLayout(dc);
    selectLayout();
  }

  // Build the layout shown outside AMOLED sleep, as chosen by the user
  // settings, and fill its static text (labels).
  function buildAwakeLayout(dc as Dc) as Array<Drawable> {
    var layout;
    if (!batterySave) {
      // Full layout: choose dark or light theme
      layout = darkMode
        ? Rez.Layouts.WatchFace(dc)
        : Rez.Layouts.WatchFaceLight(dc);
      setLayout(layout);
      loadLayout(); // read field assignments from properties into fieldLayout[]
      drawLabels(dc); // populate static label text views
    } else {
      // Battery-save layout: minimal display, no data fields or graph
      layout = darkMode
        ? Rez.Layouts.BatterySave(dc)
        : Rez.Layouts.BatterySaveLight(dc);
      setLayout(layout);
    }

    // Soften the dark-theme white and blue text. The light theme is left
    // alone: its background is white anyway
    if (requiresBurnIn && darkMode) {
      applyAmoledColors(false);
    }
    return layout;
  }

  // Build the minimal layout shown during AMOLED sleep. The dark variant is
  // forced regardless of the theme: a white background would trip the
  // burn-in protector and blank the screen.
  function buildSleepLayout(dc as Dc) as Array<Drawable> {
    var layout = Rez.Layouts.BatterySave(dc);
    setLayout(layout);

    // Dim the time: in white it lights up to ~18% of the screen, above the
    // burn-in protector's 10% luminance limit
    (View.findDrawableById("FieldTime") as Text).setColor(
      Graphics.COLOR_DK_GRAY
    );

    // Remember base positions of the drawables to pixel-shift in sleep
    shiftedViews = [];
    shiftedBase = [];
    var ids = ["FieldTime", "FieldDate", "FieldIcons"];
    for (var i = 0; i < ids.size(); i = i + 1) {
      var view = View.findDrawableById(ids[i]);
      shiftedViews.add(view);
      shiftedBase.add([view.locX, view.locY]);
    }

    applyAmoledColors(true);
    return layout;
  }

  // Show the prebuilt layout matching the current sleep state. Cheap: the
  // drawables keep their text and colours across swaps.
  function selectLayout() as Void {
    sleepLayoutActive = amoledSleep;
    setLayout(amoledSleep ? sleepLayout : awakeLayout);
    minimalLayout = batterySave || amoledSleep;
  }

  function onShow() as Void {}

  // Main render entry point — called every second in normal mode,
  // every minute in low-power mode.
  //
  // Drawing order matters: View.onUpdate() flushes the layout drawables to
  // the display, so the graph (drawn with raw DC calls) must come AFTER to
  // avoid being overwritten by the layout flush.
  function onUpdate(dc as Dc) as Void {
    // Rebuild layouts if flagged by onSettingsChanged(); otherwise just swap
    // to the prebuilt layout if the sleep state changed since the last frame
    if (redrawLayout) {
      onLayout(dc);
      redrawLayout = false;
    } else if (sleepLayoutActive != amoledSleep) {
      selectLayout();
    }

    if (!minimalLayout) {
      drawData(dc); // populate complication / sensor data text views
    }

    drawDate(dc); // always rendered regardless of battery-save mode
    drawTime(dc);
    drawIcons(dc);

    if (amoledSleep) {
      applyBurnInShift();
    }

    View.onUpdate(dc); // flush layout drawables to the display

    // Graph is painted on top of the flushed layout via raw DC primitives
    if (!minimalLayout && showGraph > 0) {
      updateGraphCache();
      drawGraph(dc);
    }
    deferGraphRefresh = false;

    // drawBoundingBoxes(dc);  // uncomment to debug tap zones
  }

  function onHide() as Void {}

  // Defer the graph refresh to keep the wake-up frame cheap (see
  // deferGraphRefresh). On AMOLED, also switch back to the awake layout:
  // MIP screens keep the full layout in sleep, so nothing changes there.
  // The layout swap itself happens in the next onUpdate (see selectLayout).
  function onExitSleep() as Void {
    deferGraphRefresh = true;
    if (amoledSleep) {
      amoledSleep = false;
      WatchUi.requestUpdate();
    }
  }

  // AMOLED only: switch to the minimal sleep layout in low-power mode to stay
  // within the burn-in protector's luminance limit. With always-on disabled
  // the screen is off and no frame may be drawn at all, in which case the
  // awake layout simply stays active and waking up costs nothing.
  function onEnterSleep() as Void {
    if (requiresBurnIn) {
      amoledSleep = true;
      WatchUi.requestUpdate();
    }
  }

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
      // 12-hour mode: fold PM hours down without zero-padding; midnight is 12
      if (hours > 12) {
        hours = hours - 12;
      } else if (hours == 0) {
        hours = 12;
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

    // Always set, even when empty, so icons clear when a flag turns off
    var view = View.findDrawableById("FieldIcons") as Text;
    view.setText(icons);
  }

  // Move the minimal-layout drawables by a small per-minute offset from their
  // base positions, so no pixel stays lit in the same spot during sleep.
  function applyBurnInShift() {
    var offset =
      burnInOffsets[System.getClockTime().min % burnInOffsets.size()];
    for (var i = 0; i < shiftedViews.size(); i = i + 1) {
      shiftedViews[i].setLocation(
        shiftedBase[i][0] + offset[0],
        shiftedBase[i][1] + offset[1]
      );
    }
  }

  // Recolour the dark-theme blue text to AMOLED_BLUE and the white text
  // (white by default, as it has no colour in layout.xml) to AMOLED_WHITE.
  // In the sleep layout only the blue is changed: buildSleepLayout already
  // dims the time. Acts on the layout currently set.
  function applyAmoledColors(forSleep as Boolean) {
    recolorDrawables(["FieldDate", "FieldIcons"], AMOLED_BLUE);
    if (forSleep) {
      return;
    }

    var ids = ["FieldTime", "FieldGraphData"];
    for (var i = 0; i < fieldLayout.size(); i = i + 1) {
      ids.add(fieldLayout[i]["id"] + "Data");
    }
    recolorDrawables(ids, AMOLED_WHITE);
  }

  // Drawables missing from the active layout (data fields in BatterySave)
  // are skipped
  function recolorDrawables(ids as Array<String>, color as Number) {
    for (var i = 0; i < ids.size(); i = i + 1) {
      var view = View.findDrawableById(ids[i]);
      if (view != null) {
        (view as Text).setColor(color);
      }
    }
  }

  // Refresh the graph cache when it is missing, or once a minute — except on
  // the first frame after waking up, which draws the cached bars as they are
  // (see deferGraphRefresh). Sensor history is sampled at most about once a
  // minute, so refreshing more often would redraw the same bars.
  function updateGraphCache() as Void {
    var minute = Time.now().value() / 60;
    if (graphBars != null && (minute == graphMinute || deferGraphRefresh)) {
      return;
    }
    graphBars = computeGraph();
    graphMinute = minute;
  }

  // Draw the cached sensor history bar chart using raw DC primitives.
  function drawGraph(dc) {
    if (graphBars == null) {
      return;
    }

    // Set bar colour once — it is constant for the entire graph render
    dc.setColor(
      graphCatalog[showGraph]["colorDark"],
      Graphics.COLOR_TRANSPARENT
    );

    for (var i = 0; i < graphBars.size(); ++i) {
      var barHeight = graphBars[i];
      var x = graphXBase - i;
      var y = graphYBase - barHeight;

      // Explicit bounds guard — replaces a try/catch in the hot path
      if (barHeight > 0 && y >= 0 && x >= 0 && x < dw) {
        dc.fillRectangle(x, y, 1, barHeight);
      }
    }
  }

  // Compute the bar heights of the sensor history chart, one per bin, newest
  // first. Returns an empty array when there is nothing to draw.
  //
  // Strategy: fetch GRAPH_PERIOD seconds of sensor history and bucket the
  // samples into 1-pixel-wide time bins (newest = rightmost); each bin's bar
  // height is proportional to the normalised average value.
  //
  // Normalisation formula:
  //   norm = (midpoint - curMin * scale) / (curMax - curMin * scale)
  // The `scale` factor (< 1.0) compresses the effective floor so that
  // low values still produce a visible bar rather than collapsing to zero.
  //
  // This walks every sample in the period, which makes it the most expensive
  // routine of the face: it is only called through updateGraphCache().
  function computeGraph() as Array<Numeric> {
    var bars = [] as Array<Numeric>;

    // Cache the entire catalog entry to avoid repeated dict lookups per bin
    var catalog = graphCatalog[showGraph];
    if (catalog["iterator"] == null) {
      return bars; // this graph type has no history data source
    }

    // --- Fetch sensor history ------------------------------------------------

    var getSensorHistory = new Lang.Method(
      Toybox.SensorHistory,
      catalog["iterator"]
    );
    var sample = getSensorHistory.invoke({
      :period => GRAPH_PERIOD,
      :order => SensorHistory.ORDER_NEWEST_FIRST,
    });

    if (sample == null) {
      return bars;
    }

    var curMin = sample.getMin();
    var curMax = sample.getMax();
    var sampleData = sample.next(); // prime the iterator with the first sample

    // Guard: no data, or degenerate range (division by zero in normalisation)
    if (sampleData == null || curMin == null || curMax == null) {
      return bars;
    }
    if (curMin == 0 || curMax == 0 || curMax <= curMin) {
      return bars;
    }

    // Normalisation constants — computed once, reused every iteration
    var scale = catalog["scale"];
    var scaledMin = curMin * scale;
    var denom = curMax - scaledMin;

    // --- Bucketing loop ------------------------------------------------------

    var graphValue = 0; // last known sample value (carried across bin boundaries)
    var secsBin = 0; // accumulated seconds placed in the current bin
    var lastGraphSecs = sample.getNewestSampleTime().value();
    var graphBinMax;
    var graphBinMin;
    var graphSecs;
    var finished = false;

    for (var i = 0; i < graphBins && !finished; ++i) {
      graphBinMax = 0;
      graphBinMin = 0;

      // If there is leftover time from the previous bin, seed this bin
      // with the last known value so there are no visual gaps
      if (secsBin > 0 && graphValue != null) {
        graphBinMax = graphValue;
        graphBinMin = graphValue;
      }

      // Consume samples until this bin has accumulated graphBinSecs of data
      while (!finished && secsBin < graphBinSecs) {
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
      if (secsBin >= graphBinSecs) {
        secsBin -= graphBinSecs;
      }

      // Bar only if this bin has at least one valid reading: normalise the
      // midpoint of [binMin, binMax] to [0..1] and scale to pixels
      var barHeight = 0;
      if (graphBinMax > 0 && graphBinMax >= graphBinMin) {
        var norm = ((graphBinMax + graphBinMin) / 2 - scaledMin) / denom;
        barHeight = norm * GRAPH_HEIGHT;
      }
      bars.add(barHeight);
    }
    return bars;
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

  // Current value of a system complication, or null when unavailable.
  // getComplication() throws ComplicationNotFoundException when the device
  // firmware does not provide the requested type.
  function getComplicationValue(type) {
    if (Toybox has :Complications) {
      try {
        return Complications.getComplication(new Complications.Id(type)).value;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Newest sample of a SensorHistory iterator, or null when there is no data
  // (e.g. right after a device reset).
  function getNewestSample(iterator) {
    var sample = iterator != null ? iterator.next() : null;
    return sample != null ? sample.data : null;
  }

  function getEmpty() {
    return "";
  }

  // Today's low/high temperature from the Weather complication (e.g. "12/24")
  function getWeather() {
    if (Toybox has :Weather) {
      var data = Toybox.Weather.getCurrentConditions();
      if (
        data == null ||
        data.lowTemperature == null ||
        data.highTemperature == null
      ) {
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
    var data = getComplicationValue(
      Complications.COMPLICATION_TYPE_CALENDAR_EVENTS
    );
    return data != null ? data : "--";
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
    var data = getComplicationValue(Complications.COMPLICATION_TYPE_BATTERY);
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
    var data = getComplicationValue(Complications.COMPLICATION_TYPE_ALTITUDE);
    if (data == null && Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :altitude) {
        data = Toybox.Activity.getActivityInfo().altitude;
      }
    }
    if (data == null) {
      data = getNewestSample(Toybox.SensorHistory.getElevationHistory({}));
    }
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Ambient temperature in °C, rounded. Fallback: Complications → SensorHistory.
  function getTemperature() {
    var data = getComplicationValue(
      Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE
    );
    if (data == null) {
      data = getNewestSample(Toybox.SensorHistory.getTemperatureHistory({}));
    }
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Body Battery level 0-100. Fallback: Complications → SensorHistory.
  function getBodyBattery() {
    var data = getComplicationValue(
      Complications.COMPLICATION_TYPE_BODY_BATTERY
    );
    if (data == null) {
      data = getNewestSample(Toybox.SensorHistory.getBodyBatteryHistory({}));
    }
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Stress level 0-100. Fallback: Complications → SensorHistory.
  function getStress() {
    var data = getComplicationValue(Complications.COMPLICATION_TYPE_STRESS);
    if (data == null) {
      data = getNewestSample(Toybox.SensorHistory.getStressHistory({}));
    }
    return data != null ? (data + 0.5).toNumber().toString() : "--";
  }

  // Heart rate in bpm. Fallback: Complications → Activity → SensorHistory.
  // The SensorHistory path filters out INVALID_HR_SAMPLE sentinel values.
  function getHeartRate() {
    var data = getComplicationValue(Complications.COMPLICATION_TYPE_HEART_RATE);
    if (data == null && Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :currentHeartRate) {
        data = Toybox.Activity.getActivityInfo().currentHeartRate;
      }
    }
    if (data == null && Toybox has :SensorHistory) {
      if (Toybox.SensorHistory has :getHeartRateHistory) {
        data = getNewestSample(Toybox.SensorHistory.getHeartRateHistory({}));
        if (data == Toybox.ActivityMonitor.INVALID_HR_SAMPLE) {
          data = null;
        }
      }
    }
    return data != null ? Lang.format("$1$", [data]) : "--";
  }

  // Active calories burned. Fallback: Complications → Activity.
  function getCalories() {
    var data = getComplicationValue(Complications.COMPLICATION_TYPE_CALORIES);
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
    var data = getComplicationValue(Complications.COMPLICATION_TYPE_STEPS);
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

    // 5 digits keep one decimal ("12.3k"), 6+ digits drop it ("123k")
    if (!(data instanceof Toybox.Lang.Number)) {
      return data.toString();
    } else if (data >= 100000) {
      return (data / 1000).toString() + "k";
    } else if (data >= 10000) {
      return (
        (data / 1000).toString() + "." + ((data / 100) % 10).toString() + "k"
      );
    }

    return data.toString();
  }

  // Floors climbed today. Fallback: Complications → ActivityMonitor.
  function getFloors() {
    var data = getComplicationValue(
      Complications.COMPLICATION_TYPE_FLOORS_CLIMBED
    );
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
    var data = getComplicationValue(
      Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE
    );
    if (data == null && Toybox has :Activity) {
      if (Toybox.Activity.getActivityInfo() has :meanSeaLevelPressure) {
        data = Toybox.Activity.getActivityInfo().meanSeaLevelPressure;
      }
    }
    if (data == null && Toybox has :SensorHistory) {
      if (Toybox.SensorHistory has :getPressureHistory) {
        data = getNewestSample(Toybox.SensorHistory.getPressureHistory({}));
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
