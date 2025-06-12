module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Effect.Browser.Navigation as Nav exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import Effect.Subscription as Subscription exposing (Subscription)
import Html exposing (..)
import Html.Attributes as Attr exposing (class, style)
import Html.Events exposing (onClick)
import Lamdera
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
      , counter = 0
      , clientId = "waiting..."
      }
    , sendToBackend GetCounter
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
    Subscription.none


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Lamdera Counter Example"
    , body =
        [ div 
            [ style "font-family" "system-ui, -apple-system, sans-serif"
            , style "max-width" "600px"
            , style "margin" "40px auto"
            , style "padding" "20px"
            , style "text-align" "center"
            ]
            [ h1 [] [ text "🔄 Synchronized Counter" ]
            , p [ style "color" "#666", style "margin-bottom" "30px" ] 
                [ text "Open this in multiple browser windows to see real-time synchronization!" ]
            
            -- Counter Display
            , div 
                [ style "background" "#f0f0f0"
                , style "border-radius" "12px"
                , style "padding" "40px"
                , style "margin-bottom" "30px"
                ]
                [ div 
                    [ style "font-size" "72px"
                    , style "font-weight" "bold"
                    , style "color" "#333"
                    , style "margin-bottom" "20px"
                    , Attr.id "counter-value"
                    ]
                    [ text (String.fromInt model.counter) ]
                
                -- Buttons
                , div [ style "display" "flex", style "gap" "20px", style "justify-content" "center" ]
                    [ button 
                        [ onClick Decrement
                        , style "font-size" "24px"
                        , style "padding" "10px 30px"
                        , style "border" "none"
                        , style "border-radius" "8px"
                        , style "background" "#dc3545"
                        , style "color" "white"
                        , style "cursor" "pointer"
                        , Attr.id "decrement-button"
                        ]
                        [ text "−" ]
                    
                    , button 
                        [ onClick Increment
                        , style "font-size" "24px"
                        , style "padding" "10px 30px"
                        , style "border" "none"
                        , style "border-radius" "8px"
                        , style "background" "#28a745"
                        , style "color" "white"
                        , style "cursor" "pointer"
                        , Attr.id "increment-button"
                        ]
                        [ text "+" ]
                    ]
                ]
            
            -- Last Update Info
            , div [ style "color" "#999", style "font-size" "14px" ]
                [ text <|
                    if model.clientId == "waiting..." then
                        "Waiting for first update..."
                    else if model.clientId == "" then
                        "Counter initialized"
                    else
                        "Last updated by: " ++ model.clientId
                ]
            
            -- Instructions
            , div 
                [ style "margin-top" "40px"
                , style "padding" "20px"
                , style "background" "#e8f4f8"
                , style "border-radius" "8px"
                , style "text-align" "left"
                ]
                [ h3 [ style "margin-top" "0" ] [ text "🧪 Testing this app" ]
                , p [] [ text "This app includes test templates using lamdera-program-test." ]
                , p [] [ text "To run the tests:" ]
                , pre 
                    [ style "background" "#f5f5f5"
                    , style "padding" "10px"
                    , style "border-radius" "4px"
                    , style "overflow-x" "auto"
                    ]
                    [ text "elm-test-rs --compiler /opt/homebrew/bin/lamdera" ]
                , p [ style "margin-bottom" "0" ] 
                    [ text "Check out "
                    , code [] [ text "tests/Tests.elm" ]
                    , text " to see the tests in action!"
                    ]
                ]
            ]
        ]
    }