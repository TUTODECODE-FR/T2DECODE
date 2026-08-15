// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class TDCCommunityEntry {
  final String id;
  final String title;
  final String description;
  final String author;
  final String authorKey;
  final String category;
  final String level;
  final String sha256;
  final String url;
  final String signature;
  final String tdcContent;

  const TDCCommunityEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.authorKey,
    required this.category,
    required this.level,
    required this.sha256,
    required this.url,
    required this.signature,
    required this.tdcContent,
  });

  factory TDCCommunityEntry.fromJson(Map<String, dynamic> json) => TDCCommunityEntry(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        author: json['author'] ?? 'Communauté',
        authorKey: json['author-key'] ?? '',
        category: json['category'] ?? 'linux',
        level: json['level'] ?? 'beginner',
        sha256: json['sha256'] ?? '',
        url: json['url'] ?? '',
        signature: json['signature'] ?? '',
        tdcContent: json['content'] ?? '',
      );
}

class TDCCommunityService {
  static const String manifestUrl = 'https://tutodecode.gitlab.io/tdc-community/manifest.json';
  static const String mrTemplateUrl = 'https://gitlab.com/tutodecode/tdc-community/-/merge_requests/new';

  static final List<TDCCommunityEntry> mockCommunityCourses = [
    TDCCommunityEntry(
      id: 'ansible-automation',
      title: 'Ansible : Automatisation d\'Infrastructure',
      description: 'Déployez et configurez vos parcs de serveurs en quelques playbooks YAML souverains.',
      author: 'Marc DevOps',
      authorKey: 'FP-a89b2c41',
      category: 'cloud',
      level: 'intermediate',
      sha256: '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
      url: 'https://tutodecode.gitlab.io/tdc-community/courses/ansible.tdc',
      signature: 'MEQCID1K2L3M...',
      tdcContent: '''course "ansible-automation" {
  title: "Ansible : Automatisation d'Infrastructure"
  description: "Déployez et configurez vos parcs de serveurs en quelques playbooks YAML souverains."
  category: cloud
  level: intermediate
  duration: 3h
  icon: Rocket

  module "mod-1" {
    title: "1. Playbooks et Inventaires"
    duration: 30min
    content """
# Introduction à Ansible
Ansible permet l'automatisation sans agent via SSH.
    """
    quiz {
      question "Quel est le protocole utilisé par Ansible pour se connecter aux nœuds Linux ?" {
        options: ["SSH", "Telnet", "RDP", "SNMP"]
        correctAnswer: 0
        explanation: "Ansible est agentless et s'appuie nativement sur OpenSSH."
      }
    }
  }
}''',
    ),
    TDCCommunityEntry(
      id: 'wireshark-deep-dive',
      title: 'Wireshark : Analyse de Paquets Réseau',
      description: 'Inspectez les flux TCP/IP, résolvez les pannes et traquez les anomalies protocolaires.',
      author: 'CyberNet',
      authorKey: 'FP-c741e982',
      category: 'network',
      level: 'advanced',
      sha256: '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8',
      url: 'https://tutodecode.gitlab.io/tdc-community/courses/wireshark.tdc',
      signature: 'MEYCIQD...',
      tdcContent: '''course "wireshark-deep-dive" {
  title: "Wireshark : Analyse de Paquets Réseau"
  description: "Inspectez les flux TCP/IP, résolvez les pannes et traquez les anomalies protocolaires."
  category: network
  level: advanced
  duration: 4h
  icon: Router

  module "mod-1" {
    title: "1. Capture et Filtres d'Affichage"
    duration: 45min
    content """
# Analyse Protocolaires avec Wireshark
Les filtres de capture (BPF) diffèrent des filtres d'affichage (Display Filters).
    """
    quiz {
      question "Quel filtre d'affichage isole le trafic HTTP ?" {
        options: ["http", "tcp.port == 80", "ip.proto == http", "web.traffic"]
        correctAnswer: 0
        explanation: "Le mot-clé simple 'http' filtre immédiatement tous les paquets du protocole HTTP."
      }
    }
  }
}''',
    ),
  ];

  static Future<List<TDCCommunityEntry>> fetchManifest() async {
    try {
      final response = await http.get(Uri.parse(manifestUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['entries'] is List) {
          return (decoded['entries'] as List)
              .map((e) => TDCCommunityEntry.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (_) {}

    // Fallback local hors-ligne fiable
    return mockCommunityCourses;
  }

  static bool verifyChecksum(String content, String expectedSha256) {
    if (expectedSha256.isEmpty) return true;
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes).toString();
    return digest.toLowerCase() == expectedSha256.toLowerCase();
  }
}
