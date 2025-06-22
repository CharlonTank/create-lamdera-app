module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick)
import I18n exposing (Language(..), Translation)
import Lamdera
import LocalStorage exposing (LocalStorage, LocalStorageUpdate(..))
import Theme exposing (Mode(..), UserPreference(..))
import Types exposing (..)
import Url


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }


init : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    ( { key = key
      , localStorage = LocalStorage.defaultLocalStorage
      , message = "Welcome to Lamdera!"
      }
    , LocalStorage.getLocalStorage
    )


subscriptions : FrontendModel -> Sub FrontendMsg
subscriptions model =
    LocalStorage.receiveLocalStorage ReceivedLocalStorage


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
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
            ( model, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )

        ReceivedLocalStorage localStorage ->
            ( { model | localStorage = localStorage }
            , Cmd.none
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


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    let
        ({ t, isDark } as userConfig) =
            getUserConfig model.localStorage
        
        darkClass =
            if isDark then "dark" else ""
    in
    { title = t.appTitle
    , body =
        [ div [ class darkClass ]
            [ div [ class "min-h-screen bg-gradient-to-br from-purple-400 via-pink-500 to-red-500 dark:from-purple-900 dark:via-pink-900 dark:to-red-900 transition-colors duration-300" ]
                [ div [ class "container mx-auto px-4 py-8" ]
                    [ -- Header with language and theme switchers
                      viewHeader userConfig model
                    
                    -- Main content
                    , div [ class "text-center mb-12 mt-8" ]
                        [ img [ Attr.src "https://lamdera.app/lamdera-logo-black.png", class "h-20 mx-auto mb-8 drop-shadow-lg dark:invert" ] []
                        , h1 [ class "text-5xl font-bold text-white mb-4 drop-shadow-lg" ] 
                            [ text t.appTitle ]
                        , p [ class "text-xl text-white/90" ] 
                            [ text t.welcome ]
                        ]
                    
                    -- Cards Section
                    , div [ class "grid md:grid-cols-3 gap-6 mb-12" ]
                        [ -- Card 1
                          viewCard "🚀" t.fastDevelopment t.fastDevelopmentDesc "purple"
                        
                        -- Card 2
                        , viewCard "🎨" t.beautifulDesign t.beautifulDesignDesc "pink"
                        
                        -- Card 3
                        , viewCard "⚡" t.hotReload t.hotReloadDesc "red"
                        ]
                    
                    -- Button Examples
                    , div [ class "text-center space-y-4" ]
                        [ h2 [ class "text-3xl font-bold text-white mb-6" ] [ text t.buttonExamples ]
                        , div [ class "flex flex-wrap gap-4 justify-center" ]
                            [ button [ class "px-6 py-3 bg-blue-500 dark:bg-blue-600 text-white font-semibold rounded-lg shadow-md hover:bg-blue-700 dark:hover:bg-blue-800 transform hover:scale-105 transition-all duration-200" ]
                                [ text t.primaryButton ]
                            , button [ class "px-6 py-3 bg-green-500 dark:bg-green-600 text-white font-semibold rounded-lg shadow-md hover:bg-green-700 dark:hover:bg-green-800 transform hover:scale-105 transition-all duration-200" ]
                                [ text t.successButton ]
                            , button [ class "px-6 py-3 bg-gray-800 dark:bg-gray-700 text-white font-semibold rounded-lg shadow-md hover:bg-gray-900 dark:hover:bg-gray-600 transform hover:scale-105 transition-all duration-200" ]
                                [ text t.darkButton ]
                            , button [ class "px-6 py-3 bg-white dark:bg-gray-200 text-purple-600 dark:text-purple-700 font-semibold rounded-lg shadow-md hover:bg-gray-100 dark:hover:bg-gray-300 transform hover:scale-105 transition-all duration-200" ]
                                [ text t.lightButton ]
                            ]
                        ]
                    
                    -- Footer
                    , div [ class "mt-16 text-center text-white/80" ]
                        [ p [ class "mb-2" ] [ text t.editMessage ]
                        , p [ class "text-sm" ] 
                            [ text t.tailwindMessage ]
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
            [ h1 [ class "text-2xl font-bold text-white" ] [ text t.appTitle ]
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
                t.english 
            else 
                t.french)
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
                    t.lightTheme

                DarkMode ->
                    t.darkTheme

                SystemMode ->
                    t.systemTheme
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