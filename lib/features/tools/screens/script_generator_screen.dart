// ============================================================
// Script Generator Screen — Générateur de scripts et automation
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';

class ScriptGeneratorScreen extends StatefulWidget {
  const ScriptGeneratorScreen({super.key});

  @override
  State<ScriptGeneratorScreen> createState() => _ScriptGeneratorScreenState();
}

class _ScriptGeneratorScreenState extends State<ScriptGeneratorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Generator State
  ScriptCategory _selectedCategory = ScriptCategory.automation;
  ScriptLanguage _selectedLanguage = ScriptLanguage.bash;
  final List<ScriptTemplate> _templates = [];
  final List<GeneratedScript> _generatedScripts = [];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customScriptController = TextEditingController();
  bool _isGenerating = false;
  StreamSubscription<OllamaChunk>? _streamSub;

  // Automation State
  final List<AutomationTask> _tasks = [];
  bool _isRunningAutomation = false;
  Timer? _automationTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeTemplates();
    _loadGeneratedScripts();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _tabController.dispose();
    _descriptionController.dispose();
    _customScriptController.dispose();
    _automationTimer?.cancel();
    super.dispose();
  }

  void _initializeTemplates() {
    _templates.addAll([
      // System Administration
      ScriptTemplate(
        id: 'backup_system',
        name: 'Backup Complet du Système',
        description: 'Crée un backup complet du système avec compression',
        category: ScriptCategory.system,
        language: ScriptLanguage.bash,
        template: r'''#!/bin/bash
# Backup Complet du Système
# Généré par TUTODECODE Script Generator

BACKUP_DIR="/backup/$(date +%Y%m%d)"
SOURCE_DIR="/"
EXCLUDE_FILE="/tmp/backup_exclude.txt"

# Créer le répertoire de backup
mkdir -p "$BACKUP_DIR"

# Créer fichier d'exclusion
cat > "$EXCLUDE_FILE" << EOF
/proc
/sys
/dev
/run
/tmp
/var/tmp
/mnt
/media
/lost+found
EOF

# Démarrer le backup
echo "Début du backup: $(date)"
tar -czf "$BACKUP_DIR/system_backup.tar.gz" \
    --exclude-from="$EXCLUDE_FILE" \
    --one-file-system \
    "$SOURCE_DIR"

# Vérifier le backup
if [ $? -eq 0 ]; then
    echo "Backup terminé avec succès: $(date)"
    echo "Taille: $(du -h "$BACKUP_DIR/system_backup.tar.gz" | cut -f1)"
else
    echo "ERREUR: Le backup a échoué"
    exit 1
fi

# Nettoyer les anciens backups (garder 7 jours)
find /backup -name "system_backup.tar.gz" -mtime +7 -delete

echo "Backup terminé: $(date)"''',
        parameters: [
          ScriptParameter(name: 'BACKUP_DIR', type: 'directory', defaultValue: '/backup'),
          ScriptParameter(name: 'EXCLUDE_DIRS', type: 'text', defaultValue: '/tmp,/var/tmp'),
        ],
      ),

      ScriptTemplate(
        id: 'monitor_system',
        name: 'Monitoring Système',
        description: 'Surveille l\'utilisation CPU, RAM et disque',
        category: ScriptCategory.monitoring,
        language: ScriptLanguage.bash,
        template: r'''#!/bin/bash
# Monitoring Système en Temps Réel
# Généré par TUTODECODE Script Generator

LOG_FILE="/var/log/system_monitor.log"
ALERT_CPU=80
ALERT_MEM=90
ALERT_DISK=85

while true; do
    # Récupérer les métriques
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Logger les métriques
    echo "$TIMESTAMP - CPU: ${CPU_USAGE}% - RAM: ${MEM_USAGE}% - DISK: ${DISK_USAGE}%" >> "$LOG_FILE"
    
    # Vérifier les alertes
    if (( $(echo "$CPU_USAGE > $ALERT_CPU" | bc -l) )); then
        echo "ALERTE CPU: ${CPU_USAGE}% à $TIMESTAMP" >> "$LOG_FILE"
    fi
    
    if (( $(echo "$MEM_USAGE > $ALERT_MEM" | bc -l) )); then
        echo "ALERTE RAM: ${MEM_USAGE}% à $TIMESTAMP" >> "$LOG_FILE"
    fi
    
    if [ "$DISK_USAGE" -gt "$ALERT_DISK" ]; then
        echo "ALERTE DISK: ${DISK_USAGE}% à $TIMESTAMP" >> "$LOG_FILE"
    fi
    
    sleep 30
done''',
        parameters: [
          ScriptParameter(name: 'ALERT_CPU', type: 'number', defaultValue: '80'),
          ScriptParameter(name: 'ALERT_MEM', type: 'number', defaultValue: '90'),
          ScriptParameter(name: 'ALERT_DISK', type: 'number', defaultValue: '85'),
        ],
      ),

      ScriptTemplate(
        id: 'security_audit',
        name: 'Audit de Sécurité',
        description: 'Effectue un audit de sécurité complet',
        category: ScriptCategory.security,
        language: ScriptLanguage.bash,
        template: r'''#!/bin/bash
# Audit de Sécurité Complet
# Généré par TUTODECODE Script Generator

REPORT_DIR="/security_audit/$(date +%Y%m%d)"
mkdir -p "$REPORT_DIR"

echo "=== AUDIT DE SÉCURITÉ - $(date) ===" > "$REPORT_DIR/security_report.txt"

# 1. Utilisateurs avec shell
echo -e "\n1. UTILISATEURS AVEC SHELL:" >> "$REPORT_DIR/security_report.txt"
cat /etc/passwd | grep -E "(bash|sh|zsh)" >> "$REPORT_DIR/security_report.txt"

# 2. Permissions SUID
echo -e "\n2. FICHIERS SUID:" >> "$REPORT_DIR/security_report.txt"
find / -type f -perm -4000 -ls 2>/dev/null >> "$REPORT_DIR/security_report.txt"

# 3. Connexions réseau actives
echo -e "\n3. CONNEXIONS RÉSEAU:" >> "$REPORT_DIR/security_report.txt"
netstat -tuln >> "$REPORT_DIR/security_report.txt"

# 4. Services en écoute
echo -e "\n4. SERVICES EN ÉCOUTE:" >> "$REPORT_DIR/security_report.txt"
ss -tulpn >> "$REPORT_DIR/security_report.txt"

# 5. Logs récents suspects
echo -e "\n5. LOGS SUSPECTS (24h):" >> "$REPORT_DIR/security_report.txt"
grep -i "failed\|error\|attack\|intrusion" /var/log/auth.log --since="1 day ago" >> "$REPORT_DIR/security_report.txt" 2>/dev/null

# 6. Vérifier les mises à jour
echo -e "\n6. MISES À JOUR:" >> "$REPORT_DIR/security_report.txt"
apt list --upgradable 2>/dev/null | grep -v "WARNING" >> "$REPORT_DIR/security_report.txt"

echo "Audit terminé. Rapport: $REPORT_DIR/security_report.txt"''',
        parameters: [],
      ),

      // Network Scripts
      ScriptTemplate(
        id: 'network_scanner',
        name: 'Scanner Réseau',
        description: 'Scan un réseau pour détecter les hôtes actifs',
        category: ScriptCategory.network,
        language: ScriptLanguage.python,
        template: r'''#!/usr/bin/env python3
# Scanner Réseau Avancé
# Généré par TUTODECODE Script Generator

import socket
import threading
import ipaddress
import sys
from datetime import datetime

class NetworkScanner:
    def __init__(self, network, ports):
        self.network = network
        self.ports = ports
        self.active_hosts = []
        self.lock = threading.Lock()
    
    def scan_port(self, host, port):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((host, port))
            sock.close()
            
            if result == 0:
                with self.lock:
                    self.active_hosts.append((host, port))
                    print(f"[+] {host}:{port} - OUVERT")
        except:
            pass
    
    def scan_host(self, host):
        for port in self.ports:
            thread = threading.Thread(target=self.scan_port, args=(host, port))
            thread.start()
    
    def scan_network(self):
        print(f"Scan du réseau {self.network}...")
        print(f"Ports: {self.ports}")
        print(f"Début: {datetime.now()}")
        print("-" * 50)
        
        network = ipaddress.ip_network(self.network)
        threads = []
        
        for host in network.hosts():
            thread = threading.Thread(target=self.scan_host, args=(str(host),))
            threads.append(thread)
            thread.start()
        
        for thread in threads:
            thread.join()
        
        print("-" * 50)
        print(f"Scan terminé: {datetime.now()}")
        print(f"Hôtes actifs trouvés: {len(set(host for host, port in self.active_hosts))}")
        
        # Afficher les résultats
        hosts = {}
        for host, port in self.active_hosts:
            if host not in hosts:
                hosts[host] = []
            hosts[host].append(port)
        
        for host, ports in sorted(hosts.items()):
            print(f"\n{host}: {sorted(ports)}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 network_scanner.py <network>")
        print("Exemple: python3 network_scanner.py 192.168.1.0/24")
        sys.exit(1)
    
    network = sys.argv[1]
    common_ports = [21, 22, 23, 25, 53, 80, 110, 143, 443, 993, 995]
    
    scanner = NetworkScanner(network, common_ports)
    scanner.scan_network()''',
        parameters: [
          ScriptParameter(name: 'NETWORK', type: 'text', defaultValue: '192.168.1.0/24'),
          ScriptParameter(name: 'PORTS', type: 'text', defaultValue: '22,80,443'),
        ],
      ),

      // Database Scripts
      ScriptTemplate(
        id: 'database_backup',
        name: 'Backup MySQL',
        description: 'Backup automatique de bases de données MySQL',
        category: ScriptCategory.database,
        language: ScriptLanguage.bash,
        template: r'''#!/bin/bash
# Backup Automatique MySQL
# Généré par TUTODECODE Script Generator

DB_USER="backup_user"
DB_PASS="secure_password"
BACKUP_DIR="/mysql_backup/$(date +%Y%m%d)"
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"

echo "Début backup MySQL: $(date)"

# Lister toutes les bases de données
databases=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)")

# Backup chaque base de données
for db in $databases; do
    echo "Backup de la base: $db"
    
    mysqldump -u "$DB_USER" -p"$DB_PASS" \
        --single-transaction \
        --routines \
        --triggers \
        "$db" | gzip > "$BACKUP_DIR/${db}_$(date +%H%M%S).sql.gz"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✓ $db backup réussi"
    else
        echo "✗ Erreur backup $db"
    fi
done

# Nettoyer les anciens backups
find /mysql_backup -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup MySQL terminé: $(date)"
echo "Espace utilisé: $(du -sh "$BACKUP_DIR" | cut -f1)"''',
        parameters: [
          ScriptParameter(name: 'DB_USER', type: 'text', defaultValue: 'backup_user'),
          ScriptParameter(name: 'DB_PASS', type: 'password', defaultValue: 'secure_password'),
          ScriptParameter(name: 'RETENTION_DAYS', type: 'number', defaultValue: '7'),
        ],
      ),

      // Web Scripts
      ScriptTemplate(
        id: 'web_health_check',
        name: 'Health Check Web',
        description: 'Vérifie la santé de services web',
        category: ScriptCategory.web,
        language: ScriptLanguage.python,
        template: r'''#!/usr/bin/env python3
# Health Check Services Web
# Généré par TUTODECODE Script Generator

import requests
import json
import time
from datetime import datetime

class WebHealthChecker:
    def __init__(self):
        self.services = [
            {"name": "Main Website", "url": "https://example.com", "timeout": 10},
            {"name": "API Server", "url": "https://api.example.com/health", "timeout": 5},
            {"name": "Admin Panel", "url": "https://admin.example.com", "timeout": 10},
        ]
        self.results = []
    
    def check_service(self, service):
        try:
            start_time = time.time()
            response = requests.get(
                service["url"], 
                timeout=service["timeout"],
                verify=False  # Pour les certificats auto-signés
            )
            response_time = (time.time() - start_time) * 1000
            
            result = {
                "name": service["name"],
                "url": service["url"],
                "status": response.status_code,
                "response_time": round(response_time, 2),
                "status_text": "OK" if response.status_code == 200 else "ERROR",
                "timestamp": datetime.now().isoformat()
            }
            
        except requests.exceptions.Timeout:
            result = {
                "name": service["name"],
                "url": service["url"],
                "status": 0,
                "response_time": 0,
                "status_text": "TIMEOUT",
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            result = {
                "name": service["name"],
                "url": service["url"],
                "status": 0,
                "response_time": 0,
                "status_text": str(e),
                "timestamp": datetime.now().isoformat()
            }
        
        self.results.append(result)
        return result
    
    def run_checks(self):
        print("Health Check - " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        print("=" * 60)
        
        for service in self.services:
            result = self.check_service(service)
            status_icon = "✓" if result["status"] == 200 else "✗"
            
            print(f"{status_icon} {result['name']}")
            print(f"   URL: {result['url']}")
            print(f"   Status: {result['status']} ({result['status_text']})")
            print(f"   Response Time: {result['response_time']}ms\n")
        
        # Sauvegarder les résultats
        with open(f"health_check_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json", "w") as f:
            json.dump(self.results, f, indent=2)
        
        print(f"Results saved to health_check_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")

if __name__ == "__main__":
    checker = WebHealthChecker()
    checker.run_checks()''',
        parameters: [
          ScriptParameter(name: 'SERVICES', type: 'json', defaultValue: '[{"name":"Site","url":"https://example.com"}]'),
        ],
      ),
    ]);
  }

  void _loadGeneratedScripts() {
    // Simuler chargement de scripts générés précédemment
    _generatedScripts.addAll([
      GeneratedScript(
        id: '1',
        name: 'Backup Personnalisé',
        language: ScriptLanguage.bash,
        content: '#!/bin/bash\\necho "Script de backup personnalisé"',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        category: ScriptCategory.system,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            border: Border(bottom: BorderSide(color: TdcColors.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.code, color: Colors.purple.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Générateur de Scripts & Automation',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Text(
                  '${_generatedScripts.length} scripts générés',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: TdcColors.surfaceAlt.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.purple.shade700,
            labelColor: Colors.purple.shade700,
            unselectedLabelColor: TdcColors.textMuted,
            tabs: const [
              Tab(text: 'Générateur'),
              Tab(text: 'Templates'),
              Tab(text: 'Automation'),
              Tab(text: 'Mes Scripts'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneratorTab(),
              _buildTemplatesTab(),
              _buildAutomationTab(),
              _buildMyScriptsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Générateur de Scripts IA',
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Décrivez ce que vous voulez faire et l\'IA générera le script approprié.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Configuration
          Row(
            children: [
              Expanded(
                child: _buildLanguageSelector(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategorySelector(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Description
          const Text(
            'Description du Script',
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 6,
            style: const TextStyle(color: TdcColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Ex: Je veux un script qui surveille l\'utilisation CPU et envoie une alerte si > 80%...',
              filled: true,
              fillColor: TdcColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bouton de génération
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGenerating || _descriptionController.text.isEmpty ? null : _generateScript,
                  icon: _isGenerating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? 'Ghost AI génère…' : 'Générer avec Ghost AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_isGenerating) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _streamSub?.cancel();
                    setState(() => _isGenerating = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.stop, color: Colors.white),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Résultat
          if (_customScriptController.text.isNotEmpty) ...[
            const Text(
              'Script Généré',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TdcColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TdcColors.surfaceAlt.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.code, color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedLanguage.name.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _copyGeneratedScript,
                          icon: const Icon(Icons.copy, color: TdcColors.textSecondary),
                        ),
                        IconButton(
                          onPressed: _saveGeneratedScript,
                          icon: const Icon(Icons.save, color: TdcColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _customScriptController,
                      maxLines: 20,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langage',
          style: TextStyle(
            color: TdcColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TdcColors.border),
          ),
          child: DropdownButton<ScriptLanguage>(
            value: _selectedLanguage,
            isExpanded: true,
            items: ScriptLanguage.values.map((language) {
              return DropdownMenuItem(
                value: language,
                child: Row(
                  children: [
                    Icon(language.icon, color: language.color, size: 20),
                    const SizedBox(width: 8),
                    Text(language.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedLanguage = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catégorie',
          style: TextStyle(
            color: TdcColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TdcColors.border),
          ),
          child: DropdownButton<ScriptCategory>(
            value: _selectedCategory,
            isExpanded: true,
            items: ScriptCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 20),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        return _buildTemplateCard(_templates[index]);
      },
    );
  }

  Widget _buildTemplateCard(ScriptTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: TdcColors.surface,
      child: InkWell(
        onTap: () => _showTemplateDetails(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: template.language.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.language.name,
                      style: TextStyle(
                        color: template.language.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: template.category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.category.name,
                      style: TextStyle(
                        color: template.category.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: TdcColors.textMuted, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.name,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (template.parameters.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.tune, color: TdcColors.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${template.parameters.length} paramètres configurables',
                      style: const TextStyle(
                        color: TdcColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutomationTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Tâches Automatisées',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addAutomationTask,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: TdcColors.textMuted, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune tâche automatisée',
                        style: TextStyle(color: TdcColors.textMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Créez votre première tâche automatisée',
                        style: TextStyle(color: TdcColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(_tasks[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(AutomationTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.isEnabled ? Icons.play_circle : Icons.pause_circle,
                  color: task.isEnabled ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  task.name,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: task.isEnabled,
                  onChanged: (value) => _toggleTask(task.id, value),
                  activeColor: Colors.purple.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(
                color: TdcColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: TdcColors.textMuted, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Exécution: ${task.schedule}',
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.history, color: TdcColors.textMuted, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Dernière: ${_formatDate(task.lastRun)}',
                  style: const TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyScriptsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Mes Scripts Générés',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_generatedScripts.length} scripts',
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _generatedScripts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code_off, color: TdcColors.textMuted, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun script généré',
                        style: TextStyle(color: TdcColors.textMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Générez votre premier script',
                        style: TextStyle(color: TdcColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _generatedScripts.length,
                  itemBuilder: (context, index) {
                    return _buildScriptCard(_generatedScripts[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScriptCard(GeneratedScript script) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: TdcColors.surface,
      child: InkWell(
        onTap: () => _showScriptDetails(script),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: script.language.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      script.language.name,
                      style: TextStyle(
                        color: script.language.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: script.category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      script.category.name,
                      style: TextStyle(
                        color: script.category.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: TdcColors.textMuted, size: 16),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editScript(script);
                          break;
                        case 'copy':
                          _copyScript(script);
                          break;
                        case 'delete':
                          _deleteScript(script.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      )),
                      const PopupMenuItem(value: 'copy', child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Copier'),
                        ],
                      )),
                      const PopupMenuItem(value: 'delete', child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                script.name,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Créé le ${_formatDate(script.createdAt)}',
                style: const TextStyle(
                  color: TdcColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Methods
  Future<void> _generateScript() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _customScriptController.text = '';
    });

    // Vérifier si Ollama est disponible
    final status = await OllamaService.checkStatus();

    if (!mounted) return;

    if (!status.running || status.models.isEmpty) {
      // Fallback vers template si Ollama n'est pas disponible
      _customScriptController.text = _generateScriptFallback(description, _selectedLanguage);
      setState(() => _isGenerating = false);
      return;
    }

    final model = status.models.first;
    final langName = _selectedLanguage.name;
    final prompt = 'Génère uniquement le code $langName complet et fonctionnel pour : $description\n'
        'Règles : code propre avec commentaires en français, pas d\'explication en dehors du code, '
        'inclure les imports nécessaires, gestion d\'erreurs basique.';

    final buffer = StringBuffer();
    _streamSub = OllamaService.stream(
      model,
      [{'role': 'user', 'content': prompt}],
      system: 'Tu es un expert en scripting. Tu génères uniquement du code $langName propre et fonctionnel. '
          'Ne réponds qu\'avec du code, sans explication avant ou après.',
    ).listen(
      (chunk) {
        if (!chunk.isThinking) {
          buffer.write(chunk.text);
          _customScriptController.text = buffer.toString();
        }
      },
      onDone: () {
        if (mounted) setState(() => _isGenerating = false);
      },
      onError: (_) {
        // Fallback si erreur durant le streaming
        if (mounted) {
          _customScriptController.text = _generateScriptFallback(description, _selectedLanguage);
          setState(() => _isGenerating = false);
        }
      },
      cancelOnError: true,
    );
  }

  String _generateScriptFallback(String description, ScriptLanguage language) {
    switch (language) {
      case ScriptLanguage.bash:
        return '''#!/bin/bash
# Script généré par TUTODECODE
# Description: $description
# Date: ${DateTime.now().toIso8601String()}

set -e

echo "Début du script: \$(date)"

# Implémentez votre logique ici
# $description

echo "Script terminé: \$(date)"
exit 0''';
      case ScriptLanguage.python:
        return '''#!/usr/bin/env python3
# Script généré par TUTODECODE
# Description: $description
# Date: ${DateTime.now().toIso8601String()}

import sys
import os
from datetime import datetime

def main():
    print(f"Début du script: {datetime.now()}")
    # Implémentez votre logique ici
    # $description
    print(f"Script terminé: {datetime.now()}")

if __name__ == "__main__":
    main()''';
      case ScriptLanguage.powershell:
        return '''# Script généré par TUTODECODE
# Description: $description
# Date: ${DateTime.now().toIso8601String()}

Write-Host "Début du script: \$(Get-Date)"

# Implémentez votre logique ici
# $description

Write-Host "Script terminé: \$(Get-Date)"
exit 0''';
      default:
        return '# Script généré par TUTODECODE\n# $description\n\n# Implémentez votre logique ici';
    }
  }

  void _copyGeneratedScript() {
    Clipboard.setData(ClipboardData(text: _customScriptController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Script copié dans le presse-papiers')),
    );
  }

  void _saveGeneratedScript() {
    final script = GeneratedScript(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Script généré - ${DateTime.now().toString().substring(0, 10)}',
      language: _selectedLanguage,
      content: _customScriptController.text,
      createdAt: DateTime.now(),
      category: _selectedCategory,
    );
    
    setState(() {
      _generatedScripts.insert(0, script);
      _customScriptController.clear();
      _descriptionController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Script sauvegardé')),
    );
  }

  void _showTemplateDetails(ScriptTemplate template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: TdcColors.surface,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(template.category.icon, color: template.category.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                template.description,
                style: const TextStyle(color: TdcColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      template.template,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: template.template));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Template copié')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAutomationTask() {
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(
        onAdd: (task) {
          setState(() => _tasks.add(task));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tâche ajoutée')),
          );
        },
      ),
    );
  }

  void _toggleTask(String taskId, bool enabled) {
    setState(() {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(isEnabled: enabled);
      }
    });
  }

  void _showScriptDetails(GeneratedScript script) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: TdcColors.surface,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(script.language.icon, color: script.language.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      script.name,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      script.content,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: script.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Script copié')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editScript(GeneratedScript script) {
    _customScriptController.text = script.content;
    _tabController.animateTo(0); // Switch to generator tab
  }

  void _copyScript(GeneratedScript script) {
    Clipboard.setData(ClipboardData(text: script.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Script copié')),
    );
  }

  void _deleteScript(String scriptId) {
    setState(() {
      _generatedScripts.removeWhere((s) => s.id == scriptId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Script supprimé')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _AddTaskDialog extends StatefulWidget {
  final Function(AutomationTask) onAdd;

  const _AddTaskDialog({required this.onAdd});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scheduleController = TextEditingController(text: '0 2 * * *');
  final _scriptController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TdcColors.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ajouter une Tâche Automatisée',
              style: TextStyle(
                color: TdcColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: TdcColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nom de la tâche',
                filled: true,
                fillColor: TdcColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: TdcColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description',
                filled: true,
                fillColor: TdcColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scheduleController,
              style: const TextStyle(color: TdcColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Schedule (cron)',
                hintText: '0 2 * * * (tous les jours à 2h)',
                filled: true,
                fillColor: TdcColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scriptController,
              maxLines: 4,
              style: const TextStyle(color: TdcColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Script à exécuter',
                filled: true,
                fillColor: TdcColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _nameController.text.isNotEmpty ? () {
                    final task = AutomationTask(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      description: _descriptionController.text,
                      schedule: _scheduleController.text,
                      script: _scriptController.text,
                      isEnabled: true,
                      lastRun: DateTime.now(),
                    );
                    widget.onAdd(task);
                    Navigator.pop(context);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    _scriptController.dispose();
    super.dispose();
  }
}

// Models
class ScriptTemplate {
  final String id;
  final String name;
  final String description;
  final ScriptCategory category;
  final ScriptLanguage language;
  final String template;
  final List<ScriptParameter> parameters;

  const ScriptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.language,
    required this.template,
    required this.parameters,
  });
}

class ScriptParameter {
  final String name;
  final String type;
  final String defaultValue;

  const ScriptParameter({
    required this.name,
    required this.type,
    required this.defaultValue,
  });
}

class GeneratedScript {
  final String id;
  final String name;
  final ScriptLanguage language;
  final String content;
  final DateTime createdAt;
  final ScriptCategory category;

  const GeneratedScript({
    required this.id,
    required this.name,
    required this.language,
    required this.content,
    required this.createdAt,
    required this.category,
  });
}

class AutomationTask {
  final String id;
  final String name;
  final String description;
  final String schedule;
  final String script;
  final bool isEnabled;
  final DateTime lastRun;

  const AutomationTask({
    required this.id,
    required this.name,
    required this.description,
    required this.schedule,
    required this.script,
    required this.isEnabled,
    required this.lastRun,
  });

  AutomationTask copyWith({
    String? id,
    String? name,
    String? description,
    String? schedule,
    String? script,
    bool? isEnabled,
    DateTime? lastRun,
  }) {
    return AutomationTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      script: script ?? this.script,
      isEnabled: isEnabled ?? this.isEnabled,
      lastRun: lastRun ?? this.lastRun,
    );
  }
}

enum ScriptLanguage {
  bash('Bash', Icons.terminal, Colors.green),
  python('Python', Icons.code, Colors.blue),
  powershell('PowerShell', Icons.desktop_windows, Colors.purple),
  javascript('JavaScript', Icons.javascript, Colors.yellow);

  const ScriptLanguage(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

enum ScriptCategory {
  system('Système', Icons.computer, Colors.blue),
  network('Réseau', Icons.router, Colors.green),
  security('Sécurité', Icons.security, Colors.red),
  database('Base de données', Icons.storage, Colors.orange),
  web('Web', Icons.language, Colors.purple),
  monitoring('Monitoring', Icons.monitor, Colors.teal),
  automation('Automation', Icons.autorenew, Colors.indigo);

  const ScriptCategory(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}
