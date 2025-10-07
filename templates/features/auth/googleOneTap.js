// Google One Tap authentication
// This file handles the Google One Tap sign-in flow

exports.init = async function (app) {
  let clientId = null;

  // Function to setup Google One Tap once the library is loaded
  function setupGoogleOneTap() {
    if (!clientId) {
      console.error('Google One Tap: Client ID not set');
      return;
    }

    if (typeof google === 'undefined' || !google.accounts) {
      console.error('Google Identity Services library not loaded');
      return;
    }

    // Check if we're on localhost for development
    const isLocalhost =
      window.location.hostname === 'localhost' ||
      window.location.hostname === '127.0.0.1' ||
      window.location.hostname.includes('localhost');

    // Initialize Google One Tap
    google.accounts.id.initialize({
      client_id: clientId,
      callback: handleCredentialResponse,
      auto_select: !isLocalhost, // Disable auto-select on localhost to avoid errors
      cancel_on_tap_outside: false, // Don't cancel if user clicks outside
      itp_support: true, // Enable Intelligent Tracking Prevention support
      use_fedcm_for_prompt: true, // Enable FedCM (Federated Credential Management) API
    });

    // Display the One Tap prompt
    try {
      google.accounts.id.prompt((notification) => {
        // Using the new FedCM-compatible approach
        // Check if notification has getMomentType (newer API)
        if (notification.getMomentType) {
          const momentType = notification.getMomentType();

          if (momentType === 'display') {
            console.log('One Tap displayed');
            if (app.ports.googleOneTapStatus) {
              app.ports.googleOneTapStatus.send({
                status: 'displayed',
              });
            }
          } else if (momentType === 'skipped') {
            console.log('One Tap skipped');
            if (app.ports.googleOneTapStatus) {
              app.ports.googleOneTapStatus.send({
                status: 'skipped',
              });
            }
          } else if (momentType === 'dismissed') {
            console.log('One Tap dismissed');
            if (app.ports.googleOneTapStatus) {
              app.ports.googleOneTapStatus.send({
                status: 'dismissed',
              });
            }
          }

          // For not displayed, check if getNotDisplayedReason exists
          if (notification.getNotDisplayedReason) {
            const reason = notification.getNotDisplayedReason();
            if (reason) {
              console.log('One Tap not displayed:', reason);
              if (app.ports.googleOneTapStatus) {
                app.ports.googleOneTapStatus.send({
                  status: 'not_displayed',
                  reason: reason,
                });
              }
            }
          }
        } else {
          // Fallback for older API (will be deprecated)
          if (notification.isNotDisplayed && notification.isNotDisplayed()) {
            console.log('One Tap not displayed:', notification.getNotDisplayedReason());
            if (app.ports.googleOneTapStatus) {
              app.ports.googleOneTapStatus.send({
                status: 'not_displayed',
                reason: notification.getNotDisplayedReason(),
              });
            }
          } else if (notification.isSkippedMoment && notification.isSkippedMoment()) {
            console.log('One Tap skipped');
            if (app.ports.googleOneTapStatus) {
              app.ports.googleOneTapStatus.send({
                status: 'skipped',
              });
            }
          }
        }
      });
    } catch (error) {
      console.error('Google One Tap error:', error);
      if (app.ports.googleOneTapStatus) {
        app.ports.googleOneTapStatus.send({
          status: 'error',
          reason: error.message || 'Unknown error',
        });
      }
    }
  }

  function handleCredentialResponse(response) {
    // Send the ID token to Elm
    if (app.ports.googleOneTapResponse) {
      app.ports.googleOneTapResponse.send({
        credential: response.credential,
      });
    }
  }

  // Function to manually trigger sign in (for button fallback)
  function triggerGoogleSignIn() {
    if (typeof google !== 'undefined' && google.accounts) {
      google.accounts.id.prompt();
    }
  }

  // Function to sign out (disables auto-select for One Tap)
  function googleOneTapSignOut() {
    if (typeof google !== 'undefined' && google.accounts) {
      google.accounts.id.disableAutoSelect();
    }
  }

  // Listen for initialization command from Elm
  if (app.ports.initializeGoogleOneTap) {
    app.ports.initializeGoogleOneTap.subscribe(function (data) {
      clientId = data.clientId;

      // Wait for the Google Identity Services library to load
      if (typeof google !== 'undefined' && google.accounts) {
        setupGoogleOneTap();
      } else {
        // If the library isn't loaded yet, wait for it
        window.addEventListener('load', function () {
          setupGoogleOneTap();
        });
      }
    });
  }

  // Listen for manual trigger command
  if (app.ports.triggerGoogleOneTap) {
    app.ports.triggerGoogleOneTap.subscribe(function () {
      triggerGoogleSignIn();
    });
  }

  // Listen for sign out command
  if (app.ports.googleOneTapSignOut) {
    app.ports.googleOneTapSignOut.subscribe(function () {
      googleOneTapSignOut();
    });
  }
};
