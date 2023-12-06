import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'package:pulse_oximter/core/utils/media_query_values.dart';

class CustomCircularProgressIndicator extends StatefulWidget {
  final double progressValue;
  final double oldValue;
  final double MAX;
  final double MIN;
  final String title;
  final Color primaryColor;

  const CustomCircularProgressIndicator({
    Key? key,
    required this.progressValue,
    required this.oldValue,
    required this.MAX,
    required this.MIN,
    required this.title,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<CustomCircularProgressIndicator> createState() =>
      _CustomCircularProgressIndicatorState();
}

class _CustomCircularProgressIndicatorState
    extends State<CustomCircularProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(
      begin: widget.oldValue,
      end: widget.progressValue,
    ).animate(_animationController);
  }

  @override
  void didUpdateWidget(CustomCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progressValue != oldWidget.progressValue) {
      _reverseAnimation();
    }
  }

  void _reverseAnimation() {
    _progressAnimation = Tween<double>(
      begin: widget.oldValue,
      end: widget.progressValue,
    ).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          PositionedDirectional(
            top: context.height * .1,
            start: 0,
            child: Text(
              widget.title,
              style: style.copyWith(
                fontSize: 14.0,
              ),
            ),
          ),
          SfRadialGauge(
            enableLoadingAnimation: true,
            axes: <RadialAxis>[
              RadialAxis(
                minimum: widget.MIN,
                maximum: widget.MAX,
                showLabels: false,
                showTicks: false,
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    positionFactor: 0.1,
                    angle: 90,
                    widget: Text(
                      _progressAnimation.value.toStringAsFixed(1),
                      style: style.copyWith(fontSize: 20.0),
                    ),
                  ),
                  GaugeAnnotation(
                    positionFactor: 0.99,
                    angle: 122,
                    widget: Text(
                      "${widget.MIN.toInt()}",
                      style: style,
                    ),
                  ),
                  GaugeAnnotation(
                    positionFactor: 0.99,
                    angle: 65,
                    widget: Text(
                      "${widget.MAX.toInt()}",
                      style: style,
                    ),
                  )
                ],
                pointers: <GaugePointer>[
                  RangePointer(
                    value: _progressAnimation.value,
                    cornerStyle: CornerStyle.bothCurve,
                    color: widget.primaryColor,
                    width: 0.2,
                    sizeUnit: GaugeSizeUnit.factor,
                  )
                ],
                axisLineStyle: const AxisLineStyle(
                  thickness: 0.2,
                  cornerStyle: CornerStyle.bothCurve,
                  color: Color.fromARGB(30, 0, 169, 181),
                  thicknessUnit: GaugeSizeUnit.factor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
