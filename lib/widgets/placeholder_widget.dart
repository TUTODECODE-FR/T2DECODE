// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';

class PlaceholderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const PlaceholderCard({required this.title, this.subtitle = ''});
  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text(title), subtitle: Text(subtitle)));
  }
}
