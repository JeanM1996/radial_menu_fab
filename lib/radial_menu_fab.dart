library radial_menu_fab;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;

/**
 * 
 * A widget that displays a radial menu with a floating action button.
 * The menu is displayed when the fab is pressed.
 * The menu is dismissed when the fab is pressed again.
 * The menu is dismissed when the user clicks outside the menu.
 * Develop by [Jean Mosquera- 3A Flutter Developer](https://jeanmosquera.me/)
 * [Github]( https://github.com/JeanM1996 )
 * [Repository](https://github.com/JeanM1996/radial_menu_fab)
 * [3A Portal](https://www.tresastronautas.com/)
 */

typedef DisplayChange = void Function(bool isOpen);

class RadialMenuFab extends StatefulWidget {
  final List<Widget> children; // The menu items
  final Alignment alignment; // The alignment of the menu items
  final Color? ringColor; // The color of the ring
  final double? ringDiameter; // The diameter of the ring
  final double? ringWidth; // The width of the ring
  final double fabSize; // The size of the floating action button
  final double fabElevation; // The elevation of the floating action button
  final Color? fabColor; // The color of the floating action button
  final Color?
      fabOpenColor; // The color of the floating action button when the menu is open
  final Color?
      fabCloseColor; // The color of the floating action button when the menu is closed
  final Widget? fabChild; // The child of the floating action button
  final Widget
      fabOpenIcon; // The icon of the floating action button when the menu is open
  final Widget
      fabCloseIcon; // The icon of the floating action button when the menu is closed
  final ShapeBorder?
      fabIconBorder; // The shape of the floating action button icon
  final EdgeInsets fabMargin; // The margin of the floating action button
  final Duration animationDuration; // The duration of the animation
  final Curve animationCurve; // The curve of the animation
  final DisplayChange?
      onDisplayChange; // The callback when the menu is opened or closed

  // Constructor
  RadialMenuFab(
      {Key? key,
      this.alignment = Alignment.bottomRight,
      this.ringColor,
      this.ringDiameter,
      this.ringWidth,
      this.fabSize = 64.0,
      this.fabElevation = 8.0,
      this.fabColor,
      this.fabOpenColor,
      this.fabCloseColor,
      this.fabIconBorder,
      this.fabChild,
      this.fabOpenIcon = const Icon(Icons.menu),
      this.fabCloseIcon = const Icon(Icons.close),
      this.fabMargin = const EdgeInsets.all(16.0),
      this.animationDuration = const Duration(milliseconds: 800),
      this.animationCurve = Curves.easeInOutCirc,
      this.onDisplayChange,
      required this.children})
      : assert(children.length >= 1),
        super(key: key);
  // State
  @override
  FabCircularMenuState createState() => FabCircularMenuState();
}

// State class of the widget
class FabCircularMenuState extends State<RadialMenuFab>
    with SingleTickerProviderStateMixin {
  late double _screenWidth;
  late double _screenHeight;
  late double _marginH;
  late double _marginV;
  late double _directionX;
  late double _directionY;
  late double _translationX;
  late double _translationY;

  Color? _ringColor;
  double? _ringDiameter;
  double? _ringWidth;
  Color? _fabColor;
  Color? _fabOpenColor;
  Color? _fabCloseColor;
  late ShapeBorder _fabIconBorder;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation _scaleCurve;
  late Animation<double> _rotateAnimation;
  late Animation _rotateCurve;
  Animation<Color?>? _colorAnimation;
  late Animation _colorCurve;

  bool _isOpen = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    this._ringDiameter = widget.ringDiameter;
    _animationController =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _scaleCurve = CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.4, curve: widget.animationCurve));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_scaleCurve as Animation<double>)
      ..addListener(() {
        setState(() {});
      });

    _rotateCurve = CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: widget.animationCurve));
    _rotateAnimation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(_rotateCurve as Animation<double>)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateProps();
  }

  @override
  Widget build(BuildContext context) {
    // This makes the widget able to correctly redraw on
    // hot reload while keeping performance in production
    if (!kReleaseMode) {
      _calculateProps();
    }

    return Container(
      margin: widget.fabMargin,
      // Removes the default FAB margin
      transform: Matrix4.translationValues(8.0, 8.0, 0.0),
      child: Stack(
        alignment: widget.alignment,
        children: <Widget>[
          // Ring
          Transform(
            transform: Matrix4.translationValues(
              _translationX,
              _translationY,
              0.0,
            )..scale(_scaleAnimation.value),
            alignment: FractionalOffset.center,
            child: OverflowBox(
              maxWidth: (_ringDiameter),
              maxHeight: _ringDiameter,
              child: Container(
                width: _ringDiameter,
                height: _ringDiameter,
                child: CustomPaint(
                  painter: _RingPainter(
                    width: _ringWidth,
                    color: _ringColor,
                  ),
                  child: _scaleAnimation.value == 1.0
                      ? Transform.rotate(
                          angle: (2 * pi) *
                              _rotateAnimation.value *
                              _directionX *
                              _directionY,
                          child: Container(
                            child: Stack(
                              alignment: Alignment.center,
                              children: widget.children
                                  .asMap()
                                  .map((index, child) => MapEntry(index,
                                      _applyTransformations(child, index)))
                                  .values
                                  .toList(),
                            ),
                          ),
                        )
                      : Container(),
                ),
              ),
            ),
          ),

          // FAB
          Container(
            width: widget.fabSize,
            height: widget.fabSize,
            child: RawMaterialButton(
              fillColor: _colorAnimation!.value,
              shape: _fabIconBorder,
              elevation: widget.fabElevation,
              onPressed: () {
                if (_isAnimating) return;

                if (_isOpen) {
                  close();
                } else {
                  open();
                }
              },
              child: Center(
                child: widget.fabChild == null
                    ? (_scaleAnimation.value == 1.0
                        ? widget.fabCloseIcon
                        : widget.fabOpenIcon)
                    : widget.fabChild,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calculates the properties of the widget
  Widget _applyTransformations(Widget child, int index) {
    double angleFix = 0.0;
    if (widget.alignment.x == 0) {
      angleFix = 45.0 * _directionY.abs();
    } else if (widget.alignment.y == 0) {
      angleFix = -45.0 * _directionX.abs();
    }

    final angle =
        vector.radians(75.0 / (widget.children.length - 1) * index + angleFix);

    return Transform(
        transform: Matrix4.translationValues(
            (-(_ringDiameter! / 2) * cos(angle - .4) +
                    (_ringWidth! / 2 * cos(angle - .9))) *
                _directionX,
            (-(_ringDiameter! / 2) * sin(angle - .4) +
                    (_ringWidth! / 2 * sin(angle - .95))) *
                _directionY,
            0.0),
        alignment: FractionalOffset.center,
        child: Material(
          color: Colors.transparent,
          child: child,
        ));
  }

  // Calculates the properties of the widget
  void _calculateProps() {
    _ringColor = widget.ringColor ?? Theme.of(context).accentColor;
    _fabColor = widget.fabColor ?? Theme.of(context).primaryColor;
    _fabOpenColor = widget.fabOpenColor ?? _fabColor;
    _fabCloseColor = widget.fabCloseColor ?? _fabColor;
    _fabIconBorder = widget.fabIconBorder ?? CircleBorder();
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _ringDiameter =
        widget.ringDiameter ?? min(_screenWidth, _screenHeight) * 1.25;
    _ringWidth = widget.ringWidth ?? _ringDiameter! * 0.3;
    _marginH = (widget.fabMargin.right + widget.fabMargin.left) / 2;
    _marginV = (widget.fabMargin.top + widget.fabMargin.bottom) / 2;
    _directionX = widget.alignment.x == 0 ? 1 : 1 * widget.alignment.x.sign;
    _directionY = widget.alignment.y == 0 ? 1 : 1 * widget.alignment.y.sign;
    _translationX =
        ((_screenWidth - widget.fabSize) / 2 - _marginH) * widget.alignment.x;
    _translationY =
        ((_screenHeight - widget.fabSize) / 2 - _marginV) * widget.alignment.y;

    if (_colorAnimation == null || !kReleaseMode) {
      _colorCurve = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.0,
            0.4,
            curve: widget.animationCurve,
          ));
      _colorAnimation = ColorTween(begin: _fabCloseColor, end: _fabOpenColor)
          .animate(_colorCurve as Animation<double>)
        ..addListener(() {
          setState(() {});
        });
    }
  }

  /// Opens the floating action button
  void open() {
    _isAnimating = true;
    _animationController.forward().then((_) {
      _isAnimating = false;
      _isOpen = true;
      if (widget.onDisplayChange != null) {
        widget.onDisplayChange!(true);
      }
    });
  }

  // Closes the floating action button
  void close() {
    _isAnimating = true;
    _animationController.reverse().then((_) {
      _isAnimating = false;
      _isOpen = false;
      if (widget.onDisplayChange != null) {
        widget.onDisplayChange!(false);
      }
    });
  }

  bool get isOpen => _isOpen;
}

// The ring painter
class _RingPainter extends CustomPainter {
  final double? width;
  final Color? color;

  _RingPainter({required this.width, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width < width! ? size.width : width!;

    canvas.drawArc(
        Rect.fromLTWH(
            width! / 2, width! / 2, size.width - width!, size.height - width!),
        0.0,
        2 * pi,
        false,
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
