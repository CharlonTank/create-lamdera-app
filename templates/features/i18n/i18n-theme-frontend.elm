module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import I18n exposing (Language(..), Translation)
import Lamdera
import LocalStorage exposing (LocalStorage, LocalStorageUpdate(..))
import Theme exposing (Mode(..), Theme, UserPreference(..))
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
        ({ c, t } as userConfig) =
            getUserConfig model.localStorage
    in
    { title = t.appTitle
    , body =
        [ div
            [ Attr.style "background-color" c.background
            , Attr.style "color" c.text
            , Attr.style "min-height" "100vh"
            , Attr.style "font-family" "system-ui, -apple-system, sans-serif"
            ]
            [ viewHeader userConfig model
            , viewContent userConfig model
            ]
        ]
    }


viewHeader : UserConfig -> FrontendModel -> Html FrontendMsg
viewHeader userConfig model =
    div
        [ Attr.style "background-color" c.secondaryBackground
        , Attr.style "padding" "1rem"
        , Attr.style "border-bottom" ("1px solid " ++ c.border)
        ]
        [ div
            [ Attr.style "max-width" "1200px"
            , Attr.style "margin" "0 auto"
            , Attr.style "display" "flex"
            , Attr.style "justify-content" "space-between"
            , Attr.style "align-items" "center"
            ]
            [ h1 [ Attr.style "margin" "0" ] [ text t.appTitle ]
            , div [ Attr.style "display" "flex", Attr.style "gap" "1rem" ]
                [ viewLanguageSelector userConfig model.localStorage.language
                , viewThemeSelector userConfig model.localStorage.userPreference
                ]
            ]
        ]


viewLanguageSelector : UserConfig -> Language -> Html FrontendMsg
viewLanguageSelector userConfig currentLanguage =
    div [ Attr.style "display" "flex", Attr.style "gap" "0.5rem" ]
        [ button
            [ onClick (ChangeLanguage EN)
            , Attr.style "padding" "0.5rem 1rem"
            , Attr.style "border" "none"
            , Attr.style "border-radius" "4px"
            , Attr.style "cursor" "pointer"
            , Attr.style "background-color"
                (if currentLanguage == EN then
                    c.primary

                 else
                    c.secondaryBackground
                )
            , Attr.style "color"
                (if currentLanguage == EN then
                    "#fff"

                 else
                    c.text
                )
            ]
            [ text t.english ]
        , button
            [ onClick (ChangeLanguage FR)
            , Attr.style "padding" "0.5rem 1rem"
            , Attr.style "border" "none"
            , Attr.style "border-radius" "4px"
            , Attr.style "cursor" "pointer"
            , Attr.style "background-color"
                (if currentLanguage == FR then
                    c.primary

                 else
                    c.secondaryBackground
                )
            , Attr.style "color"
                (if currentLanguage == FR then
                    "#fff"

                 else
                    c.text
                )
            ]
            [ text t.french ]
        ]


viewThemeSelector : UserConfig -> UserPreference -> Html FrontendMsg
viewThemeSelector userConfig currentPreference =
    div [ Attr.style "display" "flex", Attr.style "gap" "0.5rem" ]
        [ viewThemeButton userConfig currentPreference LightMode "☀️"
        , viewThemeButton userConfig currentPreference DarkMode "🌙"
        , viewThemeButton userConfig currentPreference SystemMode "🖥️"
        ]


viewThemeButton : UserConfig -> UserPreference -> UserPreference -> String -> Html FrontendMsg
viewThemeButton userConfig currentPreference targetPreference icon =
    button
        [ onClick (ChangeTheme targetPreference)
        , Attr.style "padding" "0.5rem"
        , Attr.style "border" "none"
        , Attr.style "border-radius" "4px"
        , Attr.style "cursor" "pointer"
        , Attr.style "font-size" "1.2rem"
        , Attr.style "background-color"
            (if currentPreference == targetPreference then
                c.primary

             else
                c.secondaryBackground
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


viewContent : UserConfig -> FrontendModel -> Html FrontendMsg
viewContent userConfig model =
    div
        [ Attr.style "max-width" "800px"
        , Attr.style "margin" "2rem auto"
        , Attr.style "padding" "0 1rem"
        , Attr.style "text-align" "center"
        ]
        [ img
            [ Attr.src
                (if Theme.getMode model.localStorage.userPreference model.localStorage.systemMode == Dark then
                    "https://lamdera.app/lamdera-logo-white.png"

                 else
                    "https://lamdera.app/lamdera-logo-black.png"
                )
            , Attr.width 150
            , Attr.style "margin-bottom" "2rem"
            ]
            []
        , h2 [] [ text t.welcome ]
        , p [ Attr.style "color" c.textSecondary ]
            [ text model.message ]
        , viewPreferences userConfig model
        ]


viewPreferences : UserConfig -> FrontendModel -> Html FrontendMsg
viewPreferences userConfig model =
    div
        [ Attr.style "margin-top" "3rem"
        , Attr.style "padding" "2rem"
        , Attr.style "background-color" c.cardBackground
        , Attr.style "border-radius" "8px"
        , Attr.style "box-shadow" "0 2px 4px rgba(0,0,0,0.1)"
        ]
        [ h3 [] [ text t.preferences ]
        , div [ Attr.style "margin-top" "1rem" ]
            [ p []
                [ strong [] [ text (t.language ++ ": ") ]
                , text
                    (case model.localStorage.language of
                        EN ->
                            t.english

                        FR ->
                            t.french
                    )
                ]
            , p []
                [ strong [] [ text (t.theme ++ ": ") ]
                , text
                    (case model.localStorage.userPreference of
                        LightMode ->
                            t.lightTheme

                        DarkMode ->
                            t.darkTheme

                        SystemMode ->
                            t.systemTheme
                    )
                ]
            ]
        ]


getUserConfig : LocalStorage -> UserConfig
getUserConfig localStorage =
    let
        mode =
            Theme.getMode localStorage.userPreference localStorage.systemMode
    in
    { t = I18n.translations localStorage.language
    , c = Theme.getTheme mode
    }