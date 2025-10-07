# GitHub OAuth Setup Guide

This guide explains how to set up GitHub OAuth authentication for your Lamdera application.

## Prerequisites

- A GitHub account
- Your Lamdera application URL (for development: `http://localhost:8000`)

## Step 1: Create a GitHub OAuth App

**Note**: GitHub OAuth Apps cannot be created via CLI/API. They must be created through the web interface.

### Using the Web Interface

1. Open GitHub Developer Settings using the CLI:

   ```bash
   `gh browse --settings`
   ```

   Or go directly to [GitHub Developer Settings](https://github.com/settings/developers)

2. Click on "OAuth Apps" in the left sidebar
3. Click "New OAuth App"
4. Fill in the application details:

   - **Application name**: Your app name (e.g., "My Lamdera App")
   - **Homepage URL**: `http://localhost:8000` (for development) or your production URL
   - **Authorization callback URL**: `http://localhost:8000/login/OAuthGithub/callback` (for development) or `https://your-app.lamdera.app/login/OAuthGithub/callback` (for production)
   - **Application description**: Optional description of your app

5. Click "Register application"

### CLI Commands for Managing OAuth Apps

List your existing OAuth Apps:

```bash
# Unfortunately, there's no direct API to list OAuth apps
# You can view them at:
gh browse --web https://github.com/settings/developers
```

## Step 2: Get Your Client ID and Secret

After creating the app:

1. You'll see your **Client ID** on the app page
2. Click "Generate a new client secret" to create a **Client Secret**
3. **Important**: Copy the client secret immediately - you won't be able to see it again!

### Storing Credentials Securely

For development, you can use environment variables:

```bash
# Add to your .env file or shell profile
export GITHUB_CLIENT_ID="your-client-id"
export GITHUB_CLIENT_SECRET="your-client-secret"
```

## Step 3: Configure Your Lamdera Application

### For Development

Update `src/Env.elm` with your credentials:

```elm
githubAppClientId : String
githubAppClientId =
    "your-actual-client-id"  -- Replace with your GitHub OAuth App Client ID

githubAppClientSecret : String
githubAppClientSecret =
    "your-actual-client-secret"  -- Replace with your GitHub OAuth App Client Secret
```

### For Production

Set environment variables in your Lamdera dashboard:

1. Go to your [Lamdera Dashboard](https://dashboard.lamdera.app)
2. Navigate to your app's settings
3. Add environment variables:
   - `GITHUB_CLIENT_ID`: Your GitHub OAuth App Client ID
   - `GITHUB_CLIENT_SECRET`: Your GitHub OAuth App Client Secret

Then update `src/Env.elm` to use these environment variables:

```elm
githubAppClientId : String
githubAppClientId =
    Env.value "GITHUB_CLIENT_ID"
        |> Maybe.withDefault "development-client-id"

githubAppClientSecret : String
githubAppClientSecret =
    Env.value "GITHUB_CLIENT_SECRET"
        |> Maybe.withDefault "development-client-secret"
```

## Step 4: Test Your Setup

1. Run your Lamdera application: `bun start`, `npm start` or `./lamdera-dev-watch.sh`
2. Navigate to the login page
3. Click "Sign in with GitHub"
4. You should be redirected to GitHub to authorize the application
5. After authorization, you'll be redirected back to your app and logged in

## Troubleshooting

### "The redirect_uri MUST match the registered callback URL"

Make sure your callback URL in the GitHub OAuth App settings exactly matches what your app is using:

- For development: `http://localhost:8000/login/OAuthGithub/callback`
- For production: `https://your-app.lamdera.app/login/OAuthGithub/callback`

### "Bad credentials" error

Double-check that:

- Your client ID and secret are correctly copied
- There are no extra spaces or characters
- You're using the correct environment (development vs production credentials)

### User email is not returned

GitHub may not return the user's email if:

- The user has no public email set
- The user hasn't verified their email

The elm-auth library handles this by fetching the user's emails separately and selecting the primary verified email.

## Security Notes

1. **Never commit your client secret to version control**
2. Use environment variables for production deployments
3. Keep your development and production OAuth apps separate
4. Regularly rotate your client secrets in production

## Multiple Environments

It's recommended to create separate GitHub OAuth Apps for each environment:

- **Development**: `http://localhost:8000`
- **Staging**: `https://staging-your-app.lamdera.app`
- **Production**: `https://your-app.lamdera.app`

This allows you to test changes without affecting production users.

## Alternative: GitHub Apps (Programmable Creation)

If you need to create apps programmatically, consider using GitHub Apps instead of OAuth Apps:

```bash
# GitHub Apps can be created via API
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /app-manifests/{code}/conversions
```

GitHub Apps offer several advantages:

- Can be created programmatically via API
- Support multiple callback URLs
- Use fine-grained permissions
- Can act on behalf of users or as themselves
- Use short-lived tokens for better security

However, integrating GitHub Apps requires different authentication flows than OAuth Apps.
