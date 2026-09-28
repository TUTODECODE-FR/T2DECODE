# Claims bénévoles (marqueurs)

Chaque fichier `N.md` (N = iid de l’issue GitLab) réserve la tâche `#N`.

## Format

```markdown
# Claim pour l'issue #42
username: ton-pseudo-gitlab
```

Ou une seule ligne : `ton-pseudo-gitlab`

## Flux

1. Branche `volunteer/prendre-N`
2. Ajouter ce fichier
3. MR titrée exactement `prendre #N`
4. **Pipeline verte = ticket verrouillé immédiatement** (même si la MR reste ouverte)
5. Le bot assigne l’issue (`en-cours`) et merge la MR automatiquement

Abandon : fermer la MR → le ticket est libéré. Inactivité 14 j → fermeture auto.

Voir [VOLUNTEER_BOARD.md](../../VOLUNTEER_BOARD.md) et [CONTRIBUTING.md](../../CONTRIBUTING.md).
