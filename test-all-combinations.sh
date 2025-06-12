#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory for tests
BASE_DIR="manual-tests"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create manual-tests directory if it doesn't exist
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Clean up existing test directories
echo -e "${YELLOW}Cleaning up existing test directories...${NC}"
rm -rf app-*

# All possible flag combinations (excluding github)
# Flags: cursor, tailwind, test, i18n
declare -a apps=(
    # No flags
    "app-basic:"
    
    # Single flags
    "app-cursor:--cursor yes"
    "app-tailwind:--tailwind"
    "app-test:--test"
    "app-i18n:--i18n"
    
    # Two flags
    "app-cursor-tailwind:--cursor yes --tailwind"
    "app-cursor-test:--cursor yes --test"
    "app-cursor-i18n:--cursor yes --i18n"
    "app-tailwind-test:--tailwind --test"
    "app-tailwind-i18n:--tailwind --i18n"
    "app-test-i18n:--test --i18n"
    
    # Three flags
    "app-cursor-tailwind-test:--cursor yes --tailwind --test"
    "app-cursor-tailwind-i18n:--cursor yes --tailwind --i18n"
    "app-cursor-test-i18n:--cursor yes --test --i18n"
    "app-tailwind-test-i18n:--tailwind --test --i18n"
    
    # All flags
    "app-all-features:--cursor yes --tailwind --test --i18n"
)

# Total number of combinations
total=${#apps[@]}
echo -e "${BLUE}Creating ${total} test applications with different flag combinations${NC}\n"

# Counter for progress
count=0

# Generate each app
for app_config in "${apps[@]}"; do
    count=$((count + 1))
    
    # Split the config into name and flags
    IFS=':' read -r app_name flags <<< "$app_config"
    
    echo -e "${GREEN}[$count/$total] Creating $app_name${NC}"
    
    # Build the command
    cmd="node ../index.js --name $app_name"
    if [ -n "$flags" ]; then
        cmd="$cmd $flags"
    fi
    
    # Execute the command
    echo -e "${BLUE}Running: $cmd${NC}"
    
    # Add --no-github to avoid any GitHub operations
    cmd="$cmd --no-github"
    
    # For apps with Tailwind, we'll need npm install which can be slow
    if [[ "$flags" == *"--tailwind"* ]]; then
        echo -e "${YELLOW}Note: This app includes Tailwind CSS, npm install may take a moment...${NC}"
        echo -e "${BLUE}Progress will be shown during npm installation${NC}"
    fi
    
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $app_name created successfully${NC}\n"
    else
        echo -e "${YELLOW}✗ Failed to create $app_name${NC}\n"
    fi
done

echo -e "${GREEN}All test applications created!${NC}"
echo -e "${BLUE}Testing compilation for each app...${NC}\n"

# Test compilation for each app
for app_config in "${apps[@]}"; do
    IFS=':' read -r app_name flags <<< "$app_config"
    
    echo -e "${GREEN}Testing $app_name...${NC}"
    
    cd "$app_name"
    
    # Test Elm compilation
    if lamdera make src/Frontend.elm src/Backend.elm > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Elm compilation successful${NC}"
    else
        echo -e "  ${YELLOW}✗ Elm compilation failed${NC}"
    fi
    
    # Test if tests exist and run them
    if [ -f "tests/Tests.elm" ]; then
        if elm-test-rs --compiler $(which lamdera) > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Tests pass${NC}"
        else
            echo -e "  ${YELLOW}✗ Tests failed${NC}"
        fi
    fi
    
    # Check if Tailwind is set up
    if [ -f "tailwind.config.js" ]; then
        if npx tailwindcss -i ./src/styles.css -o ./public/styles.css > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Tailwind CSS compilation successful${NC}"
        else
            echo -e "  ${YELLOW}✗ Tailwind CSS compilation failed${NC}"
        fi
    fi
    
    cd ..
    echo
done

echo -e "${GREEN}All tests completed!${NC}"
echo -e "${BLUE}You can now manually test each app by navigating to its directory and running:${NC}"
echo -e "  - For standard apps: ${YELLOW}./lamdera-dev-watch.sh${NC}"
echo -e "  - For Tailwind apps: ${YELLOW}npm start${NC}"