#!/usr/bin/env bash
# For each "name old -> new" line in nvcmp output: copy the AUR recipe to aur/<name>
# on a branch and open a PR so the PKGBUILD diff is reviewed before anything builds.
# Own-source packages (own/*) are rebuilt via workflow_dispatch instead (no review).
# Opening a new PR for a package closes older open update/<name>-* PRs, so only the newest stays.
set -euo pipefail
gh auth setup-git
while read -r name old arrow new; do
  # nvcmp prints "name old -> new" for updates and "name None ++ new" for packages with no recipe yet.
  [ "$arrow" = "->" ] || [ "$arrow" = "++" ] || continue
  if [ -d "own/$name" ]; then gh workflow run build.yml -f pkg="own/$name"; continue; fi
  git clone --depth 1 "https://aur.archlinux.org/$name.git" "/tmp/aur-$name"
  br="update/$name-${new//:/.}"; git checkout -B "$br"
  mkdir -p "aur/$name"; rsync -a --delete --exclude .git --exclude .gitignore "/tmp/aur-$name/" "aur/$name/"
  git add "aur/$name"
  # The recipe is already imported (e.g. only the pkgrel differs from old_ver.json): nothing to review.
  if git diff --cached --quiet; then echo "$name: recipe unchanged, skipping"; git checkout -q main; continue; fi
  git -c user.name=ci -c user.email=ci@users.noreply.github.com commit -qm "aur: $name $old -> $new"
  git push -f origin "$br"
  gh pr create --title "aur: $name $old -> $new" --body "Review the PKGBUILD diff before merging; merging triggers the build." --head "$br" || true
  # Close older open update PRs for the same package (their branches are named update/<name>-<version>).
  new_pr=$(gh pr list --state open --head "$br" --json number --jq '.[0].number // empty')
  if [ -n "$new_pr" ]; then
    gh pr list --state open --json number,headRefName \
      --jq ".[] | select(.headRefName | startswith(\"update/$name-\")) | select(.number != $new_pr) | .number" |
    while read -r old_pr; do
      gh pr close "$old_pr" --delete-branch --comment "Superseded by #$new_pr (newer update for $name)." || true
    done
  fi
  git checkout -q main
done < "$1"
