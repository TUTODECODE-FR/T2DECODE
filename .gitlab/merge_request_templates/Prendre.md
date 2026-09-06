## Claim bénévole — `prendre #<iid>`

> **Titre de la MR** (obligatoire) : exactement `prendre #<iid>`  
> Exemple : `prendre #42`

### Checklist

- [ ] Branche `volunteer/prendre-<iid>`
- [ ] Fichier `volunteer/claims/<iid>.md` avec mon pseudo GitLab
- [ ] Issue cible ouverte et **sans** autre assignee
- [ ] Commit(s) avec **DCO** (`Signed-off-by: …`)

### Après merge

La CI (`volunteer_claim_apply`) assigne l’issue à l’auteur du claim et pose `en-cours`.  
Ce n’est **pas** la MR de code : le travail se fait ensuite sur une branche feature + MR classique.

Docs : [VOLUNTEER_BOARD.md](../../VOLUNTEER_BOARD.md)
