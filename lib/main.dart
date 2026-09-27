import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/enviro_sense_app.dart';

void main() {
  runApp(const ProviderScope(child: EnviroSenseApp()));
}
