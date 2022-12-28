#!/bin/bash

set -e
set -x

if [ -z "$INPUT_SOURCE_FILES" ]
then
  echo "Source file must be defined"
  return -1
fi

if [ $INPUT_DESTINATION_HEAD_BRANCH == "main" ] || [ $INPUT_DESTINATION_HEAD_BRANCH == "master"] || [ $INPUT_DESTINATION_HEAD_BRANCH == "qa"]
then
  echo "Destination head branch cannot be 'main', 'master' or 'qa'"
  return -1
fi

if [ -z "$INPUT_PULL_REQUEST_REVIEWERS" ]
then
  PULL_REQUEST_REVIEWERS=$INPUT_PULL_REQUEST_REVIEWERS
else
  PULL_REQUEST_REVIEWERS='-r '$INPUT_PULL_REQUEST_REVIEWERS
fi

CLONE_DIR=$(mktemp -d)

echo "Setting git variables"
export GITHUB_TOKEN=$API_TOKEN_GITHUB
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"

echo "Cloning destination git repository"
git clone "https://$API_TOKEN_GITHUB@github.com/$INPUT_DESTINATION_REPO.git" "$CLONE_DIR"

echo "Copying contents to git repo"
file_names=${INPUT_SOURCE_FILES//;/ }
files_length=${#file_names[@]}
for i in "${file_names[@]}"
do
  tmp=${i//[^0-9.]/}
  version=${tmp%?}
  if [ ! -d "$CLONE_DIR/$INPUT_DESTINATION_FOLDER/dd-$version"];then
   mkdir "$CLONE_DIR/$INPUT_DESTINATION_FOLDER/dd-$version" 
  fi
  cp "$INPUT_SOURCE_FOLDER/i" "$CLONE_DIR/$INPUT_DESTINATION_FOLDER/dd-$version" 
done

cd "$CLONE_DIR"
git checkout -b "$INPUT_DESTINATION_HEAD_BRANCH"

echo "Adding git commit"
git add .
if git status | grep -q "Changes to be committed"
then
  git commit --message "Update from https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
  echo "Pushing git commit"
  git push -u origin HEAD:$INPUT_DESTINATION_HEAD_BRANCH
  echo "Creating a pull request"
  gh pr create -t $INPUT_DESTINATION_HEAD_BRANCH \
               -b $INPUT_DESTINATION_HEAD_BRANCH \
               -B $INPUT_DESTINATION_BASE_BRANCH \
               -H $INPUT_DESTINATION_HEAD_BRANCH \
                  $PULL_REQUEST_REVIEWERS
else
  echo "No changes detected"
fi
