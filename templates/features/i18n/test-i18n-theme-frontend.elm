module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Effect.Browser.Navigation as Nav exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import Effect.Subscription as Subscription exposing (Subscription)
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
viewThemeButton ({ c, t } as userConfig) currentPreference targetPreference icon =
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
        [ Attr.style "max-width" "600px"
        , Attr.style "margin" "40px auto"
        , Attr.style "padding" "20px"
        , Attr.style "text-align" "center"
        ]
        [ h1 [] [ text ("🔄 " ++ t.counter) ]
        , p [ Attr.style "color" c.textSecondary, Attr.style "margin-bottom" "30px" ] 
            [ text t.welcome ]
        
        -- Counter Display
        , div 
            [ Attr.style "background" c.cardBackground
            , Attr.style "border-radius" "12px"
            , Attr.style "padding" "40px"
            , Attr.style "margin-bottom" "30px"
            , Attr.style "box-shadow" "0 2px 4px rgba(0,0,0,0.1)"
            ]
            [ div 
                [ Attr.style "font-size" "72px"
                , Attr.style "font-weight" "bold"
                , Attr.style "color" c.text
                , Attr.style "margin-bottom" "20px"
                , Attr.id "counter-value"
                ]
                [ text (String.fromInt model.counter) ]
            
            -- Buttons
            , div [ Attr.style "display" "flex", Attr.style "gap" "20px", Attr.style "justify-content" "center" ]
                [ button 
                    [ onClick Decrement
                    , Attr.style "font-size" "24px"
                    , Attr.style "padding" "10px 30px"
                    , Attr.style "border" "none"
                    , Attr.style "border-radius" "8px"
                    , Attr.style "background" c.danger
                    , Attr.style "color" "white"
                    , Attr.style "cursor" "pointer"
                    , Attr.id "decrement-button"
                    ]
                    [ text t.decrement ]
                
                , button 
                    [ onClick Increment
                    , Attr.style "font-size" "24px"
                    , Attr.style "padding" "10px 30px"
                    , Attr.style "border" "none"
                    , Attr.style "border-radius" "8px"
                    , Attr.style "background" c.success
                    , Attr.style "color" "white"
                    , Attr.style "cursor" "pointer"
                    , Attr.id "increment-button"
                    ]
                    [ text t.increment ]
                ]
            ]
        
        -- Last Update Info
        , div [ Attr.style "color" c.textSecondary, Attr.style "font-size" "14px" ]
            [ text <|
                if model.clientId == "waiting..." then
                    t.waitingForUpdate
                else if model.clientId == "" then
                    t.counterInitialized
                else
                    t.lastUpdatedBy ++ ": " ++ model.clientId
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