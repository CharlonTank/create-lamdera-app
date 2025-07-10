module Pages.Admin exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import I18n exposing (Translations)
import RemoteData exposing (RemoteData)
import Types exposing (..)


view : Translations -> FrontendModel -> Html FrontendMsg
view _ model =
    case model.currentUser of
        Nothing ->
            -- Not logged in - redirect to login
            div [ class "max-w-md mx-auto" ]
                [ div [ class "bg-white/20 dark:bg-black/30 backdrop-blur-md rounded-lg p-8 shadow-xl text-center" ]
                    [ h2 [ class "text-2xl font-bold text-white mb-4" ]
                        [ text "Access Denied" ]
                    , p [ class "text-white/80 mb-6" ]
                        [ text "You must be logged in to access the admin panel." ]
                    , a [ href "/login", class "bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded transition-colors" ]
                        [ text "Go to Login" ]
                    ]
                ]

        Just userInfo ->
            -- Check if user is admin (check if email is admin@example.com)
            if userInfo.email == "admin@example.com" then
                viewAdminPanel model

            else
                div [ class "max-w-md mx-auto" ]
                    [ div [ class "bg-white/20 dark:bg-black/30 backdrop-blur-md rounded-lg p-8 shadow-xl text-center" ]
                        [ h2 [ class "text-2xl font-bold text-white mb-4" ]
                            [ text "Access Denied" ]
                        , p [ class "text-white/80 mb-6" ]
                            [ text "You don't have admin privileges." ]
                        , a [ href "/", class "bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded transition-colors" ]
                            [ text "Go Home" ]
                        ]
                    ]


getCounterValue : RemoteData String Int -> String
getCounterValue counter =
    case counter of
        RemoteData.NotAsked ->
            "..."

        RemoteData.Loading ->
            "Loading..."

        RemoteData.Failure _ ->
            "Error"

        RemoteData.Success value ->
            String.fromInt value


getUserCount : RemoteData String (List User) -> String
getUserCount users =
    case users of
        RemoteData.NotAsked ->
            "..."

        RemoteData.Loading ->
            "Loading..."

        RemoteData.Failure _ ->
            "Error"

        RemoteData.Success userList ->
            String.fromInt (List.length userList)


viewAdminPanel : FrontendModel -> Html FrontendMsg
viewAdminPanel model =
    div [ class "max-w-4xl mx-auto" ]
        [ div [ class "bg-white/20 dark:bg-black/30 backdrop-blur-md rounded-lg p-8 shadow-xl" ]
            [ h1 [ class "text-3xl font-bold text-white mb-8 text-center" ]
                [ text "🛠️ Admin Panel" ]

            -- Admin Stats
            , div [ class "grid grid-cols-1 md:grid-cols-3 gap-6 mb-8" ]
                [ viewStatCard "👥" "Total Users" (getUserCount model.adminUsers) "All registered users"
                , viewStatCard "💬" "Chat Messages" (String.fromInt (List.length model.chatMessages)) "Total messages sent"
                , viewStatCard "🔄" "Counter Value" (getCounterValue model.counter) "Current counter state"
                ]

            -- Admin Actions
            , div [ class "space-y-6" ]
                [ h2 [ class "text-2xl font-bold text-white mb-4" ]
                    [ text "Admin Actions" ]
                , div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]
                    [ button
                        [ class "bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-lg transition-colors font-semibold"
                        , onClick (LoggedInAdminFrontendMsg ResetCounter)
                        ]
                        [ text "🔄 Reset Counter" ]
                    , button
                        [ class "bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-lg transition-colors font-semibold"
                        , onClick (LoggedInAdminFrontendMsg ClearChatMessages)
                        ]
                        [ text "🗑️ Clear Chat Messages" ]
                    , button
                        [ class "bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors font-semibold"
                        , onClick (LoggedInAdminFrontendMsg SendTestEmail)
                        ]
                        [ text "📧 Send Test Email" ]
                    ]
                ]

            -- Users Management
            , div [ class "space-y-4" ]
                [ h2 [ class "text-2xl font-bold text-white mb-4" ]
                    [ text "👥 Users Management" ]
                , viewUsersRemoteData model.adminUsers model.editingUser
                ]

            -- Messages Management
            , div [ class "space-y-4" ]
                [ h2 [ class "text-2xl font-bold text-white mb-4" ]
                    [ text "💬 Messages Management" ]
                , viewMessagesRemoteData model.adminMessages model.editingMessage
                ]

            -- Current User Info
            , case model.currentUser of
                Just userInfo ->
                    div [ class "mt-8 p-4 bg-white/10 rounded-lg" ]
                        [ h3 [ class "text-lg font-semibold text-white mb-2" ]
                            [ text "Current Admin User" ]
                        , p [ class "text-white/80" ]
                            [ text ("Email: " ++ userInfo.email) ]
                        , case userInfo.name of
                            Just name ->
                                p [ class "text-white/80" ]
                                    [ text ("Name: " ++ name) ]

                            Nothing ->
                                text ""
                        ]

                Nothing ->
                    text ""
            ]
        ]


viewStatCard : String -> String -> String -> String -> Html msg
viewStatCard icon title value description =
    div [ class "bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20" ]
        [ div [ class "flex items-center justify-between mb-2" ]
            [ span [ class "text-2xl" ] [ text icon ]
            , span [ class "text-2xl font-bold text-white" ] [ text value ]
            ]
        , h3 [ class "text-lg font-semibold text-white mb-1" ]
            [ text title ]
        , p [ class "text-white/60 text-sm" ]
            [ text description ]
        ]


viewUsersTable : List User -> Maybe ( Email, User ) -> Html FrontendMsg
viewUsersTable users editingUser =
    div [ class "bg-white/10 backdrop-blur-sm rounded-lg p-4 border border-white/20" ]
        [ if List.isEmpty users then
            p [ class "text-white/60 text-center py-4" ]
                [ text "No users found" ]

          else
            div [ class "overflow-x-auto" ]
                [ table [ class "w-full text-white" ]
                    [ thead []
                        [ tr [ class "border-b border-white/20" ]
                            [ th [ class "text-left py-2 px-3" ] [ text "Profile" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Email" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Name" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Username" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Admin" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody []
                        (List.map (viewUserRow editingUser) users)
                    ]
                ]
        ]


viewUserRow : Maybe ( Email, User ) -> User -> Html FrontendMsg
viewUserRow editingUser user =
    case editingUser of
        Just ( editEmail, editUser ) ->
            if editEmail == user.email then
                viewUserEditRow editUser

            else
                viewUserDisplayRow user

        Nothing ->
            viewUserDisplayRow user


viewUserDisplayRow : User -> Html FrontendMsg
viewUserDisplayRow user =
    tr [ class "border-b border-white/10" ]
        [ td [ class "py-2 px-3" ]
            [ case user.profilePicture of
                Just picture ->
                    img
                        [ src picture
                        , alt "Profile"
                        , class "w-8 h-8 rounded-full object-cover"
                        ]
                        []

                Nothing ->
                    -- Default avatar with first letter
                    div
                        [ class "w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center text-white font-semibold text-xs"
                        ]
                        [ text (String.left 1 (Maybe.withDefault user.email user.username) |> String.toUpper) ]
            ]
        , td [ class "py-2 px-3" ] [ text user.email ]
        , td [ class "py-2 px-3" ] [ text (Maybe.withDefault "-" user.name) ]
        , td [ class "py-2 px-3" ] [ text (Maybe.withDefault "-" user.username) ]
        , td [ class "py-2 px-3" ]
            [ if user.isAdmin then
                span [ class "bg-green-600 text-white px-2 py-1 rounded text-xs" ] [ text "Admin" ]

              else
                span [ class "bg-gray-600 text-white px-2 py-1 rounded text-xs" ] [ text "User" ]
            ]
        , td [ class "py-2 px-3" ]
            [ div [ class "flex gap-2" ]
                [ button
                    [ class "bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg (StartEditingUser user.email user))
                    , id ("edit-user-" ++ user.email)
                    ]
                    [ text "✏️ Edit" ]
                , button
                    [ class "bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg (AdminDeleteUser user.email))
                    , id ("delete-user-" ++ user.email)
                    ]
                    [ text "🗑️ Delete" ]
                ]
            ]
        ]


viewUserEditRow : User -> Html FrontendMsg
viewUserEditRow user =
    tr [ class "border-b border-white/10 bg-blue-900/20" ]
        [ td [ class "py-2 px-3" ]
            [ case user.profilePicture of
                Just picture ->
                    img
                        [ src picture
                        , alt "Profile"
                        , class "w-8 h-8 rounded-full object-cover"
                        ]
                        []

                Nothing ->
                    -- Default avatar with first letter
                    div
                        [ class "w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center text-white font-semibold text-xs"
                        ]
                        [ text (String.left 1 (Maybe.withDefault user.email user.username) |> String.toUpper) ]
            ]
        , td [ class "py-2 px-3" ] [ text user.email ]
        , td [ class "py-2 px-3" ]
            [ input
                [ type_ "text"
                , value (Maybe.withDefault "" user.name)
                , class "bg-white/10 text-white px-2 py-1 rounded text-sm w-full"
                , placeholder "Name"
                , id ("edit-user-name-" ++ user.email)
                , onInput
                    (\newName ->
                        LoggedInAdminFrontendMsg
                            (StartEditingUser user.email
                                { user
                                    | name =
                                        if String.trim newName == "" then
                                            Nothing

                                        else
                                            Just newName
                                }
                            )
                    )
                ]
                []
            ]
        , td [ class "py-2 px-3" ]
            [ input
                [ type_ "text"
                , value (Maybe.withDefault "" user.username)
                , class "bg-white/10 text-white px-2 py-1 rounded text-sm w-full"
                , placeholder "Username"
                , id ("edit-user-username-" ++ user.email)
                , onInput
                    (\newUsername ->
                        LoggedInAdminFrontendMsg
                            (StartEditingUser user.email
                                { user
                                    | username =
                                        if String.trim newUsername == "" then
                                            Nothing

                                        else
                                            Just newUsername
                                }
                            )
                    )
                ]
                []
            ]
        , td [ class "py-2 px-3" ]
            [ if user.isAdmin then
                span [ class "bg-green-600 text-white px-2 py-1 rounded text-xs" ] [ text "Admin" ]

              else
                span [ class "bg-gray-600 text-white px-2 py-1 rounded text-xs" ] [ text "User" ]
            ]
        , td [ class "py-2 px-3" ]
            [ div [ class "flex gap-2" ]
                [ button
                    [ class "bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg (SaveUserEdit user.email user))
                    ]
                    [ text "💾 Save" ]
                , button
                    [ class "bg-gray-600 hover:bg-gray-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg CancelEditing)
                    ]
                    [ text "❌ Cancel" ]
                ]
            ]
        ]


viewMessagesTable : List ChatMessage -> Maybe ( String, ChatMessage ) -> Html FrontendMsg
viewMessagesTable messages editingMessage =
    div [ class "bg-white/10 backdrop-blur-sm rounded-lg p-4 border border-white/20" ]
        [ if List.isEmpty messages then
            p [ class "text-white/60 text-center py-4" ]
                [ text "No messages found" ]

          else
            div [ class "overflow-x-auto" ]
                [ table [ class "w-full text-white" ]
                    [ thead []
                        [ tr [ class "border-b border-white/20" ]
                            [ th [ class "text-left py-2 px-3" ] [ text "ID" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Author" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Email" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Content" ]
                            , th [ class "text-left py-2 px-3" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody []
                        (List.map (viewMessageRow editingMessage) messages)
                    ]
                ]
        ]


viewMessageRow : Maybe ( String, ChatMessage ) -> ChatMessage -> Html FrontendMsg
viewMessageRow editingMessage message =
    case editingMessage of
        Just ( editId, editMessage ) ->
            if editId == message.id then
                viewMessageEditRow editMessage

            else
                viewMessageDisplayRow message

        Nothing ->
            viewMessageDisplayRow message


viewMessageDisplayRow : ChatMessage -> Html FrontendMsg
viewMessageDisplayRow message =
    tr [ class "border-b border-white/10" ]
        [ td [ class "py-2 px-3 text-xs" ] [ text message.id ]
        , td [ class "py-2 px-3" ] [ text message.author ]
        , td [ class "py-2 px-3 text-sm" ] [ text message.authorEmail ]
        , td [ class "py-2 px-3 max-w-xs truncate" ] [ text message.content ]
        , td [ class "py-2 px-3" ]
            [ div [ class "flex gap-2" ]
                [ button
                    [ class "bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg (StartEditingMessage message.id message))
                    , id ("edit-message-" ++ message.id)
                    ]
                    [ text "✏️ Edit" ]
                , button
                    [ class "bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg (AdminDeleteMessage message.id))
                    , id ("delete-message-" ++ message.id)
                    ]
                    [ text "🗑️ Delete" ]
                ]
            ]
        ]


viewMessageEditRow : ChatMessage -> Html FrontendMsg
viewMessageEditRow message =
    tr [ class "border-b border-white/10 bg-blue-900/20" ]
        [ td [ class "py-2 px-3 text-xs" ] [ text message.id ]
        , td [ class "py-2 px-3" ] [ text message.author ]
        , td [ class "py-2 px-3 text-sm" ] [ text message.authorEmail ]
        , td [ class "py-2 px-3" ]
            [ input
                [ type_ "text"
                , value message.content
                , class "bg-white/10 text-white px-2 py-1 rounded text-sm w-full"
                , placeholder "Message content"
                , id ("edit-message-content-" ++ message.id)
                , onInput (\newContent -> LoggedInAdminFrontendMsg (StartEditingMessage message.id { message | content = newContent }))
                ]
                []
            ]
        , td [ class "py-2 px-3" ]
            [ div [ class "flex gap-2" ]
                [ button
                    [ class "bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg (SaveMessageEdit message.id message))
                    ]
                    [ text "💾 Save" ]
                , button
                    [ class "bg-gray-600 hover:bg-gray-700 text-white px-3 py-1 rounded text-xs transition-colors"
                    , onClick (LoggedInAdminFrontendMsg CancelEditing)
                    ]
                    [ text "❌ Cancel" ]
                ]
            ]
        ]


{-| View users table with RemoteData handling
-}
viewUsersRemoteData : RemoteData String (List User) -> Maybe ( Email, User ) -> Html FrontendMsg
viewUsersRemoteData usersRemoteData editingUser =
    case usersRemoteData of
        RemoteData.NotAsked ->
            div [ class "bg-white/10 backdrop-blur-sm rounded-lg p-4 border border-white/20" ]
                [ p [ class "text-white/60 text-center py-4" ]
                    [ text "Users data not requested yet" ]
                ]

        RemoteData.Loading ->
            div [ class "bg-white/10 backdrop-blur-sm rounded-lg p-4 border border-white/20" ]
                [ p [ class "text-white/60 text-center py-4" ]
                    [ text "Loading users..." ]
                ]

        RemoteData.Failure error ->
            div [ class "bg-red-500/20 backdrop-blur-sm rounded-lg p-4 border border-red-500/50" ]
                [ p [ class "text-red-200 text-center py-4" ]
                    [ text ("Error loading users: " ++ error) ]
                ]

        RemoteData.Success users ->
            viewUsersTable users editingUser


{-| View messages table with RemoteData handling
-}
viewMessagesRemoteData : RemoteData String (List ChatMessage) -> Maybe ( String, ChatMessage ) -> Html FrontendMsg
viewMessagesRemoteData messagesRemoteData editingMessage =
    case messagesRemoteData of
        RemoteData.NotAsked ->
            div [ class "bg-white/10 backdrop-blur-sm rounded-lg p-4 border border-white/20" ]
                [ p [ class "text-white/60 text-center py-4" ]
                    [ text "Messages data not requested yet" ]
                ]

        RemoteData.Loading ->
            div [ class "bg-white/10 backdrop-blur-sm rounded-lg p-4 border border-white/20" ]
                [ p [ class "text-white/60 text-center py-4" ]
                    [ text "Loading messages..." ]
                ]

        RemoteData.Failure error ->
            div [ class "bg-red-500/20 backdrop-blur-sm rounded-lg p-4 border border-red-500/50" ]
                [ p [ class "text-red-200 text-center py-4" ]
                    [ text ("Error loading messages: " ++ error) ]
                ]

        RemoteData.Success messages ->
            viewMessagesTable messages editingMessage
