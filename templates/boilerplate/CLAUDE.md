# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Lamdera-Specific Information

### What is Lamdera?
Lamdera is a full-stack web framework where both frontend and backend are written in Elm. Key features:
- **Automatic client-server communication**: No need to write HTTP requests or WebSocket code
- **Type-safe across the stack**: Share types between frontend and backend
- **Built-in persistence**: Backend state is automatically persisted
- **Zero-config deployment**: Deploy with `lamdera deploy`

### Project Structure
```
src/
├── Frontend.elm     # Client-side logic and views
├── Backend.elm      # Server-side logic and state management
├── Types.elm        # Shared types between frontend and backend
├── Env.elm          # Environment configuration (auto-generated)
└── Evergreen/       # Migration files for data schema changes

public/              # Static assets (images, CSS, etc.)
elm-pkg-js/          # JavaScript interop files
```

### Key Concepts

1. **Messages Flow**:
   - `FrontendMsg`: Messages handled by the frontend
   - `BackendMsg`: Messages handled by the backend
   - `ToBackend`: Messages sent from frontend to backend
   - `ToFrontend`: Messages sent from backend to frontend

2. **State Management**:
   - `FrontendModel`: Client state (includes navigation key, local storage, etc.)
   - `BackendModel`: Server state (automatically persisted)

3. **URL Routing**: 
   - Uses `Url.Parser` for client-side routing
   - Routes defined in `Types.elm` as a custom type
   - Navigation handled via `Browser.Navigation`

### SEO and Meta Tags
For better social media sharing and SEO:
- Edit the `head.html` file in your project root
- Include Open Graph tags for Facebook/LinkedIn
- Include Twitter Card tags for Twitter
- Lamdera will inject this content into the `<head>` of your application

### Package Management
```bash
# Install a package (auto-accepts prompts)
yes | lamdera install user/package

# Example:
yes | lamdera install elm/http
yes | lamdera install elm/json
```

### Deployment
```bash
# Deploy to Lamdera hosting
lamdera deploy

# Check deployment status
lamdera status

# View logs
lamdera logs
```

### Testing with lamdera-program-test
The project uses `lamdera-program-test` for end-to-end testing:
- Simulates full client-server interactions
- Can test multiple connected clients
- Verifies both frontend views and backend state
- If you need more info on how Effect or lamdera-program-test works, you can look there ~/.elm/0.19.1/packages/lamdera/program-test/3.0.0

### Environment Variables
- Development: Defined in `.env` file
- Production: Set via `lamdera env:set KEY value`

### Static Assets
- Place in `public/` directory
- Accessed via absolute paths (e.g., `/image.jpg`)
- Automatically served by Lamdera

### Performance Tips
- Backend state is kept in memory for fast access
- Use `Effect.Lamdera.sendToBackend` sparingly for large data
- Consider pagination for large lists
- Images should be optimized before uploading

## Development Commands

### Running the Application
```bash
# Start development server (port 8000 by default)
npm start

# Start with hot-reload for JavaScript changes
npm start:hot

# Run on a different port
PORT=3000 npm start
```

### Compilation Check
```bash
# Check if the code compiles without building
lamdera make src/Frontend.elm src/Backend.elm
```

### Testing
```bash
# Run all tests
elm-test-rs --compiler /opt/homebrew/bin/lamdera tests/Tests.elm

# Run tests in watch mode
npm run test:watch
```

### Building
```bash
# Build for production
lamdera build

# Deploy to Lamdera hosting
lamdera deploy
```

## Architecture Overview

This is a **Lamdera application** - a full-stack Elm framework where both frontend and backend are written in Elm. Key architectural points:

1. **Client-Server Communication**: Lamdera automatically handles all client-server communication. You define messages in `Types.elm` and handle them in `Frontend.elm` and `Backend.elm`.

2. **State Management**:
   - Frontend state: `FrontendModel` in `Types.elm`
   - Backend state: `BackendModel` in `Types.elm`
   - Shared data is automatically synchronized via Lamdera's effect system

3. **JavaScript Interop**: Limited to essential browser APIs via ports:
   - LocalStorage operations through `elm-pkg-js/localStorage.js`
   - Registered in `elm-pkg-js-includes.js`

4. **Styling**: Tailwind CSS with dark mode support
   - Input file: `src/styles.css`
   - Configuration: `tailwind.config.js`
   - Dark mode uses class-based switching

5. **i18n**: Multi-language support in `I18n.elm`
   - Currently supports English and French
   - Language preference persisted to localStorage

## MCP (Model Context Protocol) Tools Available

When working with Claude Code, you have access to MCP tools for enhanced capabilities:

### Browser Automation
- **Brave MCP**: Browse the internet using Brave browser
  - Can navigate to URLs and interact with web pages
  - Useful for researching documentation or testing deployed sites
  
- **Puppeteer MCP**: Control headless Chrome for automation
  - View console output and page results
  - Take screenshots
  - Run JavaScript in the browser context
  - Useful for end-to-end testing of your deployed Lamdera app

Example use cases:
- Testing your deployed site's SEO meta tags
- Verifying social media preview cards
- Checking cross-browser compatibility
- Debugging client-side JavaScript errors

## Key Development Patterns

1. **Adding New Features**: 
   - Define new message types in `Types.elm`
   - Update model types if needed
   - Handle messages in `Frontend.elm` and/or `Backend.elm`
   - Lamdera will handle the client-server communication

2. **Theme Management**: 
   - Theme logic in `Theme.elm`
   - Uses both localStorage and system preferences
   - Applied via Tailwind's dark mode classes

3. **Writing Tests with lamdera-program-test**:
   - Tests use `Effect.Test` (aliased as `TF`) for end-to-end testing
   - Basic test structure:
     ```elm
     testExample =
         TF.start "Test description" startTime config
             [ TF.connectFrontend timestamp sessionId url viewport
                 (\{ click, checkView } ->
                     [ click (Html.Selector.id "button-id")
                     , checkView (\query -> query |> findTextContent "Expected text")
                     ])
             ]
         |> TF.toTest
     ```
   - Test multiple clients by connecting multiple frontends with different session IDs
   - Use `TF.checkBackend` to assert backend state
   - Tests simulate real user interactions and verify the full application flow
   - **For comprehensive testing documentation, see [HOW_TO_WRITE_TESTS.md](./HOW_TO_WRITE_TESTS.md)**