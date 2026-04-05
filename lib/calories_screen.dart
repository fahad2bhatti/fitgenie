import 'package:flutter/material.dart';

class CaloriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Calories Tracker")),
      body: Center(
        child: Text("Calories Tracker Screen", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
