// ============================================================================
// Globals.mc
// Application-wide state, data catalogs, and hit-testing utilities.
//
// All variables declared here are module-level globals shared across
// EssenceView, EssenceDelegate, and EssenceSettingsMenu.
// ============================================================================

using Toybox.System;
using Toybox.Complications;
using Toybox.Graphics;

// --------------------------------------------------------------------------
// Runtime state flags
// --------------------------------------------------------------------------

// Unused — kept for API compatibility (do not remove)
public var bboxes = [];

// Tap bounding boxes built in EssenceView.defineBoundingBoxes().
// Each entry: { "id", "bounds" => [[xMin,yMin],[xMax,yMax]], "value", "complicationId" }
public var boundingBoxes = [];

// Set to true by onSettingsChanged() to request a full layout rebuild on the
// next onUpdate() call. Avoids rebuilding mid-render from the settings thread.
var redrawLayout = false;

// Mirror of the "BatterySave" user property — read in onLayout, used in
// onUpdate and onPress to skip all non-essential drawing and input handling.
var batterySave = false;

// Index into graphCatalog[] for the currently active graph type.
// 0 = no graph; >0 = one of the sensor history graphs.
var showGraph = 0;

// Graph size mode: 0 = small (center field only), 1 = large (full lower row).
var graphSize = 0;

// Mirror of the "DarkMode" user property — selects the layout theme in onLayout.
var darkMode = true;

// --------------------------------------------------------------------------
// Hit-testing utilities (used by EssenceDelegate.onPress)
// --------------------------------------------------------------------------

// Walk the bounding-box registry and return the Complication ID associated
// with whichever zone contains `points`, or false if no zone matches.
//
// Special case: when a graph is active (showGraph > 0) and the tap lands on
// FieldLowerCenter, the graph's own complicationId is returned instead of the
// field's, because the graph visually replaces that field.
public function checkBoundingBoxes(points) {
  for (var i = 0; i < boundingBoxes.size(); i++) {
    var currentBounds = boundingBoxes[i];
    if (checkBoundsForComplication(points, currentBounds["bounds"])) {
      if (fieldLayout[i]["id"].equals("FieldLowerCenter") && showGraph > 0) {
        // Graph occupies this zone — route the tap to the graph's complication
        if (graphCatalog[showGraph]["complicationId"] == null) {
          return false;
        }
        return graphCatalog[showGraph]["complicationId"];
      } else {
        // Standard field — route tap to the field's configured complication
        var dataIndex = fieldLayout[i]["data"];
        if (fieldCatalog[dataIndex]["complicationId"] == null) {
          return false;
        }
        return fieldCatalog[dataIndex]["complicationId"];
      }
    }
  }
  return false;
}

// Returns true if `points` falls inside the bounding box defined by `boundingBox`.
public function checkBoundsForComplication(points, boundingBox) {
  return boxContains(points, boundingBox[0], boundingBox[1]);
}

// Point-in-rectangle test.
//   points    — [x, y] tap coordinate
//   boxMinXY  — [xMin, yMin] top-left corner of the box
//   boxMaxXY  — [xMax, yMax] bottom-right corner of the box
public function boxContains(points, boxMinXY, boxMaxXY) {
  return (
    points[0] <= boxMaxXY[0] &&
    points[1] <= boxMaxXY[1] &&
    points[0] >= boxMinXY[0] &&
    points[1] >= boxMinXY[1]
  );
}

// --------------------------------------------------------------------------
// fieldLayout
//
// Maps each of the 8 screen zones to an index in fieldCatalog[].
// The "data" values are overwritten at runtime by loadLayout() from the
// user's stored properties, so the defaults here are only the initial values
// used before the first settings write.
// --------------------------------------------------------------------------
var fieldLayout = [
  { "id" => "FieldTop",         "data" => 0 },
  { "id" => "FieldUpperLeft",   "data" => 1 },
  { "id" => "FieldUpperCenter", "data" => 2 },
  { "id" => "FieldUpperRight",  "data" => 3 },
  { "id" => "FieldLowerLeft",   "data" => 4 },
  { "id" => "FieldLowerCenter", "data" => 5 },
  { "id" => "FieldLowerRight",  "data" => 6 },
  { "id" => "FieldBottom",      "data" => 7 },
];

// --------------------------------------------------------------------------
// fieldCatalog
//
// Master list of all displayable data types. Each entry describes one field:
//   "id"           — internal identifier (matches property key in settings)
//   "label"        — short string resource shown as the field label on the face
//   "labelExt"     — longer string resource shown in the settings menu
//   "getter"       — symbol of the EssenceView method that returns the value
//   "complicationId" — Complications API type for tap-through, or null
//
// Array index == the integer stored in the user property for each field zone.
// --------------------------------------------------------------------------
var fieldCatalog = [
  // 0
  { "id" => "Empty",         "label" => Rez.Strings.Empty,         "labelExt" => Rez.Strings.EmptyExt,         "getter" => :getEmpty,         "complicationId" => null },
  // 1
  { "id" => "Weather",       "label" => Rez.Strings.Weather,       "labelExt" => Rez.Strings.WeatherExt,       "getter" => :getWeather,       "complicationId" => Complications.COMPLICATION_TYPE_CURRENT_WEATHER   },
  // 2
  { "id" => "Calendar",      "label" => Rez.Strings.Calendar,      "labelExt" => Rez.Strings.CalendarExt,      "getter" => :getCalendar,      "complicationId" => Complications.COMPLICATION_TYPE_CALENDAR_EVENTS    },
  // 3
  { "id" => "Notifications", "label" => Rez.Strings.Notifications, "labelExt" => Rez.Strings.NotificationsExt, "getter" => :getNotifications, "complicationId" => Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT },
  // 4 — special: getter returns { "label", "value" } dict, not a plain string
  { "id" => "SunEvent",      "label" => Rez.Strings.SunEvent,      "labelExt" => Rez.Strings.SunEventExt,      "getter" => :getSunEvent,      "complicationId" => Complications.COMPLICATION_TYPE_SUNRISE            },
  // 5
  { "id" => "Altimeter",     "label" => Rez.Strings.Altimeter,     "labelExt" => Rez.Strings.AltimeterExt,     "getter" => :getAltimeter,     "complicationId" => Complications.COMPLICATION_TYPE_ALTITUDE           },
  // 6
  { "id" => "HeartRate",     "label" => Rez.Strings.HeartRate,     "labelExt" => Rez.Strings.HeartRateExt,     "getter" => :getHeartRate,     "complicationId" => Complications.COMPLICATION_TYPE_HEART_RATE         },
  // 7
  { "id" => "Barometer",     "label" => Rez.Strings.Barometer,     "labelExt" => Rez.Strings.BarometerExt,     "getter" => :getBarometer,     "complicationId" => Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE },
  // 8
  { "id" => "Battery",       "label" => Rez.Strings.Battery,       "labelExt" => Rez.Strings.BatteryExt,       "getter" => :getBattery,       "complicationId" => Complications.COMPLICATION_TYPE_BATTERY            },
  // 9
  { "id" => "Stress",        "label" => Rez.Strings.Stress,        "labelExt" => Rez.Strings.StressExt,        "getter" => :getStress,        "complicationId" => Complications.COMPLICATION_TYPE_STRESS             },
  // 10
  { "id" => "BodyBattery",   "label" => Rez.Strings.BodyBattery,   "labelExt" => Rez.Strings.BodyBatteryExt,   "getter" => :getBodyBattery,   "complicationId" => Complications.COMPLICATION_TYPE_BODY_BATTERY       },
  // 11
  { "id" => "Steps",         "label" => Rez.Strings.Steps,         "labelExt" => Rez.Strings.StepsExt,         "getter" => :getSteps,         "complicationId" => Complications.COMPLICATION_TYPE_STEPS              },
  // 12
  { "id" => "Floors",        "label" => Rez.Strings.Floors,        "labelExt" => Rez.Strings.FloorsExt,        "getter" => :getFloors,        "complicationId" => Complications.COMPLICATION_TYPE_FLOORS_CLIMBED     },
  // 13
  { "id" => "BatteryDays",   "label" => Rez.Strings.BatteryDays,   "labelExt" => Rez.Strings.BatteryDaysExt,   "getter" => :getBatteryDays,   "complicationId" => Complications.COMPLICATION_TYPE_BATTERY            },
  // 14
  { "id" => "SolarIntensity","label" => Rez.Strings.SolarIntensity,"labelExt" => Rez.Strings.SolarIntensityExt,"getter" => :getSolarIntensity,"complicationId" => Complications.COMPLICATION_TYPE_SOLAR_INPUT        },
  // 15
  { "id" => "Calories",      "label" => Rez.Strings.Calories,      "labelExt" => Rez.Strings.CaloriesExt,      "getter" => :getCalories,      "complicationId" => Complications.COMPLICATION_TYPE_CALORIES           },
  // 16
  { "id" => "Temperature",   "label" => Rez.Strings.Temperature,   "labelExt" => Rez.Strings.TemperatureExt,   "getter" => :getTemperature,   "complicationId" => Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE},
];

// --------------------------------------------------------------------------
// graphCatalog
//
// Describes the available sensor-history graph types. Index 0 is the sentinel
// "no graph" entry; indices 1-N are actual graph types.
//
// Each entry:
//   "id"           — internal identifier
//   "label"        — short string resource for the graph label on the face
//   "labelExt"     — longer string for the settings menu sublabel
//   "getter"       — symbol of the EssenceView method for the current value
//   "iterator"     — symbol of the Toybox.SensorHistory method for history data,
//                    or null (index 0) when no graph is active
//   "complicationId" — Complications type for tap-through from the graph zone
//   "color"        — lighter bar colour (currently reserved / commented out)
//   "colorDark"    — bar fill colour used by drawGraph()
//   "scale"        — floor-compression factor for the normalisation formula;
//                    values < 1.0 raise the effective baseline so low readings
//                    still render as a visible bar rather than collapsing to zero
// --------------------------------------------------------------------------
var graphCatalog = [
  // 0 — sentinel: no graph active
  {
    "id"           => "fieldCatalog",
    "label"        => null,
    "labelExt"     => Rez.Strings.ShowGraphfieldCatalog,
    "getter"       => :getEmpty,
    "iterator"     => null,
    "complicationId" => null,
    "color"        => null,
    "colorDark"    => null,
    "scale"        => 0.9,
  },
  // 1 — Heart rate (bpm)
  {
    "id"           => "HeartRate",
    "label"        => Rez.Strings.HeartRate,
    "labelExt"     => Rez.Strings.ShowGraphHeartRate,
    "getter"       => :getHeartRate,
    "iterator"     => :getHeartRateHistory,
    "complicationId" => Complications.COMPLICATION_TYPE_HEART_RATE,
    "color"        => Graphics.COLOR_RED,
    "colorDark"    => Graphics.COLOR_DK_RED,
    "scale"        => 0.9,
  },
  // 2 — Sea-level pressure (hPa); scale near 1.0 because the range is narrow
  {
    "id"           => "Barometer",
    "label"        => Rez.Strings.Barometer,
    "labelExt"     => Rez.Strings.ShowGraphPressure,
    "getter"       => :getBarometer,
    "iterator"     => :getPressureHistory,
    "complicationId" => Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE,
    "color"        => Graphics.COLOR_BLUE,
    "colorDark"    => Graphics.COLOR_DK_BLUE,
    "scale"        => 0.99,
  },
  // 3 — Elevation (metres)
  {
    "id"           => "Altimeter",
    "label"        => Rez.Strings.Altimeter,
    "labelExt"     => Rez.Strings.ShowGraphAltimeter,
    "getter"       => :getAltimeter,
    "iterator"     => :getElevationHistory,
    "complicationId" => Complications.COMPLICATION_TYPE_ALTITUDE,
    "color"        => Graphics.COLOR_DK_GREEN,
    "colorDark"    => Graphics.COLOR_GREEN,
    "scale"        => 0.9,
  },
];

// --------------------------------------------------------------------------
// loadLayout
//
// Reads each field zone's user property and writes the chosen fieldCatalog
// index back into fieldLayout[]["data"]. Called from EssenceView.onLayout()
// after every settings change.
// --------------------------------------------------------------------------
function loadLayout() {
  for (var i = 0; i < fieldLayout.size(); i = i + 1) {
    fieldLayout[i]["data"] = getApp().getProperty(fieldLayout[i]["id"]);
  }
}
