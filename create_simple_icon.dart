import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create a simple 1024x1024 icon
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(1024, 1024);
  
  // Blue background
  final backgroundPaint = Paint()..color = Colors.blue.shade600;
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  
  // White circle
  final circlePaint = Paint()..color = Colors.white;
  canvas.drawCircle(
    Offset(size.width / 2, size.height / 2),
    size.width * 0.3,
    circlePaint,
  );
  
  // Rupee symbol
  final textPainter = TextPainter(
    text: TextSpan(
      text: '₹',
      style: TextStyle(
        color: Colors.blue.shade800,
        fontSize: size.width * 0.3,
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
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  final file = File('assets/icon/app_icon.png');
  await file.writeAsBytes(bytes);
  
  print('✅ App icon created successfully!');
  print('📁 Location: assets/icon/app_icon.png');
  print('🔄 Now run: flutter pub run flutter_launcher_icons:main');
} 