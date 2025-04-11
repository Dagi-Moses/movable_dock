import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Entrypoint of the moving dock application .
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e, scale) {
              final tooltipText = _iconDescriptions[e];

              return Tooltip(
                message: tooltipText,
                textAlign: TextAlign.start,
                waitDuration: _kTooltipWaitDuration,
                showDuration: _kTooltipShowDuration,
                verticalOffset: _kTooltipVerticalOffset,

                preferBelow: false,
                child: Container(
                  constraints: const BoxConstraints(minWidth: _kIconMinSize),
                  height: _kIconMinSize,
                  margin: const EdgeInsets.all(_kDefaultBorderRadius),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
                    color:
                        Colors.primaries[e.hashCode % Colors.primaries.length],
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(e, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Provides a label for each icon in the Dock.
Map<IconData, String> _iconDescriptions = {
  Icons.person: 'Profile',
  Icons.message: 'Messages',
  Icons.call: 'Phone',
  Icons.camera: 'Camera',
  Icons.photo: 'Gallery',
};

/// The minimum size for dock icons.
const double _kIconMinSize = 48;

/// The maximum size of dock icons when fully hovered.
const double _kIconMaxSize = 55;

/// The base unhovered icon size.
const double _kIconBaseSize = 52;

/// The size divider used to scale the icon visually.
const double _kIconScaleDivider = 68;

/// The scale factor for drag feedback.
const double _kDragFeedbackScale = 0.9;

/// The icons tooltip vertical offset in pixels.
const double _kTooltipVerticalOffset = 35;

/// The margin offset when dragging the dock items.
const double _kMarginOffset = 30;

/// The icons tooltip wait duration before appearing.
const Duration _kTooltipWaitDuration = Duration(milliseconds: 500);

/// The icons tooltip visible duration.
const Duration _kTooltipShowDuration = Duration(seconds: 2);

/// The dock container's padding.
const double _kDockPadding = 4.0;

/// The default border radius for dock elements.
const double _kDefaultBorderRadius = 8.0;

/// The hover max vertical translation.
const double _kMaxVerticalTranslate = -11;

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({super.key, this.items = const [], required this.builder});

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T, double scale) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// The currently hovered item's index.
  int? _hoveredIndex;

  /// The currently dragged/touched item's index.
  int? _draggedIndex;

  /// Calculates scale or offset values based on distance from the hovered item.
  double calculateValue({
    required int index,
    required double initialValue,
    required double maxValue,
  }) {
    late final double finalValue;
    if (_hoveredIndex == null) {
      return initialValue;
    }
    final distance = (_hoveredIndex! - index).abs();
    double effectFactor = math.exp(-distance);
    finalValue = lerpDouble(initialValue, maxValue, effectFactor)!;

    return finalValue;
  }

  /// Calculates margin values for the items.
  double computeEdgeMargin(int index) {
    if (index != _items.length - 1) return _kIconScaleDivider;

    final double dragProximityFactor = 0.2;
    return lerpDouble(_kIconScaleDivider, _kMarginOffset, dragProximityFactor)!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(_kDockPadding),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final double verticalTranslation = calculateValue(
                index: index,
                initialValue: 0,
                maxValue: _kMaxVerticalTranslate,
              );
              final calculatedSize = calculateValue(
                index: index,
                initialValue: _kIconBaseSize,
                maxValue: _kIconMaxSize,
              );

              Matrix4 transform =
                  Matrix4.identity()..translate(0.0, verticalTranslation, 0.0);

              return DragTarget<T>(
                onAcceptWithDetails: (droppedItem) {
                  setState(() {
                    final draggedIndex = _items.indexOf(droppedItem.data);
                    if (draggedIndex != -1) {
                      _items.removeAt(draggedIndex);
                      _items.insert(index, droppedItem.data);
                    }
                    _draggedIndex = null;
                    _hoveredIndex = null;
                  });
                },
                onWillAcceptWithDetails: (droppedItem) {
                  final draggedIndex = _items.indexOf(droppedItem.data);
                  setState(() {
                    _hoveredIndex = index;
                    _draggedIndex = draggedIndex;
                  });
                  return true;
                },
                onLeave: (_) {
                  setState(() {
                    _hoveredIndex = null;
                    _draggedIndex = null;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Draggable<T>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: _kDragFeedbackScale,
                        child: widget.builder(item, calculatedSize / 70),
                      ),
                    ),
                    childWhenDragging: const PlaceholderWidget(),
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _hoveredIndex = index;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _hoveredIndex = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Durations.short3,
                        curve: Curves.easeInOut,
                        transform: transform,
                        margin:
                            _draggedIndex != null && _hoveredIndex == index
                                ? EdgeInsets.only(
                                  left: computeEdgeMargin(index),
                                )
                                : EdgeInsets.zero,

                        constraints: BoxConstraints(
                          minWidth: _kIconMinSize,
                          maxWidth: calculatedSize,
                          maxHeight: _kIconMaxSize,
                        ),
                        child: widget.builder(
                          item,
                          calculatedSize / _kIconScaleDivider,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }
}

/// Placeholder [Widget] for the dock items when dragged,
class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Durations.medium2,
      curve: Curves.easeOut,
      tween: Tween<double>(begin: _kIconMinSize, end: 0),
      builder: (BuildContext context, double value, Widget? child) {
        return SizedBox(width: value, height: value);
      },
    );
  }
}
