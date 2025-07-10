# Google One Tap Setup Guide

## Development Setup (localhost)

The FedCM error you're seeing is common when developing locally. Here's how to fix it:

### 1. Configure Google Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Navigate to "APIs & Services" > "Credentials"
4. Click on your OAuth 2.0 Client ID
5. Add these to "Authorized JavaScript origins":
   - `http://localhost` (important - without port!)
   - `http://localhost:8000`

### 2. Common Issues and Solutions

#### FedCM Error

The error "FedCM get() rejects with IdentityCredentialError" occurs when:

- Browser blocks third-party cookies (check browser settings)
- Domain isn't properly configured in Google Console
- User hasn't signed in with Google before on this domain

**Solution**: The code now automatically disables FedCM on localhost to avoid this error.

#### One Tap Not Showing

If One Tap doesn't appear:

1. Check browser console for specific error messages
2. Ensure you're not in Incognito/Private mode
3. Clear cookies for accounts.google.com and try again
4. Check if you've dismissed One Tap too many times (it gets suppressed)

### 3. Testing Google One Tap

1. Make sure you're signed into Google in your browser
2. Visit your app at `http://localhost:8000`
3. If One Tap doesn't show automatically, use the "Sign in with Google" button
4. After first sign-in, One Tap should work on subsequent visits

### 4. Production Setup

For production deployment on Lamdera:

1. Add your production domain to Google Console authorized origins
2. Update `Env.elm` with production credentials
3. One Tap will work automatically with proper domain configuration

## Troubleshooting

- **Clear browser data**: If One Tap was dismissed multiple times, clear cookies for your domain
- **Check console**: Browser console will show specific error reasons
- **Use fallback**: The regular "Sign in with Google" button always works as fallback
- **Test in regular window**: Incognito/Private mode can interfere with One Tap
