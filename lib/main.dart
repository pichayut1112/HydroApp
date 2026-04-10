import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/water_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize notifications
  await NotificationService.instance.init();

  // Bootstrap provider and schedule alarm on first run
  final provider = WaterProvider();
  await provider.init();
  await NotificationService.instance.scheduleNext(provider.settings);

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const HydroApp(),
    ),
  );
}
