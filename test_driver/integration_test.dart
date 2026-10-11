import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Salva os prints tirados pelo teste em build/prints/.
Future<void> main() => integrationDriver(
      onScreenshot: (nome, bytes, [args]) async {
        final f = File('build/prints/$nome.png');
        await f.create(recursive: true);
        await f.writeAsBytes(bytes);
        return true;
      },
    );
