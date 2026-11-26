// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Socle commun des entraînements : chaque exercice est généré (il change à chaque fois),
// l'élève répond, l'application vérifie et explique la correction.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

/// Générateur aléatoire d'un exercice. Une graine fixe donne toujours le même exercice
/// (utile pour les tests) ; sans graine, chaque exercice est différent.
class TrainingRandom {
  TrainingRandom([int? seed]) : _r = Random(seed);
  final Random _r;

  int nextInt(int max) => _r.nextInt(max);

  /// Entier dans [min, max] (bornes incluses).
  int range(int min, int max) => min + _r.nextInt(max - min + 1);
  bool nextBool() => _r.nextBool();
  T pick<T>(List<T> items) => items[_r.nextInt(items.length)];
  List<T> shuffled<T>(List<T> items) => List<T>.from(items)..shuffle(_r);
}

/// Résultat d'une vérification : juste ou faux, avec l'explication de la correction.
class TrainingCheck {
  const TrainingCheck(this.correct, this.explanation);
  final bool correct;
  final String explanation;
}

/// Cadre commun : en-tête, consigne, zone d'exercice, boutons et retour corrigé.
class TrainingFrame extends StatelessWidget {
  const TrainingFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.instruction,
    required this.child,
    required this.onCheck,
    required this.onNext,
    this.result,
    this.score = 0,
    this.attempts = 0,
    this.checkLabel = 'Vérifier',
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Consigne de l'exercice en cours (texte simple, peut contenir des retours à la ligne).
  final String instruction;
  final Widget child;
  final VoidCallback? onCheck;
  final VoidCallback onNext;
  final TrainingCheck? result;
  final int score;
  final int attempts;
  final String checkLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TdcColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: TdcColors.surface,
              border: Border(bottom: BorderSide(color: TdcColors.border)),
            ),
            child: Row(
              children: [
                Icon(icon, color: TdcColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: TdcColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: TdcColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (attempts > 0)
                  Text('$score / $attempts',
                      style: const TextStyle(
                          color: TdcColors.textSecondary,
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(instruction,
                          style: const TextStyle(
                              color: TdcColors.textPrimary,
                              fontSize: 15,
                              height: 1.5)),
                      const SizedBox(height: 16),
                      child,
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: onCheck,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(checkLabel),
                          ),
                          OutlinedButton.icon(
                            onPressed: onNext,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Nouvel exercice'),
                          ),
                        ],
                      ),
                      if (result != null) ...[
                        const SizedBox(height: 16),
                        TrainingFeedback(result: result!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encadré de correction : vert si juste, rouge sinon, avec l'explication.
class TrainingFeedback extends StatelessWidget {
  const TrainingFeedback({super.key, required this.result});
  final TrainingCheck result;

  @override
  Widget build(BuildContext context) {
    final ok = result.correct;
    final color = ok ? TdcColors.success : TdcColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? TdcColors.successDim : TdcColors.dangerDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ok ? 'Correct' : 'Pas encore',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SelectableText(result.explanation,
              style: const TextStyle(
                  color: TdcColors.textPrimary, height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}

/// Champ de réponse court, en police à chasse fixe.
class TrainingField extends StatelessWidget {
  const TrainingField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.onSubmitted,
    this.mono = true,
    this.state,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onSubmitted;
  final bool mono;

  /// null : pas encore vérifié ; true/false : bordure verte/rouge.
  final bool? state;

  @override
  Widget build(BuildContext context) {
    final border = state == null
        ? TdcColors.border
        : (state! ? TdcColors.success : TdcColors.danger);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        inputFormatters: [LengthLimitingTextInputFormatter(200)],
        style: TextStyle(
            color: TdcColors.textPrimary,
            fontFamily: mono ? 'monospace' : null),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: TdcColors.textSecondary),
          hintStyle: const TextStyle(color: TdcColors.textMuted),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: border),
              borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: border, width: 2),
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

/// Bloc de texte à chasse fixe (journal, trame hexadécimale, table de routage…).
class TrainingCode extends StatelessWidget {
  const TrainingCode(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TdcColors.border),
      ),
      child: SelectableText(text,
          style: const TextStyle(
              color: TdcColors.textPrimary,
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.45)),
    );
  }
}

/// Normalise une réponse saisie : espaces superflus retirés, casse ignorée.
String normalizeAnswer(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
