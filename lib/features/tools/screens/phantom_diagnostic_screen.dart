import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/services/phantom_cache_service.dart';
import 'package:tutodecode/core/security/phantom_trust_validator.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:path/path.dart' as p;

class PhantomDiagnosticScreen extends StatefulWidget {
  const PhantomDiagnosticScreen({super.key});

  @override
  State<PhantomDiagnosticScreen> createState() => _PhantomDiagnosticScreenState();
}

class _PhantomDiagnosticScreenState extends State<PhantomDiagnosticScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  
  bool _isLoading = false;
  String _statusLog = "T2C-Phantom Diagnostic Console\nAppuyez sur 'Connecter' pour analyser le cache local.\n";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'T2C-Phantom',
        showBackButton: false,
        actions: [],
      );
    });
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _statusLog += "\n> $message";
    });
  }

  Future<void> _connectAndLoad() async {
    final passphrase = _passphraseController.text;
    if (passphrase.isEmpty) {
      _log("Erreur: Le mot de passe ou la clé de coffre est requis.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _log("Tentative de déchiffrement du cache...");
    try {
      final coursesProvider = context.read<CoursesProvider>();
      await coursesProvider.loadFromPhantomCache(passphrase);
      
      if (coursesProvider.errorMessage == null) {
        _log("Succès: Cache déchiffré et cours chargés avec succès (Zero-Trust validé).");
      } else {
        _log("Échec: ${coursesProvider.errorMessage}");
      }
    } catch (e) {
      _log("Erreur critique: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _editPath(BuildContext context, PhantomProvider phantom) async {
    final TextEditingController pathCtrl = TextEditingController(text: phantom.activePath);
    final newPath = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Modifier le chemin du cache', style: TextStyle(color: TdcColors.accent, fontFamily: 'Courier')),
        content: TextField(
          controller: pathCtrl,
          style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'Courier'),
          decoration: InputDecoration(
            labelText: 'Chemin absolu',
            labelStyle: const TextStyle(color: TdcColors.textSecondary),
            hintText: phantom.defaultPath,
            hintStyle: const TextStyle(color: TdcColors.textMuted),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: TdcColors.border)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: TdcColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER', style: TextStyle(color: TdcColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('PAR DÉFAUT', style: TextStyle(color: TdcColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, pathCtrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent, foregroundColor: TdcColors.bg),
            child: const Text('SAUVEGARDER'),
          ),
        ],
      ),
    );

    if (newPath != null) {
      await phantom.updateCustomPath(newPath.isEmpty ? null : newPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phantom = context.watch<PhantomProvider>();
    final cacheExists = phantom.isRunning;
    final path = phantom.activePath;

    return Container(
      color: TdcColors.bg,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                cacheExists ? Icons.check_circle : Icons.error,
                color: cacheExists ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cacheExists 
                    ? "T2C-Phantom est en cours d'exécution (Cache: $path)"
                    : "Phantom non détecté (Cache introuvable à $path)",
                  style: const TextStyle(color: TdcColors.textSecondary, fontFamily: 'Courier'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                color: TdcColors.accent,
                onPressed: () => _editPath(context, phantom),
                tooltip: 'Modifier le chemin',
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passphraseController,
            obscureText: true,
            style: const TextStyle(color: TdcColors.accent, fontFamily: 'Courier'),
            decoration: const InputDecoration(
              labelText: 'Clé de coffre / Passphrase Phantom',
              labelStyle: TextStyle(color: TdcColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: TdcColors.surface),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: TdcColors.accent),
              ),
              filled: true,
              fillColor: TdcColors.surface,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _connectAndLoad,
            style: ElevatedButton.styleFrom(
              backgroundColor: TdcColors.accent,
              foregroundColor: TdcColors.bg,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: TdcColors.bg, strokeWidth: 2))
              : const Text("DÉCHIFFRER & SYNCHRONISER", style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TdcColors.surface),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _statusLog,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.greenAccent,
                    fontSize: 13,
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
