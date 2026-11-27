// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// Lecture non linéaire : corrections masquées, questions en cours de route,
// liens vers les entraînements.
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import '../data/course_repository.dart';

enum LessonSegmentKind { prose, exercise, correction }

class LessonSegment {
  const LessonSegment(this.kind, this.markdown, {this.heading});

  final LessonSegmentKind kind;
  final String markdown;
  final String? heading;
}

final RegExp _headingLine = RegExp(r'^#{2,3}\s+(.+?)\s*$');

/// Découpe le Markdown d'un chapitre aux titres `##` / `###`.
/// Les blocs de code ``` ne sont jamais coupés.
List<LessonSegment> splitLessonSegments(String markdown) {
  final segments = <LessonSegment>[];
  final buffer = StringBuffer();
  String? heading;
  var inFence = false;

  void flush() {
    final text = buffer.toString().trim();
    buffer.clear();
    if (text.isEmpty) return;
    final h = (heading ?? '').toLowerCase();
    final kind = h.startsWith('correction')
        ? LessonSegmentKind.correction
        : h.startsWith('à toi de jouer') || h.startsWith('a toi de jouer')
            ? LessonSegmentKind.exercise
            : LessonSegmentKind.prose;
    segments.add(LessonSegment(kind, text, heading: heading));
  }

  for (final line in markdown.split('\n')) {
    if (line.trimLeft().startsWith('```')) inFence = !inFence;
    final match = inFence ? null : _headingLine.firstMatch(line);
    if (match != null) {
      flush();
      heading = match.group(1);
    }
    buffer.writeln(line);
  }
  flush();
  return segments;
}

/// Questions de contrôle à placer après des parties du chapitre :
/// prises en fin de banque, au plus [max], seulement si la banque est assez
/// grande pour que le quiz final garde de la variété.
List<QuizQuestion> checkpointQuestions(List<QuizQuestion>? bank,
    {int max = 3}) {
  if (bank == null || bank.length < 6) return const [];
  final count = max < bank.length ~/ 3 ? max : bank.length ~/ 3;
  return [for (var i = 0; i < count; i++) bank[bank.length - 1 - i]];
}

class PracticeTarget {
  const PracticeTarget(this.labId, this.label, this.icon);

  final String labId;
  final String label;
  final IconData icon;
}

class _PracticeRule {
  const _PracticeRule(this.target, this.words);

  final PracticeTarget target;
  final List<String> words;
}

const List<_PracticeRule> _practiceRules = [
  _PracticeRule(
    PracticeTarget('training-subnet', 'Sous-réseaux IPv4', Icons.calculate),
    ['sous-réseau', 'sous-reseau', 'masque', 'cidr', 'vlsm'],
  ),
  _PracticeRule(
    PracticeTarget('training-routing', 'Tables de routage', Icons.alt_route),
    ['routage', 'table de routage', 'passerelle par défaut'],
  ),
  _PracticeRule(
    PracticeTarget('training-packets', 'Décoder une trame', Icons.data_object),
    ['trame', 'en-tête tcp', 'en-tête ip', 'ethernet', 'wireshark'],
  ),
  _PracticeRule(
    PracticeTarget('training-permissions', 'Droits Linux', Icons.lock_outline),
    ['chmod', 'umask', 'chown', 'droits d\'accès'],
  ),
  _PracticeRule(
    PracticeTarget(
        'training-conversions', 'Binaire et hexadécimal', Icons.swap_horiz),
    ['binaire', 'hexadécimal', 'hexadecimal'],
  ),
  _PracticeRule(
    PracticeTarget('training-terminal', 'Terminal : missions', Icons.terminal),
    ['```bash', 'ligne de commande', 'terminal'],
  ),
];

/// Entraînements liés au texte d'un chapitre (au plus [max]).
List<PracticeTarget> practiceTargetsFor(String text, {int max = 2}) {
  final lower = text.toLowerCase();
  final found = <PracticeTarget>[];
  for (final rule in _practiceRules) {
    if (rule.words.any(lower.contains)) found.add(rule.target);
    if (found.length == max) break;
  }
  return found;
}

/// Correction masquée derrière un bouton.
class RevealCorrection extends StatefulWidget {
  const RevealCorrection({super.key, required this.child});

  final Widget child;

  @override
  State<RevealCorrection> createState() => _RevealCorrectionState();
}

class _RevealCorrectionState extends State<RevealCorrection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: _open
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: BoxDecoration(
                color: TdcColors.success.withValues(alpha: 0.06),
                border: const Border(
                    left: BorderSide(color: TdcColors.success, width: 3)),
              ),
              child: widget.child,
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('reveal-correction'),
                onPressed: () => setState(() => _open = true),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Essaie d\'abord, puis voir la correction'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TdcColors.accent,
                  side: BorderSide(
                      color: TdcColors.accent.withValues(alpha: 0.5)),
                ),
              ),
            ),
    );
  }
}

/// Question rapide non notée, avec réponse immédiate.
class CheckpointQuestion extends StatefulWidget {
  const CheckpointQuestion({super.key, required this.question});

  final QuizQuestion question;

  @override
  State<CheckpointQuestion> createState() => _CheckpointQuestionState();
}

class _CheckpointQuestionState extends State<CheckpointQuestion> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final answered = _picked != null;
    final right = _picked == q.correctIndex;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TdcColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VÉRIFIE TA COMPRÉHENSION',
            style: TextStyle(
              color: TdcColors.accent,
              fontFamily: 'Aileron',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            q.question,
            style: const TextStyle(
                color: TdcColors.textPrimary, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ChoiceTile(
                text: q.choices[i],
                state: !answered
                    ? null
                    : i == q.correctIndex
                        ? true
                        : i == _picked
                            ? false
                            : null,
                onTap: answered ? null : () => setState(() => _picked = i),
              ),
            ),
          if (answered) ...[
            const SizedBox(height: 6),
            Text(
              right ? 'Exact.' : 'Pas tout à fait.',
              style: TextStyle(
                color: right ? TdcColors.success : TdcColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((q.explanation ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  q.explanation!,
                  style: const TextStyle(
                      color: TdcColors.textSecondary, height: 1.4),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.text, required this.state, this.onTap});

  final String text;
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = state == null
        ? TdcColors.border
        : state!
            ? TdcColors.success
            : TdcColors.warning;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(text, style: const TextStyle(color: TdcColors.textPrimary)),
      ),
    );
  }
}

/// Boutons « S'entraîner » vers les entraînements liés au chapitre.
class PracticeLinks extends StatelessWidget {
  const PracticeLinks({super.key, required this.targets});

  final List<PracticeTarget> targets;

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('lesson-practice'),
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'S\'ENTRAÎNER',
            style: TextStyle(
              color: TdcColors.accent,
              fontFamily: 'Aileron',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Des exercices générés à chaque fois, corrigés pas à pas.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in targets)
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/lab',
                    arguments: {'sim': t.labId},
                  ),
                  icon: Icon(t.icon, size: 16, color: Colors.black),
                  label: Text(t.label,
                      style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TdcColors.accent,
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
