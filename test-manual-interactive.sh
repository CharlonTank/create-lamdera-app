#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base directory for tests
BASE_DIR="manual-tests"
RESULTS_FILE="$BASE_DIR/recap.md"

# Check if manual-tests directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo -e "${RED}No manual-tests directory found!${NC}"
    echo -e "${YELLOW}Run ./test-all-combinations.sh first to create test projects${NC}"
    exit 1
fi

cd "$BASE_DIR"

# Get all app directories - filter to essential combinations only
all_apps=($(ls -d app-* 2>/dev/null | sort))

# If we have the full set, filter to essential combinations
if [ ${#all_apps[@]} -gt 10 ]; then
    # Use simplified set
    apps=(
        "app-basic"
        "app-basic-cursor"
        "app-tailwind"
        "app-test"
        "app-i18n"
        "app-tailwind-test"
        "app-tailwind-i18n"
        "app-test-i18n"
        "app-all-features"
    )
    # Check which ones exist
    existing_apps=()
    for app in "${apps[@]}"; do
        if [ -d "$app" ]; then
            existing_apps+=("$app")
        fi
    done
    apps=("${existing_apps[@]}")
else
    # Use all available apps
    apps=("${all_apps[@]}")
fi

if [ ${#apps[@]} -eq 0 ]; then
    echo -e "${RED}No test apps found!${NC}"
    echo -e "${YELLOW}Run ./test-all-combinations.sh or ./test-all-combinations-simplified.sh first${NC}"
    exit 1
fi

# Declare associative arrays properly
declare -A results=()
declare -A notes=()

# Function to clean up server processes
cleanup_server() {
    # Kill any running lamdera processes
    pkill -f "lamdera live" 2>/dev/null
    # Kill any running node processes (for npm start)
    pkill -f "node.*run-pty" 2>/dev/null
    # Kill any running tailwind processes
    pkill -f "tailwindcss" 2>/dev/null
    # Wait a moment for processes to die
    sleep 1
}

# Function to check if app has Tailwind
has_tailwind() {
    [ -f "$1/tailwind.config.js" ]
}

# Function to check if app has tests
has_tests() {
    [ -f "$1/tests/Tests.elm" ]
}

# Function to check if app has i18n
has_i18n() {
    [ -f "$1/src/I18n.elm" ]
}

# Function to get app features
get_features() {
    local app=$1
    local features=""
    
    [ -f "$app/.cursorrules" ] && features="${features}Cursor "
    has_tailwind "$app" && features="${features}Tailwind "
    has_tests "$app" && features="${features}Test "
    has_i18n "$app" && features="${features}i18n "
    
    [ -z "$features" ] && features="Basic"
    echo "$features"
}

# Header
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
echo -e "║     Manual Interactive Test Runner                ║"
echo -e "╚═══════════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Found ${#apps[@]} test applications${NC}"
echo -e "${YELLOW}Instructions:${NC}"
echo -e "  - Each app will launch automatically"
echo -e "  - Test the app in your browser at http://localhost:8000"
echo -e "  - Press ${GREEN}ENTER${NC} to mark as working and continue"
echo -e "  - Type any text + ${GREEN}ENTER${NC} to add notes about issues"
echo -e "  - Press ${RED}Ctrl+C${NC} to abort testing\n"

echo -e "${CYAN}Press ENTER to start testing...${NC}"
read

# Test each app
for i in "${!apps[@]}"; do
    app="${apps[$i]}"
    app_num=$((i + 1))
    features=$(get_features "$app")
    
    clear
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
    echo -e "║     Testing App $app_num of ${#apps[@]}                         ║"
    echo -e "╚═══════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BLUE}App: ${CYAN}$app${NC}"
    echo -e "${BLUE}Features: ${CYAN}$features${NC}\n"
    
    # Clean up any existing servers
    cleanup_server
    
    # Change to app directory
    cd "$app"
    
    # First, test if the app compiles
    echo -e "${BLUE}Testing compilation...${NC}"
    COMPILE_ERROR=""
    if ! lamdera make src/Frontend.elm src/Backend.elm > compile_output.txt 2>&1; then
        COMPILE_ERROR=$(cat compile_output.txt | head -50)
        echo -e "${RED}✗ Compilation failed${NC}"
        echo -e "${YELLOW}Error preview:${NC}"
        echo "$COMPILE_ERROR" | head -10
        echo -e "${YELLOW}(Full error will be saved in recap)${NC}\n"
    else
        echo -e "${GREEN}✓ Compilation successful${NC}"
    fi
    rm -f compile_output.txt
    
    # Test if app has tests and run them
    TEST_ERROR=""
    if has_tests "." && [ -z "$COMPILE_ERROR" ]; then
        echo -e "${BLUE}Running tests...${NC}"
        if ! elm-test-rs --compiler $(which lamdera) > test_output.txt 2>&1; then
            TEST_ERROR=$(cat test_output.txt | tail -30)
            echo -e "${RED}✗ Tests failed${NC}"
        else
            echo -e "${GREEN}✓ Tests passed${NC}"
        fi
        rm -f test_output.txt
    fi
    
    # Determine how to start the app
    if has_tailwind "."; then
        echo -e "${YELLOW}Starting with npm start (Tailwind detected)...${NC}"
        PORT=8000 npm start > server_output.txt 2>&1 &
        SERVER_PID=$!
    else
        echo -e "${YELLOW}Starting with lamdera-dev-watch.sh...${NC}"
        ./lamdera-dev-watch.sh > server_output.txt 2>&1 &
        SERVER_PID=$!
    fi
    
    # Wait for server to start
    echo -e "${BLUE}Waiting for server to start...${NC}"
    sleep 3
    
    # Check if server is running
    SERVER_ERROR=""
    if lsof -ti:8000 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Server started successfully${NC}"
        echo -e "${CYAN}Visit: http://localhost:8000${NC}\n"
    else
        echo -e "${RED}✗ Server failed to start${NC}\n"
        SERVER_ERROR=$(tail -20 server_output.txt)
    fi
    rm -f server_output.txt
    
    # Features to test
    echo -e "${YELLOW}Things to test:${NC}"
    echo -e "  - Page loads without errors"
    echo -e "  - Basic functionality works"
    has_tailwind "." && echo -e "  - Tailwind styles are applied"
    has_i18n "." && echo -e "  - Language switcher works (EN/FR)"
    has_i18n "." && echo -e "  - Dark mode toggle works"
    has_i18n "." && echo -e "  - Settings persist on refresh"
    has_tests "." && echo -e "  - Run: elm-test-rs --compiler \$(which lamdera)"
    
    # Check for automatic errors
    AUTO_ERRORS=""
    if [ -n "$COMPILE_ERROR" ]; then
        AUTO_ERRORS="**Compilation Error:** $COMPILE_ERROR"
    elif [ -n "$TEST_ERROR" ]; then
        AUTO_ERRORS="**Test Error:** $TEST_ERROR"
    elif [ -n "$SERVER_ERROR" ]; then
        AUTO_ERRORS="**Server Error:** $SERVER_ERROR"
    fi
    
    echo -e "\n${GREEN}Press ENTER if working, or type notes about issues:${NC}"
    read user_input
    
    # Store result - use a clean key to avoid bash interpretation issues
    app_key=$(echo "$app" | tr '-' '_')
    
    if [ -z "$user_input" ] && [ -z "$AUTO_ERRORS" ]; then
        results[$app_key]="✓ Working"
        notes[$app_key]=""
    else
        results[$app_key]="✗ Issues"
        # Combine automatic errors and user notes
        if [ -n "$AUTO_ERRORS" ] && [ -n "$user_input" ]; then
            notes[$app_key]="$AUTO_ERRORS | **User notes:** $user_input"
        elif [ -n "$AUTO_ERRORS" ]; then
            notes[$app_key]="$AUTO_ERRORS"
        else
            notes[$app_key]="$user_input"
        fi
    fi
    
    # Kill the server
    cleanup_server
    
    # Return to manual-tests directory
    cd ..
    
    echo -e "${BLUE}Moving to next app...${NC}"
    sleep 1
done

# Generate recap
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
echo -e "║     Test Results Summary                          ║"
echo -e "╚═══════════════════════════════════════════════════╝${NC}\n"

# Create recap.md
cat > "$RESULTS_FILE" << EOF
# Manual Test Results
Generated: $(date)

## Summary

Total apps tested: ${#apps[@]}

## Results Table

| App | Features | Status |
|-----|----------|--------|
EOF

# Count working/failing
working=0
failing=0

# Add results to table
for app in "${apps[@]}"; do
    features=$(get_features "$app")
    app_key=$(echo "$app" | tr '-' '_')
    status="${results[$app_key]}"
    
    # Count status
    if [[ "$status" == *"Working"* ]]; then
        ((working++))
    else
        ((failing++))
    fi
    
    echo "| $app | $features | $status |" >> "$RESULTS_FILE"
done

# Add detailed errors section
echo -e "\n## Detailed Issues\n" >> "$RESULTS_FILE"

for app in "${apps[@]}"; do
    app_key=$(echo "$app" | tr '-' '_')
    if [[ "${results[$app_key]}" == *"Issues"* ]] && [ -n "${notes[$app_key]}" ]; then
        echo "### $app" >> "$RESULTS_FILE"
        echo "" >> "$RESULTS_FILE"
        # Format multiline errors properly
        if [[ "${notes[$app_key]}" == *"Compilation Error:"* ]] || [[ "${notes[$app_key]}" == *"Server Error:"* ]] || [[ "${notes[$app_key]}" == *"Test Error:"* ]]; then
            # Split automatic errors and user notes
            if [[ "${notes[$app_key]}" == *" | **User notes:** "* ]]; then
                AUTO_PART="${notes[$app_key]%% | **User notes:** *}"
                USER_PART="${notes[$app_key]##* | **User notes:** }"
                echo "$AUTO_PART" | sed 's/\*\*Compilation Error:\*\*/#### Compilation Error\n```elm/' | sed 's/\*\*Server Error:\*\*/#### Server Error\n```/' | sed 's/\*\*Test Error:\*\*/#### Test Error\n```/' >> "$RESULTS_FILE"
                echo '```' >> "$RESULTS_FILE"
                echo "" >> "$RESULTS_FILE"
                echo "#### User Notes" >> "$RESULTS_FILE"
                echo "$USER_PART" >> "$RESULTS_FILE"
            else
                echo "${notes[$app_key]}" | sed 's/\*\*Compilation Error:\*\*/#### Compilation Error\n```elm/' | sed 's/\*\*Server Error:\*\*/#### Server Error\n```/' | sed 's/\*\*Test Error:\*\*/#### Test Error\n```/' >> "$RESULTS_FILE"
                echo '```' >> "$RESULTS_FILE"
            fi
        else
            echo "#### User Notes" >> "$RESULTS_FILE"
            echo "${notes[$app_key]}" >> "$RESULTS_FILE"
        fi
        echo "" >> "$RESULTS_FILE"
    fi
done

# Add summary stats
cat >> "$RESULTS_FILE" << EOF

## Statistics

- **Working**: $working apps
- **With Issues**: $failing apps
- **Success Rate**: $(( working * 100 / ${#apps[@]} ))%

## Test Configuration

All apps were tested with:
- Port: 8000
- Browser: (manual check)
- Platform: $(uname -s)
EOF

# Display results
echo -e "${BLUE}Results saved to: ${CYAN}$RESULTS_FILE${NC}\n"

echo -e "${GREEN}Summary:${NC}"
echo -e "  - Working: ${GREEN}$working${NC}"
echo -e "  - Issues: ${RED}$failing${NC}"

# Show failing apps if any
if [ $failing -gt 0 ]; then
    echo -e "\n${YELLOW}Apps with issues:${NC}"
    for app in "${apps[@]}"; do
        app_key=$(echo "$app" | tr '-' '_')
        if [[ "${results[$app_key]}" == *"Issues"* ]]; then
            # Show first line of notes only for summary
            first_line=$(echo "${notes[$app_key]}" | head -1)
            echo -e "  ${RED}$app${NC}: $first_line"
        fi
    done
fi

echo -e "\n${GREEN}Testing complete!${NC}"