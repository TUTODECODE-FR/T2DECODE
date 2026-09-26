## Claim bénévole — `prendre #<iid>`

> **Titre de la MR** (obligatoire) : exactement `prendre #<iid>`  
> Exemple : `prendre #42`

### Checklist

- [ ] Branche `volunteer/prendre-<iid>`
- [ ] Fichier `volunteer/claims/<iid>.md` avec **mon** pseudo GitLab (`username: …`)
- [ ] Issue cible ouverte, label `benevolat`, **sans** autre assignee
- [ ] Je n’ai **aucune autre claim active** (MR ouverte ou ticket `en-cours`)
- [ ] Commit(s) avec **DCO** (`Signed-off-by: …`)

### Effet immédiat

Dès que la pipeline de cette MR est **verte**, le ticket est **verrouillé pour vous**
(même si la MR reste ouverte). Le bot bénévole assigne ensuite l’issue
(label `en-cours`) et **merge cette MR automatiquement** — aucune relecture
mainteneur nécessaire pour un claim.

Pipeline **rouge** = ticket déjà pris (« déjà pris par @xxx »), autre claim active,
ou fichier hors zone bénévole : lisez le message de la CI.

Pour **abandonner** : fermez simplement la MR — le ticket sera libéré automatiquement.
Sans activité pendant **14 jours**, le bot ferme la claim et libère le ticket.

Ce n’est **pas** la MR de code : le travail se fait ensuite sur une branche feature + MR classique.

Docs : [VOLUNTEER_BOARD.md](../../VOLUNTEER_BOARD.md)
