import 'package:flutter/material.dart';
import '../data/course_repository.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class QcmWidget extends StatefulWidget {
  final List<QuizQuestion> questions;
  final void Function(bool success)? onComplete;

  const QcmWidget({required this.questions, this.onComplete, Key? key}) : super(key: key);

  @override
  State<QcmWidget> createState() => _QcmWidgetState();
}

class _QcmWidgetState extends State<QcmWidget> {
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _validated = false;
  bool _finished = false;

  void _validate() {
    setState(() {
      _validated = true;
      if (_selected == widget.questions[_current].correctIndex) {
        _score++;
      }
    });
  }

  void _next() {
    if (_current < widget.questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _validated = false;
      });
    } else {
      setState(() {
        _finished = true;
      });
      widget.onComplete?.call(_score == widget.questions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final success = _score == widget.questions.length;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: TdcColors.surface,
          borderRadius: TdcRadius.lg,
          border: Border.all(color: success ? TdcColors.success.withOpacity(0.5) : TdcColors.danger.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.emoji_events : Icons.error_outline,
              size: 54,
              color: success ? TdcColors.success : TdcColors.danger,
            ),
            const SizedBox(height: 20),
            Text(
              'Résultat : $_score / ${widget.questions.length}',
              style: const TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              success 
                ? 'Félicitations ! Vous avez validé ce chapitre avec brio.' 
                : 'Certaines réponses sont incorrectes. Nous vous conseillons de relire le chapitre et de réessayer.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: TdcColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            if (!success) 
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _current = 0;
                    _score = 0;
                    _selected = null;
                    _validated = false;
                    _finished = false;
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recommencer le Quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: TdcColors.accent,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Terminer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: TdcColors.success),
                    foregroundColor: TdcColors.success,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final q = widget.questions[_current];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(color: TdcColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TdcColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QUESTION ${_current + 1} SUR ${widget.questions.length}',
                  style: const TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
              ),
              Text(
                'SÉRIE EN COURS : $_score REUSSI',
                style: const TextStyle(color: TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            q.question,
            style: const TextStyle(color: TdcColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 28),
          ...List.generate(q.choices.length, (i) {
            final isSelected = _selected == i;
            final isCorrect = i == q.correctIndex;
            
            Color bgColor = isSelected ? TdcColors.accent.withOpacity(0.08) : TdcColors.surfaceAlt;
            Color borderColor = isSelected ? TdcColors.accent : TdcColors.border;
            Color iconColor = isSelected ? TdcColors.accent : TdcColors.textMuted;
            Widget? icon = isSelected ? const Center(child: Icon(Icons.check, size: 14, color: Colors.white)) : null;

            if (_validated) {
              if (isCorrect) {
                bgColor = TdcColors.success.withOpacity(0.1);
                borderColor = TdcColors.success;
                iconColor = TdcColors.success;
                icon = const Center(child: Icon(Icons.check, size: 14, color: Colors.white));
              } else if (isSelected && !isCorrect) {
                bgColor = TdcColors.danger.withOpacity(0.1);
                borderColor = TdcColors.danger;
                iconColor = TdcColors.danger;
                icon = const Center(child: Icon(Icons.close, size: 14, color: Colors.white));
              } else {
                bgColor = TdcColors.surfaceAlt.withOpacity(0.5);
                borderColor = TdcColors.border.withOpacity(0.5);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _validated ? null : () => setState(() => _selected = i),
                borderRadius: TdcRadius.md,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: TdcRadius.md,
                    border: Border.all(
                      color: borderColor,
                      width: isSelected || (_validated && isCorrect) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: iconColor, 
                            width: 2,
                          ),
                          color: (isSelected || (_validated && isCorrect)) ? iconColor : Colors.transparent,
                        ),
                        child: icon,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          q.choices[i],
                          style: TextStyle(
                            color: _validated 
                                ? (isCorrect || (isSelected && !isCorrect) ? TdcColors.textPrimary : TdcColors.textSecondary.withOpacity(0.5))
                                : (isSelected ? TdcColors.textPrimary : TdcColors.textSecondary),
                            fontSize: 15,
                            fontWeight: isSelected || (_validated && isCorrect) ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_validated && q.explanation != null && q.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TdcColors.accent.withOpacity(0.1),
                borderRadius: TdcRadius.md,
                border: Border.all(color: TdcColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: TdcColors.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.explanation!,
                      style: const TextStyle(color: TdcColors.textPrimary, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected != null ? (_validated ? _next : _validate) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: TdcRadius.md),
                elevation: 4,
                shadowColor: TdcColors.accent.withOpacity(0.4),
              ),
              child: Text(
                _validated 
                    ? (_current < widget.questions.length - 1 ? 'QUESTION SUIVANTE' : 'VOIR MON RÉSULTAT')
                    : 'VALIDER MA RÉPONSE',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
