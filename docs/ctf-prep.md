# Lab de sécurité local (offline) — préparer un environnement isolé (volontairement vulnérable)

Ce guide explique comment préparer un environnement **100% local**, **contrôlé**
et **rejouable** pour apprendre l’**audit**, la **détection** et le **durcissement**
sans exposer de services vulnérables à Internet.

T2DECODE ne “déploie” pas automatiquement des cibles vulnérables : il fournit
des outils, des cours, des simulateurs, et une base méthodologique. Le lab reste
votre responsabilité.

---

## ✅ Objectifs

- Apprendre en cassant/reconstruisant, sans dommages collatéraux.
- Produire des preuves : logs, alertes, timeline, correctifs, retest.
- Travailler comme en conditions réelles (segmentation, détection, procédures).

---

## 1) Architecture recommandée (simple et efficace)

### Option A — 3 VMs (recommandé)

- **VM Poste de test** : outils d’analyse / audit
- **VM Cible** : service/app volontairement vulnérable
- **VM Observateur** : collecte logs / IDS / dashboards (local)

Réseau : **host‑only** ou **VLAN dédié**. Pas de route vers Internet.

### Option B — 1 machine + conteneurs (prudence)

Possible, mais attention à l’exposition involontaire (ports, firewall, NAT).
Si vous utilisez Docker/Podman : binder sur `127.0.0.1` quand c’est suffisant.

---

## 2) Checklist “ne pas se tirer une balle dans le pied”

- UPnP désactivé, aucun port ouvert en WAN.
- Ports bindés en local (`127.0.0.1`) si possible.
- Pare‑feu actif sur l’hôte et sur les VMs.
- Snapshots réguliers (avant chaque exercice).
- Notes de scénario : objectifs, “flags”, étapes, remédiation.

---

## 3) Scénarios structurés (exemples)

### Scénario 1 — Web vulnérable (analyse → correction)

- Cible : application web vulnérable
- Exercice : XSS/SQLi → détection → correction → retest
- Preuves : logs + timeline + patch + rapport court

### Scénario 2 — Détection & tuning (SIEM local)

- Collecte : logs Windows/Linux
- Exercice : générer des événements réalistes, réduire les faux positifs
- Preuves : règles + captures + justification

### Scénario 3 — Visibilité est‑ouest (segmentation)

- VLAN/sous‑réseaux séparés
- Exercice : comprendre flux, filtrer, observer, alerter
- Preuves : schéma réseau + règles + captures

---

## 4) Intégration avec T2DECODE

- Documenter le scénario dans un module (Markdown/JSON) et l’importer.
- Conserver les preuves localement (captures, extraits de logs, résultats).
- Utiliser les outils offline et les labs pour réviser / simuler.
