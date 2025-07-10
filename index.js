#!/usr/bin/env node

const chalk = require('chalk');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { version } = require('./package.json');

// Configure git hooks helper
function configureGitHooks(projectPath) {
  try {
    execSync('git config core.hooksPath .githooks', { cwd: projectPath, stdio: 'ignore' });
    return true;
  } catch (error) {
    return false;
  }
}

// Parse command line arguments early
const args = process.argv.slice(2);

// Parse named arguments
const parseArgs = () => {
  const parsed = {
    init: false,
    installPrecommit: false,
    name: null,
    cursor: true,  // Always enabled
    github: null,
    visibility: 'private',
    tailwind: true,  // Always enabled
    test: true,      // Always enabled
    i18n: true,      // Always enabled
    auth: true,      // Always enabled
    boilerplate: false,
    skipInstall: false,
    packageManager: 'npm' // default to npm
  };
  
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    const nextArg = args[i + 1];
    
    switch(arg) {
      case '--init':
        parsed.init = true;
        break;
      case '--install-precommit':
        parsed.installPrecommit = true;
        break;
      case '--name':
      case '-n':
        if (!nextArg || nextArg.trim() === '') {
          console.error(chalk.red('Project name cannot be empty'));
          process.exit(1);
        }
        parsed.name = nextArg;
        i++;
        break;
      // Cursor flag removed - always enabled
      case '--github':
        if (nextArg && (nextArg === 'yes' || nextArg === 'y' || nextArg === 'no' || nextArg === 'n')) {
          parsed.github = nextArg === 'yes' || nextArg === 'y';
          i++;
        } else if (!nextArg || (nextArg !== 'yes' && nextArg !== 'no' && nextArg !== 'y' && nextArg !== 'n')) {
          console.error(chalk.red('--github must be yes or no'));
          process.exit(1);
        }
        break;
      case '--no-github':
        parsed.github = false;
        break;
      case '--public':
        parsed.visibility = 'public';
        break;
      case '--private':
        parsed.visibility = 'private';
        break;
      // Feature flags removed - all features always enabled
      case '--skip-install':
        parsed.skipInstall = true;
        break;
      case '--package-manager':
      case '--pm':
        if (nextArg && (nextArg === 'npm' || nextArg === 'bun')) {
          parsed.packageManager = nextArg;
          i++;
        } else {
          console.error(chalk.red('--package-manager must be npm or bun'));
          process.exit(1);
        }
        break;
      case '--bun':
        parsed.packageManager = 'bun';
        break;
      case '--boilerplate':
        parsed.boilerplate = true;
        break;
    }
  }
  
  return parsed;
};

const parsedArgs = parseArgs();

// Handle --version and --help before creating readline interface
if (args.includes('--version')) {
  console.log(version);
  process.exit(0);
}

if (args.includes('--help') || args.includes('-h')) {
  console.log(`
${chalk.bold('Create Lamdera App')} v${version}

${chalk.bold('Usage:')}
  npx @CharlonTank/create-lamdera-app [options]

${chalk.bold('Options:')}
  --init              Add utilities to an existing Lamdera project
  --name, -n <name>   Project name (required for new projects in non-interactive mode)
  --github <yes|no>   Create GitHub repository (yes/no)
  --no-github         Don't create GitHub repository
  --public            Make GitHub repository public
  --private           Make GitHub repository private (default)
  --skip-install      Skip package installation
  --package-manager <npm|bun>  Choose package manager (default: npm)
  --pm <npm|bun>      Shorthand for --package-manager
  --bun               Use Bun package manager
  --boilerplate       Use boilerplate template (includes all features)
  --version           Show version number
  --help, -h          Show this help message

${chalk.bold('Included Features:')}
  • Tailwind CSS for styling
  • lamdera-program-test for testing
  • Internationalization (i18n) and dark mode
  • Authentication (Google, GitHub, Email)
  • Cursor editor support
  • Pre-commit hooks

${chalk.bold('Examples:')}
  ${chalk.gray('# Create a new Lamdera project interactively')}
  npx @CharlonTank/create-lamdera-app

  ${chalk.gray('# Create a new project without prompts')}
  npx @CharlonTank/create-lamdera-app --name my-app --no-github

  ${chalk.gray('# Create a project with public GitHub repo')}
  npx @CharlonTank/create-lamdera-app --name my-app --github yes --public

  ${chalk.gray('# Use Bun for faster package installation')}
  npx @CharlonTank/create-lamdera-app --name my-app --bun

  ${chalk.gray('# Add utilities to existing project')}
  npx @CharlonTank/create-lamdera-app --init

  ${chalk.gray('# Install pre-commit hooks in existing project')}
  npx @CharlonTank/create-lamdera-app --install-precommit
`);
  process.exit(0);
}

// Only create readline interface if we need it (no args provided)
let rl = null;
const isNewProjectInteractive = !parsedArgs.init && !parsedArgs.installPrecommit && (!parsedArgs.name || parsedArgs.github === null);
const isInitInteractive = parsedArgs.init && parsedArgs.cursor === null;

if (isNewProjectInteractive || isInitInteractive) {
  rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
}

// Handle interruptions gracefully
process.on('SIGINT', () => {
  console.log(chalk.yellow('\nProcess interrupted by user'));
  process.exit(0);
});

// Helper function to execute commands
function execCommand(command, showProgress = false) {
  try {
    // Special handling for npm commands to show progress
    if (showProgress && command.startsWith('npm')) {
      console.log(chalk.blue(`⏳ Running: ${command}`));
      console.log(chalk.gray('This may take a few minutes depending on your internet connection...'));
      
      // Add progress flag to npm commands
      if (command.includes('npm install')) {
        command = command.replace('npm install', 'npm install --progress');
      }
    }
    
    // Add timeout for npm commands
    const options = { 
      stdio: 'inherit', 
      killSignal: 'SIGINT'
    };
    
    // For npm install, add a longer timeout (5 minutes)
    if (command.includes('npm install')) {
      options.timeout = 300000; // 5 minutes
    }
    
    execSync(command, options);
    
    if (showProgress && command.startsWith('npm')) {
      console.log(chalk.green('✓ Command completed successfully'));
    }
  } catch (error) {
    if (error.signal === 'SIGINT') {
      console.log(chalk.yellow('\nProcess interrupted by user'));
      process.exit(0);
    }
    if (error.code === 'ETIMEDOUT') {
      console.error(chalk.red('\nCommand timed out after 5 minutes'));
      console.error(chalk.yellow('Try running npm install manually in the project directory'));
    }
    console.error(chalk.red(`Error executing command: ${command}`));
    console.error(chalk.red(error.message));
    process.exit(1);
  }
}

// Check prerequisites
function checkPrerequisites(packageManager = 'npm') {
  try {
    execSync('lamdera --version', { stdio: 'ignore' });
  } catch {
    console.error(chalk.red('Lamdera is not installed. Please install it first.'));
    process.exit(1);
  }
  
  // Check if selected package manager is installed
  if (packageManager === 'bun') {
    try {
      execSync('bun --version', { stdio: 'ignore' });
    } catch {
      console.error(chalk.red('Bun is not installed!'));
      console.error(chalk.yellow('Please install Bun first:'));
      console.error(chalk.cyan('  curl -fsSL https://bun.sh/install | bash'));
      console.error(chalk.cyan('  or'));
      console.error(chalk.cyan('  See https://bun.sh for platform-specific instructions'));
      process.exit(1);
    }
  }
}

// Create utility files
function createUtilityFiles(projectPath, useCursor, useTest = false) {
  const templatePath = path.join(__dirname, 'templates');

  // Copy template files
  fs.copyFileSync(path.join(templatePath, 'utilities', 'lamdera-dev-watch.sh'), path.join(projectPath, 'lamdera-dev-watch.sh'));
  fs.chmodSync(path.join(projectPath, 'lamdera-dev-watch.sh'), '755');

  // Use the appropriate toggle-debugger.py version based on test mode
  const toggleDebuggerSource = useTest
    ? path.join(templatePath, 'features', 'test', 'test-toggle-debugger.py')
    : path.join(templatePath, 'utilities', 'toggle-debugger.py');
  
  fs.copyFileSync(toggleDebuggerSource, path.join(projectPath, 'toggle-debugger.py'));
  fs.chmodSync(path.join(projectPath, 'toggle-debugger.py'), '755');

  if (useCursor) {
    fs.copyFileSync(path.join(templatePath, 'utilities', '.cursorrules'), path.join(projectPath, '.cursorrules'));
    fs.copyFileSync(path.join(templatePath, 'utilities', 'openEditor.sh'), path.join(projectPath, 'openEditor.sh'));
    fs.chmodSync(path.join(projectPath, 'openEditor.sh'), '755');
  }
}

// Initialize Tailwind CSS
function setupTailwind(projectPath, baseDir, skipFrontend = false, skipInstall = false, packageManager = 'npm') {
  console.log(chalk.blue('Setting up Tailwind CSS...'));
  
  // Save current directory and change to project path
  const originalDir = process.cwd();
  process.chdir(projectPath);
  
  try {
    // Initialize package.json
    if (packageManager === 'bun') {
      execCommand('bun init -y', true);
    } else {
      execCommand('npm init -y', true);
    }
    
    // Wait a moment and verify package.json was created
    if (!fs.existsSync('./package.json')) {
      throw new Error('Failed to create package.json');
    }
    
    // Install dependencies unless skipped
    if (!skipInstall) {
      console.log(chalk.yellow(`\n📦 Installing Tailwind CSS dependencies with ${packageManager}...`));
      if (packageManager === 'bun') {
        execCommand('bun add tailwindcss@^3', true);
        execCommand('bun add -d concurrently', true);
      } else {
        execCommand('npm install tailwindcss@^3', true);
        execCommand('npm install --save-dev concurrently', true);
      }
    } else {
      console.log(chalk.yellow(`\n⚠️  Skipping ${packageManager} install as requested`));
      console.log(chalk.gray(`Run "${packageManager} install" manually later to install dependencies`));
      
      // Still need to update package.json with dependencies
      const packageJsonPath = './package.json';
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
      packageJson.dependencies = {
        ...packageJson.dependencies,
        "tailwindcss": "^3"
      };
      packageJson.devDependencies = {
        ...packageJson.devDependencies,
        "concurrently": "^9.0.0"
      };
      fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
    }
    
    // Create tailwind.config.js content manually (since v4 doesn't have init)
    const tailwindConfig = `module.exports = {
  darkMode: 'class',
  content: [
    "./src/**/*.{elm,js,html}",
    "./*.html"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}`;
  
    fs.writeFileSync('./tailwind.config.js', tailwindConfig);
    
    // Create src/styles.css
    const stylesCss = `@tailwind base;
@tailwind components;
@tailwind utilities;`;
    
    // Ensure src directory exists
    if (!fs.existsSync('./src')) {
      fs.mkdirSync('./src');
    }
    
    fs.writeFileSync('./src/styles.css', stylesCss);
  
    // Update head.html to include Tailwind styles (we're in the project directory)
    const headPath = './head.html';
    if (fs.existsSync(headPath)) {
      let headContent = fs.readFileSync(headPath, 'utf8');
    
      // Add the Tailwind CSS link before the closing style tag
      headContent = headContent.replace(
        '</style>',
        '</style>\n<link rel="stylesheet" href="/styles.css">'
      );
      
      fs.writeFileSync(headPath, headContent);
    }
  
    // Update package.json scripts (it's in the current directory after chdir)
    const packageJsonPath = './package.json';
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  
  // Use bunx instead of npx for Bun
  const runner = packageManager === 'bun' ? 'bunx' : 'npx';
  
  packageJson.scripts = {
    ...packageJson.scripts,
    "start": `${runner} concurrently -k -s first "lamdera live --port=\${PORT:-8000}" "${runner} tailwindcss -i ./src/styles.css -o ./public/styles.css --watch"`,
    "start:hot": `${runner} concurrently -k -s first "PORT=\${PORT:-8000} ./lamdera-dev-watch.sh" "${runner} tailwindcss -i ./src/styles.css -o ./public/styles.css --watch"`,
    "start:ci": `(lamdera live --port=\${PORT:-8000} &) && ${runner} tailwindcss -i ./src/styles.css -o ./public/styles.css --watch`
  };
  
  fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
  
    // Update .gitignore for Tailwind
    const templatePath = path.join(baseDir, 'templates');
    fs.copyFileSync(path.join(templatePath, 'features', 'tailwind', 'tailwind.gitignore'), './.gitignore');
    
    // Replace Frontend.elm with Tailwind example version (only if not using test mode)
    if (!skipFrontend) {
      fs.copyFileSync(path.join(templatePath, 'features', 'tailwind', 'tailwind-frontend.elm'), './src/Frontend.elm');
    }
    
    console.log(chalk.green('Tailwind CSS setup complete!'));
  } finally {
    // Restore original directory
    process.chdir(originalDir);
  }
}

// Setup lamdera-program-test
function setupLamderaTest(projectPath, baseDir) {
  console.log(chalk.blue('Setting up lamdera-program-test...'));
  
  const templatePath = path.join(baseDir, 'templates');
  
  // Replace elm.json with test version
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'test-elm.json'), path.join(projectPath, 'elm.json'));
  
  // Replace Backend.elm, Frontend.elm, and Types.elm with test versions
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'test-backend.elm'), path.join(projectPath, 'src', 'Backend.elm'));
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'test-frontend.elm'), path.join(projectPath, 'src', 'Frontend.elm'));
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'test-types.elm'), path.join(projectPath, 'src', 'Types.elm'));
  
  // Create tests directory
  fs.mkdirSync(path.join(projectPath, 'tests'), { recursive: true });
  
  // Copy test template
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'test-tests.elm'), path.join(projectPath, 'tests', 'Tests.elm'));
  
  // Copy TestsRunner.elm
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'test-TestsRunner.elm'), path.join(projectPath, 'tests', 'TestsRunner.elm'));
  
  // Copy elm-test-rs.json
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'elm-test-rs.json'), path.join(projectPath, 'elm-test-rs.json'));
  
  // Copy HOW_TO_WRITE_TESTS.md
  fs.copyFileSync(path.join(templatePath, 'features', 'test', 'HOW_TO_WRITE_TESTS.md'), path.join(projectPath, 'HOW_TO_WRITE_TESTS.md'));
  
  // Set up pre-commit hook
  const githooksDir = path.join(projectPath, '.githooks');
  fs.mkdirSync(githooksDir, { recursive: true });
  
  // Copy pre-commit hook
  const preCommitSource = path.join(templatePath, 'features', 'test', '.githooks', 'pre-commit');
  const preCommitDest = path.join(githooksDir, 'pre-commit');
  fs.copyFileSync(preCommitSource, preCommitDest);
  
  // Make pre-commit hook executable
  fs.chmodSync(preCommitDest, '755');
  
  // Configure git to use .githooks directory
  if (configureGitHooks(projectPath)) {
    console.log(chalk.green('Pre-commit hook configured!'));
  }
  
  console.log(chalk.green('lamdera-program-test setup complete!'));
  console.log(chalk.gray('To run tests: elm-test-rs --compiler $(which lamdera)'));
}

// Setup i18n and dark mode
function setupI18n(projectPath, baseDir, useTest = false, useTailwind = false) {
  console.log(chalk.blue('Setting up i18n and dark mode support...'));
  
  const templatePath = path.join(baseDir, 'templates');
  
  // Copy i18n and theme modules
  fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'I18n.elm'), path.join(projectPath, 'src', 'I18n.elm'));
  fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'Theme.elm'), path.join(projectPath, 'src', 'Theme.elm'));
  
  // Copy appropriate LocalStorage module
  if (useTest) {
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'test-LocalStorage.elm'), path.join(projectPath, 'src', 'LocalStorage.elm'));
  } else {
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'LocalStorage.elm'), path.join(projectPath, 'src', 'LocalStorage.elm'));
  }
  
  // Replace Frontend with appropriate version based on flags
  let frontendTemplate;
  if (useTailwind && useTest) {
    frontendTemplate = 'test-tailwind-i18n-theme-frontend.elm';
  } else if (useTailwind) {
    frontendTemplate = 'tailwind-i18n-theme-frontend.elm';
  } else if (useTest) {
    frontendTemplate = 'test-i18n-theme-frontend.elm';
  } else {
    frontendTemplate = 'i18n-theme-frontend.elm';
  }
  fs.copyFileSync(path.join(templatePath, 'features', 'i18n', frontendTemplate), path.join(projectPath, 'src', 'Frontend.elm'));
  
  // Replace Types with appropriate version based on flags
  let typesTemplate;
  if (useTailwind && useTest) {
    typesTemplate = 'test-tailwind-i18n-theme-types.elm';
  } else if (useTailwind) {
    typesTemplate = 'tailwind-i18n-theme-types.elm';
  } else if (useTest) {
    typesTemplate = 'test-i18n-theme-types.elm';
  } else {
    typesTemplate = 'i18n-theme-types.elm';
  }
  fs.copyFileSync(path.join(templatePath, 'features', 'i18n', typesTemplate), path.join(projectPath, 'src', 'Types.elm'));
  
  // Replace head.html with appropriate i18n version
  if (useTailwind) {
    // Tailwind needs the styles.css link
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'tailwind-i18n-theme-head.html'), path.join(projectPath, 'head.html'));
  } else if (useTest) {
    // Test mode uses inline localStorage handler (for elm-pkg-js)
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'i18n-theme-head.html'), path.join(projectPath, 'head.html'));
  } else {
    // Standard mode uses external localStorage.js file
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'i18n-theme-head-standard.html'), path.join(projectPath, 'head.html'));
  }
  
  // If using test mode, set up elm-pkg-js
  if (useTest) {
    // Create elm-pkg-js directory
    fs.mkdirSync(path.join(projectPath, 'elm-pkg-js'), { recursive: true });
    
    // Copy localStorage.js
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'elm-pkg-js', 'localStorage.js'), path.join(projectPath, 'elm-pkg-js', 'localStorage.js'));
    
    // Copy elm-pkg-js-includes.js
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'elm-pkg-js-includes.js'), path.join(projectPath, 'elm-pkg-js-includes.js'));
  } else {
    // For non-test mode, copy the standalone localStorage.js
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'localStorage.js'), path.join(projectPath, 'localStorage.js'));
  }
  
  console.log(chalk.green('i18n and dark mode setup complete!'));
  console.log(chalk.gray('Features added:'));
  console.log(chalk.gray('- Language switcher (EN/FR)'));
  console.log(chalk.gray('- Dark/Light/System theme modes'));
  console.log(chalk.gray('- Persistent user preferences'));
}

// Setup authentication
function setupAuth(projectPath, baseDir, useTest = false, useI18n = false) {
  console.log(chalk.blue('Setting up authentication...'));
  
  const templatePath = path.join(baseDir, 'templates');
  
  // Update elm.json to include elm-auth source directory
  const elmJsonPath = path.join(projectPath, 'elm.json');
  const elmJson = JSON.parse(fs.readFileSync(elmJsonPath, 'utf8'));
  elmJson['source-directories'].push('elm-auth/src');
  
  // Add auth dependencies if not already present
  const authDependencies = {
    "NoRedInk/elm-json-decode-pipeline": "1.0.1",
    "TSFoster/elm-sha1": "2.1.1",
    "TSFoster/elm-uuid": "4.2.0",
    "chelovek0v/bbase64": "1.0.1",
    "danfishgold/base64-bytes": "1.1.0",
    "elm/regex": "1.0.0",
    "elm-community/list-extra": "8.7.0",
    "folkertdev/elm-sha2": "1.0.0",
    "krisajenkins/remotedata": "6.1.0",
    "ktonon/elm-crypto": "1.1.2",
    "ktonon/elm-word": "2.1.2"
  };
  
  Object.entries(authDependencies).forEach(([pkg, version]) => {
    if (!elmJson.dependencies.direct[pkg]) {
      elmJson.dependencies.direct[pkg] = version;
    }
  });
  
  fs.writeFileSync(elmJsonPath, JSON.stringify(elmJson, null, 4));
  
  // Copy elm-auth package
  const elmAuthSrc = path.join(templatePath, 'features', 'auth', 'elm-auth');
  const elmAuthDest = path.join(projectPath, 'elm-auth');
  copyDirectoryRecursive(elmAuthSrc, elmAuthDest);
  
  // Copy core auth files
  const authFiles = ['Auth.elm', 'GoogleOneTap.elm', 'Password.elm', 'Email.elm'];
  authFiles.forEach(file => {
    fs.copyFileSync(
      path.join(templatePath, 'features', 'auth', file),
      path.join(projectPath, 'src', file)
    );
  });
  
  // Copy auth pages
  const pagesDir = path.join(projectPath, 'src', 'Pages');
  fs.mkdirSync(pagesDir, { recursive: true });
  
  const authPages = ['Login.elm', 'Register.elm', 'Admin.elm'];
  authPages.forEach(page => {
    fs.copyFileSync(
      path.join(templatePath, 'features', 'auth', page),
      path.join(pagesDir, page)
    );
  });
  
  // Update or create Env.elm
  fs.copyFileSync(
    path.join(templatePath, 'features', 'auth', 'auth-env.elm'),
    path.join(projectPath, 'src', 'Env.elm')
  );
  
  // Copy JavaScript files
  const elmPkgJsDir = path.join(projectPath, 'elm-pkg-js');
  fs.mkdirSync(elmPkgJsDir, { recursive: true });
  
  fs.copyFileSync(
    path.join(templatePath, 'features', 'auth', 'googleOneTap.js'),
    path.join(elmPkgJsDir, 'googleOneTap.js')
  );
  
  // Update or copy elm-pkg-js-includes.js
  const includesPath = path.join(projectPath, 'elm-pkg-js-includes.js');
  if (fs.existsSync(includesPath)) {
    // Append to existing file
    const existingIncludes = fs.readFileSync(includesPath, 'utf8');
    if (!existingIncludes.includes('googleOneTap')) {
      fs.appendFileSync(includesPath, '\nexports.init.push(require("./elm-pkg-js/googleOneTap").init);\n');
    }
  } else {
    // Copy new file
    fs.copyFileSync(
      path.join(templatePath, 'features', 'auth', 'auth-elm-pkg-js-includes.js'),
      includesPath
    );
  }
  
  // Update head.html
  const headPath = path.join(projectPath, 'head.html');
  if (fs.existsSync(headPath)) {
    // Check if Google Identity Services script is already included
    const headContent = fs.readFileSync(headPath, 'utf8');
    if (!headContent.includes('accounts.google.com/gsi/client')) {
      // Insert Google Identity Services script
      const updatedHead = headContent.replace(
        '</head>',
        '\n<!-- Google Identity Services for One Tap -->\n<script src="https://accounts.google.com/gsi/client" async defer></script>\n</head>'
      );
      fs.writeFileSync(headPath, updatedHead);
    }
  } else {
    // Copy auth head.html
    fs.copyFileSync(
      path.join(templatePath, 'features', 'auth', 'auth-head.html'),
      headPath
    );
  }
  
  // Copy documentation
  const docs = ['GOOGLE_ONE_TAP_SETUP.md', 'GITHUB_OAUTH_SETUP.md'];
  docs.forEach(doc => {
    fs.copyFileSync(
      path.join(templatePath, 'features', 'auth', doc),
      path.join(projectPath, doc)
    );
  });
  
  // TODO: Update Types.elm, Frontend.elm, Backend.elm, and Router.elm with auth support
  // This would be complex and require parsing/merging Elm code
  // For now, we'll note this as a manual step
  
  console.log(chalk.green('Authentication setup complete!'));
  console.log(chalk.yellow('\nIMPORTANT: Manual steps required:'));
  console.log(chalk.gray('1. Update Types.elm with auth-related types from the boilerplate'));
  console.log(chalk.gray('2. Update Frontend.elm with auth message handling'));
  console.log(chalk.gray('3. Update Backend.elm with auth backend logic'));
  console.log(chalk.gray('4. Update Router.elm to include login/register routes'));
  console.log(chalk.gray('5. Configure OAuth credentials in src/Env.elm'));
  console.log(chalk.gray('\nSee GOOGLE_ONE_TAP_SETUP.md and GITHUB_OAUTH_SETUP.md for OAuth setup instructions.'));
}

// Helper function to copy directory recursively
function copyDirectoryRecursive(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  const entries = fs.readdirSync(src, { withFileTypes: true });
  
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    
    if (entry.isDirectory()) {
      copyDirectoryRecursive(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// Initialize Lamdera project
function initializeLamderaProject(projectPath) {
  const templatePath = path.join(__dirname, 'templates', 'base');

  // Copy all files from template
  const copyRecursive = (src, dest) => {
    const exists = fs.existsSync(src);
    const stats = exists && fs.statSync(src);
    const isDirectory = exists && stats.isDirectory();
    const basename = path.basename(src);

    // Skip .DS_Store and elm-stuff
    if (basename === '.DS_Store' || basename === 'elm-stuff') {
      return;
    }

    if (isDirectory) {
      fs.mkdirSync(dest, { recursive: true });
      fs.readdirSync(src).forEach(childItemName => {
        copyRecursive(path.join(src, childItemName), path.join(dest, childItemName));
      });
    } else {
      fs.copyFileSync(src, dest);
    }
  };

  copyRecursive(templatePath, projectPath);
}

// Initialize from boilerplate - copies complete boilerplate project
function initializeFromBoilerplate(projectPath) {
  const boilerplatePath = path.join(__dirname, 'templates', 'boilerplate');
  
  if (!fs.existsSync(boilerplatePath)) {
    console.error(chalk.red('Boilerplate template not found'));
    process.exit(1);
  }

  console.log(chalk.blue('Setting up boilerplate project...'));

  // Copy all files from boilerplate
  const copyRecursive = (src, dest) => {
    const exists = fs.existsSync(src);
    const stats = exists && fs.statSync(src);
    const isDirectory = exists && stats.isDirectory();
    const basename = path.basename(src);

    // Skip .DS_Store, elm-stuff, node_modules, and git directories
    if (basename === '.DS_Store' || basename === 'elm-stuff' || basename === 'node_modules' || basename === '.git' || basename === '.lamdera') {
      return;
    }

    if (isDirectory) {
      fs.mkdirSync(dest, { recursive: true });
      fs.readdirSync(src).forEach(childItemName => {
        copyRecursive(path.join(src, childItemName), path.join(dest, childItemName));
      });
    } else {
      fs.copyFileSync(src, dest);
    }
  };

  copyRecursive(boilerplatePath, projectPath);
}

async function initializeExistingProject() {
  // Check for invalid flag combinations
  if (parsedArgs.name) {
    console.error(chalk.red('Cannot use --name with --init'));
    process.exit(1);
  }

  // Check if already in a Lamdera project
  if (!fs.existsSync('./elm.json')) {
    console.error(chalk.red('No elm.json found. Please run this command in an existing Lamdera project directory.'));
    process.exit(1);
  }

  try {
    let useCursor = parsedArgs.cursor;
    
    // Only ask if not provided via CLI
    if (useCursor === null) {
      if (rl) {
        console.log(chalk.cyan('Do you use Cursor editor? (y/n)'));
        const answer = await new Promise(resolve => rl.question('', resolve));
        useCursor = answer.toLowerCase() === 'y';
      } else {
        useCursor = false; // Default to false in non-interactive mode
      }
    }

    // Check if it's a test project
    const elmJson = JSON.parse(fs.readFileSync('./elm.json', 'utf8'));
    const isTestProject = elmJson.dependencies && 
                         elmJson.dependencies.direct && 
                         elmJson.dependencies.direct['lamdera/program-test'] !== undefined;
    
    // Create utility files
    console.log(chalk.blue('Creating utility files...'));
    createUtilityFiles(process.cwd(), useCursor, isTestProject);
    
    // Check if user wants Tailwind
    let useTailwind = parsedArgs.tailwind;
    if (useTailwind === null && rl) {
      console.log(chalk.cyan('Do you want to use Tailwind CSS? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useTailwind = answer.toLowerCase() === 'y';
    }
    
    // Set up Tailwind if requested
    if (useTailwind) {
      setupTailwind(process.cwd(), __dirname, true, parsedArgs.skipInstall, parsedArgs.packageManager); // Skip frontend since it already exists
    }
    
    // Check if user wants i18n
    let useI18n = parsedArgs.i18n;
    if (useI18n === null && rl) {
      console.log(chalk.cyan('Do you want to add internationalization and dark mode support? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useI18n = answer.toLowerCase() === 'y';
    }
    
    // Set up i18n if requested
    if (useI18n) {
      // Check if this is a test project
      const elmJson = JSON.parse(fs.readFileSync('./elm.json', 'utf8'));
      const isTestProject = elmJson.dependencies && 
                           elmJson.dependencies.direct && 
                           elmJson.dependencies.direct['lamdera/program-test'] !== undefined;
      setupI18n(process.cwd(), __dirname, isTestProject);
    }

    console.log(chalk.green('Project setup complete!'));
  } finally {
    if (rl) {
      rl.close();
    }
  }
}

async function installPrecommitHook() {
  // Check if already in a Lamdera project
  if (!fs.existsSync('./elm.json')) {
    console.error(chalk.red('No elm.json found. Please run this command in an existing Lamdera project directory.'));
    process.exit(1);
  }

  // Check if it's a git repository
  if (!fs.existsSync('.git')) {
    console.error(chalk.red('No .git directory found. Please run this command in a git repository.'));
    process.exit(1);
  }

  console.log(chalk.blue('Installing pre-commit hooks...'));

  // Create .githooks directory
  const githooksDir = path.join(process.cwd(), '.githooks');
  fs.mkdirSync(githooksDir, { recursive: true });

  // Add review directory if it doesn't exist
  const reviewDir = path.join(process.cwd(), 'review');
  if (!fs.existsSync(reviewDir)) {
    console.log(chalk.blue('Adding elm-review configuration...'));
    const templatePath = path.join(__dirname, 'templates', 'base');
    
    // Copy the review directory recursively
    const copyRecursive = (src, dest) => {
      const exists = fs.existsSync(src);
      const stats = exists && fs.statSync(src);
      const isDirectory = exists && stats.isDirectory();
      const basename = path.basename(src);

      // Skip .DS_Store and elm-stuff
      if (basename === '.DS_Store' || basename === 'elm-stuff') {
        return;
      }

      if (isDirectory) {
        fs.mkdirSync(dest, { recursive: true });
        fs.readdirSync(src).forEach(childItemName => {
          copyRecursive(path.join(src, childItemName), path.join(dest, childItemName));
        });
      } else {
        fs.copyFileSync(src, dest);
      }
    };

    copyRecursive(path.join(templatePath, 'review'), reviewDir);
    console.log(chalk.green('✅ elm-review configuration added!'));
  }

  // Check if it's a test project
  const elmJson = JSON.parse(fs.readFileSync('./elm.json', 'utf8'));
  const isTestProject = elmJson.dependencies && 
                       elmJson.dependencies.direct && 
                       elmJson.dependencies.direct['lamdera/program-test'] !== undefined;

  // Create appropriate pre-commit hook
  const templatePath = path.join(__dirname, 'templates', 'features', 'precommit');
  const hookTemplate = isTestProject ? 'pre-commit-test' : 'pre-commit-basic';
  const preCommitSource = path.join(templatePath, hookTemplate);
  const preCommitDest = path.join(githooksDir, 'pre-commit');

  // Copy the pre-commit hook
  fs.copyFileSync(preCommitSource, preCommitDest);
  
  // Make pre-commit hook executable
  fs.chmodSync(preCommitDest, '755');
  
  // Update .gitignore to include tmp/ if it exists
  const gitignorePath = path.join(process.cwd(), '.gitignore');
  if (fs.existsSync(gitignorePath)) {
    let gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
    if (!gitignoreContent.includes('tmp/') && !gitignoreContent.includes('\ntmp\n')) {
      // Add tmp/ to gitignore if not already present
      gitignoreContent = gitignoreContent.trimEnd() + '\n\n# Temporary files (Claude auto-fix logs)\ntmp/\n';
      fs.writeFileSync(gitignorePath, gitignoreContent);
      console.log(chalk.blue('✅ Added tmp/ to .gitignore'));
    }
  } else {
    // Create .gitignore with tmp/
    const gitignoreContent = `# Elm
elm-stuff/
elm.js

# OS
.DS_Store
Thumbs.db

# Editor
.idea/
.vscode/
*.swp
*.swo

# Temporary files (Claude auto-fix logs)
tmp/
`;
    fs.writeFileSync(gitignorePath, gitignoreContent);
    console.log(chalk.blue('✅ Created .gitignore with tmp/'));
  }
  
  // Configure git to use .githooks directory
  if (configureGitHooks(process.cwd())) {
    console.log(chalk.green('✅ Pre-commit hooks installed successfully!'));
    console.log(chalk.gray(''));
    console.log(chalk.gray('The following checks will run before each commit:'));
    console.log(chalk.gray('- elm-format'));
    console.log(chalk.gray('- lamdera make (compilation check)'));
    if (isTestProject) {
      console.log(chalk.gray('- elm-test-rs (run tests)'));
    }
    console.log(chalk.gray('- elm-review --fix-all'));
    console.log(chalk.gray(''));
    console.log(chalk.yellow('Note: Make sure you have elm-format and elm-review installed globally:'));
    console.log(chalk.cyan('  npm install -g elm-format elm-review'));
  } else {
    console.error(chalk.red('Failed to configure git hooks. You can manually run:'));
    console.error(chalk.cyan('  git config core.hooksPath .githooks'));
  }
}

async function createNewProject() {
  try {
    let projectName = parsedArgs.name;
    let useCursor = parsedArgs.cursor;
    let createRepo = parsedArgs.github;
    let repoVisibility = parsedArgs.visibility;
    let useTailwind = parsedArgs.tailwind;
    let useTest = parsedArgs.test;
    let useI18n = parsedArgs.i18n;
    let useAuth = parsedArgs.auth;

    // Get project name if not provided
    if (!projectName) {
      if (!rl) {
        console.error(chalk.red('Project name is required. Use --name <name> or run interactively.'));
        process.exit(1);
      }
      console.log(chalk.cyan('Enter your project name:'));
      projectName = await new Promise(resolve => rl.question('', resolve));
      
      if (!projectName) {
        console.error(chalk.red('Project name is required'));
        process.exit(1);
      }
    }

    // Validate project name
    if (!projectName || projectName.trim() === '') {
      console.error(chalk.red('Project name cannot be empty'));
      process.exit(1);
    }
    
    if (projectName.includes(' ')) {
      console.error(chalk.red('Project name cannot contain spaces'));
      process.exit(1);
    }
    
    if (!/^[a-zA-Z0-9_-]+$/.test(projectName)) {
      console.error(chalk.red('Project name can only contain letters, numbers, hyphens, and underscores'));
      process.exit(1);
    }

    // All features are enabled by default (cursor, tailwind, test, i18n, auth)
    // No need to ask for preferences

    const projectPath = path.join(process.cwd(), projectName);

    // Check if directory already exists
    if (fs.existsSync(projectPath)) {
      console.error(chalk.red(`Directory '${projectName}' already exists`));
      process.exit(1);
    }

    // Create project directory
    fs.mkdirSync(projectPath);
    process.chdir(projectPath);

    // Check if using boilerplate
    if (parsedArgs.boilerplate) {
      // Use boilerplate approach - copy everything from ~/projects/boilerplate
      initializeFromBoilerplate(projectPath);
      
      // Copy pre-commit hook for boilerplate
      console.log(chalk.blue('Setting up pre-commit hooks...'));
      const githooksDir = path.join(projectPath, '.githooks');
      fs.mkdirSync(githooksDir, { recursive: true });
      
      const preCommitSource = path.join(__dirname, 'templates', 'features', 'test', '.githooks', 'pre-commit');
      const preCommitDest = path.join(githooksDir, 'pre-commit');
      fs.copyFileSync(preCommitSource, preCommitDest);
      fs.chmodSync(preCommitDest, '755');
      
      // Run npm/bun install if not skipped
      if (!parsedArgs.skipInstall) {
        const pm = parsedArgs.packageManager;
        console.log(chalk.yellow(`\n📦 Installing dependencies with ${pm}...`));
        if (pm === 'bun') {
          execCommand('bun install', true);
        } else {
          execCommand('npm install', true);
        }
      }
    } else {
      // Original approach with individual features
      // Initialize Lamdera project
      console.log(chalk.blue('Initializing Lamdera project...'));
      initializeLamderaProject(projectPath);

      // Create utility files
      console.log(chalk.blue('Creating utility files...'));
      createUtilityFiles(projectPath, useCursor, useTest);

      // Set up Tailwind if requested
      if (useTailwind && !useTest && !useI18n) {
        setupTailwind(projectPath, __dirname, false, parsedArgs.skipInstall, parsedArgs.packageManager);
      } else if (useTailwind && !useTest && useI18n) {
        // When both Tailwind and i18n are enabled, setup Tailwind infrastructure but let i18n handle Frontend
        setupTailwind(projectPath, __dirname, true, parsedArgs.skipInstall, parsedArgs.packageManager);
      }

      // Set up lamdera-program-test if requested
      if (useTest) {
        setupLamderaTest(projectPath, __dirname);
        // If both Tailwind and test are enabled, set up Tailwind after test
        if (useTailwind) {
          console.log(chalk.yellow('Note: When using lamdera-program-test with Tailwind, you\'ll need to manually integrate Tailwind examples.'));
          setupTailwind(projectPath, __dirname, true, parsedArgs.skipInstall, parsedArgs.packageManager);
        }
      }

      // Set up i18n if requested
      if (useI18n) {
        setupI18n(projectPath, __dirname, useTest, useTailwind);
      }

      // Set up authentication if requested
      if (useAuth) {
        setupAuth(projectPath, __dirname, useTest, useI18n);
      }
    }

    // Handle GitHub repository
    if (createRepo === null && rl) {
      console.log(chalk.cyan('Do you want to create a GitHub repository? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      createRepo = answer.toLowerCase() === 'y';
    }

    if (createRepo) {
      try {
        execSync('gh --version', { stdio: 'ignore' });

        // Get visibility preference if not set
        if (createRepo && repoVisibility === 'private' && rl && parsedArgs.visibility === 'private' && !args.includes('--private')) {
          console.log(chalk.cyan('Do you want the repository to be public or private? (pub/priv)'));
          const answer = await new Promise(resolve => rl.question('', resolve));
          repoVisibility = answer === 'pub' ? 'public' : 'private';
        }

        const visibilityFlag = repoVisibility === 'public' ? '--public' : '--private';

        console.log(chalk.blue('Creating GitHub repository...'));
        execCommand('git init');
        
        // Configure git hooks if test mode is enabled or using boilerplate
        if ((parsedArgs.boilerplate || useTest) && fs.existsSync(path.join(projectPath, '.githooks', 'pre-commit'))) {
          configureGitHooks(projectPath);
        }
        
        execCommand('git add .');
        execCommand('git commit -m "Initial commit"');
        execCommand(`gh repo create "${projectName}" ${visibilityFlag} --source=. --remote=origin --push`);

        console.log(chalk.green('GitHub repository created and code pushed!'));
      } catch {
        console.log(chalk.red('GitHub CLI (gh) is not installed. Skipping repository creation.'));
      }
    }

    console.log(chalk.green('Project setup complete!'));
    const pm = parsedArgs.packageManager;
    console.log(chalk.blue('To start development server:'));
    console.log(chalk.cyan(`cd ${projectName}`));
    
    // For boilerplate, always show tailwind commands since it includes everything
    if (parsedArgs.boilerplate || useTailwind) {
      if (parsedArgs.skipInstall) {
        console.log(chalk.yellow(`\n⚠️  ${pm} install was skipped`));
        console.log(chalk.cyan(`${pm} install`));
        console.log(chalk.gray('(Run this first to install dependencies)'));
        console.log('');
      }
      console.log(chalk.cyan(`${pm} ${pm === 'bun' ? 'run' : ''} start`));
      console.log(chalk.gray('(This runs both Lamdera and Tailwind CSS watcher)'));
      console.log('');
      console.log(chalk.blue('To use a different port:'));
      console.log(chalk.cyan(`PORT=3000 ${pm} ${pm === 'bun' ? 'run' : ''} start`));
      console.log('');
      console.log(chalk.blue('For hot-reload with elm-pkg-js:'));
      console.log(chalk.cyan(`${pm} run start:hot`));
      console.log(chalk.gray(`(Also supports PORT=3000 ${pm} run start:hot)`));
    } else {
      console.log(chalk.cyan('./lamdera-dev-watch.sh'));
      console.log('');
      console.log(chalk.blue('To use a different port:'));
      console.log(chalk.cyan('./lamdera-dev-watch.sh --port=3000'));
      console.log(chalk.gray('or'));
      console.log(chalk.cyan('PORT=3000 ./lamdera-dev-watch.sh'));
    }
    
    if (parsedArgs.boilerplate || useTest) {
      console.log('');
      console.log(chalk.blue('Test examples included:'));
      console.log(chalk.gray('Check tests/Tests.elm for lamdera-program-test examples'));
      console.log(chalk.gray('To run: elm-test-rs --compiler $(which lamdera)'));
    }
    
    if (parsedArgs.boilerplate || useI18n) {
      console.log('');
      console.log(chalk.blue('i18n and dark mode features:'));
      console.log(chalk.gray('- Language switcher (EN/FR) in the header'));
      console.log(chalk.gray('- Dark/Light/System theme selector'));
      console.log(chalk.gray('- Preferences persist in localStorage'));
      console.log(chalk.gray('- Auto-detects browser language and system theme'));
    }
    
    if (parsedArgs.boilerplate) {
      console.log('');
      console.log(chalk.blue('Authentication features:'));
      console.log(chalk.gray('- Google One Tap login'));
      console.log(chalk.gray('- GitHub OAuth'));
      console.log(chalk.gray('- Email/password authentication'));
      console.log(chalk.gray('- Admin panel at /admin'));
      console.log(chalk.gray('See GOOGLE_ONE_TAP_SETUP.md and GITHUB_OAUTH_SETUP.md for OAuth setup'));
    }
  } finally {
    if (rl) {
      rl.close();
    }
  }
}

async function main() {
  try {
    checkPrerequisites(parsedArgs.packageManager);

    if (parsedArgs.installPrecommit) {
      await installPrecommitHook();
    } else if (parsedArgs.init) {
      await initializeExistingProject();
    } else {
      await createNewProject();
    }
  } catch (error) {
    console.error(chalk.red('An unexpected error occurred:'), error);
    process.exit(1);
  }
}

main(); 