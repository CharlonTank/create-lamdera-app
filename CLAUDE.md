# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `create-lamdera-app`, a CLI tool for scaffolding Lamdera applications. It's an npm package that helps users quickly create new Lamdera projects or add development utilities to existing ones.

## Build and Development Commands

```bash
# Run the CLI tool locally
node index.js

# Create a new Lamdera project
node index.js

# Add utilities to existing Lamdera project
node index.js --init

# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

## Architecture

The project consists of:
- `index.js` - Main CLI entry point that handles project scaffolding
- `/templates/` - Contains all files that get copied to new projects:
  - Utility scripts (`lamdera-dev-watch.sh`, `toggle-debugger.py`, `openEditor.sh`)
  - Configuration files (`.cursorrules`)
  - Complete Lamdera starter project in `/lamdera-init/`

## Key Implementation Details

When working on this codebase:

1. **Template Updates**: Any changes to the Lamdera starter code should be made in `/templates/lamdera-init/src/`
2. **CLI Logic**: The main scaffolding logic is in `index.js` - it checks for Lamdera installation, prompts for configuration, and copies templates
3. **Utility Scripts**: Shell and Python scripts in `/templates/` are copied as-is to new projects

## Lamdera-Specific Guidelines

From the included `.cursorrules` file:
- Model definitions (BackendModel, FrontendModel) must be in `Types.elm`
- User actions are `FrontendMsg` types
- Backend communication uses `Lamdera.sendToBackend` with `ToBackend` variants
- After modifications: `lamdera make src/Frontend.elm src/Backend.elm`
- For dependencies: use `yes | lamdera install` instead of modifying elm.json
- Fix compilation errors one at a time
- Store images directly under the `public/` directory

## Publishing

This package is published to npm as `@CharlonTank/create-lamdera-app`. When preparing a release:
1. Update version in `package.json`
2. Ensure all template files are working correctly
3. Test both new project creation and `--init` mode