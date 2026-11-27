# Google Play : publication automatique (test ouvert)

Chaque tag `vX.Y.Z` ou `vX.Y.Z.K` poussé sur GitHub lance `release.yml`. Après la release GitHub,
le job **google-play** construit l'app bundle (`.aab`), le signe avec la clé d'importation et l'envoie
sur la piste **test ouvert** (`beta`) de la Play Console, avec la note de version
`fastlane/metadata/android/en-US/changelogs/<B>.txt` (celle de F-Droid, écrite par
`scripts/nouvelle-version.sh`).

Tant que le secret `PLAY_SERVICE_ACCOUNT_JSON` n'existe pas, le job est ignoré (simple notice).

## Numéro de version

Google Play exige un `versionCode` strictement croissant. C'est `B` dans `pubspec.yaml`
(`version: X.Y.Z+B`) : `nouvelle-version.sh` l'augmente à chaque version, petite ou grande.
Ne jamais retaguer une version déjà envoyée sur Play avec le même `B`.

## À faire une seule fois (toi, dans les consoles)

### 1. Premier import manuel

Google refuse l'API tant qu'aucun bundle n'a été importé à la main.

1. Sur le Mac, dans un clone hors iCloud (`~/t2decode-build` : sous `~/Documents`, les fichiers
   délestés font échouer Gradle), avec `android/key.properties` pointant vers la clé d'importation
   `~/.t2decode-android/t2decode-release.jks` :
   `~/.flutter-3.44.1/bin/flutter build appbundle --release`
   → `build/app/outputs/bundle/release/app-release.aab`.
2. Play Console → T2DECODE → **Tester → Test ouvert → Créer une release** → importer ce `.aab`.
3. Accepter **Play App Signing** (Google garde la clé de signature de l'app ; la clé ci-dessus
   est la *clé d'importation*, enregistrée auprès de Google).
4. Remplir ce que la Console demande (fiche, classification du contenu, sécurité des données,
   public cible, statut de professionnel), puis envoyer la release en examen.

Note : l'app Play sera signée par Google, pas par ta clé. Un APK GitHub/Obtainium et la version
Play ne peuvent donc pas se mettre à jour l'un par-dessus l'autre ; il faut désinstaller pour changer.

### 2. Compte de service

1. [Google Cloud Console](https://console.cloud.google.com/) → créer (ou choisir) un projet.
2. **API et services → Bibliothèque** → activer **Google Play Android Developer API**.
3. **IAM → Comptes de service** → créer `t2decode-ci` (aucun rôle Cloud nécessaire).
4. Sur ce compte : **Clés → Ajouter une clé → JSON** → télécharger le fichier (secret, ne pas le commiter).
5. Play Console → **Utilisateurs et autorisations → Inviter un utilisateur** → l'adresse
   `t2decode-ci@<projet>.iam.gserviceaccount.com`, accès à l'app T2DECODE avec
   **Publier des versions dans les canaux de test** (et *Gérer les versions de test*).
   L'accès peut mettre jusqu'à 24 h à devenir actif.

### 3. Secrets GitHub

GitHub → TUTODECODE-FR/T2DECODE → **Settings → Secrets and variables → Actions** :

La clé d'importation Play est **séparée** de la clé des APK GitHub (secrets `ANDROID_*`, inchangés) :

| Secret | Contenu |
|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON` | contenu complet du fichier JSON du compte de service |
| `PLAY_KEYSTORE_BASE64` | `base64 -i ~/.t2decode-android/t2decode-release.jks` |
| `PLAY_KEYSTORE_PASSWORD` | mot de passe du keystore |
| `PLAY_KEY_ALIAS` | `t2decode` |
| `PLAY_KEY_PASSWORD` | mot de passe de la clé |

Depuis le dépôt, sans afficher les valeurs :

```sh
gh secret set PLAY_KEYSTORE_BASE64 < <(base64 -i ~/.t2decode-android/t2decode-release.jks)
gh secret set PLAY_KEY_ALIAS --body t2decode
gh secret set PLAY_KEYSTORE_PASSWORD   # demande la valeur
gh secret set PLAY_KEY_PASSWORD        # demande la valeur
gh secret set PLAY_SERVICE_ACCOUNT_JSON < chemin/vers/compte-de-service.json
```

## Ensuite

`sh scripts/nouvelle-version.sh petite "…"` suffit : GitHub, F-Droid, Snap, Homebrew, winget
et Google Play (test ouvert) suivent.

Tant que l'app n'a jamais été publiée (état « brouillon » dans la Console), l'API peut refuser
`status: completed` : dans ce cas, valider la première release à la main, puis relancer le job.

Vérifier un envoi : onglet **Actions** → run du tag → job *Google Play (test ouvert)*, puis
Play Console → Test ouvert.
