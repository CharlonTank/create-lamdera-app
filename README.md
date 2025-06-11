# 🚀 Create Lamdera App

> A streamlined CLI to bootstrap Lamdera applications with best practices and development tools.

## 🛠️ Quick Start

```bash
npx @CharlonTank/create-lamdera-app
```

## ⚡️ Features

```bash
# 🆕 Create a new project
npx @CharlonTank/create-lamdera-app

# 🎨 Create with Tailwind CSS
npx @CharlonTank/create-lamdera-app --tailwind yes

# Then use:
npm start          # Standard mode
npm run start:hot  # With elm-pkg-js hot-reload

# 🔧 Add utilities to existing project
npx @CharlonTank/create-lamdera-app --init

# 🐛 Toggle backend debugger
./toggle-debugger.py

# 🔄 Development server with hot-reload for elm-pkg-js
./lamdera-dev-watch.sh
```

## 🎯 Development Tools

- `.cursorrules` - AI coding guidelines for Lamdera best practices
- `lamdera-dev-watch.sh` - Smart development server with auto-reload
- **Tailwind CSS** - Optional utility-first CSS framework integration

## 📦 Prerequisites

- [Lamdera](https://lamdera.com/) - Required
- [GitHub CLI](https://cli.github.com/) - Optional, for repo creation
- [Cursor](https://cursor.sh/) - Optional, for AI-enhanced development
- [Node.js](https://nodejs.org/) - Required only if using Tailwind CSS
