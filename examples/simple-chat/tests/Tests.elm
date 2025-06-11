module Tests exposing (appTests, tests)

import Backend
import Effect.Browser.Dom as Dom
import Effect.Lamdera exposing (sessionIdFromString)
import Effect.Test as TF exposing (HttpResponse(..))
import Frontend
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector
import Json.Decode
import Time
import Types exposing (..)
import Url


-- Collection of all tests
appTests : Test
appTests =
    describe "Chat App Tests" (List.map TF.toTest tests)


tests : List (TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    [ testUserCanSetUsername
    , testUserCanSendMessage
    , testMultipleUsersCanChat
    ]


{-| Test 1: User can set a username
-}
testUserCanSetUsername : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testUserCanSetUsername =
    TF.start
        "User can set username"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend
            0
            (sessionIdFromString "alice")
            "/"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Initially should see username form
                  alice.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Enter your username" ]
                    )
                
                -- Type username
                , alice.input 200 (Dom.id "username-input") "Alice"
                
                -- Click join chat button
                , alice.click 300 (Dom.id "join-chat-button")
                
                -- Should see chat interface
                , alice.checkView
                    400
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Welcome, Alice!" ]
                    )
                ]
            )
        ]


{-| Test 2: User can send a message
-}
testUserCanSendMessage : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testUserCanSendMessage =
    TF.start
        "User can send message"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend
            0
            (sessionIdFromString "bob")
            "/"
            { width = 1024, height = 768 }
            (\bob ->
                [ -- Set username first
                  bob.input 100 (Dom.id "username-input") "Bob"
                , bob.click 200 (Dom.id "join-chat-button")
                
                -- Type a message
                , bob.input 300 (Dom.id "message-input") "Hello, world!"
                
                -- Send the message
                , bob.click 400 (Dom.id "send-button")
                
                -- Should see the message in chat
                , bob.checkView
                    500
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Bob"
                        , Test.Html.Selector.text "Hello, world!"
                        ]
                    )
                ]
            )
        ]


{-| Test 3: Multiple users can chat with each other
-}
testMultipleUsersCanChat : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testMultipleUsersCanChat =
    TF.start
        "Multiple users can chat"
        (Time.millisToPosix 0)
        config
        [ -- Alice joins
          TF.connectFrontend
            0
            (sessionIdFromString "alice")
            "/"
            { width = 1024, height = 768 }
            (\alice ->
                [ alice.input 100 (Dom.id "username-input") "Alice"
                , alice.click 200 (Dom.id "join-chat-button")
                , alice.input 300 (Dom.id "message-input") "Hi everyone!"
                , alice.click 400 (Dom.id "send-button")
                ]
            )
        
        -- Bob joins
        , TF.connectFrontend
            500
            (sessionIdFromString "bob")
            "/"
            { width = 1024, height = 768 }
            (\bob ->
                [ bob.input 600 (Dom.id "username-input") "Bob"
                , bob.click 700 (Dom.id "join-chat-button")
                
                -- Bob should see Alice's message
                , bob.checkView
                    800
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Alice"
                        , Test.Html.Selector.text "Hi everyone!"
                        ]
                    )
                
                -- Bob sends a reply
                , bob.input 900 (Dom.id "message-input") "Hello Alice!"
                , bob.click 1000 (Dom.id "send-button")
                ]
            )
        
        -- Check that Alice sees Bob's message by connecting Alice again
        , TF.connectFrontend
            1200
            (sessionIdFromString "alice-check")
            "/"
            { width = 1024, height = 768 }
            (\aliceCheck ->
                [ aliceCheck.input 1300 (Dom.id "username-input") "Alice"
                , aliceCheck.click 1400 (Dom.id "join-chat-button")
                
                -- Alice should see both messages
                , aliceCheck.checkView
                    1500
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Alice"
                        , Test.Html.Selector.text "Hi everyone!"
                        , Test.Html.Selector.text "Bob"
                        , Test.Html.Selector.text "Hello Alice!"
                        ]
                    )
                ]
            )
        ]


{-| Configuration for lamdera-program-test
-}
config : TF.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
config =
    TF.Config
        Frontend.app_
        Backend.app_
        handleHttpRequest
        handlePortToJs
        handleFileUpload
        handleMultipleFilesUpload
        testUrl


testUrl : Url.Url
testUrl =
    { protocol = Url.Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/"
    , query = Nothing
    , fragment = Nothing
    }


handleHttpRequest : { a | currentRequest : TF.HttpRequest } -> HttpResponse
handleHttpRequest _ =
    NetworkErrorResponse


handlePortToJs : { a | currentRequest : TF.PortToJs } -> Maybe ( String, Json.Decode.Value )
handlePortToJs _ =
    Nothing


handleFileUpload : { a | mimeTypes : List String } -> TF.FileUpload
handleFileUpload _ =
    TF.UnhandledFileUpload


handleMultipleFilesUpload : { a | mimeTypes : List String } -> TF.MultipleFilesUpload
handleMultipleFilesUpload _ =
    TF.UnhandledMultiFileUpload