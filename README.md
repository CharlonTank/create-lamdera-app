# create-lamdera-app

A modern CLI tool to scaffold [Lamdera](https://lamdera.com) applications with built-in support for Tailwind CSS, internationalization (i18n), dark mode, and testing.

## Features

- 🚀 **Quick Setup** - Get a working Lamdera app in seconds
- 🎨 **Tailwind CSS** - Beautiful, responsive designs out of the box
- 🌍 **i18n Support** - Built-in internationalization (EN/FR) with easy extension
- 🌓 **Dark Mode** - System-aware dark/light theme switching
- 🧪 **Testing Ready** - lamdera-program-test integration for reliable tests
- 📝 **Editor Support** - Cursor editor integration with custom rules
- 🔧 **Dev Tools** - Hot reload, debugger toggle, and more

## Installation

```bash
npm install -g @CharlonTank/create-lamdera-app
```

## Usage

### Create a new project

```bash
create-lamdera-app
```

Follow the interactive prompts to configure your project.

### Non-interactive mode

```bash
create-lamdera-app --name my-app --tailwind --i18n --test
```

### Add to existing project

```bash
cd existing-lamdera-project
create-lamdera-app --init
```

## Options

- `--name <project-name>` - Project name (required in non-interactive mode)
- `--cursor <yes|no>` - Add Cursor editor support
- `--tailwind` - Add Tailwind CSS
- `--test` - Add lamdera-program-test for testing
- `--i18n` - Add internationalization and dark mode
- `--github <yes|no>` - Create GitHub repository
- `--public/--private` - Repository visibility (with --github)
- `--init` - Add features to existing project

### Shortcuts

- `--no-cursor` - Same as `--cursor no`
- `--no-github` - Same as `--github no`
- `--no-test` - Same as `--test no`

## Project Structure

```
my-app/
├── src/
│   ├── Backend.elm
│   ├── Frontend.elm
│   ├── Types.elm
│   ├── Env.elm
│   └── (optional features)
│       ├── I18n.elm          # with --i18n
│       ├── Theme.elm         # with --i18n
│       ├── LocalStorage.elm  # with --i18n
│       └── styles.css        # with --tailwind
├── tests/                    # with --test
│   └── Tests.elm
├── public/
│   └── sample.svg
├── elm.json
├── lamdera-dev-watch.sh
├── toggle-debugger.py
├── head.html
└── (optional files)
    ├── package.json          # with --tailwind
    ├── tailwind.config.js    # with --tailwind
    ├── elm-test-rs.json      # with --test
    ├── .cursorrules          # with --cursor
    └── openEditor.sh         # with --cursor
```

## Feature Details

### Tailwind CSS Integration

When you add Tailwind CSS (`--tailwind`), you get:
- Pre-configured `tailwind.config.js`
- NPM scripts for development and production builds
- Beautiful starter template with gradient design
- Dark mode support (when combined with `--i18n`)

### Internationalization (i18n)

The `--i18n` flag adds:
- Language switcher (English/French by default)
- Dark/Light/System theme modes
- LocalStorage persistence for user preferences
- Auto-detection of browser language and system theme
- Easy-to-extend translation system

### Testing with lamdera-program-test

The `--test` flag sets up:
- Effect pattern for testable Lamdera code
- Example test suite
- elm-test-rs configuration
- Compatible with all other features

### Development Tools

Every project includes:
- `lamdera-dev-watch.sh` - Auto-recompiling development server
- `toggle-debugger.py` - Quick debugger toggling
- Hot reload support with elm-hot

## Examples

### Basic Lamdera app
```bash
create-lamdera-app --name my-app
```

### Full-featured app
```bash
create-lamdera-app --name my-app --cursor yes --tailwind --test --i18n
```

### Add Tailwind to existing project
```bash
cd my-existing-app
create-lamdera-app --init --tailwind
```

## Development

### Running Tests
```bash
npm test
npm run test:watch
npm run test:coverage
```

### Test All Flag Combinations
```bash
./test-all-combinations.sh
```

This creates 16 test applications with all possible flag combinations and verifies they compile correctly.

## Requirements

- Node.js ≥ 14.0.0
- npm ≥ 6.0.0
- [Lamdera](https://lamdera.com) installed
- [elm-test-rs](https://github.com/mpizenberg/elm-test-rs) (for testing features)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT © Charles-André Assus

## Acknowledgments

- [Lamdera](https://lamdera.com) for the amazing platform
- [Tailwind CSS](https://tailwindcss.com) for the utility-first CSS framework
- [elm-test-rs](https://github.com/mpizenberg/elm-test-rs) for fast Elm testing