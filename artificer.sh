#!/usr/bin/env sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

NUMBER_OF_FORKS=100;

# $1 is repo
# $2 is repo owner
# $3 is fork owner
compare_fork() {
    compare=$(curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H $token_string \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${2}/${1}/compare/main...${3}:main")

    if [ "$(echo "$compare" | jq -r '.status')" = "identical" ]; then
        return 0
    else
        return 1
    fi
}

# get user input
read -p "Enter repository owner: " repo_owner
read -p "Enter repository name: " repo_name 
read -p "Enter GitHub personal access token (enter to skip): " token

if [ "$token" = "" ]; then
    token_string=""
else
    token_string="Authorization: Bearer ${token}"
fi

# get repo forks
forks=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H $token_string \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${repo_owner}/${repo_name}/forks?per_page=${NUMBER_OF_FORKS}")

# analyze forks
i=1
echo "$forks" | jq -r ".[].full_name" | while read -r fork; do
    if (compare_fork $repo_name $repo_owner $(echo "$fork" | cut -d '/' -f1)); then
        # get fork artifacts
        artifacts=$(curl -s -L \
            -H "Accept: application/vnd.github+json" \
            -H $token_string \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/${fork}/actions/artifacts")

        total_count=$(echo "$artifacts" | jq -r '.total_count')

        if (( total_count > 0 )); then
            echo -e "$((i++)). ${GREEN}${fork}${NC}"
        else
            echo -e "$((i++)). ${RED}${fork}${NC}"
        fi
    else
        echo -e "$((i++)). ${RED}${fork}${NC}"
    fi
done