#!/bin/sh

set -ex

if [[ "${INPUT_DESTINATION_HEAD_BRANCH}" == "main" ]] || [[ "${INPUT_DESTINATION_HEAD_BRANCH}" == "master" ]]; then
  echo "Destination head branch cannot be 'main' nor 'master'"
  return 1
fi

if [[ -z "${INPUT_PULL_REQUEST_REVIEWERS}" ]]; then
  PULL_REQUEST_REVIEWERS="${INPUT_PULL_REQUEST_REVIEWERS}"
else
  PULL_REQUEST_REVIEWERS="-r ${INPUT_PULL_REQUEST_REVIEWERS}"
fi

CLONE_DIR=$(mktemp -d)

echo "Setting git variables"
export GITHUB_TOKEN="${API_TOKEN_GITHUB}"
git config --global user.name "github-actions"
git config --global user.email "github-actions@users.noreply.github.com"

echo "Cloning destination git repository"
git clone "https://${API_TOKEN_GITHUB}@github.com/${INPUT_DESTINATION_REPO}.git" "${CLONE_DIR}"

echo "Copying contents to git repo"
cp -r ${INPUT_SOURCE} "${CLONE_DIR}/${INPUT_DESTINATION}"
cd "$CLONE_DIR"
git checkout -b "${INPUT_DESTINATION_HEAD_BRANCH}"

echo "Adding git commit"
git add .
if git status | grep -q "Changes to be committed"; then
  git commit --message "${INPUT_COMMIT_MSG}"
  echo "Pushing git commit"
  git push -u origin "HEAD:${INPUT_DESTINATION_HEAD_BRANCH}"
  echo "Creating a pull request"
  gh pr create -t "${INPUT_PR_TITLE}" \
               -b "${INPUT_COMMIT_MSG}" \
               -B "${INPUT_DESTINATION_BASE_BRANCH}" \
               -H "${INPUT_DESTINATION_HEAD_BRANCH}" \
                  "${PULL_REQUEST_REVIEWERS}"
else
  echo "No changes detected"
fi
