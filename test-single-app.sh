#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <app-name> [port]${NC}"
    echo -e "${YELLOW}Example: $0 app-tailwind-i18n 3000${NC}"
    echo -e "\n${BLUE}Available apps:${NC}"
    if [ -d "manual-tests" ]; then
        cd manual-tests
        ls -d app-* 2>/dev/null | sort | while read app; do
            echo "  - $app"
        done
    else
        echo -e "${RED}No manual-tests directory found!${NC}"
    fi
    exit 1
fi

APP_NAME=$1
PORT=${2:-8000}
BASE_DIR="manual-tests"

# Check if app exists
if [ ! -d "$BASE_DIR/$APP_NAME" ]; then
    echo -e "${RED}App '$APP_NAME' not found in $BASE_DIR/${NC}"
    exit 1
fi

# Function to clean up server processes
cleanup_server() {
    pkill -f "lamdera live" 2>/dev/null
    pkill -f "concurrently" 2>/dev/null
    pkill -f "tailwindcss" 2>/dev/null
    sleep 1
}

# Clean up any existing servers
cleanup_server

# Trap to ensure cleanup on exit
trap cleanup_server EXIT INT TERM

cd "$BASE_DIR/$APP_NAME"

echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
echo -e "║     Testing $APP_NAME                             ║"
echo -e "╚═══════════════════════════════════════════════════╝${NC}\n"

# Show app features
features=""
[ -f ".cursorrules" ] && features="${features}Cursor "
[ -f "tailwind.config.js" ] && features="${features}Tailwind "
[ -f "tests/Tests.elm" ] && features="${features}Test "
[ -f "src/I18n.elm" ] && features="${features}i18n "
[ -z "$features" ] && features="Basic"

echo -e "${BLUE}Features: ${CYAN}$features${NC}"
echo -e "${BLUE}Port: ${CYAN}$PORT${NC}\n"

# Determine package manager
PM="npm"
if [ -f "bun.lockb" ] || ([ -f "package.json" ] && grep -q "bunx" package.json); then
    PM="bun"
fi

# Start the app
if [ -f "tailwind.config.js" ]; then
    echo -e "${YELLOW}Starting with $PM start (Tailwind detected)...${NC}"
    if [ "$PM" = "bun" ]; then
        PORT=$PORT bun run start
    else
        PORT=$PORT npm start
    fi
else
    echo -e "${YELLOW}Starting with lamdera-dev-watch.sh...${NC}"
    PORT=$PORT ./lamdera-dev-watch.sh
fi