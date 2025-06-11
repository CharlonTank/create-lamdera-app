const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

describe('create-lamdera-app CLI', () => {
  let tempDir;
  const cliPath = path.join(__dirname, '..', 'index.js');

  beforeEach(() => {
    // Create a temporary directory for each test
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'create-lamdera-app-test-'));
    process.chdir(tempDir);
  });

  afterEach(() => {
    // Clean up
    process.chdir(__dirname);
    fs.rmSync(tempDir, { recursive: true, force: true });
  });

  describe('Basic CLI functionality', () => {
    test('should display version', () => {
      const output = execSync(`node ${cliPath} --version`).toString().trim();
      expect(output).toMatch(/^\d+\.\d+\.\d+$/);
    });

    test('should display help', () => {
      const output = execSync(`node ${cliPath} --help`).toString();
      expect(output).toContain('Create Lamdera App');
      expect(output).toContain('Usage:');
      expect(output).toContain('Options:');
      expect(output).toContain('Examples:');
      expect(output).toContain('--name');
      expect(output).toContain('--cursor');
      expect(output).toContain('--github');
    });

    test('should display help with -h flag', () => {
      const output = execSync(`node ${cliPath} -h`).toString();
      expect(output).toContain('Create Lamdera App');
    });
  });

  describe('Argument parsing', () => {
    test('should require project name in non-interactive mode', () => {
      // This test confirms that without --name, the CLI tries to be interactive
      // We can't easily test interactive mode in automated tests
      const helpOutput = execSync(`node ${cliPath} --help`).toString();
      expect(helpOutput).toContain('--name');
      expect(helpOutput).toContain('required for new projects in non-interactive mode');
    });

    test('should create project with all flags', () => {
      const projectName = 'test-project';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      expect(output).toContain('Initializing Lamdera project');
      expect(output).toContain('Creating utility files');
      expect(output).toContain('Project setup complete!');
      
      // Check if project directory was created
      expect(fs.existsSync(path.join(tempDir, projectName))).toBe(true);
      
      // Check if files were created
      const projectPath = path.join(tempDir, projectName);
      expect(fs.existsSync(path.join(projectPath, 'elm.json'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/Frontend.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/Backend.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/Types.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'lamdera-dev-watch.sh'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'toggle-debugger.py'))).toBe(true);
      
      // Should not have cursor files
      expect(fs.existsSync(path.join(projectPath, '.cursorrules'))).toBe(false);
      expect(fs.existsSync(path.join(projectPath, 'openEditor.sh'))).toBe(false);
    });

    test('should create project with cursor support', () => {
      const projectName = 'test-cursor-project';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --cursor yes --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      expect(fs.existsSync(path.join(projectPath, '.cursorrules'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'openEditor.sh'))).toBe(true);
    });
  });

  describe('Init mode', () => {
    test('should add utilities to existing project', () => {
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Create a dummy existing project
      fs.writeFileSync(path.join(tempDir, 'elm.json'), '{}');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --init --cursor yes`,
        { encoding: 'utf8', cwd: tempDir }
      );
      
      expect(output).toContain('Creating utility files');
      expect(output).toContain('Project setup complete!');
      
      // Check if utility files were created
      expect(fs.existsSync(path.join(tempDir, 'lamdera-dev-watch.sh'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, 'toggle-debugger.py'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, '.cursorrules'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, 'openEditor.sh'))).toBe(true);
    });

    test('should add utilities without cursor', () => {
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Create a dummy existing project
      fs.writeFileSync(path.join(tempDir, 'elm.json'), '{}');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --init --no-cursor`,
        { encoding: 'utf8', cwd: tempDir }
      );
      
      expect(fs.existsSync(path.join(tempDir, 'lamdera-dev-watch.sh'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, 'toggle-debugger.py'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, '.cursorrules'))).toBe(false);
      expect(fs.existsSync(path.join(tempDir, 'openEditor.sh'))).toBe(false);
    });
  });

  describe('Error handling', () => {
    test('should fail if lamdera is not installed', () => {
      try {
        // Keep node in PATH but remove lamdera
        const nodePath = path.dirname(process.execPath);
        execSync(`node ${cliPath} --name test --no-cursor --no-github`, {
          encoding: 'utf8',
          env: { ...process.env, PATH: `${nodePath}:${tempDir}` }
        });
        fail('Should have thrown an error');
      } catch (error) {
        // The error will be in stderr
        const errorOutput = error.stderr.toString();
        expect(errorOutput).toContain('Lamdera is not installed');
      }
    });

    test('should handle duplicate project name gracefully', () => {
      const projectName = 'duplicate-project';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Create project first time
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      // Go back to tempDir before trying to create again
      process.chdir(tempDir);
      
      // Try to create again
      try {
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        fail('Should have thrown an error');
      } catch (error) {
        // Expected to fail with our new error message
        const errorOutput = error.stderr ? error.stderr.toString() : error.stdout.toString();
        expect(errorOutput).toContain(`Directory '${projectName}' already exists`);
      }
    });
  });

  describe('File permissions', () => {
    test('should set correct permissions on shell scripts', () => {
      const projectName = 'permissions-test';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --cursor yes --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      
      // Check file permissions (should be executable)
      const watchScriptStats = fs.statSync(path.join(projectPath, 'lamdera-dev-watch.sh'));
      const debuggerStats = fs.statSync(path.join(projectPath, 'toggle-debugger.py'));
      const editorStats = fs.statSync(path.join(projectPath, 'openEditor.sh'));
      
      // Check if files are executable (mode & 0o111 checks for any execute bit)
      expect(watchScriptStats.mode & 0o111).toBeTruthy();
      expect(debuggerStats.mode & 0o111).toBeTruthy();
      expect(editorStats.mode & 0o111).toBeTruthy();
    });
  });
});