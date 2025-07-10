module Backend exposing (..)

import Auth
import Auth.Common
import Auth.Flow
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Effect.Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Email
import Env
import Lamdera
import Password
import SeqDict as Dict
import Time
import Types exposing (..)


app =
    Effect.Lamdera.backend
        Lamdera.broadcast
        Lamdera.sendToFrontend
        app_


app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    let
        -- Create default admin user with encrypted password
        adminUser =
            { email = "admin@example.com"
            , name = Just "Admin"
            , username = Just "admin"
            , profilePicture = Nothing
            , createdAt = Time.millisToPosix 0
            , isAdmin = True
            , encryptedPassword = Just (Password.encrypt Env.adminPassword)
            }

        initialUsers =
            Dict.insert adminUser.email adminUser Dict.empty
    in
    ( { counter = 0
      , chatMessages = []
      , lastUpdatedBy = Nothing
      , sessions = Dict.empty
      , users = initialUsers
      , pendingAuths = Dict.empty
      }
    , Command.none
    )


update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        AuthBackendMsg authMsg ->
            Auth.Flow.backendUpdate (Auth.backendConfig model) authMsg

        UserConnected sessionId clientId ->
            -- Check if user has existing session and restore it
            case Dict.get sessionId model.sessions of
                Just userInfo ->
                    -- Check if this is an admin user
                    let
                        isAdmin =
                            case Dict.get userInfo.email model.users of
                                Just user ->
                                    user.isAdmin

                                Nothing ->
                                    False

                        adminCommands =
                            if isAdmin then
                                [ sendToFrontend clientId (LoggedInAdminToFrontend (AdminUsersUpdatedToFrontend (Just (Dict.values model.users))))
                                , sendToFrontend clientId (LoggedInAdminToFrontend (AdminMessagesUpdatedToFrontend (Just model.chatMessages)))
                                ]

                            else
                                []
                    in
                    ( model
                    , Command.batch
                        ([ sendToFrontend clientId (BasicToFrontend (AuthSuccessToFrontend userInfo))
                         , sendToFrontend clientId (LoggedInUserToFrontend (AllChatMessagesToFrontend model.chatMessages))
                         , sendToFrontend clientId (BasicToFrontend (CounterNewValueToFrontend model.counter model.lastUpdatedBy))
                         ]
                            ++ adminCommands
                        )
                    )

                Nothing ->
                    ( model
                    , sendToFrontend clientId (BasicToFrontend (CounterNewValueToFrontend model.counter Nothing))
                    )

        GotTimeForMessage sessionId _ content timestamp ->
            -- Handle creating the message with the actual timestamp
            case handleLoggedInUser sessionId model AnyUser of
                AuthorizedUser userInfo _ ->
                    let
                        messageId =
                            "msg-" ++ String.fromInt (List.length model.chatMessages + 1)

                        authorName =
                            Maybe.withDefault userInfo.email userInfo.username

                        newMessage =
                            { id = messageId
                            , content = content
                            , author = authorName
                            , authorEmail = userInfo.email
                            , timestamp = timestamp
                            }

                        newModel =
                            { model | chatMessages = model.chatMessages ++ [ newMessage ] }
                    in
                    ( newModel
                    , broadcast (LoggedInUserToFrontend (NewChatMessageToFrontend newMessage))
                    )

                _ ->
                    -- User no longer logged in - ignore
                    ( model, Command.none )

        EmailSent result ->
            case result of
                Ok _ ->
                    -- Email sent successfully
                    ( model, Command.none )

                Err _ ->
                    -- Email failed to send - log error but don't break the flow
                    ( model, Command.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        BasicToBackend basicMsg ->
            updateFromFrontendBasic sessionId clientId basicMsg model

        LoggedInUserToBackend userMsg ->
            withLoggedInUser sessionId
                clientId
                model
                AnyUser
                (\_ _ currentModel ->
                    updateFromFrontendLoggedInUser sessionId clientId userMsg currentModel
                )

        LoggedInAdminToBackend adminMsg ->
            withLoggedInUser sessionId
                clientId
                model
                AdminOnly
                (\_ _ currentModel ->
                    updateFromFrontendLoggedInAdmin sessionId clientId adminMsg currentModel
                )


updateFromFrontendBasic : SessionId -> ClientId -> BasicToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendBasic sessionId clientId msg model =
    case msg of
        UserIncrementToBackend ->
            let
                newModel =
                    { model | counter = model.counter + 1 }
            in
            ( newModel
            , broadcast (BasicToFrontend (CounterNewValueToFrontend newModel.counter (Just clientId)))
            )

        UserDecrementToBackend ->
            let
                newModel =
                    { model | counter = model.counter - 1 }
            in
            ( newModel
            , broadcast (BasicToFrontend (CounterNewValueToFrontend newModel.counter (Just clientId)))
            )

        GetCounterToBackend ->
            ( model
            , sendToFrontend clientId (BasicToFrontend (CounterNewValueToFrontend model.counter Nothing))
            )

        -- Auth handlers
        AuthToBackendToBackend authMsg ->
            -- Pass all auth messages to the Auth system (for Google OAuth)
            Auth.Flow.updateFromFrontend
                { asBackendMsg = AuthBackendMsg }
                clientId
                sessionId
                authMsg
                model

        EmailPasswordLoginToBackend email password ->
            -- Handle email/password login
            case Dict.get email model.users of
                Just user ->
                    -- User exists, check password
                    case user.encryptedPassword of
                        Just encryptedPwd ->
                            if Password.verify password encryptedPwd then
                                -- Password matches
                                let
                                    userInfo =
                                        { email = user.email
                                        , name = user.name
                                        , username = user.username
                                        , profilePicture = user.profilePicture
                                        }

                                    newSessions =
                                        Dict.insert sessionId userInfo model.sessions

                                    -- If admin, send admin data
                                    adminCommands =
                                        if user.isAdmin then
                                            [ sendToFrontend clientId (LoggedInAdminToFrontend (AdminUsersUpdatedToFrontend (Just (Dict.values model.users))))
                                            , sendToFrontend clientId (LoggedInAdminToFrontend (AdminMessagesUpdatedToFrontend (Just model.chatMessages)))
                                            ]

                                        else
                                            []
                                in
                                ( { model | sessions = newSessions }
                                , Command.batch
                                    ([ sendToFrontend clientId (BasicToFrontend (AuthSuccessToFrontend userInfo))
                                     , sendToFrontend clientId (LoggedInUserToFrontend (AllChatMessagesToFrontend model.chatMessages))
                                     ]
                                        ++ adminCommands
                                    )
                                )

                            else
                                -- Password doesn't match
                                ( model
                                , sendToFrontend clientId (BasicToFrontend (AuthToFrontendToFrontend (Auth.Common.AuthError (Auth.Common.ErrAuthString "Invalid email or password"))))
                                )

                        Nothing ->
                            -- No password set (OAuth user?)
                            ( model
                            , sendToFrontend clientId (BasicToFrontend (AuthToFrontendToFrontend (Auth.Common.AuthError (Auth.Common.ErrAuthString "Password login not available for this account"))))
                            )

                Nothing ->
                    -- User doesn't exist
                    ( model
                    , sendToFrontend clientId (BasicToFrontend (AuthToFrontendToFrontend (Auth.Common.AuthError (Auth.Common.ErrAuthString "Invalid email or password"))))
                    )

        EmailPasswordRegisterToBackend email password name username ->
            -- Handle email/password registration
            -- Check if user already exists
            case Dict.get email model.users of
                Just _ ->
                    -- User already exists
                    ( model
                    , sendToFrontend clientId (BasicToFrontend (AuthToFrontendToFrontend (Auth.Common.AuthError (Auth.Common.ErrAuthString "Email already registered"))))
                    )

                Nothing ->
                    -- Create new user with encrypted password
                    let
                        userInfo =
                            { email = email
                            , name = Just name
                            , username = Just username
                            , profilePicture = Nothing
                            }

                        newUser =
                            { email = email
                            , name = Just name
                            , username = Just username
                            , profilePicture = Nothing
                            , createdAt = Time.millisToPosix 0
                            , isAdmin = False
                            , encryptedPassword = Just (Password.encrypt password)
                            }

                        newSessions =
                            Dict.insert sessionId userInfo model.sessions

                        newUsers =
                            Dict.insert email newUser model.users
                    in
                    ( { model | sessions = newSessions, users = newUsers }
                    , Command.batch
                        [ sendToFrontend clientId (BasicToFrontend (AuthSuccessToFrontend userInfo))
                        , Email.sendWelcomeEmail newUser
                        ]
                    )

        GoogleOneTapTokenToBackend idToken ->
            -- Handle Google One Tap authentication
            Auth.Flow.updateFromFrontend
                { asBackendMsg = AuthBackendMsg }
                clientId
                sessionId
                (Auth.Common.AuthGoogleOneTapTokenReceived "GoogleOneTap" idToken)
                model


updateFromFrontendLoggedInUser : SessionId -> ClientId -> LoggedInUserToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendLoggedInUser sessionId clientId msg model =
    case msg of
        SendMessageToBackend content ->
            case handleLoggedInUser sessionId model AnyUser of
                AuthorizedUser _ _ ->
                    -- Request current time for the message
                    ( model
                    , Effect.Task.perform (\time -> GotTimeForMessage sessionId clientId content time) Effect.Time.now
                    )

                _ ->
                    -- Not logged in - ignore the message
                    ( model, Command.none )

        GetChatMessagesToBackend ->
            case handleLoggedInUser sessionId model AnyUser of
                AuthorizedUser _ _ ->
                    ( model
                    , sendToFrontend clientId (LoggedInUserToFrontend (AllChatMessagesToFrontend model.chatMessages))
                    )

                _ ->
                    -- Not logged in - return empty messages
                    ( model
                    , sendToFrontend clientId (LoggedInUserToFrontend (AllChatMessagesToFrontend []))
                    )

        GetUserToBackend ->
            case handleLoggedInUser sessionId model AnyUser of
                AuthorizedUser _ user ->
                    ( model
                    , sendToFrontend clientId (LoggedInUserToFrontend (UserInfoResponseToFrontend (Just user)))
                    )

                _ ->
                    ( model
                    , sendToFrontend clientId (LoggedInUserToFrontend (UserInfoResponseToFrontend Nothing))
                    )


updateFromFrontendLoggedInAdmin : SessionId -> ClientId -> LoggedInAdminToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendLoggedInAdmin sessionId clientId msg model =
    case msg of
        AdminResetCounterToBackend ->
            let
                newModel =
                    { model | counter = 0 }
            in
            ( newModel
            , broadcast (BasicToFrontend (CounterNewValueToFrontend 0 Nothing))
            )

        AdminClearChatMessagesToBackend ->
            let
                newModel =
                    { model | chatMessages = [] }
            in
            ( newModel
            , broadcast (LoggedInUserToFrontend (AllChatMessagesToFrontend []))
            )

        AdminDeleteUserToBackend email ->
            let
                newUsers =
                    Dict.remove email model.users

                newModel =
                    { model | users = newUsers }

                usersList =
                    Dict.values newUsers
            in
            ( newModel
            , Command.batch
                [ sendToFrontend clientId (LoggedInAdminToFrontend (AdminUsersUpdatedToFrontend (Just usersList)))
                , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Delete User" Nothing))
                ]
            )

        AdminDeleteMessageToBackend messageId ->
            let
                newMessages =
                    List.filter (\message -> message.id /= messageId) model.chatMessages

                newModel =
                    { model | chatMessages = newMessages }
            in
            ( newModel
            , Command.batch
                [ broadcast (LoggedInUserToFrontend (AllChatMessagesToFrontend newMessages))
                , sendToFrontend clientId (LoggedInAdminToFrontend (AdminMessagesUpdatedToFrontend (Just newMessages)))
                , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Delete Message" Nothing))
                ]
            )

        AdminEditUserToBackend email maybeUser ->
            case maybeUser of
                Just updatedUser ->
                    let
                        newUsers =
                            Dict.insert email updatedUser model.users

                        newModel =
                            { model | users = newUsers }

                        usersList =
                            Dict.values newUsers
                    in
                    ( newModel
                    , Command.batch
                        [ sendToFrontend clientId (LoggedInAdminToFrontend (AdminUsersUpdatedToFrontend (Just usersList)))
                        , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Edit User" Nothing))
                        ]
                    )

                Nothing ->
                    -- Delete user (edit with Nothing means delete)
                    let
                        newUsers =
                            Dict.remove email model.users

                        newModel =
                            { model | users = newUsers }

                        usersList =
                            Dict.values newUsers
                    in
                    ( newModel
                    , Command.batch
                        [ sendToFrontend clientId (LoggedInAdminToFrontend (AdminUsersUpdatedToFrontend (Just usersList)))
                        , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Delete User" Nothing))
                        ]
                    )

        AdminEditMessageToBackend messageId maybeMessage ->
            case maybeMessage of
                Just updatedMessage ->
                    let
                        newMessages =
                            List.map
                                (\message ->
                                    if message.id == messageId then
                                        updatedMessage

                                    else
                                        message
                                )
                                model.chatMessages

                        newModel =
                            { model | chatMessages = newMessages }
                    in
                    ( newModel
                    , Command.batch
                        [ broadcast (LoggedInUserToFrontend (AllChatMessagesToFrontend newMessages))
                        , sendToFrontend clientId (LoggedInAdminToFrontend (AdminMessagesUpdatedToFrontend (Just newMessages)))
                        , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Edit Message" Nothing))
                        ]
                    )

                Nothing ->
                    -- Delete message (edit with Nothing means delete)
                    let
                        newMessages =
                            List.filter (\message -> message.id /= messageId) model.chatMessages

                        newModel =
                            { model | chatMessages = newMessages }
                    in
                    ( newModel
                    , Command.batch
                        [ broadcast (LoggedInUserToFrontend (AllChatMessagesToFrontend newMessages))
                        , sendToFrontend clientId (LoggedInAdminToFrontend (AdminMessagesUpdatedToFrontend (Just newMessages)))
                        , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Delete Message" Nothing))
                        ]
                    )

        GetAdminDataToBackend ->
            let
                usersList =
                    Dict.values model.users
            in
            ( model
            , Command.batch
                [ sendToFrontend clientId (LoggedInAdminToFrontend (AdminUsersUpdatedToFrontend (Just usersList)))
                , sendToFrontend clientId (LoggedInAdminToFrontend (AdminMessagesUpdatedToFrontend (Just model.chatMessages)))
                ]
            )

        SendTestEmailToBackend ->
            -- Send test email to a specific test address
            case handleLoggedInUser sessionId model AdminOnly of
                AuthorizedUser _ _ ->
                    let
                        testUser =
                            { email = "hartosquatique+test+sender@gmail.com"
                            , name = Just "Test User"
                            , username = Just "testuser"
                            , profilePicture = Nothing
                            , createdAt = Time.millisToPosix 0
                            , isAdmin = False
                            , encryptedPassword = Nothing
                            }
                    in
                    ( model
                    , Command.batch
                        [ Email.sendWelcomeEmail testUser
                        , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Test Email" Nothing))
                        ]
                    )

                _ ->
                    ( model
                    , sendToFrontend clientId (LoggedInAdminToFrontend (AdminOperationResultToFrontend "Test Email" (Just "Admin access required")))
                    )


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions _ =
    Effect.Lamdera.onConnect UserConnected


{-| Helper to handle logged in user operations with different access levels
-}
type UserAccessLevel
    = AnyUser
    | AdminOnly


type UserAuthResult
    = NotLoggedIn
    | UserNotFound
    | NotAdmin
    | AuthorizedUser Auth.Common.UserInfo User


handleLoggedInUser : SessionId -> BackendModel -> UserAccessLevel -> UserAuthResult
handleLoggedInUser sessionId model accessLevel =
    case Dict.get sessionId model.sessions of
        Nothing ->
            NotLoggedIn

        Just userInfo ->
            case Dict.get userInfo.email model.users of
                Nothing ->
                    UserNotFound

                Just user ->
                    case accessLevel of
                        AnyUser ->
                            AuthorizedUser userInfo user

                        AdminOnly ->
                            if user.isAdmin then
                                AuthorizedUser userInfo user

                            else
                                NotAdmin


{-| Helper to execute an operation that requires user authentication
-}
withLoggedInUser :
    SessionId
    -> ClientId
    -> BackendModel
    -> UserAccessLevel
    -> (Auth.Common.UserInfo -> User -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
withLoggedInUser sessionId _ model accessLevel operation =
    case handleLoggedInUser sessionId model accessLevel of
        AuthorizedUser userInfo user ->
            operation userInfo user model

        NotLoggedIn ->
            ( model, Command.none )

        UserNotFound ->
            ( model, Command.none )

        NotAdmin ->
            ( model, Command.none )



-- Helper functions
