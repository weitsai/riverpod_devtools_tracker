import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/riverpod_devtools_extension.dart';

void main() {
  runApp(const RiverpodDevToolsExtensionApp());
}

class RiverpodDevToolsExtensionApp extends StatelessWidget {
  const RiverpodDevToolsExtensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: RiverpodDevToolsExtension(),
    );
  }
}




