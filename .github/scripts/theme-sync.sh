#!/usr/bin/env bash
# Keep main's theme/ folder and the shopify-live branch in step.
#   shopify-live = theme/ at the branch root; Shopify's GitHub sync follows it, and the
#   theme editor commits the ladies' changes (text, photos, section order) back to it.
# Order matters: bring editor changes into main first, then rebuild shopify-live from main,
# so neither side overwrites the other. Pushes are fast-forward only; a merge conflict
# stops the run for a person to resolve.
set -euo pipefail

PREFIX=theme
MAIN=main
LIVE=shopify-live

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git fetch origin "$MAIN" "$LIVE"
git checkout -q -B "$MAIN" "origin/$MAIN"

split=$(git subtree split --prefix "$PREFIX")

if ! git merge-base --is-ancestor "origin/$LIVE" "$split"; then
  echo "$LIVE has changes main doesn't (theme editor); merging them into $MAIN/$PREFIX"
  if ! git merge-base HEAD "origin/$LIVE" >/dev/null; then
    # First time: record in main which shopify-live commit it matches, so git can merge the two
    git subtree split --prefix "$PREFIX" --rejoin
  fi
  git subtree merge --prefix "$PREFIX" "origin/$LIVE" -m "Merge Shopify theme editor changes from $LIVE"
  git push origin "$MAIN"
  split=$(git subtree split --prefix "$PREFIX")
fi

if [ "$split" = "$(git rev-parse "origin/$LIVE")" ]; then
  echo "$LIVE is already up to date"
else
  echo "Updating $LIVE to $split"
  git push origin "$split:refs/heads/$LIVE"
fi
