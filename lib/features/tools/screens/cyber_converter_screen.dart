// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class CyberConverterScreen extends StatefulWidget {
  const CyberConverterScreen({super.key});

  @override
  State<CyberConverterScreen> createState() => _CyberConverterScreenState();
}

class _CyberConverterScreenState extends State<CyberConverterScreen> {
  final _inputController = TextEditingController();
  
  String _asciiOutput = '';
  String _hexOutput = '';
  String _binOutput = '';
  String _base64Output = '';
  String _urlOutput = '';
  
  String _currentFormat = 'ASCII';
  final List<String> _formats = ['ASCII', 'HEX', 'BINAIRE', 'BASE64', 'URL'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Cyber Convertisseur',
        showBackButton: true,
        actions: [],
      );
    });
    _inputController.text = 'TutoDeCode.org';
    _convert();
  }

  void _convert() {
    final input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _asciiOutput = '';
        _hexOutput = '';
        _binOutput = '';
        _base64Output = '';
        _urlOutput = '';
      });
      return;
    }

    List<int> bytes = [];

    try {
      // Decode input to bytes based on selected format
      if (_currentFormat == 'ASCII') {
        bytes = utf8.encode(input);
      } else if (_currentFormat == 'HEX') {
        String cleanHex = input.replaceAll(' ', '').replaceAll('0x', '');
        if (cleanHex.length % 2 != 0) cleanHex = '0$cleanHex';
        for (int i = 0; i < cleanHex.length; i += 2) {
          bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
        }
      } else if (_currentFormat == 'BINAIRE') {
        String cleanBin = input.replaceAll(' ', '');
        for (int i = 0; i < cleanBin.length; i += 8) {
          int end = i + 8;
          if (end > cleanBin.length) end = cleanBin.length;
          bytes.add(int.parse(cleanBin.substring(i, end), radix: 2));
        }
      } else if (_currentFormat == 'BASE64') {
        bytes = base64.decode(input.trim());
      } else if (_currentFormat == 'URL') {
        String decoded = Uri.decodeComponent(input);
        bytes = utf8.encode(decoded);
      }

      // Encode bytes to all formats
      setState(() {
        _asciiOutput = utf8.decode(bytes, allowMalformed: true);
        _hexOutput = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        _binOutput = bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join(' ');
        _base64Output = base64.encode(bytes);
        _urlOutput = Uri.encodeComponent(_asciiOutput);
      });
    } catch (e) {
      setState(() {
        _asciiOutput = 'Erreur de décodage';
        _hexOutput = 'Erreur de décodage';
        _binOutput = 'Erreur de décodage';
        _base64Output = 'Erreur de décodage';
        _urlOutput = 'Erreur de décodage';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          const TdcToolHeader(
            title: 'Cyber Convertisseur',
            description: 'Convertissez instantanément vos données entre ASCII, Hex, Base64, Binaire et URL.',
            howToUse: 'Sélectionnez le format de votre donnée d\'entrée via les boutons "FORMAT D\'ENTRÉE". Saisissez ensuite vos données dans le champ texte. Le convertisseur traduira automatiquement et en temps réel cette donnée dans tous les autres formats (Hexadécimal, Binaire, Base64, URL). Cliquez sur l\'icône de copie pour récupérer le résultat.',
          ),
          _buildInputSection(),
          const SizedBox(height: 24),
          _buildOutputCard('ASCII (Texte Clair)', _asciiOutput),
          const SizedBox(height: 16),
          _buildOutputCard('Hexadécimal', _hexOutput),
          const SizedBox(height: 16),
          _buildOutputCard('Binaire', _binOutput),
          const SizedBox(height: 16),
          _buildOutputCard('Base64', _base64Output),
          const SizedBox(height: 16),
          _buildOutputCard('URL-Encoded', _urlOutput),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("FORMAT D'ENTRÉE", style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildFormatSelector(),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inputController,
            onChanged: (_) => _convert(),
            maxLines: 4,
            style: const TextStyle(color: TdcColors.textPrimary, fontSize: 16, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: 'Collez vos données ici...',
              filled: true,
              fillColor: TdcColors.bg,
              border: OutlineInputBorder(borderRadius: TdcRadius.sm, borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: TdcRadius.sm,
        border: Border.all(color: TdcColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentFormat,
          dropdownColor: TdcColors.surface,
          items: _formats.map((String format) {
            return DropdownMenuItem<String>(
              value: format,
              child: Text(format, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _currentFormat = v);
              _convert();
            }
          },
        ),
      ),
    );
  }

  Widget _buildOutputCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: TdcColors.textMuted),
                onPressed: () {
                  // Copier dans le presse-papier
                },
                tooltip: 'Copier',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: TextStyle(
              color: value == 'Erreur de décodage' ? TdcColors.danger : TdcColors.textPrimary,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
