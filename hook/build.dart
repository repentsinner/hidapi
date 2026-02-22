import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final targetOS = input.config.code.targetOS;

    final builder = CBuilder.library(
      name: 'hidapi',
      assetName: 'src/hidapi_bindings.g.dart',
      sources: [
        if (targetOS == OS.windows) 'src/hidapi/windows/hid.c',
        if (targetOS == OS.macOS) 'src/hidapi/mac/hid.c',
        if (targetOS == OS.linux) 'src/hidapi/linux/hid.c',
      ],
      includes: ['src/hidapi/hidapi'],
      frameworks: [
        if (targetOS == OS.macOS) 'IOKit',
        if (targetOS == OS.macOS) 'CoreFoundation',
        if (targetOS == OS.macOS) 'AppKit',
      ],
      libraries: [if (targetOS == OS.linux) 'udev'],
      defines: {},
    );

    await builder.run(input: input, output: output);
  });
}
