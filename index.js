#!/usr/bin/env node

const chalk = require('chalk');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

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

// Initialize Lamdera project
function initializeLamderaProject(projectPath) {
  const templatePath = path.join(__dirname, 'templates', 'lamdera-init');
  
  // Create src directory
  fs.mkdirSync(path.join(projectPath, 'src'), { recursive: true });
  
  // Copy elm.json
  fs.copyFileSync(path.join(templatePath, 'elm.json'), path.join(projectPath, 'elm.json'));
  
  // Copy source files
  const sourceFiles = ['Backend.elm', 'Frontend.elm', 'Types.elm', 'Env.elm'];
  sourceFiles.forEach(file => {
    fs.copyFileSync(
      path.join(templatePath, 'src', file),
      path.join(projectPath, 'src', file)
    );
  });
}

// Install required Lamdera packages
function installPackages() {
  console.log(chalk.blue('Installing default packages...'));
  execCommand('yes | lamdera install elm/http');
  execCommand('yes | lamdera install elm/time');
  execCommand('yes | lamdera install elm/json');
}

async function initializeExistingProject() {
  try {
    console.log(chalk.cyan('Do you use Cursor editor? (y/n)'));
    const useCursor = await new Promise(resolve => rl.question('', resolve));

    // Create utility files
    console.log(chalk.blue('Creating utility files...'));
    createUtilityFiles(process.cwd(), useCursor.toLowerCase() === 'y');

    // Install packages
    installPackages();

    console.log(chalk.green('Project setup complete!'));
  } finally {
    rl.close();
  }
}

async function createNewProject() {
  try {
    console.log(chalk.cyan('Enter your project name:'));
    const projectName = await new Promise(resolve => rl.question('', resolve));

    if (!projectName) {
      console.error(chalk.red('Project name is required'));
      process.exit(1);
    }

    console.log(chalk.cyan('Do you use Cursor editor? (y/n)'));
    const useCursor = await new Promise(resolve => rl.question('', resolve));

    const projectPath = path.join(process.cwd(), projectName);

    // Create project directory
    fs.mkdirSync(projectPath);
    process.chdir(projectPath);

    // Initialize Lamdera project
    console.log(chalk.blue('Initializing Lamdera project...'));
    initializeLamderaProject(projectPath);

    // Install packages
    installPackages();

    // Create utility files
    console.log(chalk.blue('Creating utility files...'));
    createUtilityFiles(projectPath, useCursor.toLowerCase() === 'y');

    // Ask about GitHub repository
    console.log(chalk.cyan('Do you want to create a GitHub repository? (y/n)'));
    const createRepo = await new Promise(resolve => rl.question('', resolve));

    if (createRepo.toLowerCase() === 'y') {
      try {
        execSync('gh --version', { stdio: 'ignore' });
        
        console.log(chalk.cyan('Do you want the repository to be public or private? (pub/priv)'));
        const repoVisibility = await new Promise(resolve => rl.question('', resolve));
        
        const visibilityFlag = repoVisibility === 'pub' ? '--public' : '--private';
        
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
    console.log(chalk.cyan('./lamdera-dev-watch.sh'));
  } finally {
    rl.close();
  }
}

async function main() {
  try {
    checkPrerequisites();

    const args = process.argv.slice(2);
    if (args.includes('--init')) {
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