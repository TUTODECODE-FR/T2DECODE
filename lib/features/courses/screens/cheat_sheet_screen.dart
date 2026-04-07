import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/features/courses/data/cheat_sheet_repository.dart';


class CheatSheetEntry {
  final String command, description, category;
  final String? detailedExplanation;
  final String? iconName;
  final String? colorHex;
  final List<String>? options, examples, tableHeaders;
  final List<List<String>>? tableData;
  final int dangerLevel;

  CheatSheetEntry({
    required this.command,
    required this.description,
    required this.category,
    this.detailedExplanation,
    this.iconName,
    this.colorHex,
    this.options,
    this.examples,
    this.tableHeaders,
    this.tableData,
    this.dangerLevel = 1,
  });

  factory CheatSheetEntry.fromMap(Map<String, dynamic> m) {
    return CheatSheetEntry(
      command: m['command'] ?? '',
      description: m['description'] ?? '',
      category: m['category'] ?? '',
      detailedExplanation: m['detailedExplanation'],
      iconName: m['iconName'],
      colorHex: m['colorHex'],
      options: m['options'] != null ? List<String>.from(m['options']) : null,
      examples: m['examples'] != null ? List<String>.from(m['examples']) : null,
      tableHeaders: m['tableHeaders'] != null ? List<String>.from(m['tableHeaders']) : null,
      tableData: m['tableData'] != null 
          ? (m['tableData'] as List).map((row) => List<String>.from(row)).toList() 
          : null,
      dangerLevel: m['dangerLevel'] ?? 1,
    );
  }
}



class CheatSheetScreen extends StatefulWidget {
  const CheatSheetScreen({super.key});
  @override State<CheatSheetScreen> createState() => _CheatSheetScreenState();
}

class _CheatSheetScreenState extends State<CheatSheetScreen> {
  String _filter = '';
  String _selectedCategory = 'TOUT';
  List<CheatSheetEntry> _entries = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(title: 'Cheat Sheets', showBackButton: false);
    });
  }

  Future<void> _loadData() async {
    final data = await CheatSheetRepository.loadAll();
    if (mounted) {
      setState(() {
        _entries = data;
        _loading = false;
      });
      _handleArguments();
    }
  }

  void _handleArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('command')) {
        setState(() {
          _filter = args['command'] as String;
          if (args.containsKey('category')) {
            _selectedCategory = args['category'] as String;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: TdcColors.accent));
    }
    final filtered = _entries.where((e) {
      final matchesSearch = e.command.toLowerCase().contains(_filter.toLowerCase()) || 
                          e.description.toLowerCase().contains(_filter.toLowerCase());
      final matchesCat = _selectedCategory == 'TOUT' || e.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    // Tri par description
    filtered.sort((a, b) => a.description.compareTo(b.description));

    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: filtered.isEmpty
              ? const TdcEmptyState(icon: Icons.search_off, title: 'Aucune commande trouvée')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => TdcFadeSlide(
                    delay: Duration(milliseconds: i * 30),
                    child: _card(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface.withOpacity(0.3),
        border: const Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _filter = v),
            decoration: InputDecoration(
              hintText: 'Rechercher une commande...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: TdcColors.bg,
              border: OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['TOUT', 'Red Team', 'Blue Team', 'Admin Sys', 'Cloud', 'SÉCURITÉ', 'LINUX', 'WINDOWS', 'DOCKER', 'RÉSEAU', 'GIT'].map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selected: isSel,
                    onSelected: (v) => setState(() => _selectedCategory = cat),
                    selectedColor: TdcColors.accent,
                    labelStyle: TextStyle(color: isSel ? Colors.white : TdcColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(CheatSheetEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TdcCard(
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.pushNamed(context, '/cheat-sheets/details', arguments: e),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColor(e).withOpacity(0.1),
                borderRadius: TdcRadius.md,
              ),
              child: Icon(_getIcon(e), color: _getColor(e), size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(
                    text: e.description,
                    highlight: _filter,
                    style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.chevron_right, size: 14, color: TdcColors.accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _HighlightText(
                          text: e.command,
                          highlight: _filter,
                          style: const TextStyle(color: TdcColors.textMuted, fontFamily: 'monospace', fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CopyButton(text: e.command),
          ],
        ),
      ),
    );
  }

  Color _getColor(CheatSheetEntry e) {
    if (e.colorHex != null && e.colorHex!.isNotEmpty) {
      final hex = e.colorHex!.replaceAll('#', '');
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    switch (e.category) {
      case 'WINDOWS': return const Color(0xFF00A4EF);
      case 'MAC': return const Color(0xFF999999);
      case 'LINUX': return const Color(0xFFFCC624);
      case 'DOCKER': return const Color(0xFF2496ED);
      case 'RÉSEAU': return const Color(0xFF10B981);
      case 'GIT': return const Color(0xFFF05032);
      case 'SÉCURITÉ': return const Color(0xFFEF4444);
      default: return TdcColors.accent;
    }
  }

  IconData _getIcon(CheatSheetEntry e) {
    if (e.iconName != null && e.iconName!.isNotEmpty) {
      switch (e.iconName) {
        case 'security': return Icons.security;
        case 'terminal': return Icons.terminal;
        case 'cloud': return Icons.cloud;
        case 'dns': return Icons.dns;
        case 'lock': return Icons.lock;
        case 'api': return Icons.api;
        case 'bug_report': return Icons.bug_report;
        case 'admin_panel_settings': return Icons.admin_panel_settings;
        case 'storage': return Icons.storage;
        case 'network': return Icons.network_check;
        case 'search': return Icons.search;
      }
    }
    switch (e.category) {
      case 'WINDOWS': return Icons.window;
      case 'MAC': return Icons.apple;
      case 'LINUX': return Icons.terminal;
      case 'DOCKER': return Icons.directions_boat;
      case 'RÉSEAU': return Icons.lan;
      case 'GIT': return Icons.merge_type;
      case 'SÉCURITÉ': return Icons.security;
      default: return Icons.code;
    }
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_copied ? Icons.check : Icons.copy_rounded, 
             size: 18, 
             color: _copied ? Colors.green : TdcColors.textMuted),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: widget.text));
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      tooltip: 'Copier la commande',
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  const _HighlightText({required this.text, required this.highlight, required this.style, this.maxLines, this.overflow});

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty || !text.toLowerCase().contains(highlight.toLowerCase())) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final String lowText = text.toLowerCase();
    final String lowHighlight = highlight.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = lowText.indexOf(lowHighlight, start)) != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + highlight.length),
        style: TextStyle(backgroundColor: TdcColors.accent.withOpacity(0.3), color: Colors.white),
      ));
      start = indexOfHighlight + highlight.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(style: style, children: spans),
    );
  }
}
