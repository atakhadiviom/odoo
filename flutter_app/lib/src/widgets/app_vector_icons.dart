import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppVectorIcon extends StatelessWidget {
  const AppVectorIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.selected = false,
    this.color,
  });

  final String name;
  final double size;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AppVectorIconPainter(
          name: name,
          selected: selected,
          color: resolvedColor,
        ),
      ),
    );
  }
}

class AppStarIcon extends StatelessWidget {
  const AppStarIcon({
    super.key,
    this.size = 20,
    this.filled = true,
    this.color = const Color(0xFFF5A623),
  });

  final double size;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StarPainter(color: color, filled: filled),
      ),
    );
  }
}

class _AppVectorIconPainter extends CustomPainter {
  const _AppVectorIconPainter({
    required this.name,
    required this.selected,
    required this.color,
  });

  final String name;
  final bool selected;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.7 : 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (name.toLowerCase()) {
      case 'back':
      case 'arrow_back':
      case 'arrow-back':
        _drawBack(canvas, size, stroke);
        break;
      case 'shop':
      case 'storefront':
      case 'shopping_bag':
      case 'shopping-bag':
        _drawStorefront(canvas, size, stroke, fill);
        break;
      case 'cart':
      case 'bag':
      case 'shopping_cart':
      case 'shopping-cart':
        _drawCart(canvas, size, stroke, fill);
        break;
      case 'account':
      case 'person':
        _drawPerson(canvas, size, stroke, fill);
        break;
      case 'brands':
      case 'brand':
        _drawTag(canvas, size, stroke, fill);
        break;
      case 'scan':
      case 'barcode':
      case 'qr_code_scanner':
      case 'qr-code-scanner':
        _drawScan(canvas, size, stroke);
        break;
      case 'wishlist':
      case 'heart':
        _drawHeart(canvas, size, stroke, fill);
        break;
      case 'search':
        _drawSearch(canvas, size, stroke);
        break;
      case 'review':
      case 'rate_review':
      case 'rate-review':
      case 'pencil':
        _drawReview(canvas, size, stroke);
        break;
      case 'share':
        _drawShare(canvas, size, stroke, fill);
        break;
      case 'logout':
      case 'sign_out':
      case 'sign-out':
        _drawLogout(canvas, size, stroke);
        break;
      case 'refresh':
      case 'sync':
        _drawRefresh(canvas, size, stroke);
        break;
      case 'bell':
      case 'notifications':
        _drawBell(canvas, size, stroke, fill);
        break;
      case 'check':
      case 'done':
        _drawCheck(canvas, size, stroke);
        break;
      case 'home':
      default:
        _drawHome(canvas, size, stroke, fill);
        break;
    }
  }

  void _drawBack(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * .78, h * .50), Offset(w * .24, h * .50), stroke);
    canvas.drawLine(Offset(w * .24, h * .50), Offset(w * .46, h * .28), stroke);
    canvas.drawLine(Offset(w * .24, h * .50), Offset(w * .46, h * .72), stroke);
  }

  void _drawHome(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final house = Path()
      ..moveTo(w * .16, h * .48)
      ..lineTo(w * .50, h * .18)
      ..lineTo(w * .84, h * .48)
      ..lineTo(w * .75, h * .48)
      ..lineTo(w * .75, h * .82)
      ..lineTo(w * .25, h * .82)
      ..lineTo(w * .25, h * .48)
      ..close();
    selected ? canvas.drawPath(house, fill) : canvas.drawPath(house, stroke);
    if (!selected) {
      canvas.drawLine(
          Offset(w * .43, h * .82), Offset(w * .43, h * .62), stroke);
      canvas.drawLine(
          Offset(w * .57, h * .82), Offset(w * .57, h * .62), stroke);
      canvas.drawLine(
          Offset(w * .43, h * .62), Offset(w * .57, h * .62), stroke);
    }
  }

  void _drawStorefront(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final roof = Path()
      ..moveTo(w * .20, h * .22)
      ..lineTo(w * .80, h * .22)
      ..lineTo(w * .88, h * .42)
      ..lineTo(w * .12, h * .42)
      ..close();
    selected ? canvas.drawPath(roof, fill) : canvas.drawPath(roof, stroke);
    canvas.drawLine(Offset(w * .20, h * .42), Offset(w * .20, h * .82), stroke);
    canvas.drawLine(Offset(w * .80, h * .42), Offset(w * .80, h * .82), stroke);
    canvas.drawLine(Offset(w * .18, h * .82), Offset(w * .82, h * .82), stroke);
    canvas.drawLine(Offset(w * .50, h * .42), Offset(w * .50, h * .82), stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .30, h * .56, w * .14, h * .26),
        Radius.circular(w * .025),
      ),
      selected ? (Paint()..color = Colors.white.withOpacity(.7)) : stroke,
    );
    for (final x in <double>[.30, .42, .54, .66]) {
      canvas.drawLine(
          Offset(w * x, h * .24), Offset(w * (x - .04), h * .42), stroke);
    }
  }

  void _drawCart(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * .12, h * .26), Offset(w * .24, h * .26), stroke);
    final basket = Path()
      ..moveTo(w * .24, h * .26)
      ..lineTo(w * .32, h * .62)
      ..quadraticBezierTo(w * .34, h * .68, w * .42, h * .68)
      ..lineTo(w * .76, h * .68)
      ..quadraticBezierTo(w * .82, h * .68, w * .84, h * .62)
      ..lineTo(w * .90, h * .38)
      ..lineTo(w * .30, h * .38);
    canvas.drawPath(basket, stroke);
    canvas.drawLine(Offset(w * .40, h * .44), Offset(w * .42, h * .61), stroke);
    canvas.drawLine(Offset(w * .57, h * .44), Offset(w * .57, h * .61), stroke);
    canvas.drawLine(Offset(w * .74, h * .44), Offset(w * .70, h * .61), stroke);
    canvas.drawCircle(
        Offset(w * .42, h * .82), w * .055, selected ? fill : stroke);
    canvas.drawCircle(
        Offset(w * .74, h * .82), w * .055, selected ? fill : stroke);
  }

  void _drawPerson(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
        Offset(w * .5, h * .31), w * .15, selected ? fill : stroke);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .24, h * .56, w * .52, h * .28),
      Radius.circular(w * .18),
    );
    selected ? canvas.drawRRect(body, fill) : canvas.drawRRect(body, stroke);
  }

  void _drawTag(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * .22, h * .28)
      ..lineTo(w * .58, h * .20)
      ..lineTo(w * .82, h * .44)
      ..lineTo(w * .48, h * .78)
      ..lineTo(w * .22, h * .52)
      ..close();
    selected ? canvas.drawPath(path, fill) : canvas.drawPath(path, stroke);
    final dotPaint = selected ? (Paint()..color = Colors.white) : stroke;
    canvas.drawCircle(Offset(w * .55, h * .36), w * .045, dotPaint);
  }

  void _drawScan(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    for (final rect in <Rect>[
      Rect.fromLTWH(w * .18, h * .18, w * .22, h * .22),
      Rect.fromLTWH(w * .60, h * .18, w * .22, h * .22),
      Rect.fromLTWH(w * .18, h * .60, w * .22, h * .22),
      Rect.fromLTWH(w * .60, h * .60, w * .22, h * .22),
    ]) {
      canvas.drawLine(
          rect.topLeft, Offset(rect.left + rect.width, rect.top), stroke);
      canvas.drawLine(
          rect.topLeft, Offset(rect.left, rect.top + rect.height), stroke);
    }
    canvas.drawLine(Offset(w * .28, h * .50), Offset(w * .72, h * .50), stroke);
  }

  void _drawHeart(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * .50, h * .80)
      ..cubicTo(w * .12, h * .55, w * .12, h * .26, w * .36, h * .25)
      ..cubicTo(w * .47, h * .25, w * .50, h * .34, w * .50, h * .34)
      ..cubicTo(w * .50, h * .34, w * .53, h * .25, w * .64, h * .25)
      ..cubicTo(w * .88, h * .26, w * .88, h * .55, w * .50, h * .80)
      ..close();
    selected ? canvas.drawPath(path, fill) : canvas.drawPath(path, stroke);
  }

  void _drawSearch(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * .43, h * .43), w * .22, stroke);
    canvas.drawLine(Offset(w * .60, h * .60), Offset(w * .80, h * .80), stroke);
  }

  void _drawReview(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .15, h * .20, w * .70, h * .48),
      Radius.circular(w * .12),
    );
    canvas.drawRRect(bubble, stroke);
    final tail = Path()
      ..moveTo(w * .34, h * .68)
      ..lineTo(w * .27, h * .82)
      ..lineTo(w * .48, h * .68);
    canvas.drawPath(tail, stroke);
    canvas.drawLine(Offset(w * .34, h * .40), Offset(w * .66, h * .40), stroke);
    canvas.drawLine(Offset(w * .34, h * .53), Offset(w * .56, h * .53), stroke);
  }

  void _drawShare(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final points = <Offset>[
      Offset(w * .28, h * .52),
      Offset(w * .66, h * .28),
      Offset(w * .68, h * .74),
    ];
    canvas.drawLine(points[0], points[1], stroke);
    canvas.drawLine(points[0], points[2], stroke);
    for (final point in points) {
      canvas.drawCircle(point, w * .08, selected ? fill : stroke);
    }
  }

  void _drawLogout(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .18, w * .40, h * .64),
        Radius.circular(w * .06),
      ),
      stroke,
    );
    canvas.drawLine(Offset(w * .42, h * .50), Offset(w * .84, h * .50), stroke);
    canvas.drawLine(Offset(w * .68, h * .34), Offset(w * .84, h * .50), stroke);
    canvas.drawLine(Offset(w * .68, h * .66), Offset(w * .84, h * .50), stroke);
  }

  void _drawRefresh(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(w * .22, h * .22, w * .56, h * .56);
    canvas.drawArc(rect, math.pi * .15, math.pi * 1.28, false, stroke);
    canvas.drawArc(rect, math.pi * 1.25, math.pi * 1.25, false, stroke);
    canvas.drawLine(Offset(w * .73, h * .24), Offset(w * .78, h * .43), stroke);
    canvas.drawLine(Offset(w * .73, h * .24), Offset(w * .55, h * .30), stroke);
    canvas.drawLine(Offset(w * .27, h * .76), Offset(w * .22, h * .57), stroke);
    canvas.drawLine(Offset(w * .27, h * .76), Offset(w * .45, h * .70), stroke);
  }

  void _drawBell(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final bell = Path()
      ..moveTo(w * .28, h * .70)
      ..quadraticBezierTo(w * .34, h * .58, w * .34, h * .42)
      ..cubicTo(w * .34, h * .24, w * .66, h * .24, w * .66, h * .42)
      ..quadraticBezierTo(w * .66, h * .58, w * .72, h * .70)
      ..close();
    selected ? canvas.drawPath(bell, fill) : canvas.drawPath(bell, stroke);
    canvas.drawLine(Offset(w * .24, h * .70), Offset(w * .76, h * .70), stroke);
    canvas.drawLine(Offset(w * .45, h * .23), Offset(w * .55, h * .23), stroke);
    canvas.drawArc(
      Rect.fromLTWH(w * .42, h * .68, w * .16, h * .14),
      0,
      math.pi,
      false,
      stroke,
    );
  }

  void _drawCheck(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * .22, h * .52), Offset(w * .42, h * .72), stroke);
    canvas.drawLine(Offset(w * .42, h * .72), Offset(w * .80, h * .28), stroke);
  }

  @override
  bool shouldRepaint(covariant _AppVectorIconPainter oldDelegate) {
    return name != oldDelegate.name ||
        selected != oldDelegate.selected ||
        color != oldDelegate.color;
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide * .46;
    final inner = outer * .45;
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    filled ? canvas.drawPath(path, fill) : canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return color != oldDelegate.color || filled != oldDelegate.filled;
  }
}
