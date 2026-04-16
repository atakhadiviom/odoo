import 'package:flutter/material.dart';

Color? parseHexColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) return null;

  String hex = hexString.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }

  if (hex.length == 8) {
    return Color(int.parse(hex, radix: 16));
  }

  return null;
}
