# 🚀 Deploying to Darklang - Step by Step

Let's get your zero-dependency create-lamdera-app live in the next 30 minutes!

## Step 1: Create Your Darklang Account (2 minutes)

1. Go to **https://darklang.com**
2. Click **"Sign Up"** or **"Get Started"**
3. Create your account (free tier is perfect for this)

## Step 2: Create a New Canvas (1 minute)

1. Once logged in, click **"Create a new Canvas"**
2. Name it: `create-lamdera-app` (or your preferred name)
3. Your canvas URL will be: `https://create-lamdera-app-[username].builtwithdark.com`

## Step 3: Deploy the Code (20 minutes)

You'll need to copy each `.dark` file into your Darklang canvas. Here's the order:

### 3.1 Deploy main.dark (Core API)

1. In your Darklang canvas, create a new HTTP handler
2. Copy ALL content from `main.dark`
3. The handlers will auto-create as you paste

**Endpoints in main.dark:**
- `[/ GET]` - Welcome page
- `[/health GET]` - Health check
- `[/project/create-pure POST]` - Main project creation
- `[/templates/list GET]` - List templates

### 3.2 Deploy cli.dark (Web Interface)

1. Copy ALL content from `cli.dark`
2. This creates the web-based CLI

**Endpoints in cli.dark:**
- `[/cli GET]` - Interactive web terminal
- `[/create GET]` - Quick create with URL params
- `[/cli/create POST]` - CLI API endpoint
- `[/cli/list GET]` - List templates via CLI
- `[/cli/help GET]` - CLI help
- `[/compare GET]` - Compare implementations

### 3.3 Deploy dev-server.dark (Development Tools)

1. Copy ALL content from `dev-server.dark`
2. This creates the cloud development environment

**Endpoints in dev-server.dark:**
- `[/dev/:projectId GET]` - Development server
- `[/dev/:projectId/editor GET]` - Code editor
- `[/dev/:projectId/debug-toggle POST]` - Debug toggle
- `[/dev/:projectId/css POST]` - CSS processor
- `[/dev/:projectId/tests GET]` - Test runner
- `[/dev/:projectId/file/:filename GET]` - Read files
- `[/dev/:projectId/file/:filename POST]` - Save files

### 3.4 Deploy test-runner.dark (Testing Framework)

1. Copy ALL content from `test-runner.dark`
2. This creates the test infrastructure

**Endpoints in test-runner.dark:**
- `[/test/interactive GET]` - Interactive test UI
- `[/test/all-combinations POST]` - Run all tests
- `[/test/run-single POST]` - Run single test
- `[/test/unit GET]` - Unit tests
- `[/test/status GET]` - Test status

## Step 4: Set Up Data Storage (3 minutes)

In Darklang, you'll need to create a datastore for projects:

1. In your canvas, create a new Datastore
2. Name: `projects` 
3. Schema:
   ```
   {
     id: String,
     name: String, 
     files: Dict<String, String>,
     config: ProjectConfig,
     lastModified: Date,
     isActive: Bool
   }
   ```

## Step 5: Test Your Deployment (4 minutes)

### 5.1 Test Health Check
```bash
curl https://create-lamdera-app-[username].builtwithdark.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "create-lamdera-app-pure-darklang",
  "version": "2.0.0",
  "dependencies": 0
}
```

### 5.2 Test Web CLI
Open in browser:
```
https://create-lamdera-app-[username].builtwithdark.com/cli
```

You should see the interactive terminal!

### 5.3 Test Project Creation
```bash
curl "https://create-lamdera-app-[username].builtwithdark.com/create?name=test-project"
```

### 5.4 Test the Test Runner
```
https://create-lamdera-app-[username].builtwithdark.com/test/interactive
```

## Step 6: Custom Domain (Optional)

1. In Darklang, go to Settings → Custom Domains
2. Add your domain (e.g., `create-lamdera-app.com`)
3. Update DNS records as instructed

## 🎯 Quick Deployment Checklist

- [ ] Created Darklang account
- [ ] Created new canvas
- [ ] Copied main.dark
- [ ] Copied cli.dark
- [ ] Copied dev-server.dark
- [ ] Copied test-runner.dark
- [ ] Created projects datastore
- [ ] Tested health endpoint
- [ ] Tested web CLI
- [ ] Tested project creation
- [ ] All tests passing

## 🚨 Common Issues & Solutions

### "Function not found"
- Make sure you copied ALL content from each .dark file
- Check that function names match exactly

### "Datastore not found"
- Create the `projects` datastore in your canvas
- Also create `dev_projects` for the dev server

### "CORS issues"
- Darklang handles CORS automatically
- If issues persist, check browser console

## 🎉 Success!

Once deployed, you can share these URLs:

**For Users:**
- Web CLI: `https://[your-canvas].builtwithdark.com/cli`
- Quick Create: `https://[your-canvas].builtwithdark.com/create?name=my-app`

**For Developers:**
- API Docs: `https://[your-canvas].builtwithdark.com/health`
- Test Suite: `https://[your-canvas].builtwithdark.com/test/interactive`

## 📢 Share Your Success!

Once live, share on social media:
```
🚀 Just deployed create-lamdera-app with ZERO dependencies using @darklang!

No npm ❌
No node ❌  
No python ❌
Just pure cloud ✅

Try it: https://[your-canvas].builtwithdark.com/cli

#Lamdera #Darklang #ZeroDependencies
```

---

**Need help?** The Darklang Discord is super helpful: https://darklang.com/discord