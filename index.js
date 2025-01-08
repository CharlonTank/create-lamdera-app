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

// Helper function to execute commands
function execCommand(command) {
  try {
    execSync(command, { stdio: 'inherit' });
  } catch (error) {
    console.error(chalk.red(`Error executing command: ${command}`));
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
  
  fs.copyFileSync(path.join(templatePath, 'toggle_debugger.py'), path.join(projectPath, 'toggle_debugger.py'));
  fs.chmodSync(path.join(projectPath, 'toggle_debugger.py'), '755');

  if (useCursor) {
    fs.copyFileSync(path.join(templatePath, '.cursorrules'), path.join(projectPath, '.cursorrules'));
    fs.copyFileSync(path.join(templatePath, 'openEditor.sh'), path.join(projectPath, 'openEditor.sh'));
    fs.chmodSync(path.join(projectPath, 'openEditor.sh'), '755');
  }
}

async function main() {
  checkPrerequisites();

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
  execCommand('lamdera init');

  // Install default packages
  console.log(chalk.blue('Installing default packages...'));
  execCommand('yes | lamdera install elm/http');
  execCommand('yes | lamdera install elm/time');
  execCommand('yes | lamdera install elm/json');

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

  rl.close();
}

main().catch(error => {
  console.error(chalk.red('An error occurred:'), error);
  process.exit(1);
}); 