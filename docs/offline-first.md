# Offline‑first : limites, compromis, bonnes pratiques

T2DECODE est pensé pour fonctionner **sans cloud** et **sans dépendance Internet**.
Cette approche est idéale pour apprendre, tester et travailler en environnement
contraint (air‑gapped, zone blanche, datacenter, réseaux régulés), mais elle
implique des compromis.

L’objectif est simple : **rendre ces compromis explicites**, et donner des
méthodes concrètes pour garder un environnement réaliste et “sérieux”.

---

## ✅ Ce que l’approche offline‑first apporte

- **Contrôle total** : aucun service externe requis, aucune dépendance à une API.
- **Réduction de la surface d’exposition** : moins de risques d’exfiltration.
- **Répétabilité** : snapshots, scénarios rejouables, supports reproductibles.
- **Souveraineté** : approprié pour les environnements sensibles.

---

## ⚠️ Limites et réserves (compromis réels)

### 1) Pas de données “temps réel”

En air‑gapped, vous n’avez pas (ou volontairement pas) :
- flux de menaces “live”
- réputation IP/domaines à jour
- IOC en continu

**Mitigation** : importer des packs, travailler sur des captures locales, rejouer
des incidents simulés, préparer des données d’exemple, conserver des archives.

### 2) Contenu à préparer / maintenir soi‑même

Sans cloud, c’est **vous** qui gérez :
- les cours et supports (modules importés)
- les exercices (scénarios)
- les mises à jour (quand vous le décidez)

**Mitigation** : créer des “packs” offline (ZIP/USB), versionner les modules,
documenter une procédure d’update manuelle (changelog + hash).

### 3) Moins de scénarios cloud‑native

Certains apprentissages sont naturellement cloud‑centric (SaaS, IAM managé…).

**Mitigation** : simuler localement (VMs, conteneurs, K8s local), se concentrer
sur les fondamentaux (réseau, logs, crypto, systèmes), puis “basculer” quand un
environnement autorisé existe.

---

## 🧪 Bonnes pratiques “lab sérieux”

- **Réseau isolé** : host‑only / VLAN dédié / pas d’exposition WAN (UPnP off).
- **Snapshots** : avant/après chaque exercice.
- **Journalisation locale** : Windows Event Logs/Sysmon, journald, Suricata…
- **Séparation des rôles** : “attaquant”, “cible”, “observateur” (SIEM) en VMs.
- **Traçabilité** : notes + objectifs + preuve (timeline d’alertes / retest).

---

## 🔥 Entraînement CTF / vulnérable (local)

Un environnement volontairement vulnérable est l’une des méthodes les plus
efficaces pour progresser en sécurité, **à condition qu’il reste isolé**.

Guide pratique : `docs/ctf-prep.md`.

