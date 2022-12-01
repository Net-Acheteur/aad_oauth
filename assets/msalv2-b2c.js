// Needs to be a var at the top level to get hoisted to global scope.
// https://stackoverflow.com/questions/28776079/do-let-statements-create-properties-on-the-global-object/28776236#28776236
var aadOauth = (function () {
  let myMSALObj = null;
  let authResult = null;
  let redirectHandlerTask = null;

  const tokenRequest = {
    scopes: 'openid profile email',
    // Hardcoded?
    prompt: null,
  };

  // Initialise the myMSALObj for the given client, authority and scope
  function init(config) {
    // TODO: Add support for other MSAL / B2C configuration
    var msalConfig = {
      auth: {
        clientId: config.clientId,
        authority: 'https://' + config.tenant + '.b2clogin.com/' + config.tenant + '.onmicrosoft.com/b2c_1_signin',
        redirectUri: config.redirectUri,
        responseMode: 'form_post',
        scope: tokenRequest.scopes,
        responseType: 'code id_token',
        knownAuthorities: [ 'https://' + config.tenant + '.b2clogin.com/' ],
      },
      cache: {
        cacheLocation: "localStorage",
        storeAuthStateInCookie: false,
      },
    };

    if (typeof config.scope === "string") {
      tokenRequest.scopes = config.scope.split(" ");
    } else {
      tokenRequest.scopes = config.scope;
    }

    tokenRequest.prompt = config.prompt;

    myMSALObj = new msal.PublicClientApplication(msalConfig);
    // Register Callbacks for Redirect flow and record the task so we
    // can await its completion in the login API

    redirectHandlerTask = myMSALObj.handleRedirectPromise();
  }

  /// Authorize user via refresh token or web gui if necessary.
  ///
  /// Setting [refreshIfAvailable] to [true] should attempt to re-authenticate
  /// with the existing refresh token, if any, even though the access token may
  /// still be valid; however MSAL doesn't support this. Therefore it will have
  /// the same impact as when it is set to [false].
  /// [useRedirect] uses the MSAL redirection based token acquisition instead of
  /// a popup window. This is the only way that iOS based devices will acquire
  /// a token using MSAL when the application is installed to the home screen.
  /// This is because the popup window operates outside the sandbox of the PWA and
  /// won't share cookies or local storage with the PWA sandbox. Redirect flow works
  /// around this issue by having the MSAL authentication take place directly within
  /// the PWA sandbox browser.
  /// The token is requested using acquireTokenSilent, which will refresh the token
  /// if it has nearly expired. If this fails for any reason, it will then move on
  /// to attempt to refresh the token using an interactive login.

  async function login(refreshIfAvailable, useRedirect, onSuccess, onError) {
    try {
      // The redirect handler task will complete with auth results if we
      // were redirected from AAD. If not, it will complete with null
      // We must wait for it to complete before we allow the login to
      // attempt to acquire a token silently, and then progress to interactive
      // login (if silent acquisition fails).
      let result = await redirectHandlerTask;
      if (result !== null) {
        authResult = result;
      }
    }
    catch (error) {
      authResultError = error;
      onError(authResultError);
      return;
    }

    // Try to sign in silently, assuming we have already signed in and have
    // a cached access token
    const account = getAccount();
    if (account !== null) {
      try {
        // Silent acquisition only works if we the access token is either
        // within its lifetime, or the refresh token can successfully be
        // used to refresh it. This will throw if the access token can't
        // be acquired.
        const silentAuthResult = await myMSALObj.acquireTokenSilent({
          scopes: tokenRequest.scopes,
          prompt: "none",
          account: account
        });

        authResult = silentAuthResult;

        // Skip interactive login
        onSuccess(authResult.accessToken ?? null);

        return;
      } catch (error) {
        // Swallow errors and continue to interactive login
        console.log(error.message)
      }
    }

    if (useRedirect) {
      myMSALObj.acquireTokenRedirect({
        scopes: tokenRequest.scopes,
        prompt: tokenRequest.prompt,
        account: account
      });
    } else {
      // Sign in with popup
      try {
        const interactiveAuthResult = await myMSALObj.loginPopup({
          scopes: tokenRequest.scopes,
          prompt: tokenRequest.prompt,
          account: account
        });

        authResult = interactiveAuthResult;

        onSuccess(authResult.accessToken ?? null);
      } catch (error) {
        // rethrow
        console.warn(error.message);
        onError(error);
      }
    }
  }

  function getAccount() {
    // If we have recently authenticated, we use the auth'd account;
    // otherwise we fallback to using MSAL APIs to find cached auth
    // accounts in browser storage.
    if (authResult !== null && authResult.account !== null) {
      return authResult.account
    }

    const currentAccounts = myMSALObj.getAllAccounts();

    if (currentAccounts === null || currentAccounts.length === 0) {
      return null;
    } else {
      return currentAccounts[0];
    }
  }

  function logout(onSuccess, onError) {
    const account = getAccount();

    if (!account) {
      onSuccess();
      return;
    }

    authResult = null;
    authResultError = null;
    tokenRequest.scopes = null;
    myMSALObj
      .logout({ account: account })
      .then((_) => onSuccess())
      .catch(onError);
  }

  function getAccessToken() {
    return authResult ? authResult.accessToken : null;
  }

  function getIdToken() {
    return authResult ? authResult.idToken : null;
  }

  async function recoverAccount(onSuccess, onError) {
    const account = getAccount();
    if (account !== null) {
      try {
        const silentAuthResult = await myMSALObj.acquireTokenSilent({
          scopes: tokenRequest.scopes,
          prompt: "none",
          account: account
        });

        authResult = silentAuthResult;
        onSuccess();
      } catch (error) {
        console.log(error.message);
        onError();
      }
    }else {
      onError();
    }
  }

  return {
    init: init,
    login: login,
    logout: logout,
    getIdToken: getIdToken,
    getAccessToken: getAccessToken,
    recoverAccount: recoverAccount
  };
})();