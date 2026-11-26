#!/bin/sh
# Sortir une nouvelle version de T2DECODE en une commande.
#
#   sh scripts/nouvelle-version.sh petite "Couleurs du menu corrigées"   # 1.0.7 → 1.0.7.1 → 1.0.7.2…
#   sh scripts/nouvelle-version.sh grande "Nouveaux cours réseau"        # 1.0.7.x → 1.0.8
#   ESSAI=1 sh scripts/nouvelle-version.sh petite "…"                    # montre sans rien changer
#
# Met à jour pubspec.yaml (X.Y.Z+B, B augmente toujours), lib/core/app_version.dart
# (X.Y.Z.K+B), snap/snapcraft.yaml, la note F-Droid (changelogs/B.txt), lance les
# tests, commite, crée le tag vX.Y.Z[.K] et pousse sur GitHub : la CI publie
# partout (GitHub, GitLab, SourceForge, Snap, Homebrew, winget, F-Droid).
set -eu

type=${1:-}
message=${2:-}
case "$type" in petite|grande) ;; *)
	echo "usage : sh scripts/nouvelle-version.sh petite|grande \"ce qui change\""; exit 2 ;;
esac
[ -n "$message" ] || { echo "❌ indique en une phrase ce qui change (affiché sur F-Droid)"; exit 2; }

racine=$(git rev-parse --show-toplevel)
cd "$racine"

# Dépôt GitHub (source) : remote dont l'adresse contient github.com…/T2DECODE
remote=${REMOTE:-}
[ -n "$remote" ] || remote=$(git remote -v | awk '/github\.com[:\/]TUTODECODE-FR\/T2DECODE(\.git)? \(push\)/{print $1; exit}')
[ -n "$remote" ] || {
	echo "❌ aucun remote vers GitHub. Ajoute-le :"
	echo "   git remote add github https://github.com/TUTODECODE-FR/T2DECODE.git"
	exit 1
}

# seuls les fichiers suivis comptent (les fichiers non suivis ne sont jamais commités ici)
[ -z "$(git status --porcelain --untracked-files=no)" ] || {
	echo "❌ des modifications ne sont pas commitées"; git status --short --untracked-files=no; exit 1; }
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "❌ place-toi sur main (git switch main)"; exit 1; }
export GIT_TERMINAL_PROMPT=0
git fetch -q --no-tags "$remote" main
[ "$(git rev-parse HEAD)" = "$(git rev-parse "$remote/main")" ] || {
	echo "❌ main n'est pas à jour avec $remote/main (git pull $remote main)"; exit 1; }

# Version actuelle : pubspec.yaml X.Y.Z+B
ligne=$(sed -n 's/^version: *\([0-9][0-9.]*\)+\([0-9][0-9]*\) *$/\1 \2/p' pubspec.yaml)
[ -n "$ligne" ] || { echo "❌ pubspec.yaml : ligne « version: X.Y.Z+B » introuvable"; exit 1; }
base=${ligne% *}; build=${ligne#* }
maj=${base%%.*}; reste=${base#*.}; min=${reste%%.*}; pat=${reste#*.}
nbuild=$((build + 1))

if [ "$type" = grande ]; then
	nbase="$maj.$min.$((pat + 1))"
	nom=$nbase
else
	nbase=$base
	# plus grand K déjà publié sur GitHub pour cette base (tags vX.Y.Z.K)
	k=$(git ls-remote --tags --refs "$remote" "v$base.*" | sed 's#.*refs/tags/##' | sed -n "s/^v$(printf %s "$base" | sed 's/\./\\./g')\.\([0-9][0-9]*\)$/\1/p" | sort -n | tail -1)
	nom="$base.$(( ${k:-0} + 1 ))"
fi
tag="v$nom"
[ -z "$(git ls-remote --tags --refs "$remote" "$tag")" ] || { echo "❌ le tag $tag existe déjà sur GitHub"; exit 1; }
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && { echo "❌ le tag $tag existe déjà ici (git tag -d $tag)"; exit 1; }

echo "Version actuelle : $(sed -n "s/^const String kAppVersion = '\(.*\)';/\1/p" lib/core/app_version.dart) (pubspec $base+$build)"
echo "Nouvelle version : $nom (pubspec $nbase+$nbuild, tag $tag)"
echo "Note F-Droid     : $message"
if [ "${ESSAI:-0}" = 1 ]; then echo "(essai : rien n'est modifié)"; exit 0; fi

printf "Publier %s ? [o/N] " "$tag"; read -r ok
case "$ok" in o|O|oui) ;; *) echo "annulé"; exit 1 ;; esac

perl -0pi -e "s/^version: *[0-9.]+\\+[0-9]+ *\$/version: $nbase+$nbuild/m" pubspec.yaml
perl -0pi -e "s/^const String kAppVersion = '[^']*';/const String kAppVersion = '$nom+$nbuild';/m" lib/core/app_version.dart
perl -0pi -e "s/^version: .*\$/version: '$nom'/m" snap/snapcraft.yaml
mkdir -p fastlane/metadata/android/en-US/changelogs
printf '%s\n' "$message" > "fastlane/metadata/android/en-US/changelogs/$nbuild.txt"

# Vérifications avant de publier (Flutter du projet si présent)
# Flutter : $FLUTTER, sinon ~/.flutter-3.44.1 (hors iCloud), sinon celui du projet, sinon le PATH
flutter=${FLUTTER:-}
[ -z "$flutter" ] && [ -x "$HOME/.flutter-3.44.1/bin/flutter" ] && flutter="$HOME/.flutter-3.44.1/bin/flutter"
[ -z "$flutter" ] && [ -x "$racine/.flutter-sdk/bin/flutter" ] && flutter="$racine/.flutter-sdk/bin/flutter"
[ -z "$flutter" ] && flutter=$(command -v flutter || true)
if [ -n "$flutter" ]; then
	"$flutter" test --dart-define=SKIP_GOLDENS=true test/unit/app_version_test.dart >/dev/null ||
		{ echo "❌ test de version en échec : rien n'est publié (git checkout . pour annuler)"; exit 1; }
	"$flutter" test --dart-define=SKIP_GOLDENS=true >/dev/null ||
		{ echo "❌ tests en échec : rien n'est publié (git checkout . pour annuler)"; exit 1; }
	echo "✅ tests OK"
else
	echo "⚠️  Flutter introuvable : tests non lancés ici (la CI les lancera)"
fi

git add pubspec.yaml lib/core/app_version.dart snap/snapcraft.yaml \
	"fastlane/metadata/android/en-US/changelogs/$nbuild.txt"
git commit -q -s -m "chore(release): $tag

$message"
git tag -a "$tag" -m "T2DECODE $nom : $message"
git push -q "$remote" HEAD:refs/heads/main
git push -q "$remote" "refs/tags/$tag"
echo "✅ $tag envoyé sur GitHub : la CI publie (~25 min)."
echo "   Suivi : https://github.com/TUTODECODE-FR/T2DECODE/actions"
