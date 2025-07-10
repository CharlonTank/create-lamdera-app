# create-lamdera-app

A modern CLI tool to scaffold [Lamdera](https://lamdera.com) applications with a complete feature set including Tailwind CSS, authentication, internationalization (i18n), dark mode, and testing.

## Features

Every generated app includes:

- 🚀 **Quick Setup** - Get a fully-featured Lamdera app in seconds
- 🎨 **Tailwind CSS** - Beautiful, responsive designs out of the box
- 🔐 **Authentication** - Google One Tap, GitHub OAuth, and Email authentication
- 🌍 **i18n Support** - Built-in internationalization (EN/FR) with easy extension
- 🌓 **Dark Mode** - System-aware dark/light theme switching
- 🧪 **Testing Ready** - lamdera-program-test integration for reliable tests
- 📝 **Editor Support** - Cursor editor integration with custom rules
- 🔧 **Dev Tools** - Hot reload, debugger toggle, and pre-commit hooks
- ⚡ **Bun Support** - Use Bun for 10x faster package installs

## Installation

```bash
npm install -g @CharlonTank/create-lamdera-app
```

## Usage

### Create a new project

```bash
create-lamdera-app
```

Follow the interactive prompts to set your project name and GitHub preferences.

### Non-interactive mode

```bash
create-lamdera-app --name my-app --github yes
```

### Add to existing project

```bash
cd existing-lamdera-project
create-lamdera-app --init
```

## Options

- `--name <project-name>` - Project name (required in non-interactive mode)
- `--github <yes|no>` - Create GitHub repository
- `--no-github` - Don't create GitHub repository
- `--public/--private` - Repository visibility (default: private)
- `--init` - Add features to existing project
- `--package-manager <npm|bun>` - Choose package manager (default: npm)
- `--pm <npm|bun>` - Shorthand for --package-manager
- `--bun` - Use Bun package manager (same as --pm bun)
- `--skip-install` - Skip package installation

## Project Structure

```
my-app/
├── src/
│   ├── Backend.elm
│   ├── Frontend.elm
│   ├── Types.elm
│   ├── Env.elm
│   ├── I18n.elm          # Internationalization
│   ├── Theme.elm         # Dark mode support
│   ├── LocalStorage.elm  # Persistent storage
│   ├── Auth.elm          # Authentication logic
│   ├── Login.elm         # Login page
│   ├── Register.elm      # Registration page
│   ├── Admin.elm         # Admin dashboard
│   ├── Password.elm      # Password utilities
│   ├── Email.elm         # Email utilities
│   ├── GoogleOneTap.elm  # Google auth setup
│   ├── DomId.elm         # DOM element IDs
│   └── styles.css        # Tailwind input file
├── tests/
│   └── Tests.elm         # Example tests
├── public/
│   └── sample.svg
├── elm.json
├── package.json          # With Tailwind scripts
├── tailwind.config.js
├── .githooks/
│   └── pre-commit       # Auto-format on commit
├── lamdera-dev-watch.sh  # Development server
├── toggle-debugger.py    # Debug helper
├── head.html
├── .cursorrules         # Cursor editor rules
└── openEditor.sh        # Quick editor opener
```

## Development

### Start the development server

```bash
cd my-app
npm start
# or
bun run start
```

This runs both Lamdera and Tailwind CSS watchers concurrently.

### Use a different port

```bash
PORT=3000 npm start
```

### Run with hot reload

```bash
npm run start:hot
```

### Run tests

```bash
elm-test-rs --compiler $(which lamdera)
```

## Authentication Setup

The generated app includes authentication scaffolding for:
- Google One Tap sign-in
- GitHub OAuth
- Email authentication

To enable authentication:
1. Set up OAuth apps with Google/GitHub
2. Add your credentials to `auth-env.elm`
3. Configure callback URLs

## i18n and Theming

- Language switcher (EN/FR) in the header
- Dark/Light/System theme selector
- Preferences persist in localStorage
- Auto-detects browser language and system theme

## Testing

Example tests are included using `lamdera-program-test`. The tests demonstrate:
- User interactions (clicks, form inputs)
- Frontend message handling
- Backend communication
- Effect command testing

## Package Manager Support

### Using Bun (recommended for speed)

```bash
create-lamdera-app --name my-app --bun
```

Bun provides 10-100x faster package installation compared to npm.

### Install Bun

```bash
curl -fsSL https://bun.sh/install | bash
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT