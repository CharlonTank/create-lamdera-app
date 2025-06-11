module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Effect.Browser.Navigation as Nav exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import Effect.Subscription as Subscription exposing (Subscription)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (..)
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
      , username = ""
      , currentMessage = ""
      , messages = []
      , isUsernameSet = False
      }
    , Command.none
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

        UsernameChanged newUsername ->
            ( { model | username = newUsername }, Command.none )

        SetUsername ->
            if String.trim model.username /= "" then
                ( { model | isUsernameSet = True }
                , sendToBackend (UserJoined model.username)
                )
            else
                ( model, Command.none )

        MessageChanged newMessage ->
            ( { model | currentMessage = newMessage }, Command.none )

        SendMessage ->
            if String.trim model.currentMessage /= "" && model.isUsernameSet then
                ( { model | currentMessage = "" }
                , sendToBackend (UserSentMessage model.username model.currentMessage)
                )
            else
                ( model, Command.none )

        NoOpFrontendMsg ->
            ( model, Command.none )


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case msg of
        NewMessage chatMessage ->
            ( { model | messages = model.messages ++ [chatMessage] }, Command.none )

        AllMessages messages ->
            ( { model | messages = messages }, Command.none )

        UserListUpdate users ->
            -- For now, we'll just ignore this, but we could show active users
            ( model, Command.none )


subscriptions : FrontendModel -> Subscription FrontendOnly FrontendMsg
subscriptions model =
    Subscription.none


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Simple Chat"
    , body =
        [ div [ style "font-family" "system-ui, -apple-system, sans-serif" ]
            [ if not model.isUsernameSet then
                usernameView model
              else
                chatView model
            ]
        ]
    }


usernameView : FrontendModel -> Html FrontendMsg
usernameView model =
    div 
        [ style "max-width" "400px"
        , style "margin" "100px auto"
        , style "padding" "40px"
        , style "border" "1px solid #ddd"
        , style "border-radius" "8px"
        , style "text-align" "center"
        ]
        [ h1 [] [ text "💬 Simple Chat" ]
        , p [ style "color" "#666" ] [ text "Enter your username to start chatting" ]
        , input
            [ type_ "text"
            , placeholder "Your username"
            , value model.username
            , onInput UsernameChanged
            , id "username-input"
            , style "width" "100%"
            , style "padding" "12px"
            , style "border" "1px solid #ddd"
            , style "border-radius" "4px"
            , style "margin-bottom" "16px"
            , style "font-size" "16px"
            ]
            []
        , button
            [ onClick SetUsername
            , id "join-chat-button"
            , style "width" "100%"
            , style "padding" "12px"
            , style "background-color" "#007bff"
            , style "color" "white"
            , style "border" "none"
            , style "border-radius" "4px"
            , style "font-size" "16px"
            , style "cursor" "pointer"
            ]
            [ text "Join Chat" ]
        ]


chatView : FrontendModel -> Html FrontendMsg
chatView model =
    div 
        [ style "max-width" "800px"
        , style "margin" "20px auto"
        , style "padding" "20px"
        ]
        [ -- Header
          div 
            [ style "background-color" "#f8f9fa"
            , style "padding" "20px"
            , style "border-radius" "8px 8px 0 0"
            , style "border-bottom" "1px solid #ddd"
            ]
            [ h1 [ style "margin" "0" ] [ text "💬 Simple Chat" ]
            , p [ style "margin" "5px 0 0 0", style "color" "#666" ] 
                [ text ("Welcome, " ++ model.username ++ "!") ]
            ]
        
        -- Messages
        , div 
            [ style "height" "400px"
            , style "overflow-y" "auto"
            , style "border" "1px solid #ddd"
            , style "border-top" "none"
            , style "padding" "20px"
            , style "background-color" "white"
            ]
            (if List.isEmpty model.messages then
                [ div [ style "text-align" "center", style "color" "#999", style "margin-top" "150px" ]
                    [ text "No messages yet. Be the first to say something!" ]
                ]
             else
                List.map messageView model.messages
            )
        
        -- Message input
        , div 
            [ style "display" "flex"
            , style "border" "1px solid #ddd"
            , style "border-top" "none"
            , style "border-radius" "0 0 8px 8px"
            ]
            [ input
                [ type_ "text"
                , placeholder "Type your message..."
                , value model.currentMessage
                , onInput MessageChanged
                , id "message-input"
                , style "flex" "1"
                , style "padding" "16px"
                , style "border" "none"
                , style "font-size" "16px"
                ]
                []
            , button
                [ onClick SendMessage
                , id "send-button"
                , style "padding" "16px 24px"
                , style "background-color" "#007bff"
                , style "color" "white"
                , style "border" "none"
                , style "cursor" "pointer"
                , style "font-size" "16px"
                ]
                [ text "Send" ]
            ]
        ]


messageView : ChatMessage -> Html FrontendMsg
messageView message =
    div 
        [ style "margin-bottom" "16px"
        , style "padding" "12px"
        , style "background-color" "#f8f9fa"
        , style "border-radius" "8px"
        ]
        [ div 
            [ style "font-weight" "bold"
            , style "color" "#007bff"
            , style "margin-bottom" "4px"
            ]
            [ text message.author ]
        , div [ style "color" "#333" ] [ text message.content ]
        ]