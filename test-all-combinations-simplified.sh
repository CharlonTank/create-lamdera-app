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

# Simplified test combinations (excluding cursor since it doesn't affect functionality)
# We'll test cursor only once with basic to verify it works
declare -a apps=(
    # Basic tests
    "app-basic:"
    "app-basic-cursor:--cursor yes"  # Just to verify cursor files are created
    
    # Single feature tests
    "app-tailwind:--tailwind"
    "app-test:--test"
    "app-i18n:--i18n"
    
    # Two feature combinations
    "app-tailwind-test:--tailwind --test"
    "app-tailwind-i18n:--tailwind --i18n"
    "app-test-i18n:--test --i18n"
    
    # Three features
    "app-all-features:--tailwind --test --i18n"
)

# Total number of combinations
total=${#apps[@]}
echo -e "${BLUE}Creating ${total} test applications (simplified set)${NC}\n"

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
    
    # Add --no-github to avoid any GitHub operations
    cmd="$cmd --no-github"
    
    # Execute the command
    echo -e "${BLUE}Running: $cmd${NC}"
    
    # For apps with Tailwind, add skip-install flag if requested
    if [[ "$flags" == *"--tailwind"* ]]; then
        if [ "${SKIP_NPM_INSTALL:-false}" = "true" ]; then
            echo -e "${YELLOW}Note: Skipping npm install for Tailwind (use SKIP_NPM_INSTALL=false to enable)${NC}"
            cmd="$cmd --skip-install"
        else
            echo -e "${YELLOW}Note: This app includes Tailwind CSS, npm install may take a moment...${NC}"
        fi
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
    
    # Check if cursor files were created (only for the cursor test)
    if [[ "$app_name" == "app-basic-cursor" ]]; then
        if [ -f ".cursorrules" ] && [ -f "openEditor.sh" ]; then
            echo -e "  ${GREEN}✓ Cursor files created successfully${NC}"
        else
            echo -e "  ${YELLOW}✗ Cursor files missing${NC}"
        fi
    fi
    
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
echo -e "${BLUE}Functional test combinations:${NC}"
echo -e "  - Basic (no features)"
echo -e "  - Single features: Tailwind, Test, i18n"
echo -e "  - All pairs of features"
echo -e "  - All features combined"
echo -e "\n${YELLOW}Note: Cursor flag only adds .cursorrules and openEditor.sh${NC}"
echo -e "${YELLOW}      It doesn't affect other features, so we test it once.${NC}"