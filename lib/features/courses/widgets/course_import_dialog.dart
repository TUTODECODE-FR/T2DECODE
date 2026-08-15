// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';
import 'package:tutodecode/core/services/tdc_signature_service.dart';
import 'package:tutodecode/core/services/module_service.dart';
import 'package:tutodecode/features/courses/data/course_repository.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class CourseImportDialog extends StatefulWidget {
  const CourseImportDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CourseImportDialog(),
    );
  }

  @override
  State<CourseImportDialog> createState() => _CourseImportDialogState();
}

class _CourseImportDialogState extends State<CourseImportDialog> {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _pickAndImportFile() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tdc', 'json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final file = result.files.first;
      String content = '';
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }

      if (content.trim().isEmpty) {
        throw Exception("Le fichier sélectionné est vide.");
      }

      await _processImport(file.name, content);
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur d'importation : ${e.toString().replaceAll('Exception: ', '')}";
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImport(String fileName, String content) async {
    try {
      Map<String, dynamic> courseMap;
      if (fileName.endsWith('.tdc') || content.contains('course ')) {
        courseMap = TDCParser.parseCourse(content);
      } else {
        courseMap = json.decode(content);
      }

      if (courseMap['id'] == null || courseMap['title'] == null) {
        throw Exception("Format de cours invalide (id ou titre manquant).");
      }

      final category = (courseMap['category'] ?? '').toString().trim();
      final isCustomCat = category.isNotEmpty &&
          !Course.standardCategories.contains(category.toLowerCase());

      if (isCustomCat && mounted) {
        final addCat = await _promptCustomCategory(category);
        if (addCat == true) {
          // Enregistrer la catégorie custom si souhaité
          final prefs = await SharedPreferences.getInstance();
          final existing = prefs.getStringList('tdc_custom_categories') ?? [];
          if (!existing.contains(category)) {
            existing.add(category);
            await prefs.setStringList('tdc_custom_categories', existing);
          }
        }
      }

      final moduleService = ModuleService();
      final savedCourse = await moduleService.saveImportedCourse(fileName, content);

      if (savedCourse != null && mounted) {
        final prov = context.read<CoursesProvider>();
        await prov.reload();

        setState(() {
          _isProcessing = false;
          _successMessage = "Cours « ${savedCourse.title} » importé avec succès !";
        });
      } else {
        throw Exception("Impossible de sauvegarder le module dans l'espace local.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Parsing/Validation échoué : $e";
        _isProcessing = false;
      });
    }
  }

  Future<bool?> _promptCustomCategory(String catName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF27272A)),
        ),
        title: Row(
          children: [
            const Icon(Icons.folder_special_outlined, color: Color(0xFFF5EBDA), size: 22),
            const SizedBox(width: 10),
            const Text("Nouvelle catégorie détectée",
                style: TextStyle(color: Color(0xFFF5EBDA), fontSize: 16)),
          ],
        ),
        content: Text(
          "Ce cours contient la catégorie personnalisée « $catName ».\n\nSouhaitez-vous importer cette catégorie dans votre registre local pour le filtrage du catalogue ?",
          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Ignorer", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5EBDA),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Oui, importer la catégorie",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EBDA).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_open_outlined,
                      color: Color(0xFFF5EBDA), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Importer un cours (.TDC)",
                        style: TextStyle(
                          color: Color(0xFFF5EBDA),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Sélectionnez un fichier .tdc ou .json souverain",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _isProcessing ? null : _pickAndImportFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3F3F46),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: const Color(0xFFF5EBDA).withOpacity(0.8),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Cliquez pour parcourir votre ordinateur",
                      style: TextStyle(
                        color: Color(0xFFF5EBDA),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Formats pris en charge : .tdc (TUTODECODE Script) & .json",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFF5EBDA),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("Parsing et vérification de la signature Ed25519...",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _successMessage != null ? "Fermer" : "Annuler",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
