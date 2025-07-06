import 'package:flutter/material.dart';
import 'package:savvy/screens/Categories/models/category_model.dart';

final List<Category> globalCategories = [
    Category(id: "114ed927-ca6b-47df-bf3d-689ff3b8bbd9", name: "Food", icon: Icons.restaurant),
    Category(id: "4c056838-9227-4b3d-9fcd-ac117f5a95cb", name: "Transportation", icon: Icons.directions_car),
    Category(id: "3782b789-59fa-45b1-a214-c29e21a2f0e3", name: "Health", icon: Icons.health_and_safety),
    Category(id: "755da918-2e9e-436a-b38a-2fbad36e9c94", name: "Education", icon: Icons.school),
    Category(id: "813c1667-760d-46c2-8226-dc139cc8c86c", name: "LifeStyle", icon: Icons.emoji_people),
    Category(id: "337bf3ed-8f2e-4647-ac50-30f327316d07", name: "Fashion", icon: Icons.checkroom),
    Category(id: "5a0e2666-4ce0-4992-a3e1-fa66d8c061b9", name: "Entertainment", icon: Icons.movie),
    Category(id: 'save', name: "Savings", icon: Icons.savings, type: CategoryType.savings),
  ];
