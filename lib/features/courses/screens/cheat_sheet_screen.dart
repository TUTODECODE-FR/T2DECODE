// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tutodecode/features/courses/data/cheat_sheet_categories.dart';
import 'package:tutodecode/features/courses/data/cheat_sheet_repository.dart';
import 'package:tutodecode/features/courses/data/cheat_sheet_style.dart';

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
      tableHeaders: m['tableHeaders'] != null
          ? List<String>.from(m['tableHeaders'])
          : null,
      tableData: m['tableData'] != null
          ? (m['tableData'] as List)
              .map((row) => List<String>.from(row))
              .toList()
          : null,
      dangerLevel: m['dangerLevel'] ?? 1,
    );
  }
}

class CheatSheetScreen extends StatefulWidget {
  const CheatSheetScreen({super.key});
  @override
  State<CheatSheetScreen> createState() => _CheatSheetScreenState();
}

class _CheatSheetScreenState extends State<CheatSheetScreen> {
  String _filter = '';
  String _selectedCategory = 'TOUT';
  List<CheatSheetEntry> _entries = [];
  bool _loading = true;
  String? _loadedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ShellProvider>()
          .updateShell(title: 'Cheat Sheets', showBackButton: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale.languageCode;
    if (_loadedLocale != locale) {
      _loadData(locale: locale);
    }
  }

  Future<void> _loadData({required String locale}) async {
    setState(() => _loading = true);
    final data = await CheatSheetRepository.loadAll(locale: locale);
    if (mounted) {
      setState(() {
        _entries = data;
        _loading = false;
        _loadedLocale = locale;
      });
      _handleArguments();
    }
  }

  void _handleArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
      return const Center(
          child: CircularProgressIndicator(color: TdcColors.accent));
    }
    final filtered = _entries.where((e) {
      return CheatSheetCategories.matchesSearch(e, _filter) &&
          CheatSheetCategories.matchesFilter(_selectedCategory, e);
    }).toList();

    // Tri : commandes critiques (dangerLevel=3) en tête, puis par description
    filtered.sort((a, b) {
      if (b.dangerLevel != a.dangerLevel)
        return b.dangerLevel.compareTo(a.dangerLevel);
      return a.description.compareTo(b.description);
    });

    final critical = filtered.where((e) => e.dangerLevel == 3).toList();

    return Column(
      children: [
        _buildSearchAndFilters(),
        if (_filter.isEmpty &&
            _selectedCategory == 'TOUT' &&
            critical.isNotEmpty)
          _buildCriticalBanner(critical.length),
        Expanded(
          child: filtered.isEmpty
              ? const TdcEmptyState(
                  icon: Icons.search_off, title: 'Aucune commande trouvée')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final card = _card(filtered[i]);
                    if (i >= 12) return card;
                    return TdcFadeSlide(
                      delay: Duration(milliseconds: i * 20),
                      child: card,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCriticalBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TdcColors.warningDim,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: TdcColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count commandes sensibles dans cette liste — lisez l\'explication avant d\'exécuter.',
              style: const TextStyle(
                  color: TdcColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final categories = CheatSheetCategories.filterLabels;
    final totalEntries = _entries.length;
    final filteredCount = _entries.where((e) {
      return CheatSheetCategories.matchesSearch(e, _filter) &&
          CheatSheetCategories.matchesFilter(_selectedCategory, e);
    }).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: TdcColors.surface.withValues(alpha: 0.3),
        border: const Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats header
          Row(
            children: [
              Text(
                '$filteredCount',
                style: const TextStyle(
                    color: TdcColors.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                ' / $totalEntries commandes',
                style:
                    const TextStyle(color: TdcColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              // Légende danger level
              _DangerLegend(level: 1, label: 'Normal'),
              const SizedBox(width: 10),
              _DangerLegend(level: 2, label: 'Prudence'),
              const SizedBox(width: 10),
              _DangerLegend(level: 3, label: 'Sensible'),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _filter = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher une commande...',
              prefixIcon: Icon(Icons.search, size: 18),
              filled: true,
              fillColor: TdcColors.bg,
              border: OutlineInputBorder(
                  borderRadius: TdcRadius.md, borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selected: isSel,
                    onSelected: (v) => setState(() => _selectedCategory = cat),
                    selectedColor: TdcColors.accent,
                    labelStyle: TextStyle(
                        color: isSel ? Colors.white : TdcColors.textSecondary),
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
    final color = CheatSheetStyle.categoryColor(e);
    final dangerColor =
        e.dangerLevel >= 2 ? CheatSheetStyle.dangerColor(e.dangerLevel) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: TdcColors.surface,
          borderRadius: TdcRadius.lg,
          border: Border.all(
            color: dangerColor != null
                ? dangerColor.withValues(alpha: 0.3)
                : TdcColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: TdcRadius.lg,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/cheat-sheets/details',
                  arguments: e),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: color, width: 4)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: TdcRadius.md,
                      ),
                      child: Icon(CheatSheetStyle.categoryIcon(e),
                          color: color, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _HighlightText(
                                  text: e.description,
                                  highlight: _filter,
                                  style: const TextStyle(
                                    color: TdcColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (dangerColor != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: dangerColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color:
                                            dangerColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        e.dangerLevel == 3
                                            ? Icons.warning_amber_rounded
                                            : Icons.info_outline,
                                        size: 11,
                                        color: dangerColor,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        CheatSheetStyle.dangerLabel(
                                            e.dangerLevel),
                                        style: TextStyle(
                                          color: dangerColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: TdcColors.bg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color:
                                      TdcColors.border.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chevron_right,
                                    size: 13, color: TdcColors.accent),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: _HighlightText(
                                    text: e.command,
                                    highlight: _filter,
                                    style: const TextStyle(
                                      color: TdcColors.textMuted,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (e.detailedExplanation != null &&
                              e.detailedExplanation!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              e.detailedExplanation!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TdcColors.textTertiary,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            e.category,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CopyButton(text: e.command),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _DangerLegend extends StatelessWidget {
  final int level;
  final String label;
  const _DangerLegend({required this.level, required this.label});

  Color get _color => CheatSheetStyle.dangerColor(level);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: _color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
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
          size: 18, color: _copied ? Colors.green : TdcColors.textMuted),
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

  const _HighlightText(
      {required this.text,
      required this.highlight,
      required this.style,
      this.maxLines,
      this.overflow});

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty ||
        !text.toLowerCase().contains(highlight.toLowerCase())) {
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
        text: text.substring(
            indexOfHighlight, indexOfHighlight + highlight.length),
        style: TextStyle(
            backgroundColor: TdcColors.accent.withValues(alpha: 0.3),
            color: Colors.white),
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
