import 'package:flutter/material.dart';

/// The BladeWatch companion: reach the car from a phone or desktop, over Pear from anywhere or
/// directly over the LAN when on the same network (epic BladeWatch-rdtj).
///
/// A scaffold (BladeWatch-rdtj.10). The transport lands in BladeWatch-rdtj.8, pairing and the
/// screens in BladeWatch-rdtj.11.
void main() => runApp(const CompanionApp());

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BladeWatch',
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const Scaffold(
        body: Center(child: Text('Pair with your car to get started.')),
      ),
    );
  }
}
