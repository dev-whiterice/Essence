# Essence

Essence — a clean, battery-friendly digital watchface for Garmin devices.

![Essence Watchface](https://github.com/dev-lessismore/Essence/blob/main/doc/fenix8.png?raw=true)

---

## Contribution

As I have learned from others, maybe I can help too.

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/devlessismore)

**Code contributions:** Fork → Develop → Pull request → Review. This is the way.

---

## Description

Essence is a digital watchface designed to be easy to read and battery-friendly.
It supports up to 8 configurable data fields and an optional sensor history graph.

### Supported devices

| Device | Resolution |
|---|---|
| Approach S70 47mm | 454×454 |
| Descent Mk3 51mm | 454×454 |
| Enduro 3 | 454×454 |
| epix Pro 51mm | 454×454 |
| fēnix 7 / 7 Pro / 7 Pro (no WiFi) | 260×260 |
| fēnix 7X / 7X Pro / 7X Pro (no WiFi) | 390×390 |
| fēnix 8 47mm | 454×454 |
| fēnix 8 Solar 47mm / 51mm | 454×454 |
| Forerunner 255 / 255M | 260×260 |
| Forerunner 955 | 390×390 |
| Forerunner 965 | 454×454 |
| Venu 3 | 454×454 |

---

## Fields

Each of the 8 screen zones (Top, Upper Left/Center/Right, Lower Left/Center/Right, Bottom)
can be independently configured to show one of the following data types:

| Field | Description |
|---|---|
| Empty | Blank — hides the zone |
| Weather | Today's low / high temperature |
| Calendar | Next calendar event |
| Notifications | Unread notification count |
| Sunrise / Sunset | Time of next sunrise or sunset (label updates automatically) |
| Altitude | Current altitude in metres |
| Heart Rate | Current heart rate in bpm |
| Barometer | Sea-level pressure in hPa |
| Battery | Battery percentage |
| Stress | Stress level (0–100) |
| Body Battery | Body Battery level (0–100) |
| Steps | Step count (displayed as `10k`, `11k`… above 9 999) |
| Floors | Floors climbed today |
| Battery Days | Estimated days of charge remaining |
| Solar Intensity | Solar charging intensity (solar models only) |
| Calories | Active calories burned |
| Temperature | Ambient temperature in °C |

Data is sourced in priority order: **Complications API → Activity API → SensorHistory API**,
so the most power-efficient source is always preferred.

---

## Graph

The Lower Center zone can optionally display a 4-hour sensor history graph.
Available graph types:

| Graph | Colour |
|---|---|
| Heart Rate | Red |
| Barometer | Blue |
| Altimeter | Green |

Graph size is configurable: **Small** (center field only) or **Large** (spans the full lower row).

---

## Settings

Accessible via long-press on the watch face or through the Garmin Connect app.

| Setting | Description |
|---|---|
| Battery Save | Switches to a minimal display (time + date only, no data fields or graph) |
| Dark Mode | Toggles between dark and light theme |
| Field Top … Field Bottom | Selects the data type for each of the 8 field zones |
| Show Graph | Selects the graph type (or disables the graph) |
| Graph Size | Small (single field) or Large (full lower row) |

Tapping a field zone on the watch face launches the associated Garmin complication app directly.

---

## Permissions

- **ComplicationSubscriber** — reads live complication data (HR, battery, steps, etc.)
- **Positioning** — required for Sunrise/Sunset calculation
- **SensorHistory** — accesses on-device sensor history for graphs and fallback readings

---

## Languages

English (default), Italian, Spanish.

---

## Credits

Developers who share — with love — their code.
