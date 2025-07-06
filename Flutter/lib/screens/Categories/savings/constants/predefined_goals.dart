import 'package:flutter/material.dart';
import '../../models/goal_model.dart';
//"template" list.
// Goals are predefined templates, but each user customizes their target/savings.
final List<Goal> predefinedGoals = [
    Goal(name: "Travel", goalIcon: Icons.flight, targetAmount: 0),
    Goal(name: "House", goalIcon: Icons.house, targetAmount: 0),
    Goal(name: "Vehicle", goalIcon: Icons.directions_car, targetAmount: 0),
    Goal(name: "Wedding", goalIcon: Icons.favorite_outline_rounded, targetAmount: 0),
    Goal(name: "Emergency", goalIcon: Icons.medical_services,targetAmount: 0),
    Goal(name: "Mobile", goalIcon: Icons.phone_android, targetAmount: 0),
    //Goal(name: "Investment", goalIcon: Icons.show_chart_sharp, targetAmount: 0),
  ];