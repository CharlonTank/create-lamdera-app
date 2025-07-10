module Pages.Chat exposing (view)

import Auth.Common
import Html exposing (..)
import Html.Attributes as Attr exposing (class, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import I18n exposing (Translations)
import Time
import Types exposing (..)


view : Translations -> FrontendModel -> Html FrontendMsg
view _ model =
    div []
        [ div [ class "text-center mb-8 mt-8" ]
            [ h1 [ class "text-5xl font-bold text-white mb-4 drop-shadow-lg" ]
                [ text "💬 Chat" ]
            , p [ class "text-xl text-white/90" ]
                [ text "Real-time chat with other users" ]
            ]

        -- Check if user is logged in
        , case model.currentUser of
            Nothing ->
                -- Not logged in - show login requirement
                div [ class "max-w-md mx-auto" ]
                    [ div [ class "bg-white/20 dark:bg-black/30 backdrop-blur-md rounded-lg p-8 shadow-xl text-center" ]
                        [ h2 [ class "text-2xl font-bold text-white mb-4" ]
                            [ text "🔒 Private Chat" ]
                        , p [ class "text-white/80 mb-6" ]
                            [ text "Chat is only for logged in users. Please log in to access the chat." ]
                        , div [ class "flex gap-4 justify-center" ]
                            [ a [ Attr.href "/login", class "bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded transition-colors" ]
                                [ text "Login" ]
                            , a [ Attr.href "/register", class "bg-purple-600 hover:bg-purple-700 text-white px-6 py-2 rounded transition-colors" ]
                                [ text "Register" ]
                            ]
                        ]
                    ]

            Just userInfo ->
                -- Logged in - show chat interface
                viewChatInterface model userInfo model.timezone
        ]


viewChatInterface : FrontendModel -> Auth.Common.UserInfo -> Time.Zone -> Html FrontendMsg
viewChatInterface model userInfo timezone =
    -- Chat Container
    div [ class "max-w-4xl mx-auto" ]
        [ div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl overflow-hidden" ]
            [ -- Chat Header
              div [ class "bg-purple-600 dark:bg-purple-700 px-6 py-4" ]
                [ h2 [ class "text-xl font-semibold text-white" ]
                    [ text "💬 Live Chat" ]
                , p [ class "text-purple-100 text-sm" ]
                    [ text ("Connected as: " ++ Maybe.withDefault userInfo.email userInfo.username) ]
                ]

            -- Messages Area
            , div
                [ class "h-96 overflow-y-auto p-4 space-y-3"
                , Attr.id "chat-messages"
                ]
                (if List.isEmpty model.chatMessages then
                    [ div [ class "text-center text-gray-500 dark:text-gray-400 mt-8" ]
                        [ text "🌟 No messages yet. Be the first to say hello!" ]
                    ]

                 else
                    List.map (viewMessage userInfo.email timezone) model.chatMessages
                )

            -- Message Input
            , div [ class "border-t dark:border-gray-700 p-4" ]
                [ Html.form
                    [ onSubmit (LoggedInUserFrontendMsg SendChatMessage)
                    , class "flex gap-3"
                    ]
                    [ input
                        [ type_ "text"
                        , value model.chatInput
                        , onInput (\input -> LoggedInUserFrontendMsg (UpdateChatInput input))
                        , placeholder "Type your message..."
                        , class "flex-1 px-4 py-2 border dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
                        , Attr.id "chat-input"
                        ]
                        []
                    , button
                        [ type_ "submit"
                        , onClick (LoggedInUserFrontendMsg SendChatMessage)
                        , class "px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 transition-colors duration-200"
                        , Attr.id "send-button"
                        , Attr.disabled (String.trim model.chatInput == "")
                        ]
                        [ text "Send" ]
                    ]
                ]
            ]

        -- Chat Info
        , div [ class "mt-6 bg-white/10 dark:bg-black/20 backdrop-blur-md rounded-lg p-4" ]
            [ div [ class "flex items-center justify-between text-white/80 text-sm" ]
                [ span [] [ text ("Messages: " ++ String.fromInt (List.length model.chatMessages)) ]
                , span [] [ text "Messages sync in real-time across all connected clients" ]
                ]
            ]
        ]


viewMessage : String -> Time.Zone -> ChatMessage -> Html FrontendMsg
viewMessage currentUserEmail timezone message =
    let
        isOwnMessage =
            message.authorEmail == currentUserEmail

        messageClass =
            if isOwnMessage then
                "ml-auto bg-purple-600 text-white"

            else
                "mr-auto bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-white"
    in
    div
        [ class "flex"
        , class
            (if isOwnMessage then
                "justify-end"

             else
                "justify-start"
            )
        ]
        [ div
            [ class ("max-w-xs lg:max-w-md px-4 py-2 rounded-lg " ++ messageClass)
            , Attr.attribute "data-message-id" message.id
            ]
            [ if not isOwnMessage then
                div [ class "text-xs opacity-75 mb-1" ]
                    [ text message.author ]

              else
                text ""
            , div [ class "text-sm" ]
                [ text message.content ]
            , div [ class "text-xs opacity-60 mt-1" ]
                [ text (formatTime timezone message.timestamp) ]
            ]
        ]


formatTime : Time.Zone -> Time.Posix -> String
formatTime zone time =
    let
        hour =
            Time.toHour zone time

        minute =
            Time.toMinute zone time

        second =
            Time.toSecond zone time

        padZero num =
            if num < 10 then
                "0" ++ String.fromInt num

            else
                String.fromInt num
    in
    padZero hour ++ ":" ++ padZero minute ++ ":" ++ padZero second
