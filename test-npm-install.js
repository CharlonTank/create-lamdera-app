#!/usr/bin/env node

// Test script to debug npm install issues
const { spawn } = require('child_process');
const chalk = require('chalk');

console.log(chalk.blue('Testing npm install with different approaches...\n'));

// Test 1: Using spawn instead of execSync
function testSpawn() {
  console.log(chalk.yellow('Test 1: Using spawn with real-time output'));
  
  const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
  const child = spawn(npm, ['install', 'tailwindcss@^3', '--verbose'], {
    stdio: 'inherit',
    shell: true
  });

  child.on('error', (error) => {
    console.error(chalk.red('Spawn error:'), error);
  });

  child.on('exit', (code) => {
    if (code === 0) {
      console.log(chalk.green('✓ Install completed successfully'));
    } else {
      console.log(chalk.red(`✗ Install failed with code ${code}`));
    }
  });
}

// Test 2: Check npm config
function checkNpmConfig() {
  console.log(chalk.yellow('\nTest 2: Checking npm configuration'));
  
  const { execSync } = require('child_process');
  
  try {
    console.log(chalk.gray('Registry:'), execSync('npm config get registry').toString().trim());
    console.log(chalk.gray('Proxy:'), execSync('npm config get proxy').toString().trim() || 'none');
    console.log(chalk.gray('HTTPS Proxy:'), execSync('npm config get https-proxy').toString().trim() || 'none');
    console.log(chalk.gray('Strict SSL:'), execSync('npm config get strict-ssl').toString().trim());
  } catch (error) {
    console.error(chalk.red('Error checking npm config:'), error.message);
  }
}

// Test 3: Try with different registry
function testWithDifferentRegistry() {
  console.log(chalk.yellow('\nTest 3: Testing with npm registry directly'));
  
  const { execSync } = require('child_process');
  
  try {
    execSync('npm install tailwindcss@^3 --registry https://registry.npmjs.org --verbose', {
      stdio: 'inherit'
    });
    console.log(chalk.green('✓ Install with explicit registry worked'));
  } catch (error) {
    console.error(chalk.red('Install with explicit registry failed:'), error.message);
  }
}

// Run tests based on command line argument
const testToRun = process.argv[2];

if (testToRun === '1') {
  testSpawn();
} else if (testToRun === '2') {
  checkNpmConfig();
} else if (testToRun === '3') {
  testWithDifferentRegistry();
} else {
  console.log(chalk.cyan('Usage: node test-npm-install.js [1|2|3]'));
  console.log(chalk.gray('  1 - Test with spawn (real-time output)'));
  console.log(chalk.gray('  2 - Check npm configuration'));
  console.log(chalk.gray('  3 - Test with explicit registry'));
  console.log(chalk.cyan('\nRunning npm config check by default...'));
  checkNpmConfig();
}