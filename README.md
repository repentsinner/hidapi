# hidapi

Dart FFI bindings for [hidapi](https://github.com/libusb/hidapi) — the
cross-platform C library for USB and Bluetooth HID device access.

Compiles hidapi 0.15.0 from source at build time via
[Dart build hooks](https://dart.dev/interop/c-interop). No system-level
hidapi installation required.

## Why this package?

- **Pure Dart.** No Flutter dependency. Works in CLI tools, servers, and
  any Dart application.
- **Modern build.** Uses Dart 3.10 native build hooks to compile hidapi
  from vendored source. No manual toolchain setup beyond a C compiler.
- **Complete API.** Wraps every public hidapi function — enumerate, open,
  read/write, feature and input reports, report descriptors, string
  queries, device info, and version introspection.

## Platform support

| Platform | Backend          |
|----------|------------------|
| Windows  | `windows/hid.c`  |
| macOS    | `mac/hid.c`      |
| Linux    | `linux/hid.c`    |

## Requirements

- Dart SDK >=3.10.0
- A C toolchain (MSVC, Clang, or GCC) reachable by `native_toolchain_c`
- Linux: `libudev-dev` (or equivalent)

## Install

```
dart pub add hidapi
```

## Usage

```dart
import 'package:hidapi/hidapi.dart';

void main() {
  hidInit();
  try {
    // List all HID devices (0, 0 = match any VID/PID)
    final devices = hidEnumerate();
    for (final d in devices) {
      print('${d.manufacturer} ${d.product} — ${d.path}');
    }

    // Open a specific device by path
    if (devices.isNotEmpty) {
      final dev = hidOpenPath(devices.first.path);
      try {
        dev.setNonBlocking(true);
        final data = dev.read(64, timeout: Duration(milliseconds: 100));
        print('Read ${data.length} bytes');
      } finally {
        dev.close();
      }
    }
  } finally {
    hidExit();
  }
}
```

## API

### Top-level functions

| Function | Description |
|----------|-------------|
| `hidInit()` | Initialize hidapi. Auto-called by `hidEnumerate`/`hidOpenPath` if needed. |
| `hidExit()` | Free hidapi resources. |
| `hidEnumerate({vendorId, productId})` | List connected HID devices. Pass 0 to match all. |
| `hidOpen(vendorId, productId, {serialNumber})` | Open a device by VID/PID. Returns `HidDevice`. |
| `hidOpenPath(path)` | Open a device by its platform path. Returns `HidDevice`. |
| `hidVersion()` | hidapi version as `({int major, int minor, int patch})`. |
| `hidVersionStr()` | hidapi version as `String`. |

### HidDevice

| Method | Description |
|--------|-------------|
| `read(maxLength, {timeout})` | Read up to N bytes. Returns `Uint8List`. |
| `write(data)` | Write bytes. First byte = report ID (0x00 for single-report devices). |
| `sendFeatureReport(data)` | Send a feature report. |
| `getFeatureReport(reportId, maxLength)` | Get a feature report. |
| `getInputReport(reportId, maxLength)` | Get an input report. |
| `getReportDescriptor(maxLength)` | Get the raw HID report descriptor. |
| `getManufacturerString()` | Get the manufacturer string. |
| `getProductString()` | Get the product string. |
| `getSerialNumberString()` | Get the serial number string. |
| `getIndexedString(index)` | Get a string by USB string index. |
| `setNonBlocking(bool)` | Toggle blocking/non-blocking reads. |
| `getDeviceInfo()` | Metadata for the open device. |
| `close()` | Release the device handle. |

### HidDeviceInfo

Returned by `hidEnumerate()` and `HidDevice.getDeviceInfo()`. Fields:
`path`, `vendorId`, `productId`, `serialNumber`, `releaseNumber`,
`manufacturer`, `product`, `usagePage`, `usage`, `interfaceNumber`,
`busType`.

### HidBusType

Enum: `unknown`, `usb`, `bluetooth`, `i2c`, `spi`.

## How the build works

The Dart build hook (`hook/build.dart`) downloads a pinned, SHA-256-verified
tarball of hidapi 0.15.0 on first build. Subsequent builds use the cached
source. The C code compiles via `native_toolchain_c` — no manual steps.

## Upstream

- hidapi: [libusb/hidapi](https://github.com/libusb/hidapi)
- Maintainer: originally [signal11](https://github.com/signal11/hidapi),
  now under [libusb](https://github.com/libusb) org

## License

See [LICENSE](LICENSE).
