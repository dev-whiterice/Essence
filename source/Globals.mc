using Toybox.System;
using Toybox.Complications;
using Toybox.Graphics;

public var bboxes = [];
public var boundingBoxes = [];
var redrawLayout = false;
var batterySave = false;
var showGraph = 0;
var darkMode = true;

public function checkBoundingBoxes(points) {
  for (var i = 0; i < boundingBoxes.size(); i++) {
    var currentBounds = boundingBoxes[i];
    if (checkBoundsForComplication(points, currentBounds["bounds"])) {
      if (fieldLayout[i]["id"].equals("FieldLowerCenter") && showGraph > 0) {
        if (graphCatalog[showGraph]["complicationId"] == null) {
          return false;
        }
        return graphCatalog[showGraph]["complicationId"];
      } else {
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
public function checkBoundsForComplication(points, boundingBox) {
  return boxContains(points, boundingBox[0], boundingBox[1]);
}

public function boxContains(points, boxMinXY, boxMaxXY) {
  return (
    points[0] <= boxMaxXY[0] &&
    points[1] <= boxMaxXY[1] &&
    points[0] >= boxMinXY[0] &&
    points[1] >= boxMinXY[1]
  );
}

var fieldLayout = [
  {
    "id" => "FieldTop",
    "data" => 0,
  },
  {
    "id" => "FieldUpperLeft",
    "data" => 1,
  },
  {
    "id" => "FieldUpperCenter",
    "data" => 2,
  },
  {
    "id" => "FieldUpperRight",
    "data" => 3,
  },
  {
    "id" => "FieldLowerLeft",
    "data" => 4,
  },
  {
    "id" => "FieldLowerCenter",
    "data" => 5,
  },
  {
    "id" => "FieldLowerRight",
    "data" => 6,
  },
  {
    "id" => "FieldBottom",
    "data" => 7,
  },
];

var fieldCatalog = [
  {
    "id" => "Empty",
    "label" => Rez.Strings.Empty,
    "labelExt" => Rez.Strings.EmptyExt,
    "getter" => :getEmpty,
    "complicationId" => null,
  },
  {
    "id" => "Weather",
    "label" => Rez.Strings.Weather,
    "labelExt" => Rez.Strings.WeatherExt,
    "getter" => :getWeather,
    "complicationId" => Complications.COMPLICATION_TYPE_CURRENT_WEATHER,
  },
  {
    "id" => "Calendar",
    "label" => Rez.Strings.Calendar,
    "labelExt" => Rez.Strings.CalendarExt,
    "getter" => :getCalendar,
    "complicationId" => Complications.COMPLICATION_TYPE_CALENDAR_EVENTS,
  },
  {
    "id" => "Notifications",
    "label" => Rez.Strings.Notifications,
    "labelExt" => Rez.Strings.NotificationsExt,
    "getter" => :getNotifications,
    "complicationId" => Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT,
  },
  {
    "id" => "SunEvent",
    "label" => Rez.Strings.SunEvent,
    "labelExt" => Rez.Strings.SunEventExt,
    "getter" => :getSunEvent,
    "complicationId" => Complications.COMPLICATION_TYPE_SUNRISE,
  },
  {
    "id" => "Altimeter",
    "label" => Rez.Strings.Altimeter,
    "labelExt" => Rez.Strings.AltimeterExt,
    "getter" => :getAltimeter,
    "complicationId" => Complications.COMPLICATION_TYPE_ALTITUDE,
  },
  {
    "id" => "HeartRate",
    "label" => Rez.Strings.HeartRate,
    "labelExt" => Rez.Strings.HeartRateExt,
    "getter" => :getHeartRate,
    "complicationId" => Complications.COMPLICATION_TYPE_HEART_RATE,
  },
  {
    "id" => "Barometer",
    "label" => Rez.Strings.Barometer,
    "labelExt" => Rez.Strings.BarometerExt,
    "getter" => :getBarometer,
    "complicationId" => Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE,
  },
  {
    "id" => "Battery",
    "label" => Rez.Strings.Battery,
    "labelExt" => Rez.Strings.BatteryExt,
    "getter" => :getBattery,
    "complicationId" => Complications.COMPLICATION_TYPE_BATTERY,
  },
  {
    "id" => "Stress",
    "label" => Rez.Strings.Stress,
    "labelExt" => Rez.Strings.StressExt,
    "getter" => :getStress,
    "complicationId" => Complications.COMPLICATION_TYPE_STRESS,
  },
  {
    "id" => "BodyBattery",
    "label" => Rez.Strings.BodyBattery,
    "labelExt" => Rez.Strings.BodyBatteryExt,
    "getter" => :getBodyBattery,
    "complicationId" => Complications.COMPLICATION_TYPE_BODY_BATTERY,
  },
  {
    "id" => "Steps",
    "label" => Rez.Strings.Steps,
    "labelExt" => Rez.Strings.StepsExt,
    "getter" => :getSteps,
    "complicationId" => Complications.COMPLICATION_TYPE_STEPS,
  },
  {
    "id" => "Floors",
    "label" => Rez.Strings.Floors,
    "labelExt" => Rez.Strings.FloorsExt,
    "getter" => :getFloors,
    "complicationId" => Complications.COMPLICATION_TYPE_FLOORS_CLIMBED,
  },
  {
    "id" => "BatteryDays",
    "label" => Rez.Strings.BatteryDays,
    "labelExt" => Rez.Strings.BatteryDaysExt,
    "getter" => :getBatteryDays,
    "complicationId" => Complications.COMPLICATION_TYPE_BATTERY,
  },
  {
    "id" => "SolarIntensity",
    "label" => Rez.Strings.SolarIntensity,
    "labelExt" => Rez.Strings.SolarIntensityExt,
    "getter" => :getSolarIntensity,
    "complicationId" => Complications.COMPLICATION_TYPE_SOLAR_INPUT,
  },
  {
    "id" => "Calories",
    "label" => Rez.Strings.Calories,
    "labelExt" => Rez.Strings.CaloriesExt,
    "getter" => :getCalories,
    "complicationId" => Complications.COMPLICATION_TYPE_CALORIES,
  },
  {
    "id" => "Temperature",
    "label" => Rez.Strings.Temperature,
    "labelExt" => Rez.Strings.TemperatureExt,
    "getter" => :getTemperature,
    "complicationId" => Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE,
  },
];

var graphCatalog = [
  {
    "id" => "fieldCatalog",
    "label" => null,
    "labelExt" => Rez.Strings.ShowGraphfieldCatalog,
    "getter" => :getEmpty,
    "iterator" => null,
    "complicationId" => null,
    "color" => null,
    "colorDark" => null,
    "scale" => 0.9,
  },
  {
    "id" => "HeartRate",
    "label" => Rez.Strings.HeartRate,
    "labelExt" => Rez.Strings.ShowGraphHeartRate,
    "getter" => :getHeartRate,
    "iterator" => :getHeartRateHistory,
    "complicationId" => Complications.COMPLICATION_TYPE_HEART_RATE,
    "color" => Graphics.COLOR_RED,
    "colorDark" => Graphics.COLOR_DK_RED,
    "scale" => 0.9,
  },
  {
    "id" => "Barometer",
    "label" => Rez.Strings.Barometer,
    "labelExt" => Rez.Strings.ShowGraphPressure,
    "getter" => :getBarometer,
    "iterator" => :getPressureHistory,
    "complicationId" => Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE,
    "color" => Graphics.COLOR_BLUE,
    "colorDark" => Graphics.COLOR_DK_BLUE,
    "scale" => 0.99,
  },
  {
    "id" => "Altimeter",
    "label" => Rez.Strings.Altimeter,
    "labelExt" => Rez.Strings.ShowGraphAltimeter,
    "getter" => :getAltimeter,
    "iterator" => :getElevationHistory,
    "complicationId" => Complications.COMPLICATION_TYPE_ALTITUDE,
    "colorDark" => Graphics.COLOR_GREEN,
    "color" => Graphics.COLOR_DK_GREEN,
    "scale" => 0.9,
  },
];

function loadLayout() {
  for (var i = 0; i < fieldLayout.size(); i = i + 1) {
    fieldLayout[i]["data"] = getApp().getProperty(fieldLayout[i]["id"]);
  }
}
