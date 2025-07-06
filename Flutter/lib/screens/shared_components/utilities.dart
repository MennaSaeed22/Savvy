// import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:savvy/screens/globals.dart';

// Widget buildCategoryItem({
//   String  ?categoryName,
// })=>Container(
//   child: Column(
//     children: [
//       Card(
//         : BoxDecoration(
//           color: softBlue,
//           borderRadius: BorderRadius.circular(20),
//         ),

//         child: Image.asset("assets\\icons\\categories_icons\\food.png"),

//         ),
//       ),
//     ],
//   ),
// );
Widget buildCategoryItem({
  required String text,
  required IconData icon,
  //required bool animationStyle,
}) =>
    Container(
      child: Column(
        children: [
          Card(
              elevation: 12,
              child: Container(
                width: 200,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: softBlue,
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
Widget buildCategoryItem2({
  required VoidCallback onTap,
  required String text,
  required IconData icon,
}) =>
    InkWell(
      onTap: onTap,
      hoverColor: Colors.blue,
      child: Container(
        color: Colors.yellow,
        height: 100,
        child: Column(
          children: [
            Card(
              
              child: Icon(icon),
              elevation: 15,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            )
          ],
        ),
      ),
    );
