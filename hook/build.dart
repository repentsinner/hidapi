import 'dart:io';

import 'package:archive/archive.dart';
import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Use master branch to get the latest device monitoring API
/// that has not been released in a stable tag yet.
const _version = 'master';
const _tarballUrl =
    'https://github.com/libusb/hidapi/archive/refs/heads/$_version.tar.gz';
// SHA-256 will vary since master changes, we skip hash check
const String? _expectedSha256 = null;

/// Directory name inside the tarball (GitHub's archive prefix).
const _extractedDir = 'hidapi-$_version';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final cacheDir = input.outputDirectoryShared;
    final sourceDir = cacheDir.resolve(_extractedDir);
    final tarballFile = File.fromUri(cacheDir.resolve('$_version.tar.gz'));

    await _ensureSource(tarballFile, sourceDir);

    final sourcePath = sourceDir.toFilePath();
    final targetOS = input.config.code.targetOS;

    final builder = CBuilder.library(
      name: 'hidapi',
      assetName: 'src/hidapi_bindings.g.dart',
      sources: [
        if (targetOS == OS.windows) '$sourcePath/windows/hid.c',
        if (targetOS == OS.macOS) '$sourcePath/mac/hid.c',
        if (targetOS == OS.linux) '$sourcePath/linux/hid.c',
      ],
      includes: ['$sourcePath/hidapi'],
      // native_toolchain_c only passes -framework flags when
      // language is set to objectiveC — plain C silently drops them.
      language: targetOS == OS.macOS ? Language.objectiveC : Language.c,
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

/// Download and extract the hidapi source if not already cached.
Future<void> _ensureSource(File tarball, Uri sourceDir) async {
  final dir = Directory.fromUri(sourceDir);
  if (dir.existsSync()) return;

  if (!tarball.existsSync()) {
    await _download(tarball);
  }

  _verifyHash(tarball);
  _extract(tarball, dir.parent);
}

/// Download the tarball from GitHub.
Future<void> _download(File destination) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(_tarballUrl));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download $_tarballUrl: HTTP ${response.statusCode}',
      );
    }
    final sink = destination.openWrite();
    await response.pipe(sink);
  } finally {
    client.close();
  }
}

/// Verify the SHA-256 hash of the downloaded tarball.
void _verifyHash(File tarball) {
  if (_expectedSha256 == null) {
    // Skip hash verification when using master branch
    return;
  }
  final bytes = tarball.readAsBytesSync();
  final digest = sha256.convert(bytes);
  if (digest.toString() != _expectedSha256) {
    tarball.deleteSync();
    throw Exception(
      'SHA-256 mismatch for ${tarball.path}:\n'
      '  expected: $_expectedSha256\n'
      '  got:      $digest',
    );
  }
}

/// Extract the tar.gz archive into [outputDir].
void _extract(File tarball, Directory outputDir) {
  final bytes = tarball.readAsBytesSync();
  final archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));

  for (final file in archive) {
    final path = '${outputDir.path}/${file.name}';
    if (file.isFile) {
      final outFile = File(path);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(path).createSync(recursive: true);
    }
  }
}
