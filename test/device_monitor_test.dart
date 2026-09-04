import
'dart:async';
import 'package:hidapi/hidapi.dart';

void main() async {
  print('Testing HID device connection/disconnection monitoring...');
  print('=' * 60);

  // Initialize the library
  hidInit();
  print('hidapi version: ${hidVersionStr()}');
  print('');

  // Do initial enumeration
  final initialDevices = hidEnumerate();
  print('Initial device count: ${initialDevices.length}');
  for (final dev in initialDevices) {
    print('  - ${dev.manufacturer} ${dev.product} '
          '(vid: 0x${dev.vendorId.toRadixString(16)}, '
          'pid: 0x${dev.productId.toRadixString(16)})');
  }
  print('');

  // Test creating a monitor
  print('Starting device monitor...');
  print('Waiting for device changes (connect/disconnect)...');
  print('Press Ctrl+C to exit');
  print('');

  final monitor = HidDeviceMonitor();
  int eventCount = 0;

  final subscription = monitor.events.listen((event) {
    eventCount++;
    final timestamp = DateTime.now().toIso8601String();
    final typeStr = event.type == HidDeviceEventType.added
        ? 'CONNECTED'
        : 'DISCONNECTED';
    final dev = event.deviceInfo;
    print('[$timestamp] [$typeStr] Event #$eventCount:');
    print('  Path: ${dev.path}');
    print('  Vendor ID: 0x${dev.vendorId.toRadixString(16)}');
    print('  Product ID: 0x${dev.productId.toRadixString(16)}');
    print('  Manufacturer: ${dev.manufacturer}');
    print('  Product: ${dev.product}');
    print('  Serial: ${dev.serialNumber}');
    print('');
  });

  monitor.start();
  print('Monitor started successfully! isMonitoring = ${monitor.isMonitoring}');
  print('');

  // Keep the program running
  await Completer<void>().future;

  // Cleanup (unreachable in this example, but for completeness)
  await subscription.cancel();
  monitor.stop();
  monitor.dispose();
  hidExit();
}
