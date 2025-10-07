# Google One Tap FedCM Migration Guide

## Overview

Google is migrating One Tap authentication to use the FedCM (Federated Credential Management) API. This is a new browser API that provides better privacy and security for federated authentication.

## Changes Made

### 1. Updated Notification Handling

The old deprecated methods have been replaced with FedCM-compatible methods:

**Old (Deprecated):**

```javascript
notification.isNotDisplayed();
notification.isSkippedMoment();
notification.getNotDisplayedReason();
```

**New (FedCM-Compatible):**

```javascript
notification.getMomentType(); // Returns: 'display', 'skipped', or 'dismissed'
notification.getNotDisplayedReason(); // Still available but accessed differently
```

### 2. Enabled FedCM

Updated the initialization to explicitly enable FedCM:

```javascript
google.accounts.id.initialize({
  // ... other options
  use_fedcm_for_prompt: true, // Enable FedCM API
});
```

### 3. Backward Compatibility

The implementation includes fallback logic for browsers that don't yet support the new API:

- Checks for the existence of new methods before using them
- Falls back to old methods if new ones aren't available
- This ensures the code works during the transition period

## Benefits of FedCM

1. **Better Privacy**: Users have more control over their identity information
2. **Browser Integration**: Native browser UI for credential management
3. **Improved Security**: Protection against tracking and fingerprinting
4. **Future-Proof**: Aligns with web standards and browser evolution

## Testing

To test FedCM integration:

1. Use a modern Chrome browser (version 108+)
2. Enable FedCM flag if needed: `chrome://flags/#fedcm`
3. Test on both localhost and production domains
4. Verify that One Tap still works as expected

## Troubleshooting

If One Tap stops working after migration:

1. Check browser console for FedCM-related errors
2. Ensure your domain is properly configured in Google Cloud Console
3. Verify that FedCM is supported in the user's browser
4. Check if the user has disabled third-party cookies (FedCM helps with this)

## Resources

- [Google's FedCM Migration Guide](https://developers.google.com/identity/gsi/web/guides/fedcm-migration)
- [FedCM Specification](https://fedidcg.github.io/FedCM/)
- [Chrome FedCM Documentation](https://developer.chrome.com/docs/privacy-sandbox/fedcm/)
