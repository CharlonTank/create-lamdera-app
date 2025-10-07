#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing create-lamdera-app locally...${NC}"

# Check if node and npm are installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js is not installed. Please install Node.js first.${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${YELLOW}npm is not installed. Please install npm first.${NC}"
    exit 1
fi

# Check if already linked or exists
if [ -e "/opt/homebrew/bin/create-lamdera-app" ]; then
    echo -e "${YELLOW}create-lamdera-app found at /opt/homebrew/bin/create-lamdera-app${NC}"
    echo -e "${BLUE}Removing existing file...${NC}"
    rm -f /opt/homebrew/bin/create-lamdera-app
fi

if [ -e "/usr/local/bin/create-lamdera-app" ]; then
    echo -e "${YELLOW}create-lamdera-app found at /usr/local/bin/create-lamdera-app${NC}"
    echo -e "${BLUE}Removing existing file...${NC}"
    rm -f /usr/local/bin/create-lamdera-app
fi

# Also try unlinking just in case
npm unlink -g create-lamdera-app 2>/dev/null || true

# Check if globally installed
if npm list -g @CharlonTank/create-lamdera-app &>/dev/null; then
    echo -e "${YELLOW}Global npm package @CharlonTank/create-lamdera-app detected.${NC}"
    echo -e "${BLUE}Uninstalling global package first...${NC}"
    npm uninstall -g @CharlonTank/create-lamdera-app
fi

# Run npm link
if npm link; then
    echo -e "${GREEN}✅ create-lamdera-app is now available globally!${NC}"
    echo -e "${GREEN}✅ Your local development version is linked.${NC}"
    echo ""
    echo -e "You can now use it in several ways:"
    echo -e "  ${BLUE}npx create-lamdera-app${NC}"
    echo -e "  ${BLUE}create-lamdera-app${NC}"
    echo ""
    echo -e "Any changes you make to the local code will be immediately reflected."
    echo ""
    echo -e "To uninstall the local version and revert to npm:"
    echo -e "  ${YELLOW}npm unlink -g create-lamdera-app${NC}"
else
    echo -e "${YELLOW}Failed to link create-lamdera-app. Please check npm permissions.${NC}"
    exit 1
fi