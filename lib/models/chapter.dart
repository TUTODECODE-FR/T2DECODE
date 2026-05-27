// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
class Chapter {
  final String id;
  final String title;
  final String? description;
  final String? category;

  Chapter({required this.id, required this.title, this.description, this.category});

  factory Chapter.fromMap(Map<String, dynamic> m) => Chapter(
    id: m['id'],
    title: m['title'],
    description: m['description'],
    category: m['category'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
  };
}
