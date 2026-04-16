import 'package:flutter/material.dart';

String formatMoney(String currency, double amount) {
  return '$currency ${amount.toStringAsFixed(2)}';
}

IconData iconForName(String value, {required bool outlined}) {
  switch (value) {
    case 'shop':
    case 'storefront':
      return outlined ? Icons.storefront_outlined : Icons.storefront;
    case 'cart':
    case 'bag':
      return outlined ? Icons.shopping_bag_outlined : Icons.shopping_bag;
    case 'brands':
    case 'brand':
      return outlined ? Icons.sell_outlined : Icons.sell;
    case 'scan':
    case 'barcode':
      return outlined ? Icons.qr_code_scanner_outlined : Icons.qr_code_scanner;
    case 'wishlist':
    case 'heart':
      return outlined ? Icons.favorite_border : Icons.favorite;
    case 'account':
    case 'person':
      return outlined ? Icons.person_outline : Icons.person;
    case 'home':
    default:
      return outlined ? Icons.home_outlined : Icons.home;
  }
}
