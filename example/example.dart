import 'package:hidapi/hidapi.dart';

void main() {
  hidInit();

  // Example 1: Simple enumeration
  print('=== Initial enumeration ===');
  final devices = hidEnumerate();
  print('Found ${devices.length} HID device(s):');
  for (final d in devices) {
    print('  ${d.manufacturer} ${d.product} — ${d.path}');
  }
  print('');

  // Example 2: Listen to device connection/disconnection events
  print('=== Starting native device event monitoring ===');
  print('Native hidapi 0.16.0+ device monitoring will notify immediately');
  print('when devices are connected or disconnected');
  print('Press Ctrl+C to exit');
  print('');

  // Using the global monitor for all devices
  HidDeviceEvents.start();

  HidDeviceEvents.events.listen((event) {
    final type = event.type == HidDeviceEventType.added ? 'ADDED' : 'REMOVED';
    final dev = event.deviceInfo;
    print('[$type] ${dev.manufacturer} ${dev.product} (vid: 0x${dev.vendorId.toRadixString(16)}, pid: 0x${dev.productId.toRadixString(16)}) — ${dev.path}');
  });

  // Alternative: Create a custom monitor that only monitors specific devices
  // final monitor = HidDeviceMonitor(
  //   vendorId: 0x1234, // replace with your vendor ID
  //   productId: 0x5678, // replace with your product ID
  // );
  // monitor.start();
  // monitor.events.listen((event) {
  //   print('Custom monitor: $event');
  // });
  //
  // // Remember to dispose when done:
  // // monitor.dispose();
}
