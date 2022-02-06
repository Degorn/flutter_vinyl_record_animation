import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinyl record animation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Material(
        child: SafeArea(
          child: Center(
            child: SizedBox.square(
              dimension: 200,
              child: VinylRecord(),
            ),
          ),
        ),
      ),
    );
  }
}

class VinylRecord extends StatefulWidget {
  const VinylRecord({Key? key}) : super(key: key);

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord> with TickerProviderStateMixin {
  late final _folderHoverAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _collectionScaleAnimationController.forward();
      } else {
        _collectionScaleAnimationController.reverse();
      }
    });
  late final _hoverDiskOffsetAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.0, -0.2),
  ).animate(CurvedAnimation(
    parent: _folderHoverAnimationController,
    curve: Curves.ease,
  ));
  late final _hoverFolderOffsetAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.0, 0.05),
  ).animate(CurvedAnimation(
    parent: _folderHoverAnimationController,
    curve: Curves.ease,
  ));

  late final _collectionScaleAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final _collectionScaleAnimation = Tween<double>(
    begin: 1.0,
    end: 1.15,
  ).animate(
    CurvedAnimation(
      parent: _collectionScaleAnimationController,
      curve: Curves.easeInOutBack,
      reverseCurve: Curves.easeOutQuad,
    ),
  );

  late final _diskShowcaseAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void dispose() {
    _folderHoverAnimationController.dispose();
    _diskShowcaseAnimationController.dispose();
    _collectionScaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _folderHoverAnimationController.forward();
      },
      onExit: (_) {
        if (_diskShowcaseAnimationController.status != AnimationStatus.forward) {
          _folderHoverAnimationController.reverse();
        }
      },
      child: GestureDetector(
        onPanEnd: (details) {
          _folderHoverAnimationController.reverse();
        },
        onTapDown: (_) {
          _folderHoverAnimationController.forward();
        },
        onTapUp: (_) async {
          if (_folderHoverAnimationController.status == AnimationStatus.completed) {
            await _diskShowcaseAnimationController.forward();
          }

          _folderHoverAnimationController.reverse();
          _diskShowcaseAnimationController.reset();
        },
        child: ScaleTransition(
          scale: _collectionScaleAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SlideTransition(
                    position: _hoverDiskOffsetAnimation,
                    child: Disk(
                      animationController: _diskShowcaseAnimationController,
                      radius: constraints.biggest.shortestSide / 2,
                    ),
                  ),
                  SlideTransition(
                    position: _hoverFolderOffsetAnimation,
                    child: Folder(
                      size: constraints.biggest.shortestSide + 2,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class Disk extends StatelessWidget {
  Disk({
    Key? key,
    required AnimationController animationController,
    required double radius,
  })  : _animationController = animationController,
        _radius = radius,
        super(key: key);

  /// Relative position to which the disk moves when it flies out of the folder.
  static const _outOffset = Offset(0.0, -0.8);

  /// Number of revolutions after leaving the folder.
  static const _turns = 2.0;

  /// Basic angle of inclination of light reflections on the disk.
  static const _lightDefaultAngle = math.pi / 3;

  /// The degree of stretching of the disk when it flies out of the folder.
  static const _strechOut = 1.2;

  /// The degree of stretching of the disk when it flies into a folder.
  static const _strechIn = 1.1;

  final AnimationController _animationController;
  final double _radius;

  late final _diskRotationAnimation = Tween<double>(
    begin: 0,
    end: _turns,
  ).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.2,
        0.85,
        curve: Curves.easeInOutBack,
      ),
    ),
  );

  late final _diskOffsetAnimation = TweenSequence<Offset>([
    TweenSequenceItem(
      tween: ConstantTween(Offset.zero),
      weight: 0.05,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: Offset.zero,
        end: _outOffset,
      ).chain(CurveTween(curve: Curves.easeInOutBack)),
      weight: 0.25,
    ),
    TweenSequenceItem(
      tween: ConstantTween(_outOffset),
      weight: 0.5,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _outOffset,
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutQuint)),
      weight: 0.2,
    ),
  ]).animate(_animationController);

  late final _diskLightRotationAnimation = Tween<double>(
    begin: _lightDefaultAngle,
    end: _lightDefaultAngle + _turns,
  ).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.2,
        0.85,
        curve: Curves.easeInOutBack,
      ),
    ),
  );

  late final _diskStretchAnimation = TweenSequence<double>([
    TweenSequenceItem(
      tween: ConstantTween(1.0),
      weight: 0.05,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: _strechOut,
      ).chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: 0.15,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _strechOut,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: 0.1,
    ),
    TweenSequenceItem(
      tween: ConstantTween(1.0),
      weight: 0.5,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: _strechIn,
      ).chain(CurveTween(curve: Curves.ease)),
      weight: 0.1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _strechIn,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutQuint)),
      weight: 0.1,
    ),
  ]).animate(_animationController);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            // Slightly pull out the disk so that during the rotation there is no frame when the
            // disk completely disappears if rotated 90 degrees to the view.
            ..setEntry(3, 2, 0.001)
            ..rotateY(math.pi * _diskRotationAnimation.value)
            ..setEntry(1, 1, _diskStretchAnimation.value),
          child: FractionalTranslation(
            translation: _diskOffsetAnimation.value,
            child: CustomPaint(
              size: Size.square(_radius * 2),
              painter: DiskPainter(
                lightAngle: math.pi * _diskLightRotationAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class Folder extends StatelessWidget {
  /// Creates a square [Folder] whose height and width are specified by the [ыize] parameter.
  const Folder({
    Key? key,
    required this.size,
  }) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const FolderPainter(),
    );
  }
}

class FolderPainter extends CustomPainter {
  const FolderPainter({
    this.sewingPadding = 10.0,
    this.sewingDashesPerLine = 6,
    this.sewingDashSpace = 8.0,
  });

  /// Internal distance from the edge of the folder to sewing.
  final double sewingPadding;

  /// The number of dashes in one line of sewing.
  final int sewingDashesPerLine;

  /// Distance between sewing dashes.
  final double sewingDashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 3, 0.0),
          Offset(size.width / 1.8, size.height),
          [
            Colors.blueGrey[400]!,
            Colors.blueGrey[700]!,
          ],
        ),
    );

    final availableSpace = size.width - sewingPadding * 2;
    var spaceForDashes = (sewingDashesPerLine - 1) * sewingDashSpace;

    var dashWidth = (availableSpace - spaceForDashes) / sewingDashesPerLine;
    var startX = sewingPadding;
    var startY = sewingPadding;

    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..shader;
    const dashCapShadowSize = Size(4, 4);

    void drawHorizontalLine({
      required double dy,
    }) {
      while (startX < size.width - dashWidth) {
        canvas.drawLine(
          Offset(startX, dy),
          Offset(startX + dashWidth, dy),
          paint,
        );
        canvas.drawShadow(
          Path()..addOval(Offset(startX - 2, dy - 3) & dashCapShadowSize),
          Colors.black38,
          2,
          false,
        );
        canvas.drawShadow(
          Path()..addOval(Offset(startX + dashWidth - 2, dy - 3) & dashCapShadowSize),
          Colors.black38,
          2,
          false,
        );
        startX += dashWidth + sewingDashSpace;
      }
      startX = sewingPadding;
    }

    void drawVerticalLine({
      required double dx,
    }) {
      while (startY < size.height - dashWidth) {
        canvas.drawLine(
          Offset(dx, startY),
          Offset(dx, startY + dashWidth),
          paint,
        );
        canvas.drawShadow(
          Path()..addOval(Offset(dx - 2, startY - 2) & dashCapShadowSize),
          Colors.black38,
          2,
          false,
        );
        canvas.drawShadow(
          Path()..addOval(Offset(dx - 2, startY + dashWidth - 2) & dashCapShadowSize),
          Colors.black38,
          2,
          false,
        );
        startY += dashWidth + sewingDashSpace;
      }
      startY = sewingPadding;
    }

    drawHorizontalLine(dy: sewingPadding);
    drawHorizontalLine(dy: size.height - sewingPadding);
    drawVerticalLine(dx: sewingPadding);
    drawVerticalLine(dx: size.width - sewingPadding);
  }

  @override
  bool shouldRepaint(covariant FolderPainter oldDelegate) {
    return false;
  }
}

class DiskPainter extends CustomPainter {
  const DiskPainter({
    this.diskColor = const Color(0xFF0E3749),
    this.lightColor = const Color(0xF0EAE8BF),
    this.lightAngle = 0,
  });

  final Color diskColor;
  final Color lightColor;
  final double lightAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Disk:
    canvas.drawCircle(center, radius, Paint()..color = diskColor);

    // Light:
    void drawLightArc(
      double width,
      double height, [
      double thickness = 10,
    ]) {
      final lightOvalCenter = Offset(
        (size.width - width) / 2,
        (size.height - height) / 2,
      );
      canvas.drawOval(
        lightOvalCenter & Size(width, height),
        Paint()
          ..color = lightColor
          ..style = PaintingStyle.fill,
      );

      final diskOvalCenter = Offset(
        (size.width - width + thickness) / 2,
        (size.height - height - thickness) / 2,
      );
      canvas.drawOval(
        diskOvalCenter & Size(width - thickness, height + thickness),
        Paint()
          ..color = diskColor
          ..style = PaintingStyle.fill,
      );
    }

    canvas.save();
    rotateCanvas(canvas, center.dx, center.dy, lightAngle);
    final arcDif = size.width / 10;
    drawLightArc(size.width - arcDif, size.width - 2 * arcDif);
    drawLightArc(size.width - 2 * arcDif, size.width - 3 * arcDif);
    drawLightArc(size.width - 3 * arcDif, size.width - 4 * arcDif);
    drawLightArc(size.width - 4 * arcDif, size.width - 5 * arcDif);
    drawLightArc(size.width - 5 * arcDif, size.width - 6 * arcDif);
    canvas.restore();

    // Lines:
    const lineColor = Colors.black54;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          size.width / 2,
          [
            Colors.transparent,
            Colors.transparent,
            lineColor,
            Colors.transparent,
            Colors.transparent,
            lineColor,
            Colors.transparent,
            Colors.transparent,
            lineColor,
            Colors.transparent,
            Colors.transparent,
            lineColor,
            Colors.transparent,
            Colors.transparent,
          ],
          const [
            0.0,
            0.49,
            0.5,
            0.51,
            0.59,
            0.60,
            0.61,
            0.79,
            0.80,
            0.81,
            0.89,
            0.90,
            0.91,
            1.0,
          ],
        ),
    );

    // Label:
    canvas.drawCircle(
      center,
      radius / 2.4,
      Paint()..color = const Color(0xFFEBE9BF),
    );
    canvas.drawCircle(
      center,
      radius / 2.6,
      Paint()..color = const Color(0xFFFBAB16),
    );

    // Hole:
    canvas.drawCircle(
      center,
      radius / 22,
      Paint()..color = const Color(0xFFEAE8BF),
    );
  }

  void rotateCanvas(Canvas canvas, double cx, double cy, double radians) {
    canvas.translate(cx, cy);
    canvas.rotate(radians);
    canvas.translate(-cx, -cy);
  }

  @override
  bool shouldRepaint(covariant DiskPainter oldDelegate) {
    return oldDelegate.lightAngle != lightAngle;
  }
}
