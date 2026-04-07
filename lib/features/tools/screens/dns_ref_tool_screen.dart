import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class DnsRefToolScreen extends StatefulWidget {
  const DnsRefToolScreen({super.key});

  @override
  State<DnsRefToolScreen> createState() => _DnsRefToolScreenState();
}

class _DnsRefToolScreenState extends State<DnsRefToolScreen> {
  final List<DnsRecordType> _records = [
    DnsRecordType('A', 'Address', 'Pointe un nom de domaine vers une adresse IPv4.', 'example.com -> 93.184.216.34', Colors.blue),
    DnsRecordType('AAAA', 'IPv6 Address', 'Pointe un nom de domaine vers une adresse IPv6.', 'example.com -> 2606:2800:220:1:248:1893:25c8:1946', Colors.indigo),
    DnsRecordType('CNAME', 'Canonical Name', 'Alias d\'un nom vers un autre (nom canonique).', 'www.example.com -> example.com', Colors.purple),
    DnsRecordType('MX', 'Mail Exchange', 'Désigne les serveurs de messagerie pour le domaine.', 'example.com -> mail.example.com (Priorité 10)', Colors.orange),
    DnsRecordType('TXT', 'Text', 'Contient des infos textuelles (SPF, DKIM, Validation).', 'v=spf1 include:_spf.google.com ~all', Colors.green),
    DnsRecordType('NS', 'Name Server', 'Définit les serveurs DNS autoritaires pour la zone.', 'ns1.provider.com, ns2.provider.com', Colors.red),
    DnsRecordType('PTR', 'Pointer', 'Utilisé pour la résolution inverse (IP vers Nom).', '34.216.184.93.in-addr.arpa -> example.com', Colors.teal),
    DnsRecordType('SRV', 'Service', 'Définit l\'emplacement de services spécifiques (SIP, LDAP).', '_sip._tcp.example.com -> 10 60 5060 sipserver.example.com', Colors.pink),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Référence DNS',
        showBackButton: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enregistrements DNS (RR)',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guide rapide des types d\'enregistrements de ressources DNS courants.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.2,
              ),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return _buildRecordCard(record);
              },
            ),
          ),
          _buildInfoFooter(),
        ],
      ),
    );
  }

  Widget _buildRecordCard(DnsRecordType record) {
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: record.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: record.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  record.type,
                  style: TextStyle(color: record.color, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                record.fullName,
                style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          Text(record.desc, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: TdcColors.bg,
              borderRadius: TdcRadius.sm,
              border: Border.all(color: TdcColors.border),
            ),
            child: Text(
              record.example,
              style: const TextStyle(color: TdcColors.success, fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: TdcRadius.md,
      ),
      child: const Row(
        children: [
          Icon(Icons.timer, color: TdcColors.textMuted, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comprendre le TTL (Time To Live)', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('C\'est la durée pendant laquelle un enregistrement est conservé en cache par les résolveurs. Un TTL bas (300s) permet des changements rapides, un TTL haut (86400s) réduit la charge serveur.',
                  style: TextStyle(color: TdcColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DnsRecordType {
  final String type, fullName, desc, example;
  final Color color;
  DnsRecordType(this.type, this.fullName, this.desc, this.example, this.color);
}
