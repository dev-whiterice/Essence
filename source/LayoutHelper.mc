using Toybox.Lang;

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
    "id" => "Weather",
    "label" => Rez.Strings.Weather,
    "getter" => :getWeather,
  },
  {
    "id" => "Calendar",
    "label" => Rez.Strings.Calendar,
    "getter" => :getCalendar,
  },
  {
    "id" => "Notifications",
    "label" => Rez.Strings.Notifications,
    "getter" => :getNotifications,
  },
  {
    "id" => "SunEvent",
    "label" => Rez.Strings.SunEvent,
    "getter" => :getSunEvent,
  },
  {
    "id" => "Altimeter",
    "label" => Rez.Strings.Altimeter,
    "getter" => :getAltimeter,
  },
  {
    "id" => "HeartRate",
    "label" => Rez.Strings.HeartRate,
    "getter" => :getHeartRate,
  },
  {
    "id" => "Barometer",
    "label" => Rez.Strings.Barometer,
    "getter" => :getBarometer,
  },
  {
    "id" => "Battery",
    "label" => Rez.Strings.Battery,
    "getter" => :getBattery,
  },
];

function loadLayout() {
  for (var i = 0; i < fieldLayout.size(); i = i + 1) {
    fieldLayout[i]["data"] = getApp().getProperty(fieldLayout[i]["id"]);
  }
}
