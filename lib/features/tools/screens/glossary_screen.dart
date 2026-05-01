import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';

class GlossaryEntry {
  final String term, definition, category;
  const GlossaryEntry({required this.term, required this.definition, required this.category});
}

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});
  @override State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _search = "";
  String _cat = "TOUT";

  final List<GlossaryEntry> _terms = [
    GlossaryEntry(category: 'RÉSEAU', term: 'IP', definition: 'Identifiant unique sur un réseau TCP/IP.'),
    GlossaryEntry(category: 'RÉSEAU', term: 'DNS', definition: 'Traduit les noms de domaine en adresses IP.'),
    GlossaryEntry(category: 'SÉCURITÉ', term: 'Firewall', definition: 'Filtre le trafic selon des règles.'),
    GlossaryEntry(category: 'SÉCURITÉ', term: 'VPN', definition: 'Tunnel sécurisé et chiffré.'),
    GlossaryEntry(category: 'SYSTÈME', term: 'Kernel', definition: 'Partie centrale de l\'OS.'),
    GlossaryEntry(category: 'SYSTÈME', term: 'RAM', definition: 'Mémoire vive volatile.'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(title: 'Glossaire Tech', showBackButton: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _terms.where((t) => (t.term.contains(_search) || t.definition.contains(_search)) && (_cat == "TOUT" || t.category == _cat)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(onChanged: (v) => setState(() => _search = v), decoration: const InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search)))),
      _categoryFilter(),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: filtered.length, itemBuilder: (context, i) => _card(filtered[i]))),
    ]);
  }

  Widget _categoryFilter() {
    final cats = ["TOUT", "RÉSEAU", "SÉCURITÉ", "SYSTÈME"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(label: Text(cats[i]), selected: _cat == cats[i], onSelected: (_) => setState(() => _cat = cats[i])),
        ),
      ),
    );
  }

  Widget _card(GlossaryEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(e.term, style: const TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(e.category, style: const TextStyle(color: TdcColors.textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 8),
        Text(e.definition, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}
