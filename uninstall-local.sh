#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Uninstalling local create-lamdera-app...${NC}"

# Run npm unlink
if npm unlink -g create-lamdera-app; then
    echo -e "${GREEN}✅ Local version of create-lamdera-app has been unlinked.${NC}"
    echo ""
    echo -e "You can now install the published version from npm:"
    echo -e "  ${BLUE}npm install -g @CharlonTank/create-lamdera-app${NC}"
    echo ""
    echo -e "Or use it directly with npx:"
    echo -e "  ${BLUE}npx @CharlonTank/create-lamdera-app${NC}"
else
    echo -e "${YELLOW}Failed to unlink create-lamdera-app.${NC}"
    echo -e "It might not be linked, or there could be a permissions issue."
fi