import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class ChmodToolScreen extends StatefulWidget {
  const ChmodToolScreen({super.key});

  @override
  State<ChmodToolScreen> createState() => _ChmodToolScreenState();
}

class _ChmodToolScreenState extends State<ChmodToolScreen> {
  // Permissions state: [read, write, execute] for [owner, group, other]
  final List<List<bool>> _perms = [
    [true, true, false], // Owner
    [true, false, false], // Group
    [true, false, false], // Other
  ];
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Calculateur Chmod',
        showBackButton: true,
      );
    });
  }

  String _getNumeric() {
    return _perms.map((p) {
      int val = 0;
      if (p[0]) val += 4;
      if (p[1]) val += 2;
      if (p[2]) val += 1;
      return val.toString();
    }).join();
  }

  String _getSymbolic() {
    final chars = ['r', 'w', 'x'];
    return _perms.map((p) {
      return List.generate(3, (i) => p[i] ? chars[i] : '-').join();
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          _buildResultCard(),
          const SizedBox(height: 24),
          _buildRiskAnalyzer(),
          const SizedBox(height: 24),
          _buildSelectorCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: TdcRadius.md,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultItem('NUMÉRIQUE', _getNumeric()),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildResultItem('SYMBOLIQUE', _getSymbolic()),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _copyAndSave,
            icon: const Icon(Icons.copy, size: 14),
            label: Text('Copier chmod ${_getNumeric()}'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 12)),
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _history.map((h) => GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: 'chmod ${h.split(' ').first} fichier')),
                child: Chip(
                  label: Text(h, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  backgroundColor: Colors.white12,
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _copyAndSave() {
    final cmd = 'chmod ${_getNumeric()} fichier';
    Clipboard.setData(ClipboardData(text: cmd));
    final entry = '${_getNumeric()} (${_getSymbolic()})';
    if (_history.isEmpty || _history.first != entry) {
      setState(() {
        _history.insert(0, entry);
        if (_history.length > 8) _history.removeLast();
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copié : $cmd'), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildResultItem(String label, String val) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
  ]);

  Widget _buildSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 32, color: TdcColors.border),
          _buildRow(0, 'PROPRIÉTAIRE (Owner)'),
          const SizedBox(height: 16),
          _buildRow(1, 'GROUPE (Group)'),
          const SizedBox(height: 16),
          _buildRow(2, 'AUTRES (Others)'),
        ],
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      const Expanded(flex: 2, child: SizedBox()),
      _buildHeaderCell('Lecture (4)'),
      _buildHeaderCell('Écriture (2)'),
      _buildHeaderCell('Exécution (1)'),
    ],
  );

  Widget _buildHeaderCell(String text) => Expanded(child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: TdcColors.textMuted, fontSize: 10))));

  Widget _buildRow(int index, String label) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        _buildToggle(index, 0),
        _buildToggle(index, 1),
        _buildToggle(index, 2),
      ],
    );
  }

  Widget _buildToggle(int row, int col) {
    final active = _perms[row][col];
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: () => setState(() => _perms[row][col] = !active),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: active ? Colors.blue.withOpacity(0.1) : TdcColors.surfaceAlt,
              borderRadius: TdcRadius.sm,
              border: Border.all(color: active ? Colors.blue : TdcColors.border),
            ),
            child: Icon(active ? Icons.check : null, color: Colors.blue, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskAnalyzer() {
    final numeric = _getNumeric();
    final is777 = numeric == '777';
    final is666 = numeric == '666';
    final otherWrite = _perms[2][1];
    final otherRead = _perms[2][0];
    
    Color color = Colors.green;
    String title = 'SÉCURISÉ';
    String desc = 'Les permissions sont restrictives et appropriées.';

    if (is777 || is666) {
      color = Colors.red;
      title = 'DANGEREUX';
      desc = 'Tout le monde peut lire et MODIFIER ce fichier. Risque majeur de compromission.';
    } else if (otherWrite) {
      color = Colors.orange;
      title = 'RISQUÉ';
      desc = 'Des utilisateurs non autorisés peuvent modifier ce fichier.';
    } else if (otherRead && numeric != '755' && numeric != '644') {
      color = Colors.blue;
      title = 'INFO';
      desc = 'Le fichier est lisible par tous (standard pour le contenu public).';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: TdcRadius.md,
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(color == Colors.red ? Icons.gpp_maybe : (color == Colors.green ? Icons.verified_user : Icons.info), color: color),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: TdcColors.textSecondary)),
            ],
          )),
        ],
      ),
    );
  }
}
