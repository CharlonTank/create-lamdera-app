# Create Lamdera App

A utility script to initialize a new Lamdera application with common utilities and configurations.

## Features

- Initializes a new Lamdera project
- Automatically installs common packages:
  - `elm/http`
  - `elm/time`
  - `elm/json`
- Creates utility files:
  - `.cursorrules` - Coding guidelines and best practices
  - `lamdera-dev-watch.sh` - Development server with auto-reload
  - `openeditor.sh` - Cursor editor integration
  - `toggle_debugger.py` - Backend debugger toggle utility
- Optional GitHub repository creation (public or private)

## Prerequisites

- [Lamdera](https://lamdera.com/)
- [GitHub CLI](https://cli.github.com/) (optional, for repository creation)

## Usage

The easiest way to use this tool is with `npx`:

```bash
# Navigate to where you want to create your project
cd your/projects/directory

# Run the script using npx
npx create-lamdera-app

# Follow the prompts:
# 1. Enter your project name
# 2. Choose whether to create a GitHub repository
# 3. If yes, choose public or private repository
```

## Development Server

After creating your project:

```bash
cd your-project-name
./lamdera-dev-watch.sh
```

This will start the Lamdera development server with auto-reload capability.

## Contributing

Feel free to open issues or submit pull requests!
