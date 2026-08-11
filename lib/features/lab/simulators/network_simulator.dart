// ignore_for_file: unused_element, deprecated_member_use
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Network Simulator - Interface Épurée & Minimaliste
// ============================================================
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import '../widgets/simulator_ai_assistant.dart';

class NetworkSimulator extends StatefulWidget {
  const NetworkSimulator({super.key});

  @override
  State<NetworkSimulator> createState() => _NetworkSimulatorState();
}

class _NetworkSimulatorState extends State<NetworkSimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.100');

  bool _isScanning = false;
  bool _isPinging = false;
  String _selectedDeviceIp = '192.168.1.1';

  List<NetworkDevice> _discoveredDevices = [];
  final List<PingResult> _pingResults = [];
  final List<CapturedPacket> _capturedPackets = [];
  CapturedPacket? _selectedPacket;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _discoveredDevices = [
      NetworkDevice(ip: '192.168.1.1', hostname: 'gateway.router', type: 'Passerelle', os: 'OpenWrt', openPorts: [22, 80, 443]),
      NetworkDevice(ip: '192.168.1.10', hostname: 'firewall-shield', type: 'Pare-feu', os: 'pfSense', openPorts: [22, 443]),
      NetworkDevice(ip: '192.168.1.100', hostname: 'web-server-prod', type: 'Serveur Web', os: 'Ubuntu', openPorts: [80, 443]),
      NetworkDevice(ip: '192.168.1.105', hostname: 'db-master-sec', type: 'Base de Données', os: 'Debian', openPorts: [5432]),
      NetworkDevice(ip: '192.168.1.210', hostname: 'workstation-dev', type: 'Poste Client', os: 'Linux', openPorts: [22]),
    ];

    _capturedPackets.addAll([
      CapturedPacket(id: 1, time: '0.0012', source: '192.168.1.210', destination: '192.168.1.1', protocol: 'DNS', info: 'Query A tutodecode.org', payload: '0000  00 0c 29 aa bb cc 52 54  00 12 34 56  ..)...RT..4V'),
      CapturedPacket(id: 2, time: '0.0035', source: '192.168.1.1', destination: '192.168.1.210', protocol: 'DNS', info: 'Response A 192.168.1.100', payload: '0000  52 54 00 12 34 56 00 0c  29 aa bb cc  RT..4V..)...'),
      CapturedPacket(id: 3, time: '0.0080', source: '192.168.1.210', destination: '192.168.1.100', protocol: 'TCP', info: '54322 → 80 [SYN]', payload: '0000  52 54 00 12 34 56 00 0c  29 aa bb cc  RT..4V..)...'),
      CapturedPacket(id: 4, time: '0.0125', source: '192.168.1.100', destination: '192.168.1.210', protocol: 'HTTP', info: 'POST /api/login HTTP/1.1', payload: 'POST /api/login HTTP/1.1\r\nHost: tutodecode.org\r\n{"user":"admin","pass":"S3cur3!"}'),
    ]);
    _selectedPacket = _capturedPackets[3];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TdcColors.bg,
      child: Column(
        children: [
          // En-tête épuré
          _buildCleanHeader(),

          // Topologie minimaliste
          _buildMinimalTopology(),

          // Onglets simples (3 onglets)
          Container(
            height: 40,
            color: TdcColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: TdcColors.accent,
              labelColor: TdcColors.accent,
              unselectedLabelColor: TdcColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
              tabs: const [
                Tab(text: 'CARTE RÉSEAU & SCAN'),
                Tab(text: 'INSPECTEUR PAQUETS'),
                Tab(text: 'ASSISTANT IA'),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNetworkScanView(),
                _buildSnifferView(),
                const SimulatorAIAssistant(
                  topic: 'Réseau épuré',
                  accentColor: TdcColors.network,
                  systemPrompt: 'Tu es Ghost. Réponds en 2 phrases max, ultra clair et concis.',
                  suggestedQuestions: [
                    'Comment marche le réseau en 1 phrase ?',
                    'Différence entre IP et MAC ?',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: TdcColors.surface,
        border: Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, color: TdcColors.accent, size: 20),
          const SizedBox(width: 10),
          const Text(
            'NETKIT — TOPOLOGIE & ANLYSE',
            style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _runScan,
            icon: _isScanning
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.radar, size: 16, color: Colors.black),
            label: Text(_isScanning ? 'SCAN...' : 'LANCER SCAN', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: TdcColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTopology() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFF07070A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _discoveredDevices.map((device) {
            final isSelected = device.ip == _selectedDeviceIp;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDeviceIp = device.ip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? TdcColors.accent.withOpacity(0.12) : TdcColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? TdcColors.accent : TdcColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(_getDeviceIcon(device.type), color: isSelected ? TdcColors.accent : TdcColors.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.hostname, style: TextStyle(color: isSelected ? TdcColors.textPrimary : TdcColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(device.ip, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: TdcColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Passerelle': return Icons.router_outlined;
      case 'Pare-feu': return Icons.shield_outlined;
      case 'Serveur Web': return Icons.dns_outlined;
      case 'Base de Données': return Icons.storage_outlined;
      default: return Icons.computer_outlined;
    }
  }

  Widget _buildNetworkScanView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ÉQUIPEMENTS RÉSEAU (${_discoveredDevices.length})', style: const TextStyle(color: TdcColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            Text('IP Locale : 192.168.1.210', style: const TextStyle(fontFamily: 'monospace', color: TdcColors.accent, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),
        ..._discoveredDevices.map((d) => _buildSimpleDeviceRow(d)),
      ],
    );
  }

  Widget _buildSimpleDeviceRow(NetworkDevice device) {
    final isSelected = device.ip == _selectedDeviceIp;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? TdcColors.accent.withOpacity(0.5) : TdcColors.border),
      ),
      child: Row(
        children: [
          Icon(_getDeviceIcon(device.type), color: TdcColors.accent, size: 18),
          const SizedBox(width: 12),
          Text(device.hostname, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Text(device.ip, style: const TextStyle(fontFamily: 'monospace', color: TdcColors.textMuted, fontSize: 11)),
          const Spacer(),
          Wrap(
            spacing: 4,
            children: device.openPorts.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
              child: Text(':$p', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: TdcColors.accent)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _runScan() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isScanning = false);
  }

  Widget _buildSnifferView() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: ListView.builder(
            itemCount: _capturedPackets.length,
            itemBuilder: (context, i) {
              final p = _capturedPackets[i];
              final isSel = _selectedPacket?.id == p.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedPacket = p),
                child: Container(
                  color: isSel ? TdcColors.accent.withOpacity(0.1) : (i.isEven ? const Color(0xFF09090D) : Colors.black),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text(p.protocol, style: TextStyle(color: p.protocol == 'HTTP' ? Colors.redAccent : TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 11))),
                      SizedBox(width: 100, child: Text(p.source, style: const TextStyle(fontFamily: 'monospace', color: TdcColors.textMuted, fontSize: 11))),
                      const Icon(Icons.arrow_right_alt, color: TdcColors.textMuted, size: 14),
                      SizedBox(width: 100, child: Text(p.destination, style: const TextStyle(fontFamily: 'monospace', color: TdcColors.textMuted, fontSize: 11))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.info, style: const TextStyle(fontFamily: 'monospace', color: TdcColors.textPrimary, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedPacket != null)
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF050508),
            child: SingleChildScrollView(
              child: Text(_selectedPacket!.payload, style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 11)),
            ),
          ),
      ],
    );
  }
}

class NetworkDevice {
  final String ip;
  final String hostname;
  final String type;
  final String os;
  final List<int> openPorts;

  NetworkDevice({required this.ip, required this.hostname, required this.type, required this.os, required this.openPorts});
}

class PingResult {
  final String message;
  PingResult({required this.message});
}

class CapturedPacket {
  final int id;
  final String time;
  final String source;
  final String destination;
  final String protocol;
  final String info;
  final String payload;

  CapturedPacket({required this.id, required this.time, required this.source, required this.destination, required this.protocol, required this.info, required this.payload});
}
