@Tags(['hardware'])
library;

import 'package:hidapi/hidapi.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(hidInit);
  tearDownAll(hidExit);

  test('enumerate all HID devices', () {
    final devices = hidEnumerate();
    // Should find at least one HID device on any dev machine.
    print('Found ${devices.length} HID device(s):');
    for (final d in devices) {
      print('  $d');
    }
    expect(devices, isNotEmpty);
  });

  test('enumerate XHC pendant (VID 0x10CE, PID 0xEB93)', () {
    final devices = hidEnumerate(vendorId: 0x10CE, productId: 0xEB93);
    print('Found ${devices.length} pendant collection(s):');
    for (final d in devices) {
      print(
        '  vid=0x${d.vendorId.toRadixString(16)} '
        'pid=0x${d.productId.toRadixString(16)} '
        'usagePage=0x${d.usagePage.toRadixString(16)} '
        'usage=0x${d.usage.toRadixString(16)} '
        'iface=${d.interfaceNumber} '
        'mfr="${d.manufacturer}" '
        'product="${d.product}" '
        'path="${d.path}"',
      );
    }
    // Pendant has 2 HID collections.
    expect(devices.length, equals(2));
  });

  test('open and read from pendant', () {
    final devices = hidEnumerate(vendorId: 0x10CE, productId: 0xEB93);
    expect(devices, isNotEmpty, reason: 'Pendant not connected');

    // Open the first collection.
    final dev = hidOpenPath(devices.first.path);
    try {
      final info = dev.getDeviceInfo();
      print('Opened: $info');
      expect(info, isNotNull);

      // Try a short read with timeout (don't block forever).
      final data = dev.read(64, timeout: Duration(milliseconds: 100));
      print('Read ${data.length} bytes: $data');
    } finally {
      dev.close();
    }
  });
}
