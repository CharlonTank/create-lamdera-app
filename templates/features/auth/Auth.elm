module Auth exposing (..)

import Auth.Common
import Auth.Flow
import Auth.Method.GoogleOneTap
import Auth.Method.OAuthGithub
import Auth.Method.OAuthGoogle
import Effect.Command as Command exposing (BackendOnly, Command, FrontendOnly)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time
import Email
import Env
import GoogleOneTap
import SeqDict as Dict
import Types exposing (..)



-- OAuth Configuration
-- To enable Google OAuth:
-- 1. Go to https://console.cloud.google.com/
-- 2. Create a new project or select existing one
-- 3. Enable Google+ API
-- 4. Create OAuth 2.0 credentials (Web application)
-- 5. Add your domain to authorized origins
-- 6. Set these environment variables:
--    export GOOGLE_CLIENT_ID="your-client-id"
--    export GOOGLE_CLIENT_SECRET="your-client-secret"
-- 7. Update Env.elm to use these values


oauthConfig : { googleAppClientId : String, googleAppClientSecret : String, githubAppClientId : String, githubAppClientSecret : String }
oauthConfig =
    { googleAppClientId = Env.googleAppClientId
    , googleAppClientSecret = Env.googleAppClientSecret
    , githubAppClientId = Env.githubAppClientId
    , githubAppClientSecret = Env.githubAppClientSecret
    }


backendConfig :
    BackendModel
    ->
        Auth.Flow.BackendUpdateConfig
            FrontendMsg
            BackendMsg
            ToFrontend
            FrontendModel
            BackendModel
            ToFrontend
backendConfig model =
    { asToFrontend = AuthToFrontendToFrontend >> BasicToFrontend
    , asBackendMsg = AuthBackendMsg
    , sendToFrontend = Effect.Lamdera.sendToFrontends
    , backendModel = model
    , loadMethod =
        Auth.Flow.methodLoaderBackend
            [ Auth.Method.OAuthGoogle.configuration
                oauthConfig.googleAppClientId
                oauthConfig.googleAppClientSecret
            , Auth.Method.GoogleOneTap.configuration
                oauthConfig.googleAppClientId
                oauthConfig.googleAppClientSecret
            , Auth.Method.OAuthGithub.configuration
                oauthConfig.githubAppClientId
                oauthConfig.githubAppClientSecret
            ]
    , handleAuthSuccess = handleAuthSuccess model
    , renewSession = renewSession
    , logout = logout
    , isDev = Env.environment == "development"
    }


logout : SessionId -> ClientId -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
logout sessionId clientId model =
    ( { model | sessions = model.sessions |> Dict.remove sessionId }
    , Effect.Lamdera.sendToFrontend clientId (BasicToFrontend AuthLogoutToFrontend)
    )


updateFromBackend : Auth.Common.ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend authToFrontendMsg model =
    case authToFrontendMsg of
        Auth.Common.AuthInitiateSignin url ->
            Auth.Flow.startProviderSignin url model

        Auth.Common.AuthError err ->
            Auth.Flow.setError model err

        Auth.Common.AuthSessionChallenge _ ->
            ( { model | loginState = NotLogged True }
            , -- Initialize Google One Tap only when we know user is not logged in
              Command.sendToJs "initializeGoogleOneTap_"
                GoogleOneTap.initializeGoogleOneTapWrapper
                (GoogleOneTap.encodeInit Env.googleAppClientId)
            )


renewSession : SessionId -> ClientId -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
renewSession sessionId clientId model =
    case Dict.get sessionId model.sessions of
        Just userInfo ->
            -- Session exists, send success response
            ( model
            , Effect.Lamdera.sendToFrontend clientId (BasicToFrontend (AuthSuccessToFrontend userInfo))
            )

        Nothing ->
            -- No session found, send challenge
            ( model
            , Effect.Lamdera.sendToFrontend clientId (BasicToFrontend (AuthToFrontendToFrontend (Auth.Common.AuthSessionChallenge Auth.Common.AuthSessionMissing)))
            )


handleAuthSuccess :
    BackendModel
    -> SessionId
    -> ClientId
    -> Auth.Common.UserInfo
    -> Auth.Common.MethodId
    -> Maybe Auth.Common.Token
    -> Effect.Time.Posix
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleAuthSuccess backendModel sessionId clientId userInfo _ _ now =
    let
        -- Create or update user in the users database
        existingUser =
            Dict.get userInfo.email backendModel.users

        updatedUser =
            case existingUser of
                Just user ->
                    -- Update existing user with new info (profile picture might have changed)
                    -- Preserve existing password
                    { user
                        | name = userInfo.name
                        , username = userInfo.username
                        , profilePicture = userInfo.profilePicture
                    }

                Nothing ->
                    -- Create new user (OAuth users have no password)
                    { email = userInfo.email
                    , name = userInfo.name
                    , username = userInfo.username
                    , profilePicture = userInfo.profilePicture
                    , createdAt = now
                    , isAdmin = False
                    , encryptedPassword = Nothing
                    }

        newUsers =
            Dict.insert userInfo.email updatedUser backendModel.users

        newSessions =
            Dict.insert sessionId userInfo backendModel.sessions

        response =
            BasicToFrontend (AuthSuccessToFrontend userInfo)

        -- Send welcome email only for new users
        emailCommand =
            case existingUser of
                Nothing ->
                    Email.sendWelcomeEmail updatedUser

                Just _ ->
                    Command.none
    in
    ( { backendModel | sessions = newSessions, users = newUsers }
    , Command.batch
        [ Effect.Lamdera.sendToFrontend clientId response
        , emailCommand
        ]
    )
