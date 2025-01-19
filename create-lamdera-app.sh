#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) is not installed. Please install it to use the GitHub repository creation feature.${NC}"
    echo -e "${BLUE}You can continue without GitHub repository creation.${NC}"
fi

# Check if lamdera is installed
if ! command -v lamdera &> /dev/null; then
    echo -e "${RED}Lamdera is not installed. Please install it first.${NC}"
    exit 1
fi

# Ask for project name
echo -e "${CYAN}Enter your project name:${NC}"
read project_name

# Create project directory
mkdir "$project_name"
cd "$project_name"

# Copy Lamdera template files
echo -e "${BLUE}Initializing Lamdera project...${NC}"
cp -r ../templates/lamdera-init/* .

# Copy utility files
echo -e "${BLUE}Creating utility files...${NC}"
cp ../templates/lamdera-dev-watch.sh .
chmod +x lamdera-dev-watch.sh
cp ../templates/toggle-debugger.py .
chmod +x toggle-debugger.py

# Ask about Cursor editor
echo -e "${CYAN}Do you use Cursor editor? (y/n)${NC}"
read use_cursor

if [ "$use_cursor" = "y" ] || [ "$use_cursor" = "Y" ]; then
    cp ../templates/.cursorrules .
    cp ../templates/openEditor.sh .
    chmod +x openEditor.sh
fi

# Ask if user wants to create a GitHub repository
echo -e "${CYAN}Do you want to create a GitHub repository? (y/n)${NC}"
read create_repo

if [ "$create_repo" = "y" ] || [ "$create_repo" = "Y" ]; then
    if command -v gh &> /dev/null; then
        echo -e "${CYAN}Do you want the repository to be public or private? (pub/priv)${NC}"
        read repo_visibility
        
        visibility_flag="--private"
        if [ "$repo_visibility" = "pub" ]; then
            visibility_flag="--public"
        fi
        
        echo -e "${BLUE}Creating GitHub repository...${NC}"
        git init
        git add .
        git commit -m "Initial commit"
        gh repo create "$project_name" $visibility_flag --source=. --remote=origin --push
        echo -e "${GREEN}GitHub repository created and code pushed!${NC}"
    else
        echo -e "${RED}GitHub CLI (gh) is not installed. Skipping repository creation.${NC}"
    fi
fi

echo -e "${GREEN}Project setup complete!${NC}"
echo -e "${BLUE}To start development server:${NC}"
echo -e "${CYAN}cd $project_name${NC}"
echo -e "${CYAN}./lamdera-dev-watch.sh${NC}" 