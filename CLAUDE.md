# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `create-lamdera-app`, a CLI tool for scaffolding Lamdera applications. It's an npm package that helps users quickly create new Lamdera projects with optional features like Tailwind CSS, i18n, dark mode, and testing support.

## Build and Development Commands

```bash
# Install dependencies
npm install

# Run the CLI tool locally
node index.js [options]

# Run unit tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Test all feature combinations (creates 8 test apps)
./test-all-combinations.sh

# Run interactive testing on generated apps
./test-manual-interactive.sh

# Test a single generated app
./test-single-app.sh app-name [port]
```

## Architecture

### Core Structure
- `index.js` - Main CLI entry point with all scaffolding logic
- `/templates/` - Template files organized by feature:
  - `/base/` - Basic Lamdera app structure
  - `/utilities/` - Development scripts (lamdera-dev-watch.sh, toggle-debugger.py)
  - `/features/` - Optional feature templates:
    - `/tailwind/` - Tailwind CSS integration files
    - `/test/` - lamdera-program-test setup
    - `/i18n/` - Internationalization and dark mode

### Key Functions in index.js
- `setupTailwind()` - Configures Tailwind CSS with concurrently for parallel processes
- `setupLamderaTest()` - Converts to Effect pattern for testable code
- `setupI18n()` - Adds i18n, dark mode, and localStorage persistence
- `createUtilityFiles()` - Copies development utilities
- `initializeLamderaProject()` - Copies base template files

### Template Organization
Templates follow a feature-based structure where each feature can be combined:
- Base template provides minimal Lamdera app
- Features are additive and designed to work together
- Special handling for feature combinations (e.g., tailwind+i18n needs specific head.html)

## Lamdera-Specific Guidelines

From the included `.cursorrules` file:
- Model definitions (BackendModel, FrontendModel) must be in `Types.elm`
- User actions are `FrontendMsg` types
- Backend communication uses `Lamdera.sendToBackend` with `ToBackend` variants
- After modifications: `lamdera make src/Frontend.elm src/Backend.elm`
- For dependencies: use `yes | lamdera install` instead of modifying elm.json
- Fix compilation errors one at a time
- Store images directly under the `public/` directory

## Critical Implementation Details

### Package Manager Support
- Supports both npm and Bun (10-100x faster installs)
- Bun is auto-detected and preferred when available
- Tailwind scripts use `concurrently` instead of `run-pty` for better compatibility
- Scripts dynamically use `npx` or `bunx` based on package manager

### Port Configuration
All generated apps support custom ports via environment variable:
```bash
# For apps with Tailwind
PORT=3000 npm start
PORT=3000 bun run start

# For basic apps
PORT=3000 ./lamdera-dev-watch.sh
```

### Feature Interactions
- **Tailwind + i18n**: Requires `tailwind-i18n-theme-head.html` template to include CSS link
- **Test + i18n**: LocalStorage module uses Effect pattern with elm-pkg-js
- **Test mode**: Replaces direct ports with Effect.Command/Effect.Subscription wrappers
- **Cursor flag**: Only adds `.cursorrules` and `openEditor.sh`, doesn't affect other features

## Testing Strategy

The test suite validates:
1. **Unit tests** (`npm test`) - Tests CLI logic and file operations
2. **Integration tests** (`./test-all-combinations.sh`) - Creates 8 apps covering essential feature combinations
3. **Manual tests** (`./test-manual-interactive.sh`) - Interactive testing of generated apps

Test combinations focus on meaningful feature interactions:
- Basic, Tailwind-only, Test-only, i18n-only
- All two-feature combinations
- All features combined

## Publishing

This package is published to npm as `@CharlonTank/create-lamdera-app`. When preparing a release:
1. Update version in `package.json`
2. Run full test suite: `npm test && ./test-all-combinations.sh`
3. Test manual installation: `npm pack && npm install -g CharlonTank-create-lamdera-app-*.tgz`
4. Publish: `npm publish`