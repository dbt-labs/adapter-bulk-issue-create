#!/bin/bash

# list of repos stored in a file
repos_file="repos.txt"
issue_title="upgrade to support dbt-core v1.6.0"
issue_body_file="upgrade_16.md"

# create an array from the line-delimited list of repos
repos=($(cat $repos_file))

# loop over the list of repos
for repo in "${repos[@]}"; do
  # create an issue in the repo using the GitHub CLI
  gh issue create -R $repo --title "$issue_title" -F $issue_body_file
done