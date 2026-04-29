import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/responsive/responsive.dart';

class LegalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TdcColors.bg,
      appBar: AppBar(
        backgroundColor: TdcColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TdcColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mentions légales', 
          style: TextStyle(
            color: TdcColors.textPrimary, 
            fontSize: TdcText.h2(context), 
            fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TdcAdaptive.padding(context, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Association TUTODECODE', 
              style: TextStyle(
                color: TdcColors.textPrimary, 
                fontSize: TdcText.h2(context), 
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Organisation à but non lucratif (Loi 1901)', 
              style: TextStyle(
                color: TdcColors.textMuted, 
                fontSize: TdcText.caption(context))),
            const SizedBox(height: 24),
            Text('Application : T2DECODE', 
              style: TextStyle(
                color: TdcColors.textSecondary, 
                fontSize: TdcText.body(context),
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('Politique de confidentialité', 
              style: TextStyle(
                color: TdcColors.textPrimary, 
                fontSize: TdcText.h3(context),
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('T2DECODE est conçu avec une approche offline-first et zéro tracking. Aucune donnée personnelle n’est collectée sur des serveurs distants.', 
              style: TextStyle(
                color: TdcColors.textSecondary, 
                fontSize: TdcText.bodySmall(context))),
            const SizedBox(height: 32),
            const Divider(color: TdcColors.border),
            const SizedBox(height: 16),
            Text('© 2026 Association TUTODECODE. Tous droits réservés.', 
              style: TextStyle(
                color: TdcColors.textMuted, 
                fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
