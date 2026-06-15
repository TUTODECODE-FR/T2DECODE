# Mises à jour P2P autonomes avec T2C-Phantom

> [!NOTE]
> Le protocole **T2C-Phantom** (moteur de synchronisation P2P via proxy Go/libp2p) est actuellement répertorié dans les prochaines étapes de développement (Phase 2 de la roadmap). Le fonctionnement ci-dessous détaille la sécurité réseau et locale actuelle de l'application concernant le chargement et la mise à jour des modules.

## 🛡️ FAQ Sécurité & Intégrité des Cours

### Comment les mises à jour sont-elles signées ?
Actuellement, il n'y a pas de mécanisme de signature cryptographique asymétrique (par exemple, via un couple de clés privée/publique de l'association) pour signer les fichiers de cours à la source. Les mises à jour s'effectuent par défaut via HTTPS sur le dépôt officiel. 

Lors de la sauvegarde locale d'un module par le [ModuleService](file:///Users/winancher/Documents/T2DECODE/lib/core/services/module_service.dart), l'application génère un hachage SHA-256 du contenu et le stocke localement dans un fichier de contrôle de métadonnées `.module_shas.json`.

### Comment les signatures sont-elles vérifiées ?
L'application effectue deux niveaux de vérification d'intégrité basés sur SHA-256 :
1. **Assets d'origine (intégrés au build) :** Au démarrage, le système anti-altération ([AntiTamperingSystem](file:///Users/winancher/Documents/T2DECODE/lib/core/security/anti_tampering.dart)) et le service de vérification d'identité ([IdentityVerificationService](file:///Users/winancher/Documents/T2DECODE/lib/core/security/identity_verification.dart)) comparent les empreintes SHA-256 réelles des fichiers critiques (`assets/courses.json`, `assets/manifest.json`, etc.) pour s'assurer qu'ils n'ont pas été modifiés.
2. **Modules additionnels (téléchargés ou importés) :** À chaque chargement d'un module présent dans le dossier local `TUTODECODE_Modules`, l'application recalcule son empreinte SHA-256 et la compare à celle stockée dans `.module_shas.json`. Si les empreintes diffèrent, le module est ignoré (`checksum mismatch`).

### Peut-on injecter un faux contenu ?
* **Localement :** Si un fichier de cours local est altéré sur le stockage de l'appareil sans mettre à jour `.module_shas.json`, l'application le détecte et refuse de le charger.
* **Réseau :** En l'absence de signature asymétrique, si un attaquant était en mesure de compromettre ou d'usurper le transport (ex. via une attaque Man-in-the-Middle si HTTPS est compromis, ou par empoisonnement DNS), il pourrait tenter d'injecter un faux fichier JSON de cours. Pour mitiger ce risque, l'application restreint strictement les téléchargements à l'hôte officiel `raw.githubusercontent.com` (aucun autre hôte ou sous-domaine n'est accepté). De plus, une validation de schéma stricte (`_validateModuleMap`) rejette tout fichier ne respectant pas les limites (taille maximale de 5 Mo, max 50 chapitres, max 100 Ko par chapitre, etc.) afin de prévenir les injections de code ou les débordements de mémoire.

### Les cours téléchargés sont-ils authentifiés ?
Non, ils ne sont pas authentifiés au sens cryptographique (pas de certificat ou de signature de clé de l'association). L'authenticité des cours de base est garantie par la signature globale du build de l'application. 

Pour les modules externes additionnels, la sécurité repose uniquement sur la confiance de la connexion HTTPS vers GitHub et sur les contrôles de structure stricts appliqués à la réception.
