#!/bin/bash
git filter-branch -f --env-filter '
if [ "$GIT_AUTHOR_EMAIL" = "108419734+itswinancher@users.noreply.github.com" ] || [ "$GIT_AUTHOR_EMAIL" = "emmc4401@gmail.com" ] || [ "$GIT_AUTHOR_NAME" = "MAX" ] || [ "$GIT_AUTHOR_NAME" = "MAXIME MARTIN CIVET" ] || [ "$GIT_AUTHOR_NAME" = "winancher" ] || [ "$GIT_AUTHOR_NAME" = "Winancher" ]; then
    export GIT_AUTHOR_NAME="winancher"
    export GIT_AUTHOR_EMAIL="108419734+itswinancher@users.noreply.github.com"
fi
if [ "$GIT_COMMITTER_EMAIL" = "108419734+itswinancher@users.noreply.github.com" ] || [ "$GIT_COMMITTER_EMAIL" = "emmc4401@gmail.com" ] || [ "$GIT_COMMITTER_NAME" = "MAX" ] || [ "$GIT_COMMITTER_NAME" = "MAXIME MARTIN CIVET" ] || [ "$GIT_COMMITTER_NAME" = "winancher" ] || [ "$GIT_COMMITTER_NAME" = "Winancher" ]; then
    export GIT_COMMITTER_NAME="winancher"
    export GIT_COMMITTER_EMAIL="108419734+itswinancher@users.noreply.github.com"
fi
' --tag-name-filter cat -- --branches --tags
