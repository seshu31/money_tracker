import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  // Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create a 1024x1024 canvas
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(1024, 1024);
  
  // Background gradient
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.blue.shade600,
        Colors.blue.shade800,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  
  // Draw background
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  
  // Draw a circle for the main icon
  final circlePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(
    Offset(size.width / 2, size.height / 2),
    size.width * 0.35,
    circlePaint,
  );
  
  // Draw rupee symbol
  final textPainter = TextPainter(
    text: TextSpan(
      text: '₹',
      style: TextStyle(
        color: Colors.blue.shade800,
        fontSize: size.width * 0.4,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    ),
  );
  
  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  // Save the icon
  final file = File('assets/icon/app_icon.png');
  await file.writeAsBytes(bytes);
  
  print('App icon generated successfully at assets/icon/app_icon.png');
} 