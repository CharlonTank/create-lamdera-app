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
    test: null
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
function execCommand(command) {
  try {
    execSync(command, { stdio: 'inherit', killSignal: 'SIGINT' });
  } catch (error) {
    if (error.signal === 'SIGINT') {
      console.log(chalk.yellow('\nProcess interrupted by user'));
      process.exit(0);
    }
    console.error(chalk.red(`Error executing command: ${command}`));
    console.error(chalk.red(error.message));
    process.exit(1);
  }
}

// Check prerequisites
function checkPrerequisites() {
  try {
    execSync('lamdera --version', { stdio: 'ignore' });
  } catch {
    console.error(chalk.red('Lamdera is not installed. Please install it first.'));
    process.exit(1);
  }
}

// Create utility files
function createUtilityFiles(projectPath, useCursor) {
  const templatePath = path.join(__dirname, 'templates');

  // Copy template files
  fs.copyFileSync(path.join(templatePath, 'lamdera-dev-watch.sh'), path.join(projectPath, 'lamdera-dev-watch.sh'));
  fs.chmodSync(path.join(projectPath, 'lamdera-dev-watch.sh'), '755');

  fs.copyFileSync(path.join(templatePath, 'toggle-debugger.py'), path.join(projectPath, 'toggle-debugger.py'));
  fs.chmodSync(path.join(projectPath, 'toggle-debugger.py'), '755');

  if (useCursor) {
    fs.copyFileSync(path.join(templatePath, '.cursorrules'), path.join(projectPath, '.cursorrules'));
    fs.copyFileSync(path.join(templatePath, 'openEditor.sh'), path.join(projectPath, 'openEditor.sh'));
    fs.chmodSync(path.join(projectPath, 'openEditor.sh'), '755');
  }
}

// Initialize Tailwind CSS
function setupTailwind(projectPath, baseDir, skipFrontend = false) {
  console.log(chalk.blue('Setting up Tailwind CSS...'));
  
  // Save current directory and change to project path
  const originalDir = process.cwd();
  process.chdir(projectPath);
  
  try {
    // Initialize npm
    execCommand('npm init -y');
    
    // Wait a moment and verify package.json was created
    if (!fs.existsSync('./package.json')) {
      throw new Error('Failed to create package.json');
    }
    
    // Install dependencies
    execCommand('npm install tailwindcss@^3');
    execCommand('npm install --save-dev run-pty');
    
    // Create tailwind.config.js content manually (since v4 doesn't have init)
    const tailwindConfig = `module.exports = {
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
  
  packageJson.scripts = {
    ...packageJson.scripts,
    "start": "run-pty % lamdera live % tailwindcss -i ./src/styles.css -o ./public/styles.css --watch",
    "start:hot": "run-pty % ./lamdera-dev-watch.sh % tailwindcss -i ./src/styles.css -o ./public/styles.css --watch"
  };
  
  fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
  
    // Update .gitignore for Tailwind
    const templatePath = path.join(baseDir, 'templates');
    fs.copyFileSync(path.join(templatePath, 'tailwind.gitignore'), './.gitignore');
    
    // Replace Frontend.elm with Tailwind example version (only if not using test mode)
    if (!skipFrontend) {
      fs.copyFileSync(path.join(templatePath, 'tailwind-frontend.elm'), './src/Frontend.elm');
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
  fs.copyFileSync(path.join(templatePath, 'test-elm.json'), path.join(projectPath, 'elm.json'));
  
  // Replace Backend.elm, Frontend.elm, and Types.elm with test versions
  fs.copyFileSync(path.join(templatePath, 'test-backend.elm'), path.join(projectPath, 'src', 'Backend.elm'));
  fs.copyFileSync(path.join(templatePath, 'test-frontend.elm'), path.join(projectPath, 'src', 'Frontend.elm'));
  fs.copyFileSync(path.join(templatePath, 'test-types.elm'), path.join(projectPath, 'src', 'Types.elm'));
  
  // Create tests directory
  fs.mkdirSync(path.join(projectPath, 'tests'), { recursive: true });
  
  // Copy test template
  fs.copyFileSync(path.join(templatePath, 'test-tests.elm'), path.join(projectPath, 'tests', 'Tests.elm'));
  
  // Copy elm-test-rs.json
  fs.copyFileSync(path.join(templatePath, 'elm-test-rs.json'), path.join(projectPath, 'elm-test-rs.json'));
  
  console.log(chalk.green('lamdera-program-test setup complete!'));
  console.log(chalk.gray('To run tests: elm-test-rs --compiler $(which lamdera)'));
}

// Initialize Lamdera project
function initializeLamderaProject(projectPath) {
  const templatePath = path.join(__dirname, 'templates', 'lamdera-init');

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
      setupTailwind(process.cwd(), __dirname, true); // Skip frontend since it already exists
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
    if (useTailwind && !useTest) {
      setupTailwind(projectPath, __dirname, false);
    }

    // Set up lamdera-program-test if requested
    if (useTest) {
      setupLamderaTest(projectPath, __dirname);
      // If both Tailwind and test are enabled, set up Tailwind after test
      if (useTailwind) {
        console.log(chalk.yellow('Note: When using lamdera-program-test with Tailwind, you\'ll need to manually integrate Tailwind examples.'));
        setupTailwind(projectPath, __dirname, true);
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
        execCommand('git add .');
        execCommand('git commit -m "Initial commit"');
        execCommand(`gh repo create "${projectName}" ${visibilityFlag} --source=. --remote=origin --push`);

        console.log(chalk.green('GitHub repository created and code pushed!'));
      } catch {
        console.log(chalk.red('GitHub CLI (gh) is not installed. Skipping repository creation.'));
      }
    }

    console.log(chalk.green('Project setup complete!'));
    console.log(chalk.blue('To start development server:'));
    console.log(chalk.cyan(`cd ${projectName}`));
    if (useTailwind) {
      console.log(chalk.cyan('npm start'));
      console.log(chalk.gray('(This runs both Lamdera and Tailwind CSS watcher)'));
      console.log('');
      console.log(chalk.blue('For hot-reload with elm-pkg-js:'));
      console.log(chalk.cyan('npm run start:hot'));
    } else {
      console.log(chalk.cyan('./lamdera-dev-watch.sh'));
    }
    
    if (useTest) {
      console.log('');
      console.log(chalk.blue('Test examples included:'));
      console.log(chalk.gray('Check tests/Tests.elm for lamdera-program-test examples'));
      console.log(chalk.gray('To run: elm-test-rs --compiler $(which lamdera)'));
    }
  } finally {
    if (rl) {
      rl.close();
    }
  }
}

async function main() {
  try {
    checkPrerequisites();

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