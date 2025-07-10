# OAuth Development Guide for Lamdera

## Known Issues in Development Mode

### Backend State Loss During OAuth Flow

In Lamdera development mode, the backend frequently restarts when files are modified. This causes the `pendingAuths` dictionary to be cleared, breaking the OAuth flow. You'll see errors like:
- "Couldn't validate auth, please login again"
- "bad_verification_code" (GitHub)
- Empty `pendingAuths` dictionary in logs

### Solutions

#### 1. Stop File Watchers During Testing
Stop any file watchers (like `lamdera-dev-watch.sh`) while testing OAuth:
```bash
# Kill the watcher process
pkill -f lamdera-dev-watch

# Start Lamdera without file watching
lamdera live
```

#### 2. Test in Production
OAuth flows work reliably in production where backend state persists:
```bash
lamdera deploy
```

#### 3. Use Mock Authentication in Development
For development, use the email/password mock authentication instead of OAuth. OAuth can be tested in staging/production environments.

#### 4. Quick Testing Strategy
1. Make all your code changes first
2. Stop file watchers
3. Run `lamdera live` 
4. Test OAuth flow without modifying any files
5. Resume development after testing

## Debugging Tips

### Enable Debug Logging
The OAuth module includes debug logging. Look for:
- "OAuth initiate - sessionId"
- "OAuth initiate - state"
- "OAuth callback - sessionId"
- "OAuth callback - pendingAuths"

### Common Error Patterns

1. **Empty pendingAuths on callback**: Backend restarted between initiation and callback
2. **Multiple "Restored BackendModel" messages**: Backend is restarting frequently
3. **"bad_verification_code"**: OAuth code expired or already used (often due to multiple attempts)

### Testing Checklist

Before testing OAuth in development:
- [ ] All code changes are complete
- [ ] File watchers are stopped
- [ ] Browser cache/cookies cleared (if testing multiple times)
- [ ] Using fresh OAuth authorization (not reusing old URLs)

## Alternative: Persistent Storage for Pending Auths

If you need OAuth to work reliably in development, consider modifying the backend to persist pending auths to a file or external storage. However, this is typically not necessary as production environments handle this correctly.

## Configuration for Development

The `Auth.elm` module now uses `Env.isDevelopment` to enable a 3-second delay in development mode. This helps ensure the backend state is persisted before OAuth redirects. Make sure to:

1. Set `isDevelopment = True` in `Env.elm` for development
2. Set `isDevelopment = False` in `Env.elm` before deploying to production

This delay gives Lamdera's development server time to persist the backend state (which happens every 2 seconds) before the OAuth redirect occurs.