module Env exposing (..)

-- The Env.elm file is for per-environment configuration.
-- See https://dashboard.lamdera.app/docs/environment for more info.
-- Google OAuth Configuration
-- To set up real OAuth:
-- 1. Go to https://console.cloud.google.com/
-- 2. Create OAuth 2.0 credentials
-- 3. Set environment variables in production:
-- https://dashboard.lamdera.app/app/REPLACE_WITH_YOUR_PROJECT/settings


googleAppClientId : String
googleAppClientId =
    "YOUR_GOOGLE_CLIENT_ID_HERE"



-- Replace with actual client ID


googleAppClientSecret : String
googleAppClientSecret =
    "YOUR_GOOGLE_CLIENT_SECRET_HERE"



-- Replace with actual client secret
-- GitHub OAuth Configuration
-- To set up real OAuth:
-- 1. Go to https://github.com/settings/developers
-- 2. Create a new OAuth App
-- 3. Set authorization callback URL to: http://localhost:8000/login/OAuthGithub/callback (or your production URL)
-- 4. Set environment variables in production:
-- https://dashboard.lamdera.app/app/REPLACE_WITH_YOUR_PROJECT/settings


githubAppClientId : String
githubAppClientId =
    "YOUR_GITHUB_CLIENT_ID_HERE"



-- Replace with actual client ID


githubAppClientSecret : String
githubAppClientSecret =
    "YOUR_GITHUB_CLIENT_SECRET_HERE"



-- Replace with actual client secret
-- Admin Configuration
-- Set in production with: lamdera env:set ADMIN_PASSWORD your-secure-password


adminPassword : String
adminPassword =
    "change-this-admin-password"



-- Development mode flag
-- Set to False when deploying to production


environment : String
environment =
    "development"



-- Resend Email Configuration
-- To set up Resend:
-- 1. Sign up at https://resend.com
-- 2. Get your API key from the dashboard
-- 3. Add your domain and verify it
-- 4. Set environment variables in production in lamdera.com


resendApiKey : String
resendApiKey =
    "YOUR_RESEND_API_KEY_HERE"


resendFromEmail : String
resendFromEmail =
    "Your App <noreply@yourdomain.com>"