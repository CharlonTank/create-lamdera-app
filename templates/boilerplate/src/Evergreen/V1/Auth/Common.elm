module Evergreen.V1.Auth.Common exposing (..)

import Effect.Lamdera
import Effect.Time
import Evergreen.V1.OAuth
import Evergreen.V1.OAuth.AuthorizationCode
import Url


type alias MethodId =
    String


type alias AuthCode =
    String


type alias UserInfo =
    { email : String
    , name : Maybe String
    , username : Maybe String
    , profilePicture : Maybe String
    }


type Error
    = ErrStateMismatch
    | ErrAuthorization Evergreen.V1.OAuth.AuthorizationCode.AuthorizationError
    | ErrAuthentication Evergreen.V1.OAuth.AuthorizationCode.AuthenticationError
    | ErrHTTPGetAccessToken
    | ErrHTTPGetUserInfo
    | ErrAuthString String


type Flow
    = Idle
    | Requested MethodId
    | Pending
    | Authorized AuthCode String
    | Authenticated Evergreen.V1.OAuth.Token
    | Done UserInfo
    | Errored Error


type alias PendingAuth =
    { created : Effect.Time.Posix
    , sessionId : Effect.Lamdera.SessionId
    , state : String
    }


type alias State =
    String


type ToBackend
    = AuthSigninInitiated
        { methodId : MethodId
        , baseUrl : Url.Url
        , username : Maybe String
        }
    | AuthCallbackReceived MethodId Url.Url AuthCode State
    | AuthRenewSessionRequested
    | AuthLogoutRequested
    | AuthGoogleOneTapTokenReceived MethodId String


type AuthChallengeReason
    = AuthSessionMissing
    | AuthSessionInvalid
    | AuthSessionExpired
    | AuthSessionLoggedOut


type ToFrontend
    = AuthInitiateSignin Url.Url
    | AuthError Error
    | AuthSessionChallenge AuthChallengeReason


type alias Token =
    { methodId : MethodId
    , token : Evergreen.V1.OAuth.Token
    , created : Effect.Time.Posix
    , expires : Effect.Time.Posix
    }


type BackendMsg
    = AuthSigninInitiated_
        { sessionId : Effect.Lamdera.SessionId
        , clientId : Effect.Lamdera.ClientId
        , methodId : MethodId
        , baseUrl : Url.Url
        , now : Effect.Time.Posix
        , username : Maybe String
        }
    | AuthSigninInitiatedDelayed_ Effect.Lamdera.SessionId ToFrontend
    | AuthCallbackReceived_ Effect.Lamdera.SessionId Effect.Lamdera.ClientId MethodId Url.Url String String Effect.Time.Posix
    | AuthSuccess Effect.Lamdera.SessionId Effect.Lamdera.ClientId MethodId Effect.Time.Posix (Result Error ( UserInfo, Maybe Token ))
    | AuthRenewSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | AuthLogout Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | AuthGoogleOneTapTokenReceived_ Effect.Lamdera.SessionId Effect.Lamdera.ClientId MethodId String Effect.Time.Posix
