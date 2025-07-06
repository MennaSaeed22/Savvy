import 'package:flutter/material.dart';
import 'package:savvy/screens/Categories/models/goal_model.dart';
import '../../../globals.dart';

class GoalProgressRing extends StatelessWidget {
  final Goal goal;
  final double size;
  final double strokeWidth;
  final bool showPercentage;
  const GoalProgressRing({
    Key? key,
    required this.goal,
    this.size = 100.0,
    this.strokeWidth = 8.0,
    this.showPercentage = true,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount == 0
        ? 0.0
        : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
// Outer progress ring (full circle background)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: Colors.grey.shade200,
              backgroundColor: Colors.transparent,
            ),
          ),
// Outer progress ring (actual progress)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              color: _getProgressColor(progress),
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
// Goal icon circle
          Container(
            width: size - strokeWidth * 2,
            height: size - strokeWidth * 2,
            decoration: BoxDecoration(
              color: softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              goal.goalIcon ?? Icons.flag,
              color: primaryColor,
              size: size / 3,
            ),
          ),
// Percentage text (optional)
          if (showPercentage)
            Positioned(
              bottom: size * 0.1,
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(progress),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return primaryColor;
    if (progress < 0.7) return primaryColor.withOpacity(0.7);
    return Colors.green;
  }
}
