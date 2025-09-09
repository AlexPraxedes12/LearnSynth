import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';

class ContextualAssociationScreen extends StatefulWidget {
  const ContextualAssociationScreen({super.key});

  @override
  State<ContextualAssociationScreen> createState() => _ContextualAssociationScreenState();
}

class _ContextualAssociationScreenState extends State<ContextualAssociationScreen> {
  late final ContentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.startStudySession('concept');
      _provider.updateMethodProgress('concept', 1.0);
    });
  }

  @override
  void dispose() {
    _provider.endStudySession('concept');
    // Don't update progress during dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContentProvider>();
    final groups = cp.conceptGroups;
    if (groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Concept Map')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(64),
            minScale: 0.5,
            maxScale: 4,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: MindMapWidget(
                root: 'Topics',
                groups: groups,
              ),
            ),
          );
        },
      ),
    );
  }
}

class MindMapWidget extends StatefulWidget {
  final String root;
  final List<ConceptGroup> groups;
  const MindMapWidget({required this.root, required this.groups, super.key});

  @override
  State<MindMapWidget> createState() => _MindMapWidgetState();
}

class _MindMapWidgetState extends State<MindMapWidget>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _controllers = {};
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    for (final g in widget.groups) {
      _expanded[g.title] = false;
      _controllers[g.title] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggle(String group) {
    final ctrl = _controllers[group]!;
    setState(() {
      _expanded[group] = !_expanded[group]!;
      if (_expanded[group]!) {
        ctrl.forward();
      } else {
        ctrl.reverse();
      }
    });
  }

  void _handleTap(Offset pos, Map<String, Offset> positions) {
    const radius = 24.0;
    for (final g in widget.groups) {
      final p = positions[g.title];
      if (p != null && (p - pos).distance <= radius) {
        _toggle(g.title);
        break;
      }
    }
  }

  Map<String, Offset> _calcPositions(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final positions = <String, Offset>{widget.root: center};
    final r1 = math.min(size.width, size.height) / 4;
    final groups = widget.groups;
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final angle = 2 * math.pi * i / groups.length;
      final gPos = center + Offset(math.cos(angle) * r1, math.sin(angle) * r1);
      positions[g.title] = gPos;

      final ctrl = _controllers[g.title]!;
      final topics = g.topics ?? [];
      final r2 = r1 + 80 * ctrl.value;
      final spread = math.pi / 3;
      for (var j = 0; j < topics.length; j++) {
        final frac = topics.length == 1 ? 0.5 : j / (topics.length - 1);
        final tAngle = angle - spread / 2 + spread * frac;
        final tPos = center + Offset(math.cos(tAngle) * r2, math.sin(tAngle) * r2);
        if (_expanded[g.title]!) {
          positions[topics[j]] = tPos;
        }
      }
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_controllers.values),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final positions = _calcPositions(size);
            return GestureDetector(
              onTapUp: (d) => _handleTap(d.localPosition, positions),
              child: CustomPaint(
                size: size,
                painter: _MindMapPainter(
                  root: widget.root,
                  groups: widget.groups,
                  positions: positions,
                  expanded: _expanded,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MindMapPainter extends CustomPainter {
  final String root;
  final List<ConceptGroup> groups;
  final Map<String, Offset> positions;
  final Map<String, bool> expanded;

  _MindMapPainter({
    required this.root,
    required this.groups,
    required this.positions,
    required this.expanded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = const TextStyle(color: Colors.white, fontSize: 12);
    final rootPos = positions[root]!;
    _drawNode(canvas, rootPos, root, Colors.grey[700]!, textStyle);

    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final color = Colors.primaries[i % Colors.primaries.length];
      final gPos = positions[g.title]!;
      _drawCurve(canvas, rootPos, gPos, color.withOpacity(0.6));
      _drawNode(canvas, gPos, g.title, color, textStyle);
      if (expanded[g.title]!) {
        final topics = g.topics ?? [];
        for (final t in topics) {
          final tPos = positions[t]!;
          _drawCurve(canvas, gPos, tPos, color.withOpacity(0.4));
          _drawNode(canvas, tPos, t, color.withOpacity(0.8), textStyle);
        }
      }
    }
  }

  void _drawCurve(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo((a.dx + b.dx) / 2, (a.dy + b.dy) / 2, b.dx, b.dy);
    canvas.drawPath(path, paint);
  }

  void _drawNode(
      Canvas canvas, Offset pos, String text, Color color, TextStyle style) {
    const radius = 24.0;
    final paint = Paint()..color = color;
    canvas.drawCircle(pos, radius, paint);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 2);
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MindMapPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.expanded != expanded;
  }
}

