module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Effect.Browser.Navigation as Nav exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import Effect.Subscription as Subscription exposing (Subscription)
import Html exposing (..)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick)
import I18n exposing (Language(..), Translation)
import Lamdera
import LocalStorage exposing (LocalStorage, LocalStorageUpdate(..))
import Theme exposing (Mode(..), UserPreference(..))
import Types exposing (..)
import Url


type alias UserConfig =
    { t : Translation
    , isDark : Bool
    }


app =
    Effect.Lamdera.frontend
        Lamdera.sendToBackend
        app_


app_ =
    { init = init
    , onUrlRequest = UrlClicked
    , onUrlChange = UrlChanged
    , update = update
    , updateFromBackend = updateFromBackend
    , subscriptions = subscriptions
    , view = view
    }


init : Url.Url -> Key -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
init url key =
    ( { key = key
      , localStorage = LocalStorage.defaultLocalStorage
      , counter = 0
      , clientId = "waiting..."
      }
    , Command.batch
        [ LocalStorage.getLocalStorage
        , sendToBackend GetCounter
        ]
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
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
            ( model, Command.none )

        Increment ->
            ( model
            , sendToBackend UserIncrement
            )

        Decrement ->
            ( model
            , sendToBackend UserDecrement
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


updateLanguage : Language -> LocalStorage -> LocalStorage
updateLanguage language localStorage =
    { localStorage | language = language }


updateUserPreference : UserPreference -> LocalStorage -> LocalStorage
updateUserPreference userPreference localStorage =
    { localStorage | userPreference = userPreference }


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case msg of
        CounterNewValue newValue triggeredBy ->
            ( { model 
              | counter = newValue
              , clientId = if triggeredBy == "" then model.clientId else triggeredBy
              }
            , Command.none
            )


subscriptions : FrontendModel -> Subscription FrontendOnly FrontendMsg
subscriptions model =
    LocalStorage.receiveLocalStorage ReceivedLocalStorage


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    let
        userConfig =
            getUserConfig model.localStorage
        
        darkClass =
            if userConfig.isDark then "dark" else ""
    in
    { title = userConfig.t.appTitle
    , body =
        [ div [ class darkClass ]
            [ div [ class "min-h-screen bg-gradient-to-br from-purple-400 via-pink-500 to-red-500 dark:from-purple-900 dark:via-pink-900 dark:to-red-900 transition-colors duration-300" ]
                [ div [ class "container mx-auto px-4 py-8" ]
                    [ -- Header with language and theme switchers
                      viewHeader userConfig model
                    
                    -- Main content
                    , div [ class "text-center mb-12 mt-8" ]
                        [ h1 [ class "text-5xl font-bold text-white mb-4 drop-shadow-lg" ] 
                            [ text ("🔄 " ++ userConfig.t.counter) ]
                        , p [ class "text-xl text-white/90" ] 
                            [ text userConfig.t.welcome ]
                        ]
                    
                    -- Counter Card
                    , div [ class "max-w-md mx-auto mb-12" ]
                        [ div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl p-8" ]
                            [ div 
                                [ class "text-7xl font-bold text-center mb-8 text-purple-600 dark:text-purple-400"
                                , Attr.id "counter-value"
                                ]
                                [ text (String.fromInt model.counter) ]
                            
                            -- Counter Buttons
                            , div [ class "flex gap-4 justify-center mb-6" ]
                                [ button 
                                    [ onClick Decrement
                                    , class "px-8 py-4 bg-red-500 dark:bg-red-600 text-white text-2xl font-semibold rounded-lg shadow-md hover:bg-red-600 dark:hover:bg-red-700 transform hover:scale-105 transition-all duration-200"
                                    , Attr.id "decrement-button"
                                    ]
                                    [ text userConfig.t.decrement ]
                                , button 
                                    [ onClick Increment
                                    , class "px-8 py-4 bg-green-500 dark:bg-green-600 text-white text-2xl font-semibold rounded-lg shadow-md hover:bg-green-600 dark:hover:bg-green-700 transform hover:scale-105 transition-all duration-200"
                                    , Attr.id "increment-button"
                                    ]
                                    [ text userConfig.t.increment ]
                                ]
                            
                            -- Last Update Info
                            , div [ class "text-center text-gray-600 dark:text-gray-400 text-sm" ]
                                [ text <|
                                    if model.clientId == "waiting..." then
                                        userConfig.t.waitingForUpdate
                                    else if model.clientId == "" then
                                        userConfig.t.counterInitialized
                                    else
                                        userConfig.t.lastUpdatedBy ++ ": " ++ model.clientId
                                ]
                            ]
                        ]
                    
                    -- Feature Cards
                    , div [ class "grid md:grid-cols-3 gap-6 mb-12" ]
                        [ viewCard "🌍" userConfig.t.multiLanguage userConfig.t.multiLanguageDesc "blue"
                        , viewCard "🎨" userConfig.t.tailwindIntegration userConfig.t.tailwindIntegrationDesc "purple"
                        , viewCard "🧪" userConfig.t.testSupport userConfig.t.testSupportDesc "green"
                        ]
                    
                    -- Footer
                    , div [ class "mt-16 text-center text-white/80" ]
                        [ p [ class "mb-2" ] [ text userConfig.t.editMessage ]
                        , p [ class "text-sm" ] 
                            [ text userConfig.t.tailwindMessage ]
                        ]
                    ]
                ]
            ]
        ]
    }


viewHeader : UserConfig -> FrontendModel -> Html FrontendMsg
viewHeader userConfig model =
    div [ class "bg-white/10 dark:bg-black/20 backdrop-blur-md rounded-lg p-4" ]
        [ div [ class "flex flex-wrap justify-between items-center gap-4" ]
            [ h1 [ class "text-2xl font-bold text-white" ] [ text userConfig.t.appTitle ]
            , div [ class "flex flex-wrap items-center gap-4" ]
                [ viewLanguageSelector userConfig model.localStorage.language
                , viewThemeSelector userConfig model.localStorage.userPreference
                ]
            ]
        ]


viewLanguageSelector : UserConfig -> Language -> Html FrontendMsg
viewLanguageSelector userConfig currentLanguage =
    div [ class "flex gap-2" ]
        [ viewLanguageButton userConfig currentLanguage EN "🇬🇧"
        , viewLanguageButton userConfig currentLanguage FR "🇫🇷"
        ]


viewLanguageButton : UserConfig -> Language -> Language -> String -> Html FrontendMsg
viewLanguageButton userConfig currentLanguage targetLanguage flag =
    button
        [ onClick (ChangeLanguage targetLanguage)
        , class <|
            "px-4 py-2 rounded-lg font-medium transition-all duration-200 " ++
            if currentLanguage == targetLanguage then
                "bg-white text-purple-600 shadow-lg transform scale-105"
            else
                "bg-white/20 text-white hover:bg-white/30"
        ]
        [ text (flag ++ " " ++ 
            if targetLanguage == EN then 
                userConfig.t.english 
            else 
                userConfig.t.french)
        ]


viewThemeSelector : UserConfig -> UserPreference -> Html FrontendMsg
viewThemeSelector userConfig currentPreference =
    div [ class "flex gap-2" ]
        [ viewThemeButton userConfig currentPreference LightMode "☀️"
        , viewThemeButton userConfig currentPreference DarkMode "🌙"
        , viewThemeButton userConfig currentPreference SystemMode "🖥️"
        ]


viewThemeButton : UserConfig -> UserPreference -> UserPreference -> String -> Html FrontendMsg
viewThemeButton userConfig currentPreference targetPreference icon =
    button
        [ onClick (ChangeTheme targetPreference)
        , class <|
            "p-2 rounded-lg transition-all duration-200 " ++
            if currentPreference == targetPreference then
                "bg-white text-purple-600 shadow-lg transform scale-105"
            else
                "bg-white/20 text-white hover:bg-white/30"
        , Attr.title
            (case targetPreference of
                LightMode ->
                    userConfig.t.lightTheme

                DarkMode ->
                    userConfig.t.darkTheme

                SystemMode ->
                    userConfig.t.systemTheme
            )
        ]
        [ text icon ]


viewCard : String -> String -> String -> String -> Html msg
viewCard icon title description colorName =
    div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl p-6 transform hover:scale-105 transition-all duration-200" ]
        [ div [ class ("text-" ++ colorName ++ "-600 dark:text-" ++ colorName ++ "-400 mb-4") ]
            [ h2 [ class "text-2xl font-semibold flex items-center gap-2" ] 
                [ span [ class "text-3xl" ] [ text icon ]
                , text title 
                ]
            ]
        , p [ class "text-gray-600 dark:text-gray-300" ]
            [ text description ]
        ]


getUserConfig : LocalStorage -> UserConfig
getUserConfig localStorage =
    let
        mode =
            Theme.getMode localStorage.userPreference localStorage.systemMode
    in
    { t = I18n.translations localStorage.language
    , isDark = mode == Dark
    }