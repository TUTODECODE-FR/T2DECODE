---
title: "[Info] Ne pas utiliser pour claim"
labels: benevolat
---

## ⚠️ Ce modèle n’assigne pas une tâche

Sur GitLab.com, le menu **Type** (Incident / Issue / Task) **ne peut pas** être
personnalisé avec « Proposition » / « Prendre ». On utilise **modèles + labels + MR**.

### Pour *prendre* une tâche libre

1. Choisir une issue `benevolat` **ouverte sans assignee**.
2. Branche `volunteer/prendre-<iid>` + fichier `volunteer/claims/<iid>.md`
   (`username: ton-pseudo-gitlab`).
3. Ouvrir une **Merge Request** dont le titre est **exactement** `prendre #<iid>`
   (modèle MR **Prendre** recommandé) + **DCO**.
4. **Pipeline verte = ticket verrouillé pour vous, immédiatement.** Le bot assigne l’issue (`en-cours`) et merge la MR tout seul.

Hub TDC Studio → **Préparer ma MR prendre**, ou docs :
[VOLUNTEER_BOARD.md](../../VOLUNTEER_BOARD.md) · [CONTRIBUTING.md](../../CONTRIBUTING.md).

### Signaux importants

| Action | Effet |
| :--- | :--- |
| Merger une issue « Proposition » | ❌ ne réserve pas la tâche |
| Merger la MR `prendre #N` | ✅ assigne + `en-cours` |
| Merger la MR de code | ✅ ferme l’issue (travail livré) |

**Ferme / annule** cette issue si tu l’as ouverte par erreur — utilise plutôt la MR claim.
