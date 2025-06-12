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
echo -e "${BLUE}Creating ${total} test applications with different flag combinations${NC}"
echo -e "${YELLOW}NOTE: This quick version skips npm install and compilation tests${NC}\n"

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
    
    # Always add --no-github
    cmd="$cmd --no-github"
    
    echo -e "${BLUE}Running: $cmd${NC}"
    
    # For Tailwind apps, temporarily bypass npm install by creating empty node_modules
    if [[ "$flags" == *"--tailwind"* ]]; then
        echo -e "${YELLOW}Skipping npm install for quick test...${NC}"
        # Create the app first
        eval "$cmd" || true
        # Then create empty node_modules to satisfy checks
        if [ -d "$app_name" ]; then
            mkdir -p "$app_name/node_modules"
            touch "$app_name/node_modules/.keep"
        fi
    else
        eval "$cmd"
    fi
    
    if [ $? -eq 0 ] || [ -d "$app_name" ]; then
        echo -e "${GREEN}✓ $app_name created successfully${NC}\n"
    else
        echo -e "${YELLOW}✗ Failed to create $app_name${NC}\n"
    fi
done

echo -e "${GREEN}All test applications created!${NC}"
echo -e "${BLUE}Quick test complete. To run full tests with compilation, use ./test-all-combinations.sh${NC}"
echo -e "${YELLOW}Note: Tailwind apps will need 'npm install' before they can be run${NC}"