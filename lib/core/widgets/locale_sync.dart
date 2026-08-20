// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';

/// Syncs CoursesProvider locale only when the active language actually changes.
class LocaleSync extends StatefulWidget {
  const LocaleSync({super.key, required this.child});

  final Widget child;

  @override
  State<LocaleSync> createState() => _LocaleSyncState();
}

class _LocaleSyncState extends State<LocaleSync> {
  String? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale.languageCode;
    if (_lastLocale == locale) return;
    _lastLocale = locale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CoursesProvider>().updateLocale(locale);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
