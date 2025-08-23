import 'package:flutter/material.dart';
import 'package:get/get.dart';


TextStyle get style => TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 35,
 color: Get.isDarkMode ? Colors.white : Colors.black,
);

TextStyle get btnStyle => TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 21,
 color: Get.isDarkMode ? Colors.white : Colors.black,
);

TextStyle get boldstyle => TextStyle(
 fontSize: 14,
 color: Get.isDarkMode ? Colors.white : Colors.black,
);

TextStyle get maxWeightStyle => TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 15,
 color: Get.isDarkMode ? Colors.white : Colors.black,
);

TextStyle get boldStyle => TextStyle(
 fontSize: 24,
 fontWeight: FontWeight.bold,
 color: Get.isDarkMode ? Colors.white : Colors.black,
);

TextStyle get greyStyle => TextStyle(
 color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[900],
 fontSize: 14,
);

TextStyle get headingTextStyle => TextStyle(
 fontSize: 20,
 color: Get.isDarkMode ? Colors.white : Colors.black,
);