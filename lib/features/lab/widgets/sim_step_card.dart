// ============================================================
// Shared Simulation Widgets
// Reusable visual components for simulator step cards:
//   SimFlowDiagram, SimLayerStack, SimComplexityBar,
//   SimPacketDiagram, SimKeyValue, SimTreeDiagram, SimCodeBlock
// ============================================================
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

// ─── SimFlowDiagram ──────────────────────────────────────────

class SimFlowNode {
  final String label;
  final IconData icon;
  final Color? overrideColor;
  const SimFlowNode(this.label, this.icon, {this.overrideColor});
}

class SimFlowDiagram extends StatelessWidget {
  final List<SimFlowNode> nodes;
  final Color color;

  const SimFlowDiagram({
    super.key,
    required this.nodes,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final c = node.overrideColor ?? color;
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(node.icon, size: 14, color: c),
              const SizedBox(width: 4),
              Text(
                node.label,
                style: TextStyle(
                  color: c,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
      if (i < nodes.length - 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.arrow_forward,
              size: 14,
              color: color.withValues(alpha: 0.5),
            ),
          ),
        );
      }
    }
    return Wrap(
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }
}

// ─── SimLayerStack ────────────────────────────────────────────

class SimLayer {
  final String name;
  final String description;
  final Color color;
  const SimLayer(this.name, this.description, this.color);
}

class SimLayerStack extends StatelessWidget {
  final List<SimLayer> layers;

  const SimLayerStack({super.key, required this.layers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(layers.length, (i) {
        final layer = layers[i];
        final isEven = i % 2 == 0;
        return Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: isEven
                ? layer.color.withValues(alpha: 0.12)
                : layer.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: layer.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                layer.name,
                style: TextStyle(
                  color: layer.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  layer.description,
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }
}

// ─── SimComplexityBar ─────────────────────────────────────────

class SimComplexityEntry {
  final String notation;
  final String name;
  final double fraction;
  final Color color;
  const SimComplexityEntry(this.notation, this.name, this.fraction, this.color);
}

class SimComplexityBar extends StatelessWidget {
  final List<SimComplexityEntry> entries;

  const SimComplexityBar({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBarWidth = constraints.maxWidth - 80;
        return Column(
          children: entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      e.notation,
                      style: TextStyle(
                        color: e.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: e.fraction),
                      duration: const Duration(milliseconds: 700),
                      builder: (context, value, _) {
                        return Stack(
                          children: [
                            Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: TdcColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 18,
                              width: maxBarWidth * value,
                              decoration: BoxDecoration(
                                color: e.color.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 6),
                              child: value > 0.15
                                  ? Text(
                                      e.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── SimPacketDiagram ─────────────────────────────────────────

class SimPacketField {
  final String label;
  final String value;
  final int flex;
  const SimPacketField(this.label, this.value, this.flex);
}

class SimPacketDiagram extends StatelessWidget {
  final List<SimPacketField> fields;
  final Color baseColor;

  const SimPacketDiagram({
    super.key,
    required this.fields,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    // Split fields into rows of max 4
    const maxPerRow = 4;
    final rows = <List<SimPacketField>>[];
    for (int i = 0; i < fields.length; i += maxPerRow) {
      rows.add(fields.sublist(i, i + maxPerRow > fields.length ? fields.length : i + maxPerRow));
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final rowFields = entry.value;
        return Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: baseColor.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: rowFields.asMap().entries.map((fe) {
              final f = fe.value;
              final fi = fe.key;
              final alpha = 0.2 + (fi / rowFields.length) * 0.35;
              return Expanded(
                flex: f.flex,
                child: Container(
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: alpha),
                    border: fi > 0
                        ? Border(
                            left: BorderSide(
                              color: baseColor.withValues(alpha: 0.3),
                            ),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        f.label,
                        style: TextStyle(
                          color: baseColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        f.value,
                        style: const TextStyle(
                          color: TdcColors.textMuted,
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ─── SimKeyValue ──────────────────────────────────────────────

class SimKVEntry {
  final String key;
  final String value;
  const SimKVEntry(this.key, this.value);
}

class SimKeyValue extends StatelessWidget {
  final List<SimKVEntry> entries;
  final Color color;

  const SimKeyValue({
    super.key,
    required this.entries,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: TdcColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 3, right: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  e.key,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── SimTreeDiagram ───────────────────────────────────────────

class SimTreeNode {
  final String label;
  final String? sublabel;
  final List<SimTreeNode> children;
  const SimTreeNode(this.label, {this.sublabel, this.children = const []});
}

class _TreeLinePainter extends CustomPainter {
  final Color color;
  final int childCount;

  _TreeLinePainter(this.color, this.childCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Vertical line down from root center
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height * 0.35),
      paint,
    );
    // Horizontal line across
    canvas.drawLine(
      Offset(size.width / (childCount + 1), size.height * 0.35),
      Offset(size.width * childCount / (childCount + 1), size.height * 0.35),
      paint,
    );
    // Vertical lines down to each child
    for (int i = 0; i < childCount; i++) {
      final x = size.width * (i + 1) / (childCount + 1);
      canvas.drawLine(
        Offset(x, size.height * 0.35),
        Offset(x, size.height * 0.65),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) => old.color != color;
}

class SimTreeDiagram extends StatelessWidget {
  final SimTreeNode root;
  final Color color;

  const SimTreeDiagram({
    super.key,
    required this.root,
    required this.color,
  });

  Widget _buildNodeBox(String label, String? sublabel, Color c, {bool isRoot = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isRoot ? 10 : 7,
        vertical: isRoot ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: isRoot ? 11 : 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (sublabel != null)
            Text(
              sublabel,
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = root.children;
    return SizedBox(
      height: 180,
      child: Column(
        children: [
          // Root node
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNodeBox(root.label, root.sublabel, color, isRoot: true),
            ],
          ),
          if (children.isNotEmpty) ...[
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TreeLinePainter(color, children.length),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: children.map((child) {
                          return Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildNodeBox(child.label, child.sublabel, color),
                                  if (child.children.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    ...child.children.take(2).map(
                                          (gc) => Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: _buildNodeBox(gc.label, gc.sublabel, color.withValues(alpha: 0.7)),
                                          ),
                                        ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SimCodeBlock ─────────────────────────────────────────────

class SimCodeBlock extends StatelessWidget {
  final String code;
  final Color color;
  final String? title;

  const SimCodeBlock({
    super.key,
    required this.code,
    required this.color,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border(
                    bottom: BorderSide(color: color.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      title!,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Text(
                  code,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
