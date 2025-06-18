#!/usr/bin/env node

const chalk = require('chalk');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { version } = require('./package.json');

// Parse command line arguments early
const args = process.argv.slice(2);

// Parse named arguments
const parseArgs = () => {
  const parsed = {
    init: false,
    name: null,
    cursor: null,
    github: null,
    visibility: 'private',
    tailwind: null,
    test: null,
    i18n: null,
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
      case '--name':
      case '-n':
        if (!nextArg || nextArg.trim() === '') {
          console.error(chalk.red('Project name cannot be empty'));
          process.exit(1);
        }
        parsed.name = nextArg;
        i++;
        break;
      case '--cursor':
        if (nextArg && (nextArg === 'yes' || nextArg === 'y' || nextArg === 'no' || nextArg === 'n')) {
          parsed.cursor = nextArg === 'yes' || nextArg === 'y';
          i++;
        } else if (!nextArg || (nextArg !== 'yes' && nextArg !== 'no' && nextArg !== 'y' && nextArg !== 'n')) {
          console.error(chalk.red('--cursor must be yes or no'));
          process.exit(1);
        }
        break;
      case '--no-cursor':
        parsed.cursor = false;
        break;
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
      case '--tailwind':
        if (nextArg === 'yes' || nextArg === 'y' || nextArg === 'no' || nextArg === 'n') {
          parsed.tailwind = nextArg === 'yes' || nextArg === 'y';
          i++;
        } else {
          parsed.tailwind = true;
        }
        break;
      case '--no-tailwind':
        parsed.tailwind = false;
        break;
      case '--test':
        if (nextArg === 'yes' || nextArg === 'y' || nextArg === 'no' || nextArg === 'n') {
          parsed.test = nextArg === 'yes' || nextArg === 'y';
          i++;
        } else {
          parsed.test = true;
        }
        break;
      case '--no-test':
        parsed.test = false;
        break;
      case '--i18n':
        if (nextArg === 'yes' || nextArg === 'y' || nextArg === 'no' || nextArg === 'n') {
          parsed.i18n = nextArg === 'yes' || nextArg === 'y';
          i++;
        } else {
          parsed.i18n = true;
        }
        break;
      case '--no-i18n':
        parsed.i18n = false;
        break;
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
  --cursor <yes|no>   Use Cursor editor (yes/no)
  --no-cursor         Don't use Cursor editor
  --github <yes|no>   Create GitHub repository (yes/no)
  --no-github         Don't create GitHub repository
  --public            Make GitHub repository public
  --private           Make GitHub repository private (default)
  --tailwind <yes|no> Add Tailwind CSS setup (yes/no)
  --no-tailwind       Don't add Tailwind CSS
  --test <yes|no>     Add lamdera-program-test setup (yes/no)
  --no-test           Don't add lamdera-program-test
  --i18n <yes|no>     Add internationalization and dark mode (yes/no)
  --no-i18n           Don't add i18n and dark mode
  --skip-install      Skip package installation for Tailwind projects
  --package-manager <npm|bun>  Choose package manager (default: npm)
  --pm <npm|bun>      Shorthand for --package-manager
  --bun               Use Bun package manager (shorthand for --pm bun)
  --version           Show version number
  --help, -h          Show this help message

${chalk.bold('Examples:')}
  ${chalk.gray('# Create a new Lamdera project interactively')}
  npx @CharlonTank/create-lamdera-app

  ${chalk.gray('# Create a new project without prompts')}
  npx @CharlonTank/create-lamdera-app --name my-app --no-cursor --no-github

  ${chalk.gray('# Create a project with Cursor and public GitHub repo')}
  npx @CharlonTank/create-lamdera-app --name my-app --cursor yes --github yes --public

  ${chalk.gray('# Create a project with Tailwind CSS')}
  npx @CharlonTank/create-lamdera-app --name my-app --tailwind yes --no-cursor

  ${chalk.gray('# Create a testable project with lamdera-program-test')}
  npx @CharlonTank/create-lamdera-app --name my-app --test yes

  ${chalk.gray('# Create a project with i18n and dark mode support')}
  npx @CharlonTank/create-lamdera-app --name my-app --i18n yes

  ${chalk.gray('# Add utilities to existing project')}
  npx @CharlonTank/create-lamdera-app --init --cursor yes
`);
  process.exit(0);
}

// Only create readline interface if we need it (no args provided)
let rl = null;
const isNewProjectInteractive = !parsedArgs.init && !parsedArgs.name;
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
function createUtilityFiles(projectPath, useCursor) {
  const templatePath = path.join(__dirname, 'templates');

  // Copy template files
  fs.copyFileSync(path.join(templatePath, 'utilities', 'lamdera-dev-watch.sh'), path.join(projectPath, 'lamdera-dev-watch.sh'));
  fs.chmodSync(path.join(projectPath, 'lamdera-dev-watch.sh'), '755');

  fs.copyFileSync(path.join(templatePath, 'utilities', 'toggle-debugger.py'), path.join(projectPath, 'toggle-debugger.py'));
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
  
  // Replace Types with appropriate version
  if (useTest) {
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'test-i18n-theme-types.elm'), path.join(projectPath, 'src', 'Types.elm'));
  } else {
    fs.copyFileSync(path.join(templatePath, 'features', 'i18n', 'i18n-theme-types.elm'), path.join(projectPath, 'src', 'Types.elm'));
  }
  
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

    // Create utility files
    console.log(chalk.blue('Creating utility files...'));
    createUtilityFiles(process.cwd(), useCursor);
    
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
      const isTestProject = elmJson.dependencies.direct['lamdera/program-test'] !== undefined;
      setupI18n(process.cwd(), __dirname, isTestProject);
    }

    console.log(chalk.green('Project setup complete!'));
  } finally {
    if (rl) {
      rl.close();
    }
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

    // Get cursor preference if not provided
    if (useCursor === null) {
      if (rl) {
        console.log(chalk.cyan('Do you use Cursor editor? (y/n)'));
        const answer = await new Promise(resolve => rl.question('', resolve));
        useCursor = answer.toLowerCase() === 'y';
      } else {
        useCursor = false; // Default to false in non-interactive mode
      }
    }

    // Get Tailwind preference if not provided
    if (useTailwind === null && rl) {
      console.log(chalk.cyan('Do you want to use Tailwind CSS? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useTailwind = answer.toLowerCase() === 'y';
    }

    // Get test preference if not provided
    if (useTest === null && rl) {
      console.log(chalk.cyan('Do you want to set up lamdera-program-test for testing? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useTest = answer.toLowerCase() === 'y';
    }

    // Get i18n preference if not provided
    if (useI18n === null && rl) {
      console.log(chalk.cyan('Do you want to add internationalization and dark mode support? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useI18n = answer.toLowerCase() === 'y';
    }

    const projectPath = path.join(process.cwd(), projectName);

    // Check if directory already exists
    if (fs.existsSync(projectPath)) {
      console.error(chalk.red(`Directory '${projectName}' already exists`));
      process.exit(1);
    }

    // Create project directory
    fs.mkdirSync(projectPath);
    process.chdir(projectPath);

    // Initialize Lamdera project
    console.log(chalk.blue('Initializing Lamdera project...'));
    initializeLamderaProject(projectPath);

    // Create utility files
    console.log(chalk.blue('Creating utility files...'));
    createUtilityFiles(projectPath, useCursor);

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
    if (useTailwind) {
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
    
    if (useTest) {
      console.log('');
      console.log(chalk.blue('Test examples included:'));
      console.log(chalk.gray('Check tests/Tests.elm for lamdera-program-test examples'));
      console.log(chalk.gray('To run: elm-test-rs --compiler $(which lamdera)'));
    }
    
    if (useI18n) {
      console.log('');
      console.log(chalk.blue('i18n and dark mode features:'));
      console.log(chalk.gray('- Language switcher (EN/FR) in the header'));
      console.log(chalk.gray('- Dark/Light/System theme selector'));
      console.log(chalk.gray('- Preferences persist in localStorage'));
      console.log(chalk.gray('- Auto-detects browser language and system theme'));
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

    if (parsedArgs.init) {
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