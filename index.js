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
    tailwind: null
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
        parsed.name = nextArg;
        i++;
        break;
      case '--cursor':
        parsed.cursor = nextArg === 'yes' || nextArg === 'y';
        i++;
        break;
      case '--no-cursor':
        parsed.cursor = false;
        break;
      case '--github':
        parsed.github = nextArg === 'yes' || nextArg === 'y';
        i++;
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
        parsed.tailwind = nextArg === 'yes' || nextArg === 'y';
        i++;
        break;
      case '--no-tailwind':
        parsed.tailwind = false;
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

  ${chalk.gray('# Add utilities to existing project')}
  npx @CharlonTank/create-lamdera-app --init --cursor yes
`);
  process.exit(0);
}

// Only create readline interface if we need it (no args provided)
let rl = null;
const isInteractive = !parsedArgs.name && !parsedArgs.init;

if (isInteractive || (parsedArgs.init && parsedArgs.cursor === null)) {
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
function setupTailwind(projectPath, baseDir) {
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
    let headContent = fs.readFileSync(headPath, 'utf8');
  
  // Add the Tailwind CSS link before the closing style tag
  headContent = headContent.replace(
    '</style>',
    '</style>\n<link rel="stylesheet" href="/styles.css">'
  );
  
  fs.writeFileSync(headPath, headContent);
  
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
    
    // Replace Frontend.elm with Tailwind example version
    fs.copyFileSync(path.join(templatePath, 'tailwind-frontend.elm'), './src/Frontend.elm');
    
    console.log(chalk.green('Tailwind CSS setup complete!'));
  } finally {
    // Restore original directory
    process.chdir(originalDir);
  }
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
  try {
    let useCursor = parsedArgs.cursor;
    
    // Only ask if not provided via CLI
    if (useCursor === null && rl) {
      console.log(chalk.cyan('Do you use Cursor editor? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useCursor = answer.toLowerCase() === 'y';
    }

    // Create utility files
    console.log(chalk.blue('Creating utility files...'));
    createUtilityFiles(process.cwd(), useCursor);

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

    // Get cursor preference if not provided
    if (useCursor === null && rl) {
      console.log(chalk.cyan('Do you use Cursor editor? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useCursor = answer.toLowerCase() === 'y';
    }

    // Get Tailwind preference if not provided
    if (useTailwind === null && rl) {
      console.log(chalk.cyan('Do you want to use Tailwind CSS? (y/n)'));
      const answer = await new Promise(resolve => rl.question('', resolve));
      useTailwind = answer.toLowerCase() === 'y';
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
    if (useTailwind) {
      setupTailwind(projectPath, __dirname);
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