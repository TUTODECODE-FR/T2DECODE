import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class _Path {
  final String id, title, subtitle;
  final IconData icon;
  final Color color;
  final List<String> courseIds;
  const _Path({required this.id, required this.title, required this.subtitle, required this.icon, required this.color, required this.courseIds});
}

const _kPaths = [
  _Path(id: 'beginner', title: 'Débutant Cybersécurité', subtitle: 'Fondations, Réseau, Linux', icon: Icons.school, color: Color(0xFF10B981), courseIds: ['linux-basics', 'network-101', 'security-intro']),
  _Path(id: 'pentester', title: 'Pentester (Red Team)', subtitle: 'Audit, Exploitation, Web', icon: Icons.bug_report, color: Color(0xFFEF4444), courseIds: ['web-hacking', 'network-pentest', 'privilege-escalation']),
  _Path(id: 'forensic', title: 'Expert Forensic (Blue Team)', subtitle: 'Analyse, Réponse, SIEM', icon: Icons.search, color: Color(0xFF3B82F6), courseIds: ['incident-response', 'memory-forensics', 'malware-analysis']),
];

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});
  @override State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> with SingleTickerProviderStateMixin {
  int _selected = 0;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _kPaths.length, vsync: this);
    _tab.addListener(() { if (!_tab.indexIsChanging) setState(() => _selected = _tab.index); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(title: 'Roadmap', showBackButton: true);
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CoursesProvider>(context);
    final path = _kPaths[_selected];
    return Column(children: [
      _tabs(),
      Expanded(child: _content(path, prov)),
    ]);
  }

  Widget _tabs() {
    return Container(
      color: TdcColors.surface,
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _kPaths[_selected].color,
        tabs: _kPaths.map((p) => Tab(text: p.title)).toList(),
      ),
    );
  }

  Widget _content(_Path path, CoursesProvider prov) {
    final courses = prov.courses.where((c) => path.courseIds.contains(c.id)).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _info(path, courses, prov),
        const SizedBox(height: 32),
        ...courses.asMap().entries.map((e) => _node(e.value, e.key, courses.length, prov, path.color)),
      ],
    );
  }

  Widget _info(_Path path, List courses, CoursesProvider prov) {
    final done = courses.fold(0, (s, c) => s + (prov.courseCompletedCount(c.id) == c.chapters.length ? 1 : 0));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(path.icon, color: path.color, size: 32),
        const SizedBox(height: 12),
        Text(path.title, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(path.subtitle, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        LinearProgressIndicator(value: courses.isEmpty ? 0 : done / courses.length, color: path.color),
      ]),
    );
  }

  Widget _node(course, i, total, prov, color) {
    final done = prov.courseCompletedCount(course.id) == course.chapters.length;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? TdcColors.success : color.withOpacity(0.1), border: Border.all(color: done ? TdcColors.success : color)),
          child: Center(child: done ? const Icon(Icons.check, size: 16, color: Colors.white) : Text('${i+1}', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ),
        if (i < total - 1) Container(width: 2, height: 40, color: TdcColors.border),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: TdcCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.title, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(course.description, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12), maxLines: 2),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (course.chapters.isNotEmpty) {
                  prov.selectChapter(course.id, course.chapters.first.id);
                  Navigator.pushNamed(context, '/chapter');
                }
              }, 
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(done ? 'Revoir' : 'Commencer'),
            ),
          ),
        ])),
      )),
    ]);
  }
}
