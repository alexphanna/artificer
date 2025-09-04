#!/usr/bin/env sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# get user input
read -p "Enter repository full name ({owner}/{repo}): " repo 
# read -p "Enter GitHub personal access token: " token 
# -H "Authorization: Bearer ${token}" \

# get repo forks
forks=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${repo}/forks?per_page=5")

# analyze forks
i=1
echo "$forks" | jq -r ".[].full_name" | while read -r fork; do
    # get fork artifacts
    artifacts=$(curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${fork}/actions/artifacts")

    total_count=$(echo "$artifacts" | jq -r '.total_count')

    if (( total_count > 0 )); then
        echo -e "$((i++)). ${fork}: ${GREEN}${total_count}${NC}"

        echo "$artifacts" | jq -r ".artifacts.[].archive_download_url" | while read -r artifact; do 
            echo -e "\t- $artifact"
        done
    else
        echo -e "$((i++)). ${fork}: ${RED}${total_count}${NC}"
    fi
done