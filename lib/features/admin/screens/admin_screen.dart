import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/responsive/responsive.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
            title: 'Administration',
            showBackButton: true,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Network Controller Plan',
              style: TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Panneau d\'administration',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TdcCard(
            child: const ListTile(
              leading: Icon(Icons.emergency_share, color: TdcColors.danger),
              title: Text('Broadcast control (simulation)',
                  style: TextStyle(color: TdcColors.textPrimary)),
              subtitle: Text('Diffuser un message d\'urgence sur tous les nœuds', 
                  style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
