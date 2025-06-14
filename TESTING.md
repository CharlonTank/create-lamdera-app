# Testing the Pure Darklang Implementation

This guide explains how to test that the Pure Darklang implementation works correctly.

## 🚀 Quick Start Testing

### Step 1: Deploy to Darklang

1. **Create Darklang Canvases**
   ```bash
   # You need 3-4 Darklang canvases (or one canvas with all code)
   # Go to https://darklang.com and create a new canvas
   ```

2. **Upload the Dark Files**
   - Copy contents of `main.dark` to your canvas
   - Copy contents of `cli.dark` to your canvas  
   - Copy contents of `dev-server.dark` to your canvas
   - Copy contents of `test-runner.dark` to your canvas

3. **Get Your Canvas URL**
   ```
   https://[your-canvas-name].builtwithdark.com
   ```

### Step 2: Test the Web CLI

```bash
# Open in browser
open https://[your-canvas-name].builtwithdark.com/cli

# Or use curl
curl https://[your-canvas-name].builtwithdark.com/cli
```

**Expected Result:** You should see an interactive web terminal with commands like:
- `create my-app`
- `create my-app --tailwind --test --i18n`
- `create --interactive`
- `list`
- `help`

### Step 3: Test Direct API Creation

```bash
# Basic project
curl "https://[your-canvas-name].builtwithdark.com/create?name=test-basic"

# With features
curl "https://[your-canvas-name].builtwithdark.com/create?name=test-full&tailwind=true&test=true&i18n=true"

# JSON API
curl -X POST https://[your-canvas-name].builtwithdark.com/project/create-pure \
  -H "Content-Type: application/json" \
  -d '{"config": {"name": "test-json", "useTailwind": true}}'
```

**Expected Result:** JSON response with:
- Project files array
- Development server URL
- Instructions

### Step 4: Test the Development Server

After creating a project, you'll get a dev server URL like:
```
https://[your-canvas-name].builtwithdark.com/dev/[project-id]
```

Visit this URL to see:
- Live app preview
- Code editor button
- Test runner button
- CSS processor button
- File manager button

### Step 5: Test the Test Runner

```bash
# Interactive test UI
open https://[your-canvas-name].builtwithdark.com/test/interactive

# Run all combination tests
curl -X POST https://[your-canvas-name].builtwithdark.com/test/all-combinations

# Run unit tests
curl https://[your-canvas-name].builtwithdark.com/test/unit
```

**Expected Results:**
- Interactive UI shows 8 test combinations
- All tests should pass
- Unit tests verify core functionality

## 📋 Comprehensive Test Checklist

### 1. Project Generation Tests

- [ ] **Basic project** creates with minimal files
- [ ] **Tailwind project** includes CSS utilities and config
- [ ] **Test project** uses Effect pattern instead of Cmd
- [ ] **i18n project** includes Theme, I18n, LocalStorage modules
- [ ] **Combined features** work together (e.g., Tailwind + i18n)
- [ ] **Project names** are validated (alphanumeric + hyphens)

### 2. Web CLI Tests

- [ ] **Interactive mode** prompts for options
- [ ] **Command parsing** works for all flags
- [ ] **Help command** shows documentation
- [ ] **List command** shows available templates
- [ ] **Clear command** clears terminal
- [ ] **Status command** shows API health

### 3. Development Server Tests

- [ ] **Live preview** shows the app
- [ ] **Hot reload** works via WebSocket
- [ ] **Code editor** loads and saves files
- [ ] **Debug toggle** comments/uncomments Debug.log
- [ ] **CSS processor** generates utilities
- [ ] **File manager** shows project structure

### 4. Test Framework Tests

- [ ] **Unit tests** run and report results
- [ ] **Integration tests** create all combinations
- [ ] **Interactive tests** allow single test runs
- [ ] **Test results** show pass/fail status

## 🧪 Local Testing (Before Deploying)

While you can't run Darklang locally, you can verify the code:

### 1. Syntax Validation

```bash
# Check that all .dark files are valid
# Look for balanced braces, quotes, parentheses
grep -n "^\[" *.dark  # Should show all endpoints
```

### 2. Endpoint Coverage

Verify all legacy functionality has endpoints:

| Legacy Feature | Darklang Endpoint |
|----------------|-------------------|
| CLI binary | `/cli` (web interface) |
| Project creation | `/project/create-pure` |
| Dev server | `/dev/:projectId` |
| Debug toggle | `/dev/:projectId/debug-toggle` |
| CSS processing | `/dev/:projectId/css` |
| Test runner | `/test/*` endpoints |
| File editing | `/dev/:projectId/file/:filename` |

### 3. Feature Parity Check

```bash
# Verify all features are mentioned in the code
grep -i "tailwind" main.dark    # CSS generation
grep -i "test" main.dark         # Effect pattern
grep -i "i18n" main.dark         # Internationalization
grep -i "cursor" main.dark       # Cursor support
```

## 🔍 Debugging Common Issues

### Issue: "Endpoint not found"
**Solution:** Ensure all endpoints are properly formatted:
```darklang
[/endpoint/path METHOD]
let handlerName (request) =
  // handler code
```

### Issue: "Project files not generated"
**Solution:** Check the `createPureDarklangProject` function in `main.dark`

### Issue: "Test failures"
**Solution:** Run individual tests via `/test/run-single` to isolate issues

### Issue: "Dev server not loading"
**Solution:** Verify project was saved with `saveProject` function

## 📊 Performance Testing

Test that the cloud implementation is fast:

```bash
# Time project creation
time curl "https://[your-canvas-name].builtwithdark.com/create?name=perf-test"

# Expected: < 1 second

# Time test suite
time curl -X POST https://[your-canvas-name].builtwithdark.com/test/all-combinations

# Expected: < 5 seconds for all 8 combinations
```

## ✅ Success Criteria

The Pure Darklang implementation is working correctly when:

1. **All project types can be created** via web CLI or API
2. **Generated projects contain all expected files**
3. **Development server provides all tools** (editor, tests, CSS)
4. **All tests pass** (unit and integration)
5. **Zero local dependencies required** - everything works in browser
6. **Performance is acceptable** (< 1s for project creation)

## 🚀 Next Steps

Once testing is complete:

1. **Deploy to production Darklang canvas**
2. **Update documentation** with production URLs
3. **Share with users** - no installation needed!
4. **Monitor usage** via Darklang analytics

Remember: Users need ZERO setup - just a web browser!