import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class PortRefToolScreen extends StatefulWidget {
  const PortRefToolScreen({super.key});

  @override
  State<PortRefToolScreen> createState() => _PortRefToolScreenState();
}

class _PortRefToolScreenState extends State<PortRefToolScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  final List<Map<String, String>> _ports = [
    {'port': '20', 'protocol': 'TCP', 'service': 'FTP Data', 'type': 'File Transfer'},
    {'port': '21', 'protocol': 'TCP', 'service': 'FTP Control', 'type': 'File Transfer'},
    {'port': '22', 'protocol': 'TCP', 'service': 'SSH', 'type': 'Admin/Secure'},
    {'port': '23', 'protocol': 'TCP', 'service': 'Telnet', 'type': 'Admin (DANGEREUX)'},
    {'port': '25', 'protocol': 'TCP', 'service': 'SMTP', 'type': 'Email Send'},
    {'port': '53', 'protocol': 'UDP/TCP', 'service': 'DNS', 'type': 'Name Resolution'},
    {'port': '67', 'protocol': 'UDP', 'service': 'DHCP Server', 'type': 'IP Assign'},
    {'port': '68', 'protocol': 'UDP', 'service': 'DHCP Client', 'type': 'IP Assign'},
    {'port': '80', 'protocol': 'TCP', 'service': 'HTTP', 'type': 'Web (Clear)'},
    {'port': '110', 'protocol': 'TCP', 'service': 'POP3', 'type': 'Email Receive'},
    {'port': '123', 'protocol': 'UDP', 'service': 'NTP', 'type': 'Time Sync'},
    {'port': '143', 'protocol': 'TCP', 'service': 'IMAP', 'type': 'Email Receive'},
    {'port': '161', 'protocol': 'UDP', 'service': 'SNMP', 'type': 'Network Mgmt'},
    {'port': '389', 'protocol': 'TCP/UDP', 'service': 'LDAP', 'type': 'Directory'},
    {'port': '443', 'protocol': 'TCP', 'service': 'HTTPS', 'type': 'Web (Secure)'},
    {'port': '445', 'protocol': 'TCP', 'service': 'SMB', 'type': 'File Sharing'},
    {'port': '514', 'protocol': 'UDP', 'service': 'Syslog', 'type': 'Logging'},
    {'port': '587', 'protocol': 'TCP', 'service': 'SMTP (TLS)', 'type': 'Email Send'},
    {'port': '636', 'protocol': 'TCP', 'service': 'LDAPS', 'type': 'Directory (Secure)'},
    {'port': '993', 'protocol': 'TCP', 'service': 'IMAPS', 'type': 'Email Receive'},
    {'port': '995', 'protocol': 'TCP', 'service': 'POP3S', 'type': 'Email Receive'},
    {'port': '1433', 'protocol': 'TCP', 'service': 'MSSQL', 'type': 'Database'},
    {'port': '3306', 'protocol': 'TCP', 'service': 'MySQL/MariaDB', 'type': 'Database'},
    {'port': '3389', 'protocol': 'TCP', 'service': 'RDP', 'type': 'Remote Desktop'},
    {'port': '5432', 'protocol': 'TCP', 'service': 'PostgreSQL', 'type': 'Database'},
    {'port': '8080', 'protocol': 'TCP', 'service': 'HTTP Proxy', 'type': 'Web (Alt)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Référence des Ports',
        showBackButton: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _ports.where((p) => p['port']!.contains(_search) || p['service']!.toLowerCase().contains(_search.toLowerCase()) || p['type']!.toLowerCase().contains(_search.toLowerCase())).toList();

    return TdcPageWrapper(
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(labelText: 'Rechercher port, service ou catégorie', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = filtered[i];
                final isUnsafe = p['type']!.contains('DANGEREUX');
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: TdcColors.surfaceAlt, borderRadius: BorderRadius.circular(4)),
                        child: Text(p['port']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TdcColors.accent)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['service']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${p['protocol']} | ${p['type']}', style: TextStyle(color: isUnsafe ? Colors.red : TdcColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
