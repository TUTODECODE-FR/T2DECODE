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
4. Après merge → CI assigne l’issue + label `en-cours`

Voir [VOLUNTEER_BOARD.md](../../VOLUNTEER_BOARD.md) et [CONTRIBUTING.md](../../CONTRIBUTING.md).
