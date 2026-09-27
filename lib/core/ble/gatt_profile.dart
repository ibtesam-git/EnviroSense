abstract final class EnviroSenseGattProfile {
  // Keep these IDs stable: the Flutter app and ESP32 firmware must match.
  static const service = '1621b17e-922c-4d5e-95c7-79a8e0cf091d';

  static const deviceInfo = '04859adc-3213-4bfb-be69-8597b12b431f';
  static const sensorCatalog = '9ef2e4ee-18bc-42cc-a39c-deadd8cb5d3a';
  static const telemetry = 'e39d8efb-a6ca-49a1-9e21-359f8b0dfd41';
  static const control = '131969b0-1a2f-49f9-9e7b-13a5b7ffd8cf';
}
