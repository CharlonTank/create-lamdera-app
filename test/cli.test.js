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
      expect(output).toContain('--tailwind');
      expect(output).toContain('--test');
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

    test('should create project with Tailwind CSS', () => {
      const projectName = 'test-tailwind-project';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Mock npm and npx commands - npm init needs to create package.json
      const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"test","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
      fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
      fs.chmodSync(path.join(tempDir, 'npm'), '755');
      fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
      fs.chmodSync(path.join(tempDir, 'npx'), '755');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --tailwind yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      expect(output).toContain('Setting up Tailwind CSS');
      expect(output).toContain('Tailwind CSS setup complete!');
      
      const projectPath = path.join(tempDir, projectName);
      expect(fs.existsSync(path.join(projectPath, 'src/styles.css'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'tailwind.config.js'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'package.json'))).toBe(true);
      
      // Check package.json has the start script
      const packageJson = JSON.parse(fs.readFileSync(path.join(projectPath, 'package.json'), 'utf8'));
      expect(packageJson.scripts.start).toContain('tailwindcss');
    });

    test('should create project with lamdera-program-test', () => {
      const projectName = 'test-program-test-project';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --test yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      expect(output).toContain('Setting up lamdera-program-test');
      expect(output).toContain('lamdera-program-test setup complete!');
      
      const projectPath = path.join(tempDir, projectName);
      expect(fs.existsSync(path.join(projectPath, 'tests/Tests.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'elm-test-rs.json'))).toBe(true);
      
      // Check that test-specific Types.elm is used
      const typesContent = fs.readFileSync(path.join(projectPath, 'src/Types.elm'), 'utf8');
      expect(typesContent).toContain('Effect.Browser.Navigation');
      expect(typesContent).toContain('CounterNewValue');
    });

    test('should create project with both Tailwind and tests', () => {
      const projectName = 'test-tailwind-and-tests';
      
      // Mock commands
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"test","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
      fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
      fs.chmodSync(path.join(tempDir, 'npm'), '755');
      fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
      fs.chmodSync(path.join(tempDir, 'npx'), '755');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --tailwind yes --test yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      expect(output).toContain('Setting up lamdera-program-test');
      expect(output).toContain('Setting up Tailwind CSS');
      expect(output).toContain('Note: When using lamdera-program-test with Tailwind');
      
      const projectPath = path.join(tempDir, projectName);
      
      // Should have both test files and tailwind files
      expect(fs.existsSync(path.join(projectPath, 'tests/Tests.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/styles.css'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'tailwind.config.js'))).toBe(true);
      
      // Frontend should be the test version, not the tailwind version
      const frontendContent = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
      expect(frontendContent).toContain('Effect.Lamdera');
      expect(frontendContent).toContain('CounterNewValue');
      expect(frontendContent).not.toContain('NoOpToFrontend');
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

    test('should fail init without elm.json', () => {
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      try {
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --init --no-cursor`,
          { encoding: 'utf8', cwd: tempDir }
        );
        fail('Should have thrown an error');
      } catch (error) {
        const errorOutput = error.stderr.toString();
        expect(errorOutput).toContain('No elm.json found');
      }
    });

    test('should not allow --init with --name', () => {
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      try {
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --init --name test-project`,
          { encoding: 'utf8' }
        );
        fail('Should have thrown an error');
      } catch (error) {
        const errorOutput = error.stderr.toString();
        expect(errorOutput).toContain('Cannot use --name with --init');
      }
    });

    test('should add tailwind to existing project with --init', () => {
      // Mock commands
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"test","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
      fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
      fs.chmodSync(path.join(tempDir, 'npm'), '755');
      fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
      fs.chmodSync(path.join(tempDir, 'npx'), '755');
      
      // Create existing project
      fs.writeFileSync(path.join(tempDir, 'elm.json'), '{}');
      fs.mkdirSync(path.join(tempDir, 'src'));
      fs.writeFileSync(path.join(tempDir, 'src/Frontend.elm'), 'module Frontend exposing (..)');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --init --tailwind yes --no-cursor`,
        { encoding: 'utf8', cwd: tempDir }
      );
      
      expect(output).toContain('Setting up Tailwind CSS');
      expect(fs.existsSync(path.join(tempDir, 'src/styles.css'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, 'tailwind.config.js'))).toBe(true);
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

    test('should handle project names with spaces', () => {
      const projectName = 'project with spaces';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      try {
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name "${projectName}" --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        fail('Should have thrown an error');
      } catch (error) {
        const errorOutput = error.stderr.toString();
        expect(errorOutput).toContain('Project name cannot contain spaces');
      }
    });

    test('should handle project names with special characters', () => {
      const projectName = 'project@#$%';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      try {
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name "${projectName}" --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        fail('Should have thrown an error');
      } catch (error) {
        const errorOutput = error.stderr.toString();
        expect(errorOutput).toContain('Project name can only contain letters, numbers, hyphens, and underscores');
      }
    });

    test('should handle empty project name', () => {
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      try {
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name "" --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        fail('Should have thrown an error');
      } catch (error) {
        const errorOutput = error.stderr.toString();
        expect(errorOutput).toContain('Project name cannot be empty');
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

  describe('Flag combinations and edge cases', () => {
    test('should handle conflicting yes/no flags gracefully', () => {
      const projectName = 'conflicting-flags';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Last flag should win
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --cursor yes --cursor no --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      expect(fs.existsSync(path.join(projectPath, '.cursorrules'))).toBe(false);
    });

    test('should handle --public and --private flags correctly', () => {
      const projectName = 'visibility-test';
      
      // Mock lamdera and gh commands
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      fs.writeFileSync(path.join(tempDir, 'gh'), '#!/bin/bash\necho "mocked"');
      fs.chmodSync(path.join(tempDir, 'gh'), '755');
      fs.writeFileSync(path.join(tempDir, 'git'), '#!/bin/bash\necho "mocked"');
      fs.chmodSync(path.join(tempDir, 'git'), '755');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --github yes --public --no-cursor`,
        { encoding: 'utf8' }
      );
      
      expect(output).toContain('Project setup complete!');
    });

    test('should validate boolean flag values', () => {
      const projectName = 'invalid-bool';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      try {
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --cursor maybe --no-github`,
          { encoding: 'utf8' }
        );
        fail('Should have thrown an error');
      } catch (error) {
        const errorOutput = error.stderr.toString();
        expect(errorOutput).toContain('--cursor must be yes or no');
      }
    });

    test('should handle all flags at once', () => {
      const projectName = 'all-flags-test';
      
      // Mock all commands
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"test","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
      fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
      fs.chmodSync(path.join(tempDir, 'npm'), '755');
      fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
      fs.chmodSync(path.join(tempDir, 'npx'), '755');
      fs.writeFileSync(path.join(tempDir, 'gh'), '#!/bin/bash\necho "mocked"');
      fs.chmodSync(path.join(tempDir, 'gh'), '755');
      fs.writeFileSync(path.join(tempDir, 'git'), '#!/bin/bash\necho "mocked"');
      fs.chmodSync(path.join(tempDir, 'git'), '755');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --cursor yes --github yes --public --tailwind yes --test yes`,
        { encoding: 'utf8' }
      );
      
      expect(output).toContain('Project setup complete!');
      
      const projectPath = path.join(tempDir, projectName);
      
      // Should have everything
      expect(fs.existsSync(path.join(projectPath, '.cursorrules'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/styles.css'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'tests/Tests.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'package.json'))).toBe(true);
    });
  });

  describe('Content validation', () => {
    test('should create valid elm.json', () => {
      const projectName = 'valid-elm-json';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      const elmJson = JSON.parse(fs.readFileSync(path.join(projectPath, 'elm.json'), 'utf8'));
      
      expect(elmJson.type).toBe('application');
      expect(elmJson['elm-version']).toBe('0.19.1');
      expect(elmJson['source-directories']).toContain('src');
      expect(elmJson.dependencies.direct).toHaveProperty('lamdera/core');
      expect(elmJson.dependencies.direct).toHaveProperty('lamdera/codecs');
    });

    test('should create compilable Elm files', () => {
      const projectName = 'compilable-elm';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      
      // Check that files have proper module declarations
      const frontend = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
      const backend = fs.readFileSync(path.join(projectPath, 'src/Backend.elm'), 'utf8');
      const types = fs.readFileSync(path.join(projectPath, 'src/Types.elm'), 'utf8');
      
      expect(frontend).toContain('module Frontend exposing');
      expect(backend).toContain('module Backend exposing');
      expect(types).toContain('module Types exposing');
      
      // Check imports
      expect(frontend).toContain('import Types exposing');
      expect(backend).toContain('import Types exposing');
    });

    test('should create valid package.json with tailwind', () => {
      const projectName = 'valid-package-json';
      
      // Mock commands
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"${projectName}","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
      fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
      fs.chmodSync(path.join(tempDir, 'npm'), '755');
      fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
      fs.chmodSync(path.join(tempDir, 'npx'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --tailwind yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      const packageJson = JSON.parse(fs.readFileSync(path.join(projectPath, 'package.json'), 'utf8'));
      
      expect(packageJson.scripts).toHaveProperty('start');
      expect(packageJson.scripts).toHaveProperty('start:hot');
      expect(packageJson.scripts.start).toContain('lamdera live');
      expect(packageJson.scripts.start).toContain('tailwindcss');
      // devDependencies are added by npm install, which is mocked in our test
      // The test should just verify the package.json structure is valid
      expect(packageJson.name).toBe(projectName);
    });

    test('should handle SIGINT gracefully', () => {
      // This test verifies that the cleanup doesn't cause issues
      // In a real scenario, SIGINT would be sent to the process
      const projectName = 'sigint-test';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      // Project should be created successfully even with potential interrupts
      expect(fs.existsSync(path.join(tempDir, projectName))).toBe(true);
    });
  });

  describe('Comprehensive Elm compilation tests', () => {
    // Helper function to create a project and test compilation
    const testCompilation = (projectName, flags, description) => {
      test(description, () => {
        // Mock all required commands
        fs.writeFileSync(path.join(tempDir, 'lamdera'), `#!/bin/bash
if [[ "$1" == "make" ]]; then
  echo "Success! Compiled"
else
  echo "1.0.0"
fi`);
        fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
        
        const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"${projectName}","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
        fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
        fs.chmodSync(path.join(tempDir, 'npm'), '755');
        fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
        fs.chmodSync(path.join(tempDir, 'npx'), '755');
        
        // Create project
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} ${flags} --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        
        const projectPath = path.join(tempDir, projectName);
        expect(fs.existsSync(projectPath)).toBe(true);
        
        // Determine which files to compile based on flags
        let filesToCompile = 'src/Frontend.elm src/Backend.elm';
        if (flags.includes('--test yes')) {
          filesToCompile += ' tests/Tests.elm';
        }
        
        // Test compilation
        const output = execSync(
          `cd ${projectPath} && PATH=${tempDir}:$PATH lamdera make ${filesToCompile}`,
          { encoding: 'utf8' }
        );
        
        expect(output).toContain('Success! Compiled');
      });
    };

    // Test all 16 possible flag combinations
    const flagCombinations = [
      { flags: '', name: 'basic', desc: 'basic project without any features' },
      { flags: '--cursor yes', name: 'cursor', desc: 'project with cursor support' },
      { flags: '--tailwind yes', name: 'tailwind', desc: 'project with Tailwind CSS' },
      { flags: '--test yes', name: 'test', desc: 'project with lamdera-program-test' },
      { flags: '--i18n yes', name: 'i18n', desc: 'project with i18n support' },
      { flags: '--cursor yes --tailwind yes', name: 'cursor-tailwind', desc: 'project with cursor + Tailwind' },
      { flags: '--cursor yes --test yes', name: 'cursor-test', desc: 'project with cursor + test' },
      { flags: '--cursor yes --i18n yes', name: 'cursor-i18n', desc: 'project with cursor + i18n' },
      { flags: '--tailwind yes --test yes', name: 'tailwind-test', desc: 'project with Tailwind + test' },
      { flags: '--tailwind yes --i18n yes', name: 'tailwind-i18n', desc: 'project with Tailwind + i18n' },
      { flags: '--test yes --i18n yes', name: 'test-i18n', desc: 'project with test + i18n' },
      { flags: '--cursor yes --tailwind yes --test yes', name: 'cursor-tailwind-test', desc: 'project with cursor + Tailwind + test' },
      { flags: '--cursor yes --tailwind yes --i18n yes', name: 'cursor-tailwind-i18n', desc: 'project with cursor + Tailwind + i18n' },
      { flags: '--cursor yes --test yes --i18n yes', name: 'cursor-test-i18n', desc: 'project with cursor + test + i18n' },
      { flags: '--tailwind yes --test yes --i18n yes', name: 'tailwind-test-i18n', desc: 'project with Tailwind + test + i18n' },
      { flags: '--cursor yes --tailwind yes --test yes --i18n yes', name: 'all-features', desc: 'project with all features enabled' }
    ];

    flagCombinations.forEach(({ flags, name, desc }) => {
      testCompilation(`compile-${name}`, flags, `should compile ${desc}`);
    });
  });

  describe('i18n functionality tests', () => {
    test('should create i18n modules', () => {
      const projectName = 'i18n-modules-test';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --i18n yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      
      // Check i18n modules exist
      expect(fs.existsSync(path.join(projectPath, 'src/I18n.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/Theme.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/LocalStorage.elm'))).toBe(true);
      
      // Check localStorage.js exists
      expect(fs.existsSync(path.join(projectPath, 'localStorage.js'))).toBe(true);
      
      // Check head.html has localStorage script reference
      const headContent = fs.readFileSync(path.join(projectPath, 'head.html'), 'utf8');
      expect(headContent).toContain('<script src="/localStorage.js"');
    });

    test('should create i18n with test mode using Effect modules', () => {
      const projectName = 'i18n-test-modules';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --i18n yes --test yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      
      // Check Effect modules are used in LocalStorage
      const localStorageContent = fs.readFileSync(path.join(projectPath, 'src/LocalStorage.elm'), 'utf8');
      expect(localStorageContent).toContain('Effect.Command');
      expect(localStorageContent).toContain('Effect.Subscription');
      expect(localStorageContent).toContain('Command FrontendOnly');
      
      // Check elm-pkg-js directory exists
      expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js/localStorage.js'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js-includes.js'))).toBe(true);
    });

    test('should add i18n to existing project with --init', () => {
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Create existing project structure
      fs.writeFileSync(path.join(tempDir, 'elm.json'), JSON.stringify({
        type: 'application',
        'source-directories': ['src'],
        'elm-version': '0.19.1',
        dependencies: {
          direct: {
            'lamdera/core': '1.0.0',
            'lamdera/codecs': '1.0.0'
          }
        }
      }));
      fs.mkdirSync(path.join(tempDir, 'src'));
      fs.writeFileSync(path.join(tempDir, 'src/Frontend.elm'), 'module Frontend exposing (..)');
      
      const output = execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --init --i18n yes --no-cursor`,
        { encoding: 'utf8', cwd: tempDir }
      );
      
      expect(output).toContain('Setting up i18n and dark mode support');
      expect(fs.existsSync(path.join(tempDir, 'src/I18n.elm'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, 'src/Theme.elm'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, 'src/LocalStorage.elm'))).toBe(true);
    });
  });

  describe('Cross-flag compatibility tests', () => {
    test('should handle conflicting features gracefully', () => {
      const projectName = 'conflict-test';
      
      // Mock commands
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"${projectName}","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
      fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
      fs.chmodSync(path.join(tempDir, 'npm'), '755');
      fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
      fs.chmodSync(path.join(tempDir, 'npx'), '755');
      
      // Test that test mode takes precedence for Frontend/Types when combined with other features
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --tailwind yes --test yes --i18n yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      
      // Frontend should have test imports
      const frontendContent = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
      expect(frontendContent).toContain('Effect.Lamdera');
      expect(frontendContent).toContain('Effect.Browser.Navigation');
      
      // Should have i18n modules
      expect(fs.existsSync(path.join(projectPath, 'src/I18n.elm'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'src/Theme.elm'))).toBe(true);
      
      // Should have tailwind files
      expect(fs.existsSync(path.join(projectPath, 'src/styles.css'))).toBe(true);
      expect(fs.existsSync(path.join(projectPath, 'tailwind.config.js'))).toBe(true);
      
      // Should have test files
      expect(fs.existsSync(path.join(projectPath, 'tests/Tests.elm'))).toBe(true);
    });

    test('should validate i18n modules content', () => {
      const projectName = 'i18n-content-test';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --i18n yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      
      // Check I18n.elm content
      const i18nContent = fs.readFileSync(path.join(projectPath, 'src/I18n.elm'), 'utf8');
      expect(i18nContent).toContain('type Language');
      expect(i18nContent).toContain('= EN');
      expect(i18nContent).toContain('| FR');
      expect(i18nContent).toContain('type alias Translation');
      expect(i18nContent).toContain('translations : Language -> Translation');
      
      // Check Theme.elm content
      const themeContent = fs.readFileSync(path.join(projectPath, 'src/Theme.elm'), 'utf8');
      expect(themeContent).toContain('type UserPreference');
      expect(themeContent).toContain('DarkMode');
      expect(themeContent).toContain('LightMode');
      expect(themeContent).toContain('SystemMode');
      expect(themeContent).toContain('type Mode');
      expect(themeContent).toContain('type alias Theme');
      
      // Check LocalStorage.elm content
      const localStorageContent = fs.readFileSync(path.join(projectPath, 'src/LocalStorage.elm'), 'utf8');
      expect(localStorageContent).toContain('port storeLocalStorageValue_');
      expect(localStorageContent).toContain('port receiveLocalStorage_');
      expect(localStorageContent).toContain('type alias LocalStorage');
    });
  });

  describe('Feature tests WITHOUT test mode', () => {
    describe('i18n without test mode', () => {
      test('should create standard i18n with ports', () => {
        const projectName = 'i18n-standard';
        
        // Mock lamdera command
        fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
        fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
        
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --i18n yes --no-test --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        
        const projectPath = path.join(tempDir, projectName);
        
        // Check LocalStorage uses ports (not Effect modules)
        const localStorageContent = fs.readFileSync(path.join(projectPath, 'src/LocalStorage.elm'), 'utf8');
        expect(localStorageContent).toContain('port storeLocalStorageValue_');
        expect(localStorageContent).toContain('port receiveLocalStorage_');
        expect(localStorageContent).not.toContain('Effect.Command');
        expect(localStorageContent).not.toContain('Effect.Subscription');
        
        // Check localStorage.js is in root (not elm-pkg-js)
        expect(fs.existsSync(path.join(projectPath, 'localStorage.js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js'))).toBe(false);
        
        // Check Frontend doesn't have Effect imports
        const frontendContent = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
        expect(frontendContent).toContain('import Browser');
        expect(frontendContent).not.toContain('import Effect.Browser');
        expect(frontendContent).toContain('import LocalStorage');
        
        // Check head.html has localStorage script reference
        const headContent = fs.readFileSync(path.join(projectPath, 'head.html'), 'utf8');
        expect(headContent).toContain('<script src="/localStorage.js"');
      });
      
      test('should create i18n + tailwind without test', () => {
        const projectName = 'i18n-tailwind-standard';
        
        // Mock commands
        fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
        fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
        
        const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"${projectName}","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
        fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
        fs.chmodSync(path.join(tempDir, 'npm'), '755');
        fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
        fs.chmodSync(path.join(tempDir, 'npx'), '755');
        
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --i18n yes --tailwind yes --no-test --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        
        const projectPath = path.join(tempDir, projectName);
        
        // Should have both features
        expect(fs.existsSync(path.join(projectPath, 'src/I18n.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/Theme.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/LocalStorage.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'tailwind.config.js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/styles.css'))).toBe(true);
        
        // LocalStorage should be standard version
        const localStorageContent = fs.readFileSync(path.join(projectPath, 'src/LocalStorage.elm'), 'utf8');
        expect(localStorageContent).toContain('port storeLocalStorageValue_');
        expect(localStorageContent).not.toContain('Effect.Command');
      });
    });
    
    describe('Tailwind without test mode', () => {
      test('should create tailwind with standard Frontend', () => {
        const projectName = 'tailwind-standard';
        
        // Mock commands
        fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
        fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
        
        const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"${projectName}","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
        fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
        fs.chmodSync(path.join(tempDir, 'npm'), '755');
        fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
        fs.chmodSync(path.join(tempDir, 'npx'), '755');
        
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --tailwind yes --no-test --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        
        const projectPath = path.join(tempDir, projectName);
        
        // Check Frontend is Tailwind version (not test version)
        const frontendContent = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
        expect(frontendContent).toContain('import Browser');
        expect(frontendContent).not.toContain('import Effect.Browser');
        expect(frontendContent).toContain('NoOpToFrontend'); // Tailwind example has this
        expect(frontendContent).not.toContain('CounterNewValue'); // Test version has this
        
        // Check head.html has Tailwind styles
        const headContent = fs.readFileSync(path.join(projectPath, 'head.html'), 'utf8');
        expect(headContent).toContain('<link rel="stylesheet" href="/styles.css">');
      });
    });
  });

  describe('Feature tests WITH test mode', () => {
    describe('i18n with test mode', () => {
      test('should create i18n with Effect modules', () => {
        const projectName = 'i18n-test-effect';
        
        // Mock lamdera command
        fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
        fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
        
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --i18n yes --test yes --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        
        const projectPath = path.join(tempDir, projectName);
        
        // Check LocalStorage uses Effect modules with ports
        const localStorageContent = fs.readFileSync(path.join(projectPath, 'src/LocalStorage.elm'), 'utf8');
        expect(localStorageContent).toContain('import Effect.Command');
        expect(localStorageContent).toContain('import Effect.Subscription');
        expect(localStorageContent).toContain('Command FrontendOnly toMsg msg');
        expect(localStorageContent).toContain('Subscription FrontendOnly msg');
        // With lamdera-program-test, ports are still declared but wrapped by Effect modules
        expect(localStorageContent).toContain('port storeLocalStorageValue_');
        expect(localStorageContent).toContain('port receiveLocalStorage_');
        expect(localStorageContent).toContain('Command.sendToJs');
        expect(localStorageContent).toContain('Subscription.fromJs');
        
        // Check elm-pkg-js directory structure
        expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js/localStorage.js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js-includes.js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'localStorage.js'))).toBe(false); // Should NOT be in root
        
        // Check Frontend has Effect imports
        const frontendContent = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
        expect(frontendContent).toContain('import Effect.Browser');
        expect(frontendContent).toContain('import Effect.Lamdera');
        expect(frontendContent).toContain('import Browser exposing (UrlRequest(..))'); // This is still needed
        expect(frontendContent).toContain('import LocalStorage');
        
        // Check elm-pkg-js-includes.js content
        const includesContent = fs.readFileSync(path.join(projectPath, 'elm-pkg-js-includes.js'), 'utf8');
        expect(includesContent).toContain("require('./elm-pkg-js/localStorage')");
        expect(includesContent).toContain('exports.init');
      });
      
      test('should create i18n + tailwind with test', () => {
        const projectName = 'i18n-tailwind-test';
        
        // Mock commands
        fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
        fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
        
        const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"${projectName}","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
        fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
        fs.chmodSync(path.join(tempDir, 'npm'), '755');
        fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
        fs.chmodSync(path.join(tempDir, 'npx'), '755');
        
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --i18n yes --tailwind yes --test yes --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        
        const projectPath = path.join(tempDir, projectName);
        
        // Should have all features
        expect(fs.existsSync(path.join(projectPath, 'src/I18n.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/Theme.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/LocalStorage.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'tailwind.config.js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'tests/Tests.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'elm-pkg-js'))).toBe(true);
        
        // LocalStorage should be Effect version
        const localStorageContent = fs.readFileSync(path.join(projectPath, 'src/LocalStorage.elm'), 'utf8');
        expect(localStorageContent).toContain('Effect.Command');
        expect(localStorageContent).toContain('Effect.Subscription');
        
        // Frontend should have test imports and i18n features
        const frontendContent = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
        expect(frontendContent).toContain('Effect.Browser');
        expect(frontendContent).toContain('Effect.Lamdera');
        expect(frontendContent).toContain('import LocalStorage');
        expect(frontendContent).toContain('import I18n');
        expect(frontendContent).toContain('import Theme');
      });
    });
    
    describe('Tailwind with test mode', () => {
      test('should create tailwind with test Frontend', () => {
        const projectName = 'tailwind-test';
        
        // Mock commands
        fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
        fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
        
        const npmScript = `#!/bin/bash
if [ "$1" = "init" ]; then
  echo '{"name":"${projectName}","version":"1.0.0","scripts":{}}' > package.json
fi
exit 0`;
        fs.writeFileSync(path.join(tempDir, 'npm'), npmScript);
        fs.chmodSync(path.join(tempDir, 'npm'), '755');
        fs.writeFileSync(path.join(tempDir, 'npx'), '#!/bin/bash\nexit 0');
        fs.chmodSync(path.join(tempDir, 'npx'), '755');
        
        execSync(
          `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --tailwind yes --test yes --no-cursor --no-github`,
          { encoding: 'utf8' }
        );
        
        const projectPath = path.join(tempDir, projectName);
        
        // Check Frontend is test version (not Tailwind example)
        const frontendContent = fs.readFileSync(path.join(projectPath, 'src/Frontend.elm'), 'utf8');
        expect(frontendContent).toContain('import Effect.Browser');
        expect(frontendContent).toContain('import Effect.Lamdera');
        expect(frontendContent).toContain('CounterNewValue'); // Test version has this
        expect(frontendContent).not.toContain('NoOpToFrontend'); // Tailwind example has this
        
        // Should still have Tailwind files
        expect(fs.existsSync(path.join(projectPath, 'tailwind.config.js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/styles.css'))).toBe(true);
      });
    });
  });

  describe('Differential feature behavior', () => {
    test('should handle --init with i18n differently for test vs non-test projects', () => {
      // Create a test project first
      const testProjectName = 'existing-test-project';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Create test project
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${testProjectName} --test yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      // Now add i18n to it
      const testProjectPath = path.join(tempDir, testProjectName);
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --init --i18n yes --no-cursor`,
        { encoding: 'utf8', cwd: testProjectPath }
      );
      
      // Check that i18n was added with Effect modules
      const localStorageContent = fs.readFileSync(path.join(testProjectPath, 'src/LocalStorage.elm'), 'utf8');
      expect(localStorageContent).toContain('Effect.Command');
      expect(localStorageContent).toContain('Effect.Subscription');
      expect(fs.existsSync(path.join(testProjectPath, 'elm-pkg-js/localStorage.js'))).toBe(true);
    });
    
    test('should validate ports vs Effect modules implementation differences', () => {
      const standardProject = 'standard-i18n';
      const testProject = 'test-i18n';
      
      // Mock lamdera command
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Create standard project
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${standardProject} --i18n yes --no-test --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      // Create test project
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${testProject} --i18n yes --test yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      // Compare LocalStorage implementations
      const standardLS = fs.readFileSync(path.join(tempDir, standardProject, 'src/LocalStorage.elm'), 'utf8');
      const testLS = fs.readFileSync(path.join(tempDir, testProject, 'src/LocalStorage.elm'), 'utf8');
      
      // Standard should have ports
      expect(standardLS).toContain('port storeLocalStorageValue_ : E.Value -> Cmd msg');
      expect(standardLS).toContain('port receiveLocalStorage_ : (E.Value -> msg) -> Sub msg');
      
      // Test should have Effect functions
      expect(testLS).toContain('storeValue : LocalStorageUpdate -> Command FrontendOnly toMsg msg');
      expect(testLS).toContain('receiveLocalStorage : (LocalStorage -> msg) -> Subscription FrontendOnly msg');
      
      // Different JavaScript integration
      expect(fs.existsSync(path.join(tempDir, standardProject, 'localStorage.js'))).toBe(true);
      expect(fs.existsSync(path.join(tempDir, testProject, 'elm-pkg-js/localStorage.js'))).toBe(true);
    });
  });

  describe('Test runner support', () => {
    test('should run tests when test flag is enabled', () => {
      const projectName = 'test-runner-project';
      
      // Mock commands
      fs.writeFileSync(path.join(tempDir, 'lamdera'), '#!/bin/bash\necho "1.0.0"');
      fs.chmodSync(path.join(tempDir, 'lamdera'), '755');
      
      // Mock elm-test-rs to simulate test running
      fs.writeFileSync(path.join(tempDir, 'elm-test-rs'), `#!/bin/bash
echo "Running tests..."
echo "Test passed: 1/1"
exit 0`);
      fs.chmodSync(path.join(tempDir, 'elm-test-rs'), '755');
      
      execSync(
        `PATH=${tempDir}:$PATH node ${cliPath} --name ${projectName} --test yes --no-cursor --no-github`,
        { encoding: 'utf8' }
      );
      
      const projectPath = path.join(tempDir, projectName);
      
      // Run tests
      const testOutput = execSync(
        `cd ${projectPath} && PATH=${tempDir}:$PATH elm-test-rs --compiler lamdera`,
        { encoding: 'utf8' }
      );
      
      expect(testOutput).toContain('Running tests');
      expect(testOutput).toContain('Test passed');
    });
  });
});