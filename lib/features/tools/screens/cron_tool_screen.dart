import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class CronToolScreen extends StatefulWidget {
  const CronToolScreen({super.key});

  @override
  State<CronToolScreen> createState() => _CronToolScreenState();
}

class _CronToolScreenState extends State<CronToolScreen> {
  final _minuteCtrl = TextEditingController(text: '*');
  final _hourCtrl = TextEditingController(text: '*');
  final _domCtrl = TextEditingController(text: '*');
  final _monthCtrl = TextEditingController(text: '*');
  final _dowCtrl = TextEditingController(text: '*');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Explorateur Cron',
        showBackButton: true,
      );
    });
  }

  String _getExplanation() {
    String m = _minuteCtrl.text == '*' ? 'Chaque minute' : 'À la minute ${_minuteCtrl.text}';
    String h = _hourCtrl.text == '*' ? 'Chaque heure' : 'À ${_hourCtrl.text} heures';
    String dm = _domCtrl.text == '*' ? '' : 'Le jour ${_domCtrl.text} du mois';
    String mon = _monthCtrl.text == '*' ? '' : 'En ${_monthCtrl.text}';
    String dw = _dowCtrl.text == '*' ? '' : 'Le jour de la semaine ${_dowCtrl.text}';

    String res = '$m, $h';
    if (dm.isNotEmpty) res += ', $dm';
    if (mon.isNotEmpty) res += ', $mon';
    if (dw.isNotEmpty) res += ', $dw';
    
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: Column(
        children: [
          _buildResultCard(),
          const SizedBox(height: 32),
          _buildInputGrid(),
          const SizedBox(height: 32),
          _buildExamples(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        children: [
          const Text('TRADUCTION HUMAINE', style: TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(_getExplanation(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TdcColors.accent)),
          const Divider(height: 32),
          Text('${_minuteCtrl.text} ${_hourCtrl.text} ${_domCtrl.text} ${_monthCtrl.text} ${_dowCtrl.text}', 
            style: const TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildInputGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildField('Min', _minuteCtrl),
            _buildField('Heure', _hourCtrl),
            _buildField('Mois', _domCtrl),
            _buildField('Jour', _monthCtrl),
            _buildField('Sem', _dowCtrl),
          ],
        ),
        const SizedBox(height: 8),
        const Text('* = Tout  |  */5 = Toutes les 5  |  1,5 = 1 et 5', style: TextStyle(fontSize: 10, color: TdcColors.textMuted)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: ctrl, textAlign: TextAlign.center, onChanged: (_) => setState(() {}), decoration: const InputDecoration(filled: true, fillColor: TdcColors.surfaceAlt)),
          ],
        ),
      ),
    );
  }

  Widget _buildExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EXEMPLES COMMUNS', style: TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _exampleRow('Toutes les minutes', '* * * * *'),
        _exampleRow('Toutes les 5 minutes', '*/5 * * * *'),
        _exampleRow('Chaque heure pile', '0 * * * *'),
        _exampleRow('Chaque jour à minuit', '0 0 * * *'),
        _exampleRow('Tous les dimanches à 4h', '0 4 * * 0'),
      ],
    );
  }

  Widget _exampleRow(String label, String code) => InkWell(
    onTap: () {
      final pts = code.split(' ');
      _minuteCtrl.text = pts[0]; _hourCtrl.text = pts[1]; _domCtrl.text = pts[2]; _monthCtrl.text = pts[3]; _dowCtrl.text = pts[4];
      setState(() {});
    },
    child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(code, style: const TextStyle(fontFamily: 'monospace', color: TdcColors.accent, fontWeight: FontWeight.bold))])),
  );
}
