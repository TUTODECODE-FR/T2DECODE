import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class PracticeNode {
  final IconData icon;
  final String label;
  final Color color;

  const PracticeNode({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class PracticeFlowDiagram extends StatelessWidget {
  final List<PracticeNode> nodes;

  const PracticeFlowDiagram({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, c) {
      final isNarrow = c.maxWidth < 520;
      if (isNarrow) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (int i = 0; i < nodes.length; i++) ...[
              _NodeChip(node: nodes[i]),
              if (i != nodes.length - 1) _ConnectorChip(color: nodes[i].color),
            ],
          ],
        );
      }
      return Row(
        children: [
          for (int i = 0; i < nodes.length; i++) ...[
            Expanded(child: _NodeTile(node: nodes[i])),
            if (i != nodes.length - 1)
              Expanded(child: _ConnectorBar(color: nodes[i].color)),
          ],
        ],
      );
    });
  }
}

class _NodeTile extends StatelessWidget {
  final PracticeNode node;
  const _NodeTile({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: node.color.withOpacity(0.10),
              border: Border.all(color: node.color.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: node.color.withOpacity(0.10),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(node.icon, size: 18, color: node.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              node.label,
              style: const TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideX(begin: 0.02, end: 0);
  }
}

class _ConnectorBar extends StatelessWidget {
  final Color color;
  const _ConnectorBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.0),
              color.withOpacity(0.6),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    ).animate().shimmer(duration: 1400.ms, color: color.withOpacity(0.25));
  }
}

class _NodeChip extends StatelessWidget {
  final PracticeNode node;
  const _NodeChip({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        border: Border.all(color: TdcColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(node.icon, size: 14, color: node.color),
          const SizedBox(width: 8),
          Text(
            node.label,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectorChip extends StatelessWidget {
  final Color color;
  const _ConnectorChip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.swap_horiz, size: 16, color: color.withOpacity(0.8))
        .animate()
        .fadeIn(duration: 200.ms)
        .shimmer(duration: 1400.ms, color: color.withOpacity(0.25));
  }
}

