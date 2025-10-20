import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'models/survey_map_model.dart';

void main() {
  runApp(const SurveyMapApp());
}

class SurveyMapApp extends StatelessWidget {
  const SurveyMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SurveyMapModel(),
      child: MaterialApp(
        title: 'SurveyMap',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context),
            child: child!,
          );
        },
      ),
    );
  }
}
