using Toybox.System;
using Toybox.Complications;

public var bboxes = [];
public var boundingBoxes = [];

public function checkBoundingBoxes(points) {
  for (var i = 0; i < boundingBoxes.size(); i++) {
    var currentBounds = boundingBoxes[i];
    if (checkBoundsForComplication(points, currentBounds["bounds"])) {
      var dataIndex = fieldLayout[i]["data"];
      if (dataField[dataIndex]["complicationId"] == null) {
        return false;
      }
      return dataField[dataIndex]["complicationId"];
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

var dataField = [
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
    "complicationId" => null,
  },
];

function loadLayout() {
  for (var i = 0; i < fieldLayout.size(); i = i + 1) {
    fieldLayout[i]["data"] = getApp().getProperty(fieldLayout[i]["id"]);
  }
}

var redrawLayout = false;
