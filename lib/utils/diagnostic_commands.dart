/// Outil diagnostic : commandes utiles pour Linux, macOS, Windows
/// Catégories : Réseau, Disque, Système, Processus, Matériel

const diagnosticCommands = [
  {
    'category': 'Réseau',
    'commands': [
      {
        'label': 'Adresse IP locale',
        'linux': 'ip a',
        'macos': 'ifconfig',
        'windows': 'ipconfig'
      },
      {
        'label': 'Ping Google',
        'linux': 'ping -c 4 google.com',
        'macos': 'ping -c 4 google.com',
        'windows': 'ping google.com'
      },
      {
        'label': 'Afficher les ports ouverts',
        'linux': 'ss -tuln',
        'macos': 'lsof -i -n',
        'windows': 'netstat -an'
      },
      {
        'label': 'Traceroute',
        'linux': 'traceroute google.com',
        'macos': 'traceroute google.com',
        'windows': 'tracert google.com'
      }
    ]
  },
  {
    'category': 'Disque',
    'commands': [
      {
        'label': 'Espace disque',
        'linux': 'df -h',
        'macos': 'df -h',
        'windows': 'wmic logicaldisk get size,freespace,caption'
      },
      {
        'label': 'Liste des disques',
        'linux': 'lsblk',
        'macos': 'diskutil list',
        'windows': 'diskpart > list disk'
      }
    ]
  },
  {
    'category': 'Système',
    'commands': [
      {
        'label': 'Infos système',
        'linux': 'uname -a',
        'macos': 'uname -a',
        'windows': 'systeminfo'
      },
      {
        'label': 'Uptime',
        'linux': 'uptime',
        'macos': 'uptime',
        'windows': 'net stats srv'
      }
    ]
  },
  {
    'category': 'Processus',
    'commands': [
      {
        'label': 'Processus actifs',
        'linux': 'ps aux',
        'macos': 'ps aux',
        'windows': 'tasklist'
      },
      {
        'label': 'Utilisation CPU/RAM',
        'linux': 'top',
        'macos': 'top',
        'windows': 'wmic cpu get loadpercentage & wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value'
      }
    ]
  },
  {
    'category': 'Matériel',
    'commands': [
      {
        'label': 'Infos matériel',
        'linux': 'lshw',
        'macos': 'system_profiler',
        'windows': 'wmic computersystem get model,name,manufacturer,systemtype'
      },
      {
        'label': 'Carte graphique',
        'linux': 'lspci | grep VGA',
        'macos': 'system_profiler SPDisplaysDataType',
        'windows': 'wmic path win32_videocontroller get name'
      }
    ]
  }
];
