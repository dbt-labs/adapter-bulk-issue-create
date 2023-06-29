#!/bin/bash

# list of repos stored in a file
issue_file="issues_16.txt"
issue_body_file="upgrade_16.md"

# create an array from the line-delimited list of repos
issues=($(cat $issue_file))

# loop over the list of repos
for issue in "${issues[@]}"; do
  # create an issue in the repo using the GitHub CLI
  gh issue edit $issue -F $issue_body_file
done