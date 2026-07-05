import 'package:flutter/material.dart';
import 'app_router.dart';
import 'design/spazz_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Spazz',
      debugShowCheckedModeBanner: false,
      theme: SpazzTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
