import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/services/phantom_cache_service.dart';
import 'package:tutodecode/core/security/phantom_trust_validator.dart';
import 'package:path/path.dart' as p;

class PhantomDiagnosticScreen extends StatefulWidget {
  const PhantomDiagnosticScreen({super.key});

  @override
  State<PhantomDiagnosticScreen> createState() => _PhantomDiagnosticScreenState();
}

class _PhantomDiagnosticScreenState extends State<PhantomDiagnosticScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  final PhantomCacheService _phantomService = PhantomCacheService(PhantomTrustValidator());
  
  bool _isLoading = false;
  String _statusLog = "T2C-Phantom Diagnostic Console\nAppuyez sur 'Connecter' pour analyser le cache local.\n";
  bool _cacheExists = false;

  @override
  void initState() {
    super.initState();
    _checkCacheDirectory();
  }

  Future<void> _checkCacheDirectory() async {
    final dir = Directory(_phantomService.defaultCachePath);
    final exists = await dir.exists();
    setState(() {
      _cacheExists = exists;
      if (exists) {
        _log("Vérification: Répertoire cache trouvé à ${_phantomService.defaultCachePath}");
      } else {
        _log("Vérification: Aucun répertoire cache trouvé à ${_phantomService.defaultCachePath}. T2C-Phantom est-il installé et exécuté ?");
      }
    });
  }

  void _log(String message) {
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TdcColors.bg,
      appBar: AppBar(
        title: const Text('Phantom Diagnostic', style: TextStyle(fontFamily: 'Courier', color: TdcColors.accent)),
        backgroundColor: TdcColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: TdcColors.accent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _cacheExists ? Icons.check_circle : Icons.error,
                  color: _cacheExists ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Chemin du cache : ${_phantomService.defaultCachePath}",
                    style: const TextStyle(color: TdcColors.textSecondary, fontFamily: 'Courier'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passphraseController,
              obscureText: true,
              style: const TextStyle(color: TdcColors.accent, fontFamily: 'Courier'),
              decoration: InputDecoration(
                labelText: 'Clé de coffre / Passphrase Phantom',
                labelStyle: const TextStyle(color: TdcColors.textSecondary),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: TdcColors.surface),
                ),
                focusedBorder: const OutlineInputBorder(
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
      ),
    );
  }
}
