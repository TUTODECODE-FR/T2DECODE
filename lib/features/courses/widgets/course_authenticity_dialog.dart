// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/services/tdc_signature_service.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';

class CourseAuthenticityDialog extends StatefulWidget {
  final Course course;

  const CourseAuthenticityDialog({super.key, required this.course});

  static Future<void> show(BuildContext context, Course course) async {
    await showDialog(
      context: context,
      builder: (context) => CourseAuthenticityDialog(course: course),
    );
  }

  @override
  State<CourseAuthenticityDialog> createState() => _CourseAuthenticityDialogState();
}

class _CourseAuthenticityDialogState extends State<CourseAuthenticityDialog> {
  bool _isTrustUpdating = false;

  Future<void> _toggleKeyTrust() async {
    final fp = widget.course.authorKeyFingerprint ?? widget.course.author;
    setState(() => _isTrustUpdating = true);

    try {
      if (widget.course.trustStatus == KeyTrustStatus.trusted) {
        await TDCSignatureService.revokeKey(widget.course.author);
      } else {
        await TDCSignatureService.trustKey(widget.course.author, fp);
      }
      if (mounted) {
        final prov = context.read<CoursesProvider>();
        await prov.reload();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isTrustUpdating = false);
    }
  }

  Future<void> _deleteCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text("Supprimer le cours local ?",
            style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 16)),
        content: Text(
          "Voulez-vous vraiment supprimer le cours « ${widget.course.title} » de votre espace local ?",
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final fileName = widget.course.sourcePath?.split('/').last ?? '${widget.course.id}.json';
      final prov = context.read<CoursesProvider>();
      await prov.deleteModule(fileName);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildOriginHeader() {
    switch (widget.course.origin) {
      case CourseOrigin.official:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EBDA).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF5EBDA).withOpacity(0.3)),
          ),
          child: Row(
            children: const [
              Icon(Icons.star_rounded, color: Color(0xFFF5EBDA), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "★ Officiel • Asso (Certifié TUTODECODE)",
                  style: TextStyle(
                    color: Color(0xFFF5EBDA),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

      case CourseOrigin.signed:
        final isConflict = widget.course.trustStatus == KeyTrustStatus.conflict;
        final isTrusted = widget.course.trustStatus == KeyTrustStatus.trusted;
        final color = isConflict
            ? Colors.amber
            : (isTrusted ? const Color(0xFF10B981) : const Color(0xFF06B6D4));

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isConflict ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isConflict
                          ? "⚠️ Conflit de clé d'auteur"
                          : "✓ Signé par ${widget.course.author}",
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (widget.course.authorKeyFingerprint != null) ...[
                const SizedBox(height: 6),
                Text(
                  "Empreinte Ed25519 : ${widget.course.authorKeyFingerprint}",
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        );

      case CourseOrigin.community:
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3F3F46)),
          ),
          child: Row(
            children: const [
              Icon(Icons.public, color: Colors.grey, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "🌐 Communauté (Non certifié cryptographically)",
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildCertificationExplanation() {
    switch (widget.course.origin) {
      case CourseOrigin.official:
        return const Text(
          "« Cours officiel certifié par l'association TUTODECODE (Empreinte SHA-256 scellée et vérifiée dans le binaire d'application). »",
          style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
        );
      case CourseOrigin.signed:
        final fp = widget.course.authorKeyFingerprint ?? 'Inconnue';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "« Signé par ${widget.course.author} • Empreinte cryptographique : [$fp] »",
              style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: widget.course.trustStatus == KeyTrustStatus.trusted
                      ? Colors.redAccent
                      : const Color(0xFF10B981),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: Icon(
                widget.course.trustStatus == KeyTrustStatus.trusted
                    ? Icons.gavel_outlined
                    : Icons.verified_outlined,
                size: 14,
                color: widget.course.trustStatus == KeyTrustStatus.trusted
                    ? Colors.redAccent
                    : const Color(0xFF10B981),
              ),
              label: _isTrustUpdating
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.course.trustStatus == KeyTrustStatus.trusted
                          ? "Révoquer la confiance de cette clé"
                          : "Faire confiance à l'auteur (TOFU)",
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.course.trustStatus == KeyTrustStatus.trusted
                            ? Colors.redAccent
                            : const Color(0xFF10B981),
                      ),
                    ),
              onPressed: _isTrustUpdating ? null : _toggleKeyTrust,
            ),
          ],
        );
      case CourseOrigin.community:
      default:
        return const Text(
          "« Cours importé de la communauté (Non certifié cryptographiquement). »",
          style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizCount = widget.course.chapters.fold<int>(
      0,
      (sum, ch) => sum + (ch.quiz?.length ?? 0),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.course.title,
                    style: const TextStyle(
                      color: Color(0xFFF5EBDA),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOriginHeader(),
            const SizedBox(height: 14),
            _buildCertificationExplanation(),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF27272A)),
            const SizedBox(height: 12),
            Text(
              widget.course.description.isNotEmpty
                  ? widget.course.description
                  : "Aucune description fournie pour ce cours.",
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Metadata Grid
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildMetaChip(Icons.category_outlined, "Catégorie : ${widget.course.category}"),
                _buildMetaChip(Icons.bar_chart_outlined, "Niveau : ${widget.course.level}"),
                _buildMetaChip(Icons.schedule_outlined, "Durée : ${widget.course.duration}"),
                _buildMetaChip(Icons.book_outlined, "${widget.course.chapters.length} Chapitres"),
                _buildMetaChip(Icons.quiz_outlined, "$quizCount QCMs"),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.course.keywords.contains('EXTERNAL'))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: "Supprimer ce cours local",
                    onPressed: _deleteCourse,
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Fermer", style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5EBDA),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text("Démarrer le cours",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        final prov = context.read<CoursesProvider>();
                        if (widget.course.chapters.isNotEmpty) {
                          prov.selectChapter(
                            widget.course.id,
                            widget.course.chapters.first.id,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFF5EBDA)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 11)),
        ],
      ),
    );
  }
}
