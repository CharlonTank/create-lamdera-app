#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Base directory for tests
BASE_DIR="manual-tests"

# Check if manual-tests directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo -e "${RED}No manual-tests directory found!${NC}"
    echo -e "${YELLOW}Run ./test-all-combinations.sh first to create test projects${NC}"
    exit 1
fi

# Store the project root directory
PROJECT_ROOT="$(pwd)"

cd "$BASE_DIR"

# Set results file path to be in project root
RESULTS_FILE="$PROJECT_ROOT/test_recap.json"

# Get all app directories - filter to essential combinations only
all_apps=($(ls -d app-* 2>/dev/null | sort))

# If we have the full set, filter to essential combinations
if [ ${#all_apps[@]} -gt 10 ]; then
    # Use simplified set
    apps=(
        "app-basic"
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
    echo -e "${YELLOW}Run ./test-all-combinations.sh first${NC}"
    exit 1
fi

# Use regular arrays with indices instead of associative arrays
# This avoids bash associative array issues
unset app_results
unset app_notes
unset app_names
app_results=()
app_notes=()
app_names=()

# Track which apps have been tested - ensure it's empty
unset tested_apps
tested_apps=()

# Helper function to get index for an app
get_app_index() {
    local app_name="$1"
    local i
    for i in "${!app_names[@]}"; do
        if [[ "${app_names[$i]}" == "$app_name" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
    return 1
}

# Helper function to store result
store_result() {
    local app_name="$1"
    local result="$2"
    local note="$3"
    
    # Add to arrays
    app_names+=("$app_name")
    app_results+=("$result")
    app_notes+=("$note")
    
    local idx=$((${#app_names[@]} - 1))
}

# Helper function to get result
get_result() {
    local app_name="$1"
    local idx=$(get_app_index "$app_name")
    if [ "$idx" -ge 0 ]; then
        echo "${app_results[$idx]}"
    fi
}

# Helper function to get note
get_note() {
    local app_name="$1"
    local idx=$(get_app_index "$app_name")
    if [ "$idx" -ge 0 ]; then
        echo "${app_notes[$idx]}"
    fi
}

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

# Function to generate recap (for both normal exit and interruption)
generate_recap() {
    # Only generate if we tested at least one app
    if [ ${#tested_apps[@]} -eq 0 ]; then
        echo -e "${YELLOW}No apps were tested, skipping recap generation${NC}"
        return
    fi
    
    clear
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
    echo -e "║     Test Results Summary                          ║"
    echo -e "╚═══════════════════════════════════════════════════╝${NC}\n"

    # Ensure we can write to the file
    touch "$RESULTS_FILE" 2>/dev/null || {
        echo -e "${RED}ERROR: Cannot write to $RESULTS_FILE${NC}"
        echo -e "${YELLOW}Current directory: $(pwd)${NC}"
        echo -e "${YELLOW}File permissions: $(ls -la "$RESULTS_FILE" 2>&1)${NC}"
        return 1
    }
    
    # Count working/failing
    working=0
    failing=0
    not_tested=0

    # Create JSON structure
    echo '{' > "$RESULTS_FILE"
    echo '  "generated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",' >> "$RESULTS_FILE"
    echo '  "summary": {' >> "$RESULTS_FILE"
    echo '    "totalApps": '${#apps[@]}',' >> "$RESULTS_FILE"
    echo '    "testedApps": '${#tested_apps[@]}',' >> "$RESULTS_FILE"
    echo '    "interrupted": '$([ ${#tested_apps[@]} -lt ${#apps[@]} ] && echo "true" || echo "false") >> "$RESULTS_FILE"
    echo '  },' >> "$RESULTS_FILE"
    echo '  "results": {' >> "$RESULTS_FILE"
    
    # Add tested apps
    first=true
    for app in "${tested_apps[@]}"; do
        features=$(get_features "$app")
        status=$(get_result "$app")
        note=$(get_note "$app")
        
        # Count status
        if [[ "$status" == *"Working"* ]]; then
            ((working++))
            status_value="working"
        else
            ((failing++))
            status_value="issues"
        fi
        
        # Add comma for all but first entry
        if [ "$first" = true ]; then
            first=false
        else
            echo ',' >> "$RESULTS_FILE"
        fi
        
        # Escape quotes in note
        escaped_note=$(echo "$note" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
        
        # Write app entry
        echo -n '    "'$app'": {' >> "$RESULTS_FILE"
        echo -n '"status": "'$status_value'",' >> "$RESULTS_FILE"
        echo -n '"features": "'$(echo "$features" | xargs)'",' >> "$RESULTS_FILE"
        echo -n '"note": "'$escaped_note'"' >> "$RESULTS_FILE"
        echo -n '}' >> "$RESULTS_FILE"
    done
    
    # Add untested apps if testing was interrupted
    if [ ${#tested_apps[@]} -lt ${#apps[@]} ]; then
        for app in "${apps[@]}"; do
            if [[ ! " ${tested_apps[@]} " =~ " ${app} " ]]; then
                ((not_tested++))
                features=$(get_features "$app")
                
                echo ',' >> "$RESULTS_FILE"
                echo -n '    "'$app'": {' >> "$RESULTS_FILE"
                echo -n '"status": "not_tested",' >> "$RESULTS_FILE"
                echo -n '"features": "'$(echo "$features" | xargs)'",' >> "$RESULTS_FILE"
                echo -n '"note": ""' >> "$RESULTS_FILE"
                echo -n '}' >> "$RESULTS_FILE"
            fi
        done
    fi
    
    echo '' >> "$RESULTS_FILE"
    echo '  },' >> "$RESULTS_FILE"
    
    # Add statistics
    success_rate=0
    if [ ${#tested_apps[@]} -gt 0 ]; then
        success_rate=$(( working * 100 / ${#tested_apps[@]} ))
    fi
    
    echo '  "statistics": {' >> "$RESULTS_FILE"
    echo '    "working": '$working',' >> "$RESULTS_FILE"
    echo '    "issues": '$failing',' >> "$RESULTS_FILE"
    echo '    "notTested": '$not_tested',' >> "$RESULTS_FILE"
    echo '    "successRate": '$success_rate >> "$RESULTS_FILE"
    echo '  },' >> "$RESULTS_FILE"
    
    # Add test configuration
    echo '  "configuration": {' >> "$RESULTS_FILE"
    echo '    "port": 8000,' >> "$RESULTS_FILE"
    echo '    "platform": "'$(uname -s)'"' >> "$RESULTS_FILE"
    echo '  }' >> "$RESULTS_FILE"
    echo '}' >> "$RESULTS_FILE"
    
    # Display results
    echo -e "${BLUE}Results saved to: ${CYAN}$RESULTS_FILE${NC}\n"

    echo -e "${GREEN}Summary:${NC}"
    echo -e "  - Tested: ${CYAN}${#tested_apps[@]}${NC} of ${#apps[@]} apps"
    echo -e "  - Working: ${GREEN}$working${NC}"
    echo -e "  - Issues: ${RED}$failing${NC}"

    # Show failing apps if any
    if [ $failing -gt 0 ]; then
        echo -e "\n${YELLOW}Apps with issues:${NC}"
        for app in "${tested_apps[@]}"; do
            status=$(get_result "$app")
            if [[ "$status" == *"Issues"* ]]; then
                # Show first line of notes only for summary
                note=$(get_note "$app")
                first_line=$(echo "$note" | head -1)
                echo -e "  ${RED}$app${NC}: $first_line"
            fi
        done
    fi
}

# Trap to handle interruption (Ctrl+C)
trap 'echo -e "\n\n${YELLOW}Testing interrupted by user${NC}"; cleanup_server; generate_recap; echo -e "\n${GREEN}Partial results saved!${NC}"; exit 0' INT

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
    
    # Check if we need to add the path prefix
    local app_path="$app"
    if [ ! -d "$app_path" ] && [ -d "./$app" ]; then
        app_path="./$app"
    fi
    
    [ -f "$app_path/.cursorrules" ] && features="${features}Cursor "
    has_tailwind "$app_path" && features="${features}Tailwind "
    has_tests "$app_path" && features="${features}Test "
    has_i18n "$app_path" && features="${features}i18n "
    
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
echo -e "  - Press ${RED}Ctrl+C${NC} at any time to stop (your feedback will be saved)\n"

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
        echo -e "${BLUE}Running tests with elm-test-rs...${NC}"
        # Run tests and show output directly
        if ! elm-test-rs --compiler $(which lamdera); then
            TEST_ERROR="Tests failed - see output above"
            echo -e "${RED}✗ Tests failed${NC}"
        else
            echo -e "${GREEN}✓ All tests passed${NC}"
        fi
        echo ""  # Add spacing after test output
    fi
    
    # Determine package manager
    PM="npm"
    # Check for bun.lockb or if package.json has bunx in scripts
    if [ -f "bun.lockb" ] || ([ -f "package.json" ] && grep -q "bunx" package.json); then
        PM="bun"
    fi
    
    # Determine how to start the app
    if has_tailwind "."; then
        # Check if node_modules exists
        if [ ! -d "node_modules" ]; then
            echo -e "${YELLOW}Warning: node_modules not found. Running $PM install...${NC}"
            if [ "$PM" = "bun" ]; then
                bun install
            else
                npm install
            fi
        fi
        
        # Use start:ci for non-TTY environments (like this test script)
        echo -e "${YELLOW}Starting with $PM run start:ci (Tailwind detected, CI mode)...${NC}"
        if [ "$PM" = "bun" ]; then
            PORT=8000 bun run start:ci > server_output.txt 2>&1 &
        else
            PORT=8000 npm run start:ci > server_output.txt 2>&1 &
        fi
        SERVER_PID=$!
    else
        echo -e "${YELLOW}Starting with lamdera-dev-watch.sh...${NC}"
        ./lamdera-dev-watch.sh > server_output.txt 2>&1 &
        SERVER_PID=$!
    fi
    
    # Wait for server to start (give more time for Tailwind apps)
    echo -e "${BLUE}Waiting for server to start...${NC}"
    if has_tailwind "."; then
        sleep 5  # More time for Tailwind to compile
    else
        sleep 3
    fi
    
    # Check if server is running
    SERVER_ERROR=""
    if lsof -ti:8000 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Server started successfully${NC}"
        echo -e "${CYAN}Visit: http://localhost:8000${NC}\n"
    else
        echo -e "${RED}✗ Server failed to start${NC}"
        if [ -f "server_output.txt" ]; then
            echo -e "${YELLOW}Server output:${NC}"
            tail -10 server_output.txt
            SERVER_ERROR=$(cat server_output.txt)
        fi
        echo ""
    fi
    # Don't remove server_output.txt yet, keep for debugging
    
    # Features to test
    echo -e "${YELLOW}Things to test:${NC}"
    echo -e "  - Page loads without errors"
    echo -e "  - Basic functionality works"
    has_tailwind "." && echo -e "  - Tailwind styles are applied"
    has_i18n "." && echo -e "  - Language switcher works (EN/FR)"
    has_i18n "." && echo -e "  - Dark mode toggle works"
    has_i18n "." && echo -e "  - Settings persist on refresh"
    
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
    
    # Store result using the new method
    if [ -z "$user_input" ] && [ -z "$AUTO_ERRORS" ]; then
        store_result "$app" "✓ Working" ""
    else
        # Combine automatic errors and user notes
        local full_note=""
        if [ -n "$AUTO_ERRORS" ] && [ -n "$user_input" ]; then
            full_note="$AUTO_ERRORS | **User notes:** $user_input"
        elif [ -n "$AUTO_ERRORS" ]; then
            full_note="$AUTO_ERRORS"
        else
            full_note="$user_input"
        fi
        
        store_result "$app" "✗ Issues" "$full_note"
    fi
    
    # Add to tested apps
    tested_apps+=("$app")
    
    # Kill the server
    cleanup_server
    
    # Clean up server output file
    rm -f server_output.txt
    
    # Return to manual-tests directory
    cd ..
    
    echo -e "${BLUE}Moving to next app...${NC}"
    sleep 1
done

# Generate recap using our function
generate_recap

echo -e "\n${GREEN}Testing complete!${NC}"