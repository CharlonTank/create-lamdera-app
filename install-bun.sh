#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════╗"
echo -e "║          Bun Installation Helper          ║"
echo -e "╚═══════════════════════════════════════════╝${NC}\n"

# Check if Bun is already installed
if command -v bun >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Bun is already installed!${NC}"
    echo -e "Version: $(bun --version)"
    exit 0
fi

echo -e "${YELLOW}Bun is not installed on your system.${NC}"
echo -e "${BLUE}Bun is a fast JavaScript runtime and package manager.${NC}"
echo -e "${BLUE}It can replace npm and is 10-100x faster for installs.${NC}\n"

echo -e "${GREEN}Would you like to install Bun? (y/n)${NC}"
read -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Installing Bun...${NC}"
    
    # Detect OS
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)     
            echo -e "${BLUE}Detected Linux${NC}"
            curl -fsSL https://bun.sh/install | bash
            ;;
        Darwin*)    
            echo -e "${BLUE}Detected macOS${NC}"
            curl -fsSL https://bun.sh/install | bash
            ;;
        *)          
            echo -e "${RED}Unsupported OS: ${OS}${NC}"
            echo -e "${YELLOW}Please visit https://bun.sh for installation instructions${NC}"
            exit 1
            ;;
    esac
    
    # Source the shell config to make bun available immediately
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc"
    fi
    
    echo -e "\n${GREEN}✓ Bun installation complete!${NC}"
    echo -e "${YELLOW}You may need to restart your terminal or run:${NC}"
    echo -e "${CYAN}source ~/.bashrc${NC} (or ${CYAN}source ~/.zshrc${NC} for zsh)"
    echo -e "\n${BLUE}Then you can use create-lamdera-app with --bun flag:${NC}"
    echo -e "${CYAN}create-lamdera-app --name my-app --tailwind --bun${NC}"
else
    echo -e "${YELLOW}Skipping Bun installation.${NC}"
    echo -e "${BLUE}You can always install it later from https://bun.sh${NC}"
fi