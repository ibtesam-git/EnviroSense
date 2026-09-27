
The application is designed to:

1. Scan for nearby BLE devices
2. Connect to a compatible ESP32 device
3. Verify that the device matches the EnviroSense BLE profile
4. Display sensor readings on a dashboard (currently populated with demo data for UI testing)

---

## Features

- **BLE Device Scanning** — Discovers nearby Bluetooth Low Energy devices in real time
- **Connection Handling** — Connects to, verifies, and disconnects from ESP32 devices reliably
- **Permission Management** — Automatically handles Android and iOS Bluetooth and location permissions
- **Dashboard UI** — Displays sensor readings for temperature, humidity, pressure, and light
- **Custom Theming** — Dark-themed interface with smooth page transitions
- **State Management with Riverpod** — Clean and scalable app architecture
- **Custom GATT Profile** — Defined BLE service and characteristics matched with corresponding ESP32 firmware

---

## Tech Stack

| Layer              | Technology                   |
|--------------------|-------------------------------|
| Framework          | Flutter (Dart)                |
| State Management   | Riverpod                      |
| Navigation         | go_router                     |
| BLE Communication  | flutter_reactive_ble           |
| Permissions        | permission_handler            |
| Target Hardware    | ESP32 (Bluetooth Low Energy)  |

---

## Current Progress

- [x] Application UI (Dashboard and Device Scan screens)
- [x] BLE scanning and connection logic
- [x] Device profile verification
- [ ] Live sensor data streaming from ESP32
- [ ] Historical data logging and charts
- [ ] Control commands sent back to the ESP32 device

---

## Roadmap

This project is being actively developed. Upcoming updates will focus on integrating live telemetry from the ESP32, adding data history and visualization, and expanding device control features. Further documentation will be added as the project progresses.

---

## Getting Started

This project is built with Flutter. To run it locally:
flutter pub get
flutter run
For general Flutter setup guidance, refer to the official Flutter documentation.
