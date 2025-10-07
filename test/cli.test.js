const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Helper to run CLI commands
function runCLI(args) {
  const cli = path.join(__dirname, '..', 'index.js');
  return execSync(`node "${cli}" ${args}`, {
    encoding: 'utf8',
    stdio: ['pipe', 'pipe', 'pipe']
  }).trim();
}

// Helper to create temp directory
function createTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'create-lamdera-app-test-'));
}

// Helper to cleanup temp directory
function cleanupTempDir(dir) {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

describe('create-lamdera-app CLI', () => {
  describe('Basic CLI functionality', () => {
    test('should display version', () => {
      const output = runCLI('--version');
      expect(output).toMatch(/\d+\.\d+\.\d+/);
    });

    test('should display help', () => {
      const output = runCLI('--help');
      expect(output).toContain('Create Lamdera App');
      expect(output).toContain('Usage:');
      expect(output).toContain('--name');
      expect(output).toContain('--github');
      expect(output).not.toContain('--tailwind'); // Old flag should not exist
      expect(output).not.toContain('--test'); // Old flag should not exist
      expect(output).not.toContain('--i18n'); // Old flag should not exist
    });
  });

  describe('Project creation with boilerplate', () => {
    let tempDir;
    let projectName;

    beforeEach(() => {
      tempDir = createTempDir();
      projectName = 'test-project';
    });

    afterEach(() => {
      cleanupTempDir(tempDir);
    });

    test('should create project with boilerplate', () => {
      const originalDir = process.cwd();
      process.chdir(tempDir);

      try {
        runCLI(`--name ${projectName} --no-github --skip-install`);

        const projectPath = path.join(tempDir, projectName);

        // Check essential files exist
        expect(fs.existsSync(path.join(projectPath, 'elm.json'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'package.json'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'tailwind.config.js'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/Frontend.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/Backend.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/Types.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/I18n.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/Theme.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/LocalStorage.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'src/Auth.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, 'tests/Tests.elm'))).toBe(true);
        expect(fs.existsSync(path.join(projectPath, '.githooks/pre-commit'))).toBe(true);
      } finally {
        process.chdir(originalDir);
      }
    }, 30000);

    test('should have config panel code in Frontend.elm', () => {
      const originalDir = process.cwd();
      process.chdir(tempDir);

      try {
        runCLI(`--name ${projectName} --no-github --skip-install`);

        const frontendPath = path.join(tempDir, projectName, 'src/Frontend.elm');
        const frontendContent = fs.readFileSync(frontendPath, 'utf8');

        // Check for config panel code
        expect(frontendContent).toContain('configPanelOpen');
        expect(frontendContent).toContain('maintenanceMode');
        expect(frontendContent).toContain('viewConfigPanel');
        expect(frontendContent).toContain('viewMaintenancePage');
        expect(frontendContent).toContain('CloseConfigPanel');
        expect(frontendContent).toContain('ToggleMaintenanceMode');
      } finally {
        process.chdir(originalDir);
      }
    }, 30000);

    test('should compile successfully', () => {
      const originalDir = process.cwd();
      process.chdir(tempDir);

      try {
        runCLI(`--name ${projectName} --no-github --skip-install`);

        const projectPath = path.join(tempDir, projectName);
        process.chdir(projectPath);

        // Try to compile
        const output = execSync('lamdera make src/Frontend.elm src/Backend.elm', {
          encoding: 'utf8',
          stdio: 'pipe'
        });

        expect(output).toContain('Success!');
      } finally {
        process.chdir(originalDir);
      }
    }, 60000);
  });

  describe('Error handling', () => {
    test('should validate project name is provided with --no-github', () => {
      // When using --no-github, a name should still be required
      // This test just verifies our CLI handles the flags correctly
      const help = runCLI('--help');
      expect(help).toContain('--name');
      expect(help).toContain('required in non-interactive mode');
    });

    test('should reject invalid project names', () => {
      expect(() => {
        runCLI('--name "project with spaces" --no-github');
      }).toThrow();
    });

    test('should handle duplicate project names', () => {
      const tempDir = createTempDir();
      const originalDir = process.cwd();
      process.chdir(tempDir);

      try {
        const projectName = 'duplicate-project';
        
        // Create first project
        runCLI(`--name ${projectName} --no-github --skip-install`);
        
        // Try to create duplicate - should fail
        expect(() => {
          runCLI(`--name ${projectName} --no-github --skip-install`);
        }).toThrow();
      } finally {
        process.chdir(originalDir);
        cleanupTempDir(tempDir);
      }
    }, 60000);
  });

  describe('Package manager support', () => {
    let tempDir;

    beforeEach(() => {
      tempDir = createTempDir();
    });

    afterEach(() => {
      cleanupTempDir(tempDir);
    });

    test('should support npm package manager', () => {
      const originalDir = process.cwd();
      process.chdir(tempDir);

      try {
        runCLI('--name test-npm --no-github --skip-install --pm npm');

        const packageJson = JSON.parse(
          fs.readFileSync(path.join(tempDir, 'test-npm', 'package.json'), 'utf8')
        );

        expect(packageJson.scripts.start).toContain('npx');
      } finally {
        process.chdir(originalDir);
      }
    }, 30000);

    test('should support bun package manager', () => {
      const originalDir = process.cwd();
      process.chdir(tempDir);

      try {
        runCLI('--name test-bun --no-github --skip-install --bun');

        const packageJson = JSON.parse(
          fs.readFileSync(path.join(tempDir, 'test-bun', 'package.json'), 'utf8')
        );

        expect(packageJson.scripts.start).toContain('bunx');
      } finally {
        process.chdir(originalDir);
      }
    }, 30000);
  });
});
