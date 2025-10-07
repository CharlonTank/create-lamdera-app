module Frontend exposing (..)

import Auth
import Auth.Common
import Auth.Flow
import Browser exposing (UrlRequest(..))
import Effect.Browser.Navigation as Nav exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Env
import GoogleOneTap
import Html exposing (..)
import Html.Attributes as Attr exposing (class, id)
import Html.Events exposing (onClick, onCheck)
import I18n exposing (Language(..), Translations)
import Json.Decode as Decode
import Json.Encode as Encode
import Lamdera
import LocalStorage exposing (LocalStorage, LocalStorageUpdate(..))
import Pages.About
import Pages.Admin
import Pages.Chat
import Pages.Home
import Pages.Login
import Pages.Register
import RemoteData
import Router
import Theme exposing (Mode(..), UserPreference(..))
import Time
import Types exposing (..)
import Url


app =
    Effect.Lamdera.frontend
        Lamdera.sendToBackend
        app_


app_ =
    { init = init
    , onUrlRequest = \urlRequest -> BasicFrontendMsg (UrlClicked urlRequest)
    , onUrlChange = \url -> BasicFrontendMsg (UrlChanged url)
    , update = update
    , updateFromBackend = updateFromBackend
    , subscriptions = subscriptions
    , view = view
    }


init : Url.Url -> Key -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
init url key =
    let
        model =
            { key = key
            , localStorage = LocalStorage.defaultLocalStorage
            , counter = RemoteData.Loading
            , lastUpdatedBy = Nothing
            , route = Router.fromUrl url
            , chatMessages = []
            , chatInput = ""

            -- Auth fields
            , authFlow = Auth.Common.Idle
            , authRedirectBaseUrl = url
            , loginState = JustArrived
            , currentUser = Nothing
            , sessionId = Nothing
            , loginForm =
                { email = ""
                , password = ""
                , isSubmitting = False
                , error = Nothing
                }
            , registerForm =
                { email = ""
                , password = ""
                , confirmPassword = ""
                , name = ""
                , username = ""
                , isSubmitting = False
                , error = Nothing
                }

            -- Admin data
            , adminUsers = RemoteData.NotAsked
            , adminMessages = RemoteData.NotAsked
            , editingUser = Nothing
            , editingMessage = Nothing

            -- Default to UTC, will be updated when we get the actual timezone
            , timezone = Time.utc
            
            -- Config panel
            , configPanelOpen = True
            , maintenanceMode = False
            }

        -- Check if this is an OAuth callback using the router
        ( finalModel, authCmd ) =
            case Router.fromUrl url of
                Router.OAuthCallback _ _ ->
                    let
                        methodId =
                            -- Extract method ID from URL path
                            case String.split "/" url.path of
                                _ :: "login" :: method :: "callback" :: _ ->
                                    method

                                _ ->
                                    "OAuthGoogle"

                        -- fallback
                        ( authModel, authCommand ) =
                            Auth.Flow.init
                                model
                                methodId
                                url
                                key
                                (\authMsg -> sendToBackend (BasicToBackend (AuthToBackendToBackend authMsg)))
                    in
                    ( authModel
                    , authCommand
                    )

                _ ->
                    ( model, Command.none )
    in
    ( finalModel
    , Command.batch
        [ LocalStorage.getLocalStorage
        , sendToBackend (BasicToBackend GetCounterToBackend)
        , sendToBackend (LoggedInUserToBackend GetChatMessagesToBackend)
        , sendToBackend (BasicToBackend (AuthToBackendToBackend Auth.Common.AuthRenewSessionRequested))
        , sendToBackend (LoggedInUserToBackend GetUserToBackend)
        , if Router.fromUrl url == Router.Admin then
            sendToBackend (LoggedInAdminToBackend GetAdminDataToBackend)

          else
            Command.none
        , Effect.Task.perform (GotTimezone >> BasicFrontendMsg) Effect.Time.here
        , authCmd

        -- Don't initialize Google One Tap here - wait until we know if user is logged in
        ]
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
    case msg of
        BasicFrontendMsg basicMsg ->
            updateBasic basicMsg model

        LoggedInUserFrontendMsg userMsg ->
            updateLoggedInUser userMsg model

        LoggedInAdminFrontendMsg adminMsg ->
            updateLoggedInAdmin adminMsg model


updateBasic : BasicFrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateBasic msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            let
                newRoute =
                    Router.fromUrl url

                ( newModel, cmd ) =
                    if newRoute == Router.Admin then
                        -- Check if user is admin before requesting data
                        case model.currentUser of
                            Just userInfo ->
                                if userInfo.email == "admin@example.com" then
                                    ( { model
                                        | route = newRoute
                                        , adminUsers = RemoteData.Loading
                                        , adminMessages = RemoteData.Loading
                                      }
                                    , sendToBackend (LoggedInAdminToBackend GetAdminDataToBackend)
                                    )

                                else
                                    ( { model | route = newRoute }, Command.none )

                            Nothing ->
                                ( { model | route = newRoute }, Command.none )

                    else
                        ( { model | route = newRoute }, Command.none )
            in
            ( newModel, cmd )

        Increment ->
            ( model
            , sendToBackend (BasicToBackend UserIncrementToBackend)
            )

        Decrement ->
            ( model
            , sendToBackend (BasicToBackend UserDecrementToBackend)
            )

        NoOpFrontendMsg ->
            ( model, Command.none )

        ReceivedLocalStorage localStorage ->
            ( { model | localStorage = localStorage }
            , Command.none
            )

        ChangeLanguage language ->
            ( { model | localStorage = updateLanguage language model.localStorage }
            , LocalStorage.storeValue (UpdateLanguage language)
            )

        ChangeTheme userPreference ->
            ( { model | localStorage = updateUserPreference userPreference model.localStorage }
            , LocalStorage.storeValue (UpdateUserPreference userPreference)
            )

        -- Auth messages
        SignInRequested ->
            -- Handle email/password login
            let
                loginForm =
                    model.loginForm
            in
            ( { model | loginForm = { loginForm | isSubmitting = True } }
            , sendToBackend (BasicToBackend (EmailPasswordLoginToBackend model.loginForm.email model.loginForm.password))
            )

        SignInWithGoogle ->
            -- Use real Google OAuth flow
            let
                -- Clean the authRedirectBaseUrl to remove any query parameters
                cleanUrl =
                    model.authRedirectBaseUrl

                cleanModel =
                    { model | authRedirectBaseUrl = { cleanUrl | query = Nothing, path = "/" } }

                ( newModel, authMsg ) =
                    Auth.Flow.signInRequested "OAuthGoogle" cleanModel Nothing
            in
            ( newModel
            , sendToBackend (BasicToBackend (AuthToBackendToBackend authMsg))
            )

        SignInWithGithub ->
            -- Use real GitHub OAuth flow
            let
                -- Clean the authRedirectBaseUrl to remove any query parameters
                cleanUrl =
                    model.authRedirectBaseUrl

                cleanModel =
                    { model | authRedirectBaseUrl = { cleanUrl | query = Nothing, path = "/" } }

                ( newModel, authMsg ) =
                    Auth.Flow.signInRequested "OAuthGithub" cleanModel Nothing
            in
            ( newModel
            , sendToBackend (BasicToBackend (AuthToBackendToBackend authMsg))
            )

        RegisterRequested ->
            let
                form =
                    model.registerForm
            in
            if form.password == form.confirmPassword then
                ( { model | registerForm = { form | isSubmitting = True, error = Nothing } }
                , sendToBackend (BasicToBackend (EmailPasswordRegisterToBackend form.email form.password form.name form.username))
                )

            else
                ( { model | registerForm = { form | error = Just "Passwords do not match" } }
                , Command.none
                )

        UpdateLoginForm newForm ->
            ( { model | loginForm = newForm }
            , Command.none
            )

        UpdateRegisterForm newForm ->
            ( { model | registerForm = newForm }
            , Command.none
            )

        GotTimezone zone ->
            ( { model | timezone = zone }
            , Command.none
            )
        
        CloseConfigPanel ->
            ( { model | configPanelOpen = False }
            , Command.none
            )
        
        ToggleMaintenanceMode ->
            ( { model | maintenanceMode = not model.maintenanceMode }
            , Command.none
            )

        GoogleOneTapResponseReceived credential ->
            -- Send the credential to the backend for verification
            ( model
            , sendToBackend (BasicToBackend (GoogleOneTapTokenToBackend credential))
            )

        GoogleOneTapStatusReceived status ->
            -- Handle One Tap status (for now just log it)
            let
                _ =
                    Debug.log "Google One Tap status" status
            in
            ( model, Command.none )


updateLoggedInUser : LoggedInUserFrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateLoggedInUser msg model =
    case msg of
        UpdateChatInput input ->
            ( { model | chatInput = input }
            , Command.none
            )

        SendChatMessage ->
            if String.trim model.chatInput == "" then
                ( model, Command.none )

            else
                ( { model | chatInput = "" }
                , sendToBackend (LoggedInUserToBackend (SendMessageToBackend (String.trim model.chatInput)))
                )

        LogoutRequested ->
            ( model
            , Command.batch
                [ sendToBackend (BasicToBackend (AuthToBackendToBackend Auth.Common.AuthLogoutRequested))
                , Command.sendToJs "googleOneTapSignOut_"
                    GoogleOneTap.googleOneTapSignOutWrapper
                    (Encode.object [])

                -- Disable auto-select for One Tap
                ]
            )


updateLoggedInAdmin : LoggedInAdminFrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateLoggedInAdmin msg model =
    case msg of
        -- Admin actions
        ResetCounter ->
            ( model
            , sendToBackend (LoggedInAdminToBackend AdminResetCounterToBackend)
            )

        ClearChatMessages ->
            ( model
            , sendToBackend (LoggedInAdminToBackend AdminClearChatMessagesToBackend)
            )

        -- Admin CRUD actions
        AdminDeleteUser email ->
            ( model
            , sendToBackend (LoggedInAdminToBackend (AdminDeleteUserToBackend email))
            )

        AdminDeleteMessage messageId ->
            ( model
            , sendToBackend (LoggedInAdminToBackend (AdminDeleteMessageToBackend messageId))
            )

        StartEditingUser email user ->
            ( { model | editingUser = Just ( email, user ) }
            , sendToBackend (LoggedInAdminToBackend (AdminEditUserToBackend email (Just user)))
            )

        StartEditingMessage messageId message ->
            ( { model | editingMessage = Just ( messageId, message ) }
            , sendToBackend (LoggedInAdminToBackend (AdminEditMessageToBackend messageId (Just message)))
            )

        CancelEditing ->
            ( { model | editingUser = Nothing, editingMessage = Nothing }
            , Command.none
            )

        SaveUserEdit email user ->
            ( { model | editingUser = Nothing }
            , sendToBackend (LoggedInAdminToBackend (AdminEditUserToBackend email (Just user)))
            )

        SaveMessageEdit messageId message ->
            ( { model | editingMessage = Nothing }
            , sendToBackend (LoggedInAdminToBackend (AdminEditMessageToBackend messageId (Just message)))
            )

        SendTestEmail ->
            ( model
            , sendToBackend (LoggedInAdminToBackend SendTestEmailToBackend)
            )


updateLanguage : Language -> LocalStorage -> LocalStorage
updateLanguage language localStorage =
    { localStorage | language = language }


updateUserPreference : UserPreference -> LocalStorage -> LocalStorage
updateUserPreference userPreference localStorage =
    { localStorage | userPreference = userPreference }


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case msg of
        BasicToFrontend basicMsg ->
            updateFromBackendBasic basicMsg model

        LoggedInUserToFrontend userMsg ->
            updateFromBackendLoggedInUser userMsg model

        LoggedInAdminToFrontend adminMsg ->
            updateFromBackendLoggedInAdmin adminMsg model


updateFromBackendBasic : BasicToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackendBasic msg model =
    case msg of
        CounterNewValueToFrontend newValue triggeredBy ->
            ( { model
                | counter = RemoteData.Success newValue
                , lastUpdatedBy = triggeredBy
              }
            , Command.none
            )

        -- Auth responses
        AuthToFrontendToFrontend authMsg ->
            Auth.updateFromBackend authMsg model

        AuthSuccessToFrontend userInfo ->
            -- Handle successful authentication
            let
                -- Only redirect to home if we're on login/register/oauth callback pages
                -- This preserves the current route when restoring sessions
                shouldRedirect =
                    case model.route of
                        Router.Login ->
                            True

                        Router.Register ->
                            True

                        Router.OAuthCallback _ _ ->
                            True

                        _ ->
                            False

                -- Check if this is an admin user and we're on admin page
                isAdmin =
                    userInfo.email == "admin@example.com"

                isOnAdminPage =
                    model.route == Router.Admin

                ( newAdminUsers, newAdminMessages, adminCommand ) =
                    if isAdmin && isOnAdminPage then
                        ( RemoteData.Loading
                        , RemoteData.Loading
                        , sendToBackend (LoggedInAdminToBackend GetAdminDataToBackend)
                        )

                    else
                        ( model.adminUsers, model.adminMessages, Command.none )

                command =
                    if shouldRedirect then
                        Command.batch [ Nav.pushUrl model.key "/", adminCommand ]

                    else
                        adminCommand
            in
            ( { model
                | currentUser = Just userInfo
                , loginState = LoggedIn userInfo
                , loginForm = { email = "", password = "", isSubmitting = False, error = Nothing }
                , adminUsers = newAdminUsers
                , adminMessages = newAdminMessages
              }
            , command
            )

        AuthLogoutToFrontend ->
            -- Handle logout confirmation
            ( { model
                | currentUser = Nothing
                , loginState = NotLogged False
                , sessionId = Nothing
                , authFlow = Auth.Common.Idle
                , chatMessages = [] -- Clear chat messages on logout
                , chatInput = "" -- Clear chat input
                , adminUsers = RemoteData.NotAsked
                , adminMessages = RemoteData.NotAsked
              }
            , Command.none
            )


updateFromBackendLoggedInUser : LoggedInUserToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackendLoggedInUser msg model =
    case msg of
        NewChatMessageToFrontend message ->
            ( { model | chatMessages = model.chatMessages ++ [ message ] }
            , Command.none
            )

        AllChatMessagesToFrontend messages ->
            ( { model | chatMessages = messages }
            , Command.none
            )

        UserInfoResponseToFrontend maybeUser ->
            case maybeUser of
                Just user ->
                    -- Convert User to UserInfo for login state
                    let
                        userInfo =
                            { email = user.email
                            , name = user.name
                            , username = user.username
                            , profilePicture = user.profilePicture
                            }
                    in
                    ( { model
                        | currentUser = Just userInfo
                        , loginState = LoggedIn userInfo
                      }
                    , Command.none
                    )

                Nothing ->
                    ( { model
                        | currentUser = Nothing
                        , loginState = NotLogged False
                      }
                    , Command.none
                    )


updateFromBackendLoggedInAdmin : LoggedInAdminToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackendLoggedInAdmin msg model =
    case msg of
        AdminUsersUpdatedToFrontend maybeUsers ->
            case maybeUsers of
                Just users ->
                    ( { model | adminUsers = RemoteData.Success users }
                    , Command.none
                    )

                Nothing ->
                    -- Error getting users (likely no permission)
                    ( { model | adminUsers = RemoteData.Failure "Access denied or not logged in" }
                    , Command.none
                    )

        AdminMessagesUpdatedToFrontend maybeMessages ->
            case maybeMessages of
                Just messages ->
                    ( { model | adminMessages = RemoteData.Success messages }
                    , Command.none
                    )

                Nothing ->
                    -- Error getting messages (likely no permission)
                    ( { model | adminMessages = RemoteData.Failure "Access denied or not logged in" }
                    , Command.none
                    )

        AdminOperationResultToFrontend _ maybeError ->
            -- Handle operation result (could show notification)
            case maybeError of
                Just _ ->
                    -- Operation failed
                    ( model
                    , Command.none
                    )

                Nothing ->
                    -- Operation succeeded
                    ( model
                    , Command.none
                    )


subscriptions : FrontendModel -> Subscription FrontendOnly FrontendMsg
subscriptions _ =
    Subscription.batch
        [ LocalStorage.receiveLocalStorage (\localStorage -> BasicFrontendMsg (ReceivedLocalStorage localStorage))
        , Subscription.fromJs "googleOneTapResponse_"
            GoogleOneTap.googleOneTapResponse
            (\value ->
                case Decode.decodeValue GoogleOneTap.decodeOneTapResponse value of
                    Ok response ->
                        BasicFrontendMsg (GoogleOneTapResponseReceived response.credential)

                    Err _ ->
                        BasicFrontendMsg NoOpFrontendMsg
            )
        , Subscription.fromJs "googleOneTapStatus_"
            GoogleOneTap.googleOneTapStatus
            (\value ->
                case Decode.decodeValue GoogleOneTap.decodeOneTapStatus value of
                    Ok status ->
                        BasicFrontendMsg (GoogleOneTapStatusReceived status)

                    Err _ ->
                        BasicFrontendMsg NoOpFrontendMsg
            )
        ]


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    let
        { t, isDark } =
            getUserConfig model.localStorage
    in
    { title = Router.toTitle t model.route ++ " - " ++ t.appTitle
    , body =
        [ div
            [ class
                (if isDark then
                    "dark"

                 else
                    ""
                )
            ]
            [ if model.maintenanceMode then
                viewMaintenancePage t
              else
                div [ class "min-h-screen bg-gradient-to-br from-purple-400 via-pink-500 to-red-500 dark:from-purple-900 dark:via-pink-900 dark:to-red-900 transition-colors duration-300" ]
                    [ div [ class "container mx-auto px-4 py-8" ]
                        [ -- Header with navigation, language and theme switchers
                          viewHeader t model

                        -- Page content
                        , viewPage t model

                        -- Footer
                        , div [ class "mt-16 text-center text-white/80" ]
                            [ p [ class "mb-2" ] [ text t.editMessage ]
                            , p [ class "text-sm" ]
                                [ text t.tailwindMessage ]
                            ]
                        ]
                    ]
            
            -- Config panel (development only)
            , if Env.environment /= "production" && model.configPanelOpen then
                viewConfigPanel t model
              else
                text ""
            ]
        ]
    }


viewHeader : Translations -> FrontendModel -> Html FrontendMsg
viewHeader t model =
    div [ class "bg-white/10 dark:bg-black/20 backdrop-blur-md rounded-lg p-4 mb-8" ]
        [ div [ class "flex flex-wrap justify-between items-center gap-4" ]
            [ div [ class "flex items-center gap-6" ]
                [ h1 [ class "text-2xl font-bold text-white" ] [ text t.appTitle ]
                , viewNavigation t model.route model.currentUser
                ]
            , div [ class "flex flex-wrap items-center gap-4" ]
                [ viewLanguageSelector t model.localStorage.language
                , viewThemeSelector t model.localStorage.userPreference
                , viewAuthSection t model
                ]
            ]
        ]


viewLanguageSelector : Translations -> Language -> Html FrontendMsg
viewLanguageSelector t currentLanguage =
    div [ class "flex gap-2" ]
        [ viewLanguageButton t currentLanguage EN "🇬🇧"
        , viewLanguageButton t currentLanguage FR "🇫🇷"
        ]


viewLanguageButton : Translations -> Language -> Language -> String -> Html FrontendMsg
viewLanguageButton t currentLanguage targetLanguage flag =
    button
        [ onClick (BasicFrontendMsg (ChangeLanguage targetLanguage))
        , class
            ("px-4 py-2 rounded-lg font-medium transition-all duration-200 "
                ++ (if currentLanguage == targetLanguage then
                        "bg-white text-purple-600 shadow-lg transform scale-105"

                    else
                        "bg-white/20 text-white hover:bg-white/30"
                   )
            )
        ]
        [ text
            (flag
                ++ " "
                ++ (if targetLanguage == EN then
                        t.english

                    else
                        t.french
                   )
            )
        ]


viewThemeSelector : Translations -> UserPreference -> Html FrontendMsg
viewThemeSelector t currentPreference =
    div [ class "flex gap-2" ]
        [ viewThemeButton t currentPreference LightMode "☀️"
        , viewThemeButton t currentPreference DarkMode "🌙"
        , viewThemeButton t currentPreference SystemMode "🖥️"
        ]


viewThemeButton : Translations -> UserPreference -> UserPreference -> String -> Html FrontendMsg
viewThemeButton t currentPreference targetPreference icon =
    button
        [ onClick (BasicFrontendMsg (ChangeTheme targetPreference))
        , class
            ("p-2 rounded-lg transition-all duration-200 "
                ++ (if currentPreference == targetPreference then
                        "bg-white text-purple-600 shadow-lg transform scale-105"

                    else
                        "bg-white/20 text-white hover:bg-white/30"
                   )
            )
        , Attr.title
            (case targetPreference of
                LightMode ->
                    t.lightTheme

                DarkMode ->
                    t.darkTheme

                SystemMode ->
                    t.systemTheme
            )
        ]
        [ text icon ]


viewNavigation : I18n.Translations -> Router.Route -> Maybe Auth.Common.UserInfo -> Html FrontendMsg
viewNavigation t currentRoute currentUser =
    nav [ class "flex gap-4" ]
        [ viewNavLink currentRoute Router.Home t.home
        , viewNavLink currentRoute Router.About t.about
        , viewNavLink currentRoute Router.Chat t.chat

        -- Show admin link only for admin users
        , case currentUser of
            Just userInfo ->
                if userInfo.email == "admin@example.com" then
                    viewNavLink currentRoute Router.Admin t.admin

                else
                    text ""

            Nothing ->
                text ""
        ]


viewAuthSection : I18n.Translations -> FrontendModel -> Html FrontendMsg
viewAuthSection t model =
    case model.loginState of
        LoggedIn userInfo ->
            div [ class "flex items-center gap-3" ]
                [ -- Profile picture
                  case userInfo.profilePicture of
                    Just picture ->
                        img
                            [ Attr.src picture
                            , Attr.alt "Profile"
                            , class "w-8 h-8 rounded-full object-cover border-2 border-white/20"
                            ]
                            []

                    Nothing ->
                        -- Default avatar with first letter of name or email
                        div
                            [ class "w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center text-white font-semibold text-sm"
                            ]
                            [ text (String.left 1 (Maybe.withDefault userInfo.email userInfo.username) |> String.toUpper) ]
                , span [ class "text-white" ]
                    [ text (Maybe.withDefault userInfo.email userInfo.username) ]
                , button
                    [ onClick (LoggedInUserFrontendMsg LogoutRequested)
                    , id "logout-button"
                    , class "px-4 py-2 bg-red-500/20 hover:bg-red-500/30 text-white rounded-lg font-medium transition-colors"
                    ]
                    [ text t.logout ]
                ]

        _ ->
            div [ class "flex gap-2" ]
                [ a
                    [ Attr.href "/login"
                    , class "px-4 py-2 bg-white/20 hover:bg-white/30 text-white rounded-lg font-medium transition-colors"
                    ]
                    [ text t.login ]
                , a
                    [ Attr.href "/register"
                    , class "px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-medium transition-colors"
                    ]
                    [ text t.register ]
                ]


viewNavLink : Router.Route -> Router.Route -> String -> Html FrontendMsg
viewNavLink currentRoute targetRoute label =
    a
        [ Attr.href (Router.toPath targetRoute)
        , class
            ("px-4 py-2 rounded-lg font-medium transition-all duration-200 "
                ++ (if currentRoute == targetRoute then
                        "bg-white text-purple-600 shadow-lg"

                    else
                        "text-white hover:bg-white/20"
                   )
            )
        ]
        [ text label ]


viewPage : Translations -> FrontendModel -> Html FrontendMsg
viewPage t model =
    case model.route of
        Router.Home ->
            Pages.Home.view t model

        Router.About ->
            Pages.About.view t

        Router.Chat ->
            Pages.Chat.view t model

        Router.Admin ->
            Pages.Admin.view t model

        Router.Login ->
            Pages.Login.view t model

        Router.Register ->
            Pages.Register.view t model

        Router.NotFound ->
            viewNotFound t

        Router.OAuthCallback _ _ ->
            Pages.Home.view t model


viewNotFound : Translations -> Html FrontendMsg
viewNotFound t =
    div [ class "text-center mt-12" ]
        [ div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl p-12 max-w-2xl mx-auto" ]
            [ h1 [ class "text-6xl font-bold text-red-500 dark:text-red-400 mb-4" ]
                [ text "😵" ]
            , h2 [ class "text-3xl font-bold text-gray-800 dark:text-gray-200 mb-4" ]
                [ text t.pageNotFound ]
            , p [ class "text-lg text-gray-600 dark:text-gray-400 mb-6" ]
                [ text t.pageNotFoundMessage ]
            , a
                [ Attr.href (Router.toPath Router.Home)
                , class "inline-block px-6 py-3 bg-purple-600 text-white font-semibold rounded-lg hover:bg-purple-700 transition-colors duration-200"
                ]
                [ text t.goHomeButton ]
            ]
        ]


viewMaintenancePage : Translations -> Html FrontendMsg
viewMaintenancePage t =
    div [ class "min-h-screen bg-gradient-to-br from-purple-400 via-pink-500 to-red-500 dark:from-purple-900 dark:via-pink-900 dark:to-red-900 flex items-center justify-center" ]
        [ div [ class "text-center text-white" ]
            [ h1 [ class "text-6xl font-bold mb-4" ] [ text t.maintenanceTitle ]
            , p [ class "text-2xl" ] [ text t.maintenanceMessage ]
            ]
        ]


viewConfigPanel : Translations -> FrontendModel -> Html FrontendMsg
viewConfigPanel t model =
    div [ class "fixed bottom-14 left-4 z-50 bg-yellow-100 dark:bg-yellow-900 p-4 rounded-lg shadow-lg border-2 border-yellow-400" ]
        [ button
            [ onClick (BasicFrontendMsg CloseConfigPanel)
            , class "absolute top-2 right-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            ]
            [ text "✕" ]
        , div [ class "text-sm font-mono text-gray-700 dark:text-gray-300 mb-2" ]
            [ text ("ENV: " ++ Env.environment) ]
        , label [ class "flex items-center cursor-pointer" ]
            [ input
                [ Attr.type_ "checkbox"
                , Attr.checked model.maintenanceMode
                , onCheck (\_ -> BasicFrontendMsg ToggleMaintenanceMode)
                , class "mr-2 h-5 w-5 text-yellow-600 rounded focus:ring-yellow-500"
                ]
                []
            , span [ class "text-sm font-semibold text-gray-700 dark:text-gray-300" ]
                [ text t.maintenanceModeLabel ]
            ]
        , div [ class "mt-3 pt-3 border-t border-yellow-400" ]
            [ div [ class "flex items-center justify-between" ]
                [ span [ class "text-sm font-semibold text-gray-700 dark:text-gray-300" ]
                    [ text t.language ]
                , div [ class "flex gap-2" ]
                    [ button
                        [ onClick (BasicFrontendMsg (ChangeLanguage FR))
                        , class
                            ("px-3 py-1 text-xs font-medium rounded transition-colors "
                                ++ (if model.localStorage.language == FR then
                                        "bg-yellow-600 text-white"
                                    else
                                        "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                                   )
                            )
                        ]
                        [ text "FR" ]
                    , button
                        [ onClick (BasicFrontendMsg (ChangeLanguage EN))
                        , class
                            ("px-3 py-1 text-xs font-medium rounded transition-colors "
                                ++ (if model.localStorage.language == EN then
                                        "bg-yellow-600 text-white"
                                    else
                                        "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                                   )
                            )
                        ]
                        [ text "EN" ]
                    ]
                ]
            ]
        , div [ class "mt-3 pt-3 border-t border-yellow-400" ]
            [ div [ class "flex items-center justify-between" ]
                [ span [ class "text-sm font-semibold text-gray-700 dark:text-gray-300" ]
                    [ text t.theme ]
                , div [ class "flex gap-1" ]
                    [ button
                        [ onClick (BasicFrontendMsg (ChangeTheme LightMode))
                        , class
                            ("px-2 py-1 text-xs font-medium rounded transition-colors "
                                ++ (if model.localStorage.userPreference == LightMode then
                                        "bg-yellow-600 text-white"
                                    else
                                        "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                                   )
                            )
                        , Attr.title t.lightTheme
                        ]
                        [ text "☀️" ]
                    , button
                        [ onClick (BasicFrontendMsg (ChangeTheme DarkMode))
                        , class
                            ("px-2 py-1 text-xs font-medium rounded transition-colors "
                                ++ (if model.localStorage.userPreference == DarkMode then
                                        "bg-yellow-600 text-white"
                                    else
                                        "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                                   )
                            )
                        , Attr.title t.darkTheme
                        ]
                        [ text "🌙" ]
                    , button
                        [ onClick (BasicFrontendMsg (ChangeTheme SystemMode))
                        , class
                            ("px-2 py-1 text-xs font-medium rounded transition-colors "
                                ++ (if model.localStorage.userPreference == SystemMode then
                                        "bg-yellow-600 text-white"
                                    else
                                        "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                                   )
                            )
                        , Attr.title t.systemTheme
                        ]
                        [ text "💻" ]
                    ]
                ]
            ]
        ]


getUserConfig : LocalStorage -> { t : Translations, isDark : Bool }
getUserConfig localStorage =
    let
        mode =
            Theme.getMode localStorage.userPreference localStorage.systemMode
    in
    { t = I18n.translations localStorage.language
    , isDark = mode == Dark
    }
