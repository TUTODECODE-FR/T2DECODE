import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Référence Matérielle',
        showBackButton: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Ports: Bureau à Distance & Admin',
              [
                _buildRefRow('22 (TCP)', 'SSH (Linux/Mac Remote Shell)', security: 'safe'),
                _buildRefRow('3389 (TCP)', 'RDP (Windows Remote Desktop)', security: 'critical'),
                _buildRefRow('5060/5061 (TCP/UDP)', 'SIP (VoIP Signaling)', security: 'risk'),
                _buildRefRow('5900 (TCP)', 'VNC (Virtual Network Computing)', security: 'risk'),
                _buildRefRow('5985 (TCP)', 'WinRM (PowerShell Remote HTTP)', security: 'risk'),
                _buildRefRow('5986 (TCP)', 'WinRM (PowerShell Remote HTTPS)', security: 'safe'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Ports: Web & Mail',
              [
                _buildRefRow('25 (TCP)', 'SMTP (Mail Outbound)', security: 'risk'),
                _buildRefRow('80 (TCP)', 'HTTP (Web non sécurisé)', security: 'risk'),
                _buildRefRow('110 (TCP)', 'POP3 (E-mail non sécurisé)', security: 'risk'),
                _buildRefRow('143 (TCP)', 'IMAP (E-mail Sync non sécurisé)', security: 'risk'),
                _buildRefRow('443 (TCP)', 'HTTPS (Web sécurisé SSL/TLS)', security: 'safe'),
                _buildRefRow('587 (TCP)', 'SMTP (Secure Inbound)', security: 'safe'),
                _buildRefRow('993 (TCP)', 'IMAP SSL (Synchronisation sécurisée)', security: 'safe'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Ports: Fichiers & Base de données',
              [
                _buildRefRow('21 (TCP)', 'FTP (Transfert non sécurisé)', security: 'critical'),
                _buildRefRow('445 (TCP)', 'SMB (Partage Windows/Samba - VULNÉRABLE)', security: 'critical'),
                _buildRefRow('515 (TCP)', 'LPD/LPR (Line Printer Daemon)', security: 'risk'),
                _buildRefRow('1433 (TCP)', 'MS SQL Server', security: 'risk'),
                _buildRefRow('1521 (TCP)', 'Oracle Database Default Port', security: 'risk'),
                _buildRefRow('3306 (TCP)', 'MySQL / MariaDB', security: 'risk'),
                _buildRefRow('5432 (TCP)', 'PostgreSQL', security: 'safe'),
                _buildRefRow('6379 (TCP)', 'Redis Key-Value Store', security: 'risk'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Ports: Infrastructure (AD/DNS/DHCP/IoT)',
              [
                _buildRefRow('53 (UDP/TCP)', 'DNS (Domain Name System)', security: 'safe'),
                _buildRefRow('67/68 (UDP)', 'DHCP (Server/Client)', security: 'safe'),
                _buildRefRow('88 (TCP)', 'Kerberos (AD Auth)', security: 'safe'),
                _buildRefRow('123 (UDP)', 'NTP (Time Sync)', security: 'safe'),
                _buildRefRow('161/162 (UDP)', 'SNMP (Simple Network Management Protocol)', security: 'risk'),
                _buildRefRow('389 (TCP)', 'LDAP (Active Directory)', security: 'risk'),
                _buildRefRow('636 (TCP)', 'LDAPS (LDAP Over SSL)', security: 'safe'),
                _buildRefRow('3478 (UDP)', 'STUN (NAT Traversal)', security: 'safe'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Stockage : SSD & NVMe (Performance)',
              [
                _buildRefRow('SATA III SSD', 'Jusqu\'à 560 Mo/s - Standard pour upgrade vieux PC'),
                _buildRefRow('NVMe Gen 3', 'Jusqu\'à 3 500 Mo/s - Standard actuel (M.2)'),
                _buildRefRow('NVMe Gen 4', 'Jusqu\'à 7 500 Mo/s - Pro / Gaming (PS5, PC récents)'),
                _buildRefRow('NVMe Gen 5', 'Jusqu\'à 12 000 Mo/s - Futur / Serveurs haute perf'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'RAM : Évolution & Fréquences',
              [
                _buildRefRow('DDR3', '800 - 2133 MHz (Vieux laptops/tours)'),
                _buildRefRow('DDR4', '2133 - 4800 MHz (Standard actuel)'),
                _buildRefRow('DDR5', '4800 - 8400+ MHz (Nouvelle génération Intel/AMD)'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'BIOS / UEFI : Codes de Bips (AMI/Phoenix)',
              [
                _buildRefRow('1 Bip court', 'Boot normal - Tout va bien'),
                _buildRefRow('2 Bips courts', 'Erreur de configuration CMOS'),
                _buildRefRow('1 Bip long, 2 ou 3 courts', 'Erreur Carte Graphique (GPU)'),
                _buildRefRow('Bips répétitifs (longs)', 'Erreur de Mémoire Vive (RAM)'),
                _buildRefRow('Bips répétitifs (courts)', 'Erreur d\'alimentation'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: TdcColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: TdcColors.surface,
            borderRadius: TdcRadius.md,
            border: Border.all(color: TdcColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildRefRow(String label, String value, {String? security}) {
    Color securityColor = TdcColors.textMuted;
    String securityText = "";
    
    if (security == 'safe') { securityColor = TdcColors.success; securityText = "SÉCURISÉ"; }
    else if (security == 'risk') { securityColor = TdcColors.warning; securityText = "À RISQUE"; }
    else if (security == 'critical') { securityColor = TdcColors.danger; securityText = "CRITIQUE"; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (security != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: securityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: securityColor.withOpacity(0.3)),
              ),
              child: Text(
                securityText,
                style: TextStyle(color: securityColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
// Fix container border logic for write_to_file
