module Tests exposing (..)

{-| IMPORTANT: In tests, NEVER use .update() method!
Always use .click, .clickLink, .input, and other user interaction methods instead.
This ensures tests simulate real user behavior rather than bypassing the UI.
-}

import Backend
import Effect.Browser.Dom as Dom
import Effect.Lamdera exposing (sessionIdFromString)
import Effect.Test as TF exposing (HttpResponse(..))
import Env
import Frontend
import Json.Decode
import Password
import SeqDict as Dict
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector
import Time
import Types exposing (..)
import Url


{-| Standard delay constant for test timing
-}
delay : TF.DelayInMs
delay =
    100



{--FrontendActions contains the possible functions we can call on the client we just connected.

    import Effect.Test
    import Test exposing (Test)
    import Url

    config =
        { frontendApp = Frontend.appFunctions
        , backendApp = Backend.appFunctions
        , handleHttpRequest = always Effect.Test.UnhandledHttpRequest
        , handlePortToJs = always Nothing
        , handleFileUpload = always Effect.Test.UnhandledFileUpload
        , handleMultipleFilesUpload = always Effect.Test.UnhandledMultiFileUpload
        , domain = unsafeUrl "https://my-app.lamdera.app"
        }

    test : Test
    test =
        Effect.Test.start "myButton is clickable"
            |> Effect.Test.connectFrontend delay
                myDomain
                { width = 1920, height = 1080 }
                (\( state, frontendActions ) ->
                    -- frontendActions is a record we can use on this specific frontend we just connected
                    state
                        |> frontendActions.click delay htmlId = "myButton" }
                )
            |> Effect.Test.toTest

    unsafeUrl : String -> Url
    unsafeUrl urlText =
        case Url.fromString urlText of
            Just url ->
                url

            Nothing ->
                unsafeUrl urlText

type alias FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { clientId : ClientId
    , keyDown :
        DelayInMs
        -> HtmlId
        -> KeyEvent
        -> List KeyOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , keyUp :
        DelayInMs
        -> HtmlId
        -> KeyEvent
        -> List KeyOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerDown :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerUp :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerEnter :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerOut :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerCancel :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerMove :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerLeave :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , pointerOver :
        DelayInMs
        -> HtmlId
        -> PointerEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , touchStart :
        DelayInMs
        -> HtmlId
        -> TouchEvent
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , touchMove :
        DelayInMs
        -> HtmlId
        -> TouchEvent
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , touchEnd :
        DelayInMs
        -> HtmlId
        -> TouchEvent
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , touchCancel :
        DelayInMs
        -> HtmlId
        -> TouchEvent
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , mouseDown :
        DelayInMs
        -> HtmlId
        -> MouseEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , mouseUp :
        DelayInMs
        -> HtmlId
        -> MouseEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , mouseEnter :
        DelayInMs
        -> HtmlId
        -> MouseEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , mouseOut :
        DelayInMs
        -> HtmlId
        -> MouseEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , mouseMove :
        DelayInMs
        -> HtmlId
        -> MouseEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , mouseLeave :
        DelayInMs
        -> HtmlId
        -> MouseEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , mouseOver :
        DelayInMs
        -> HtmlId
        -> MouseEvent
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , wheel :
        DelayInMs
        -> HtmlId
        -> Float
        -> ( Float, Float )
        -> List WheelOptions
        -> List PointerOptions
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , focus :
        DelayInMs
        -> HtmlId
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , blur :
        DelayInMs
        -> HtmlId
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , click :
        DelayInMs
        -> HtmlId
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , input :
        DelayInMs
        -> HtmlId
        -> String
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickLink :
        DelayInMs
        -> String
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , resizeWindow :
        DelayInMs
        -> { width : Int, height : Int }
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , checkView :
        delay
        -> (Test.Html.Query.Single frontendMsg -> Expectation)
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , update :
        DelayInMs
        -> frontendMsg
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , sendToBackend :
        DelayInMs
        -> toBackend
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , snapshotView :
        DelayInMs
        -> { name : String }
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , checkModel :
        DelayInMs
        -> (frontendModel -> Result String ())
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , custom :
        DelayInMs
        -> HtmlId
        -> String
        -> Json.Encode.Value
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , portEvent :
        DelayInMs
        -> String
        -> Json.Encode.Value
        -> Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    }


{-| -}
type KeyOptions
    = Key_ShiftHeld
    | Key_CtrlHeld
    | Key_MetaHeld
    | Key_AltHeld


{-| <https://developer.mozilla.org/en-US/docs/Web/API/Element/wheel_event>
-}
type WheelOptions
    = DeltaX Float
    | DeltaZ Float
    | DeltaMode DeltaMode


{-| <https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent/deltaMode>. The default is DeltaPixels so it's not included here
-}
type DeltaMode
    = DeltaLines
    | DeltaPages


{-| -}
type PointerOptions
    = PointerId Int
    | ScreenXY Float Float
    | PageXY Float Float
    | ClientXY Float Float
    | ShiftHeld
    | CtrlHeld
    | MetaHeld
    | AltHeld
    | PointerType String
    | IsNotPrimary
    | PointerWidth Float
    | PointerHeight Float
    | PointerPressure Float
    | PointerTilt Float Float
    | PointerButton Button
-}
-- Collection of all tests


appTests : Test
appTests =
    describe "Counter App Tests"
        [ describe "Authentication Tests"
            (List.map TF.toTest
                [ testPasswordValidation
                , testRegistrationCreatesPasswordProtectedAccount
                ]
            )
        , describe "All Tests" (List.map TF.toTest tests)
        ]


tests : List (TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    [ testSingleClientIncrement
    , testMultipleClientSync
    , testRoutingHomePage
    , testRoutingAboutPage
    , testRoutingNotFound
    , testNavigationBetweenPages
    , testChatPageLoads
    , testSendChatMessage
    , testMultipleClientChat
    , testRegistrationPageLoads
    , testAdminPageAccess
    , testAdminLogin
    , testRoutePreservationOnRefresh

    -- Admin tests using input fields and click actions
    , testAdminEditUser
    , testAdminEditMessage
    , testAdminDeleteUser
    , testAdminDeleteMessage
    , testMessagesAppearInAdmin
    , testChatMessagesPersistOnRefresh
    , testChatPersistenceAcrossMultipleSessions
    , testLogoutClearsSession

    -- Authentication tests
    , testPasswordValidation
    , testRegistrationCreatesPasswordProtectedAccount
    ]


{-| Test that a single client can increment the counter
-}
testSingleClientIncrement : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testSingleClientIncrement =
    TF.start
        "Single client increment"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Click increment button
                  alice.click delay (Dom.id "increment-button")

                -- Click again
                , alice.click delay (Dom.id "increment-button")

                -- Check the counter value
                , alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "2" ]
                    )
                ]
            )
        ]


{-| Test that multiple clients see the same synchronized counter
-}
testMultipleClientSync : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testMultipleClientSync =
    TF.start
        "Multiple client synchronization"
        (Time.millisToPosix 0)
        config
        [ -- Connect first client (Alice)
          TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Alice increments counter
                  alice.click delay (Dom.id "increment-button")
                ]
            )

        -- Connect second client (Bob)
        , TF.connectFrontend delay
            (sessionIdFromString "bob")
            "/"
            { width = 1024, height = 768 }
            (\bob ->
                [ -- Bob should see counter at 1 (from Alice's increment)
                  bob.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "1" ]
                    )

                -- Bob increments counter
                , bob.click delay (Dom.id "increment-button")

                -- Check backend state
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        if backendModel.counter == 2 then
                            Ok ()

                        else
                            Err ("Expected counter to be 2, but got " ++ String.fromInt backendModel.counter)
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


{-| Test that home page loads correctly with counter functionality
-}
testRoutingHomePage : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testRoutingHomePage =
    TF.start
        "Home page routing and content"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "user")
            "/"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Check that we're on home page with counter content
                  client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🔄 Counter" ]
                    )

                -- Check increment button exists
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "increment-button" ]
                    )

                -- Check navigation shows Home as active
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🏠 Home" ]
                    )
                ]
            )
        ]


{-| Test that about page loads correctly
-}
testRoutingAboutPage : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testRoutingAboutPage =
    TF.start
        "About page routing and content"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "user")
            "/about"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Check that we're on about page
                  client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "📄 About" ]
                    )

                -- Check about page content
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "About This App" ]
                    )

                -- Check tech stack section
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Tech Stack" ]
                    )

                -- Check navigation shows About as active
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "📄 About" ]
                    )
                ]
            )
        ]


{-| Test that 404 page handles invalid routes
-}
testRoutingNotFound : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testRoutingNotFound =
    TF.start
        "404 Not Found page handling"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "user")
            "/invalid-route"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Check that we see 404 content
                  client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "404 - Page Not Found" ]
                    )

                -- Check 404 emoji
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "😵" ]
                    )

                -- Check go home link exists
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "← Go Home" ]
                    )
                ]
            )
        ]


{-| Test navigation between pages works correctly
-}
testNavigationBetweenPages : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testNavigationBetweenPages =
    TF.start
        "Navigation between pages"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "user")
            "/"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Start on home page
                  client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🔄 Counter" ]
                    )

                -- Verify About navigation link exists
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "📄 About" ]
                    )

                -- Verify Home navigation link exists
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🏠 Home" ]
                    )
                ]
            )
        ]


{-| Test that chat page loads correctly
-}
testChatPageLoads : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testChatPageLoads =
    TF.start
        "Chat page loads correctly"
        (Time.millisToPosix 0)
        config
        [ -- First register the user
          TF.connectFrontend delay
            (sessionIdFromString "user")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Fill in registration form
                  client.input delay (Dom.id "email") "user@example.com"
                , client.input delay (Dom.id "password") "password"
                , client.input delay (Dom.id "confirmPassword") "password"
                , client.input delay (Dom.id "name") "Test User"
                , client.input delay (Dom.id "username") "testuser"

                -- Submit registration form
                , client.click delay (Dom.id "register-button")
                ]
            )

        -- Then navigate to chat page
        , TF.connectFrontend delay
            (sessionIdFromString "user")
            "/chat"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Check that we're on chat page
                  client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "💬 Chat" ]
                    )

                -- Check chat input exists
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "chat-input" ]
                    )

                -- Check send button exists
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "send-button" ]
                    )

                -- Check empty state message
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "No messages yet. Be the first to say hello!" ]
                    )
                ]
            )
        ]


{-| Test sending a chat message
-}
testSendChatMessage : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testSendChatMessage =
    TF.start
        "Send chat message functionality"
        (Time.millisToPosix 0)
        config
        [ -- First register alice
          TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/register"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Fill in registration form
                  alice.input delay (Dom.id "email") "alice@example.com"
                , alice.input delay (Dom.id "password") "password"
                , alice.input delay (Dom.id "confirmPassword") "password"
                , alice.input delay (Dom.id "name") "Alice"
                , alice.input delay (Dom.id "username") "alice"

                -- Submit registration form
                , alice.click delay (Dom.id "register-button")
                ]
            )

        -- Then navigate to chat and send message
        , TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/chat"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Type a message
                  alice.input delay (Dom.id "chat-input") "Hello, World!"

                -- Click send button
                , alice.click delay (Dom.id "send-button")

                -- Check message appears
                , alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Hello, World!" ]
                    )
                ]
            )
        ]


{-| Test multiple clients can chat together
-}
testMultipleClientChat : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testMultipleClientChat =
    TF.start
        "Multiple clients chat synchronization"
        (Time.millisToPosix 0)
        config
        [ -- Register Alice first
          TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/register"
            { width = 1024, height = 768 }
            (\alice ->
                [ alice.input delay (Dom.id "email") "alice@example.com"
                , alice.input delay (Dom.id "password") "password"
                , alice.input delay (Dom.id "confirmPassword") "password"
                , alice.input delay (Dom.id "name") "Alice"
                , alice.input delay (Dom.id "username") "alice"
                , alice.click delay (Dom.id "register-button")
                ]
            )

        -- Connect Alice to chat and send message
        , TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/chat"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Alice sends a message
                  alice.input delay (Dom.id "chat-input") "Hi from Alice!"
                , alice.click delay (Dom.id "send-button")
                ]
            )

        -- Register Bob
        , TF.connectFrontend delay
            (sessionIdFromString "bob")
            "/register"
            { width = 1024, height = 768 }
            (\bob ->
                [ bob.input delay (Dom.id "email") "bob@example.com"
                , bob.input delay (Dom.id "password") "password"
                , bob.input delay (Dom.id "confirmPassword") "password"
                , bob.input delay (Dom.id "name") "Bob"
                , bob.input delay (Dom.id "username") "bob"
                , bob.click delay (Dom.id "register-button")
                ]
            )

        -- Connect Bob to chat
        , TF.connectFrontend delay
            (sessionIdFromString "bob")
            "/chat"
            { width = 1024, height = 768 }
            (\bob ->
                [ -- Bob should see Alice's message
                  bob.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Hi from Alice!" ]
                    )

                -- Bob sends a reply
                , bob.input delay (Dom.id "chat-input") "Hello Alice!"
                , bob.click delay (Dom.id "send-button")

                -- Check backend has both messages
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        if List.length backendModel.chatMessages == 2 then
                            Ok ()

                        else
                            Err ("Expected 2 messages, got " ++ String.fromInt (List.length backendModel.chatMessages))
                    )
                ]
            )
        ]


{-| Test that registration page loads correctly
-}
testRegistrationPageLoads : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testRegistrationPageLoads =
    TF.start
        "Registration page loads correctly"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "user")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Check that we're on register page
                  client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Register" ]
                    )

                -- Check form fields exist
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Email" ]
                    )
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Username" ]
                    )
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Full Name" ]
                    )
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Password" ]
                    )

                -- Check submit button exists (but should not be stuck)
                , client.checkView delay
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.text "Creating account..." ]
                    )
                ]
            )
        ]


{-| Test that admin page shows access denied for non-admin users
-}
testAdminPageAccess : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testAdminPageAccess =
    TF.start
        "Admin page access control"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "user")
            "/admin"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Check that we see access denied for non-admin users
                  client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Access Denied" ]
                    )

                -- Check login link exists
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Go to Login" ]
                    )
                ]
            )
        ]


{-| Test admin login functionality
-}
testAdminLogin : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testAdminLogin =
    TF.start
        "Admin login with admin credentials"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/login"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Fill in admin email
                  client.input delay (Dom.id "email") "admin@example.com"

                -- Fill in admin password
                , client.input delay (Dom.id "password") Env.adminPassword

                -- Submit login form
                , client.click delay (Dom.id "login-button")

                -- Check that we can access admin functions
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        -- Check that admin session was created
                        case Dict.get (sessionIdFromString "admin-session") backendModel.sessions of
                            Just userInfo ->
                                if userInfo.email == "admin@example.com" then
                                    Ok ()

                                else
                                    Err ("Expected admin@example.com, got " ++ userInfo.email)

                            Nothing ->
                                Err "No session created for admin"
                    )
                ]
            )
        ]


{-| Test that route is preserved when user refreshes while logged in
-}
testRoutePreservationOnRefresh : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testRoutePreservationOnRefresh =
    TF.start
        "Route preservation on refresh for logged in users"
        (Time.millisToPosix 0)
        config
        [ -- First connect and login on login page
          TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/login"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Login first
                  client.input delay (Dom.id "email") "admin@example.com"
                , client.input delay (Dom.id "password") "admin123"
                , client.click delay (Dom.id "login-button")
                ]
            )

        -- Then connect to admin page (simulating navigation after login)
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/admin"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Simulate refresh by triggering session restoration
                  TF.checkBackend
                    delay
                    (\backendModel ->
                        -- Verify session exists
                        case Dict.get (sessionIdFromString "user-session") backendModel.sessions of
                            Just userInfo ->
                                if userInfo.email == "admin@example.com" then
                                    Ok ()

                                else
                                    Err "Session not preserved correctly"

                            Nothing ->
                                Err "Session lost after refresh"
                    )

                -- Check that we're still on admin page content
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🛠️ Admin Panel" ]
                    )

                -- Verify we see admin content, not redirected to home
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Admin Actions" ]
                    )
                ]
            )
        ]


{-| Test admin message edit functionality
TODO: Rewrite this test to use click actions instead of update calls
-}



-- testAdminEditMessage : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
-- testAdminEditMessage =
--     TF.start
--         "Admin message edit functionality"
--         (Time.millisToPosix 0)
--         config
--         [ -- Create a user and send a message
--           TF.connectFrontend delay
--             (sessionIdFromString "user-session")
--             "/chat"
--             { width = 1024, height = 768 }
--             (\client ->
--                 [ client.input delay (Dom.id "chat-input") "Original message"
--                 , client.click delay (Dom.id "send-button")
--                 ]
--             )
--
--         -- Login as admin and go to admin page
--         , TF.connectFrontend delay
--             (sessionIdFromString "admin-session")
--             "/login"
--             { width = 1024, height = 768 }
--             (\admin ->
--                 [ admin.input delay (Dom.id "email") "admin@example.com"
--                 , admin.input delay (Dom.id "password") "admin123"
--                 , admin.click delay (Dom.id "login-button")
--                 ]
--             )
--
--         , TF.connectFrontend delay
--             (sessionIdFromString "admin-session")
--             "/admin"
--             { width = 1024, height = 768 }
--             (\admin ->
--                 [ -- Check that message appears in admin panel
--                   admin.checkView
--                     delay
--                     (Test.Html.Query.has
--                         [ Test.Html.Selector.text "Original message" ]
--                     )
--
--                 -- Test editing message - TODO: Replace with click actions
--                 -- , admin.update 900 (StartEditingMessage "msg-1"
--                 --     { id = "msg-1"
--                 --     , content = "Original message"
--                 --     , author = "Anonymous"
--                 --     , authorEmail = "anonymous@example.com"
--                 --     , timestamp = Time.millisToPosix 0
--                 --     })
--
--                 -- , admin.update 1000 (SaveMessageEdit "msg-1"
--                 --     { id = "msg-1"
--                 --     , content = "Updated message"
--                 --     , author = "Anonymous"
--                 --     , authorEmail = "anonymous@example.com"
--                 --     , timestamp = Time.millisToPosix 0
--                 --     })
--
--                 -- Check backend state was updated
--                 , TF.checkBackend
--                     delay
--                     (\backendModel ->
--                         case List.head backendModel.chatMessages of
--                             Just message ->
--                                 if message.content == "Updated message" then
--                                     Ok ()
--                                 else
--                                     Err ("Message not updated: " ++ message.content)
--                             Nothing ->
--                                 Err "No messages found"
--                     )
--                 ]
--             )
--         ]


testAdminEditUser : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testAdminEditUser =
    TF.start
        "Admin user edit functionality using input fields"
        (Time.millisToPosix 0)
        config
        [ -- Create a test user
          TF.connectFrontend delay
            (sessionIdFromString "test-user")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "edit@example.com"
                , client.input delay (Dom.id "password") "password"
                , client.input delay (Dom.id "confirmPassword") "password"
                , client.input delay (Dom.id "name") "Original Name"
                , client.input delay (Dom.id "username") "originaluser"
                , client.click delay (Dom.id "register-button")
                ]
            )

        -- Login as admin
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/login"
            { width = 1024, height = 768 }
            (\admin ->
                [ admin.input delay (Dom.id "email") "admin@example.com"
                , admin.input delay (Dom.id "password") "admin123"
                , admin.click delay (Dom.id "login-button")
                ]
            )
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/admin"
            { width = 1024, height = 768 }
            (\admin ->
                [ -- Click edit button to enter edit mode
                  admin.click delay (Dom.id "edit-user-edit@example.com")

                -- Edit the user's name using input field
                , admin.input delay (Dom.id "edit-user-name-edit@example.com") "Updated Name"

                -- Edit the user's username using input field
                , admin.input delay (Dom.id "edit-user-username-edit@example.com") "updateduser"

                -- Check backend state was updated
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get "edit@example.com" backendModel.users of
                            Just user ->
                                if user.name == Just "Updated Name" && user.username == Just "updateduser" then
                                    Ok ()

                                else
                                    Err "User not updated correctly"

                            Nothing ->
                                Err "User not found in backend"
                    )
                ]
            )
        ]


testAdminEditMessage : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testAdminEditMessage =
    TF.start
        "Admin message edit functionality using input fields"
        (Time.millisToPosix 0)
        config
        [ -- Create a user and send a message
          TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "messageuser@example.com"
                , client.input delay (Dom.id "password") "password"
                , client.input delay (Dom.id "confirmPassword") "password"
                , client.input delay (Dom.id "name") "Message User"
                , client.input delay (Dom.id "username") "messageuser"
                , client.click delay (Dom.id "register-button")
                ]
            )

        -- Send a message
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/chat"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "chat-input") "Original message content"
                , client.click delay (Dom.id "send-button")
                ]
            )

        -- Login as admin
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/login"
            { width = 1024, height = 768 }
            (\admin ->
                [ admin.input delay (Dom.id "email") "admin@example.com"
                , admin.input delay (Dom.id "password") "admin123"
                , admin.click delay (Dom.id "login-button")
                ]
            )

        -- Go to admin page and edit message
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/admin"
            { width = 1024, height = 768 }
            (\admin ->
                [ -- Click edit button to enter edit mode for the message
                  admin.click delay (Dom.id "edit-message-msg-1")

                -- Edit the message content using input field
                , admin.input delay (Dom.id "edit-message-content-msg-1") "Updated message content"

                -- Check backend state was updated
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case List.head backendModel.chatMessages of
                            Just message ->
                                if message.content == "Updated message content" then
                                    Ok ()

                                else
                                    Err ("Message not updated correctly: " ++ message.content)

                            Nothing ->
                                Err "No messages found"
                    )
                ]
            )
        ]


testAdminDeleteUser : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testAdminDeleteUser =
    TF.start
        "Admin user delete functionality"
        (Time.millisToPosix 0)
        config
        [ -- Create a test user
          TF.connectFrontend delay
            (sessionIdFromString "test-user")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "delete@example.com"
                , client.input delay (Dom.id "password") "password"
                , client.input delay (Dom.id "confirmPassword") "password"
                , client.input delay (Dom.id "name") "Delete Me"
                , client.input delay (Dom.id "username") "deleteme"
                , client.click delay (Dom.id "register-button")
                ]
            )

        -- Login as admin
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/login"
            { width = 1024, height = 768 }
            (\admin ->
                [ admin.input delay (Dom.id "email") "admin@example.com"
                , admin.input delay (Dom.id "password") "admin123"
                , admin.click delay (Dom.id "login-button")
                ]
            )
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/admin"
            { width = 1024, height = 768 }
            (\admin ->
                [ -- Delete the user by clicking the delete button
                  admin.click delay (Dom.id "delete-user-delete@example.com")

                -- Check backend state - user should be gone
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get "delete@example.com" backendModel.users of
                            Just _ ->
                                Err "User was not deleted"

                            Nothing ->
                                Ok ()
                    )
                ]
            )
        ]


{-| Test admin message delete functionality
-}
testAdminDeleteMessage : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testAdminDeleteMessage =
    TF.start
        "Admin message delete functionality"
        (Time.millisToPosix 0)
        config
        [ -- First register a regular user
          TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "user@example.com"
                , client.input delay (Dom.id "password") "password"
                , client.input delay (Dom.id "confirmPassword") "password"
                , client.input delay (Dom.id "name") "Test User"
                , client.input delay (Dom.id "username") "testuser"
                , client.click delay (Dom.id "register-button")
                ]
            )

        -- Send a message as logged in user
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/chat"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "chat-input") "Message to delete"
                , client.click delay (Dom.id "send-button")
                ]
            )

        -- Login as admin and delete message
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/login"
            { width = 1024, height = 768 }
            (\admin ->
                [ admin.input delay (Dom.id "email") "admin@example.com"
                , admin.input delay (Dom.id "password") "admin123"
                , admin.click delay (Dom.id "login-button")
                ]
            )
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/admin"
            { width = 1024, height = 768 }
            (\admin ->
                [ -- Delete the message
                  admin.click delay (Dom.id "delete-message-msg-1")

                -- Check backend state - message should be gone
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        if List.isEmpty backendModel.chatMessages then
                            Ok ()

                        else
                            Err ("Messages not deleted: " ++ String.fromInt (List.length backendModel.chatMessages))
                    )
                ]
            )
        ]


{-| Test that messages appear in admin panel
-}
testMessagesAppearInAdmin : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testMessagesAppearInAdmin =
    TF.start
        "Messages appear in admin panel"
        (Time.millisToPosix 0)
        config
        [ -- Send messages from authenticated user
          TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "chatuser@example.com"
                , client.input delay (Dom.id "password") "password"
                , client.input delay (Dom.id "confirmPassword") "password"
                , client.input delay (Dom.id "name") "Chat User"
                , client.input delay (Dom.id "username") "chatuser"
                , client.click delay (Dom.id "register-button")
                ]
            )

        -- Send a message from the chat page
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/chat"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "chat-input") "Hello from chat user!"
                , client.click delay (Dom.id "send-button")
                ]
            )

        -- Login as admin and check messages appear
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/login"
            { width = 1024, height = 768 }
            (\admin ->
                [ admin.input delay (Dom.id "email") "admin@example.com"
                , admin.input delay (Dom.id "password") "admin123"
                , admin.click delay (Dom.id "login-button")
                ]
            )
        , TF.connectFrontend delay
            (sessionIdFromString "admin-session")
            "/admin"
            { width = 1024, height = 768 }
            (\admin ->
                [ -- Check that message appears in admin Messages Management
                  admin.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Hello from chat user!" ]
                    )

                -- Check that author email appears
                , admin.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "chatuser@example.com" ]
                    )

                -- Check that username appears as author
                , admin.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "chatuser" ]
                    )
                ]
            )
        ]


{-| Test that chat messages persist when user refreshes the page
-}
testChatMessagesPersistOnRefresh : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testChatMessagesPersistOnRefresh =
    TF.start
        "Chat messages persist on page refresh"
        (Time.millisToPosix 0)
        config
        [ -- First register user
          TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "user@example.com"
                , client.input delay (Dom.id "password") "password"
                , client.input delay (Dom.id "confirmPassword") "password"
                , client.input delay (Dom.id "name") "Test User"
                , client.input delay (Dom.id "username") "testuser"
                , client.click delay (Dom.id "register-button")
                ]
            )

        -- Connect and send a message
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/chat"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Send a message
                  client.input delay (Dom.id "chat-input") "This should persist!"
                , client.click delay (Dom.id "send-button")

                -- Verify message appears
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "This should persist!" ]
                    )

                -- Check backend has the message
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        if List.length backendModel.chatMessages == 1 then
                            case List.head backendModel.chatMessages of
                                Just msg ->
                                    if msg.content == "This should persist!" then
                                        Ok ()

                                    else
                                        Err ("Wrong message content: " ++ msg.content)

                                Nothing ->
                                    Err "No message found"

                        else
                            Err ("Expected 1 message, got " ++ String.fromInt (List.length backendModel.chatMessages))
                    )
                ]
            )

        -- Simulate refresh by reconnecting with same session
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/chat"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Wait a bit for messages to load
                  TF.checkBackend
                    delay
                    (\backendModel ->
                        -- Verify backend still has the message
                        if List.length backendModel.chatMessages == 1 then
                            Ok ()

                        else
                            Err ("Messages lost on refresh! Expected 1, got " ++ String.fromInt (List.length backendModel.chatMessages))
                    )

                -- Check that message appears in the view after refresh
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "This should persist!" ]
                    )
                ]
            )
        ]


{-| Test comprehensive chat persistence across multiple sessions and users
-}
testChatPersistenceAcrossMultipleSessions : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testChatPersistenceAcrossMultipleSessions =
    TF.start
        "Chat persistence across multiple sessions and users"
        (Time.millisToPosix 0)
        config
        [ -- First register Alice
          TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/register"
            { width = 1024, height = 768 }
            (\alice ->
                [ alice.input delay (Dom.id "email") "alice@example.com"
                , alice.input delay (Dom.id "password") "password"
                , alice.input delay (Dom.id "confirmPassword") "password"
                , alice.input delay (Dom.id "name") "Alice"
                , alice.input delay (Dom.id "username") "alice"
                , alice.click delay (Dom.id "register-button")
                ]
            )

        -- Alice sends multiple messages
        , TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/chat"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Send first message
                  alice.input delay (Dom.id "chat-input") "Message 1"
                , alice.click delay (Dom.id "send-button")

                -- Send second message
                , alice.input delay (Dom.id "chat-input") "Message 2"
                , alice.click delay (Dom.id "send-button")

                -- Verify both messages appear
                , alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Message 1" ]
                    )
                , alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Message 2" ]
                    )
                ]
            )

        -- Register Bob
        , TF.connectFrontend delay
            (sessionIdFromString "bob")
            "/register"
            { width = 1024, height = 768 }
            (\bob ->
                [ bob.input delay (Dom.id "email") "bob@example.com"
                , bob.input delay (Dom.id "password") "password"
                , bob.input delay (Dom.id "confirmPassword") "password"
                , bob.input delay (Dom.id "name") "Bob"
                , bob.input delay (Dom.id "username") "bob"
                , bob.click delay (Dom.id "register-button")
                ]
            )

        -- Second user connects and adds messages
        , TF.connectFrontend delay
            (sessionIdFromString "bob")
            "/chat"
            { width = 1024, height = 768 }
            (\bob ->
                [ -- Bob should see Alice's messages
                  bob.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Message 1" ]
                    )
                , bob.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Message 2" ]
                    )

                -- Bob sends his own messages
                , bob.input delay (Dom.id "chat-input") "Hello from Bob!"
                , bob.click delay (Dom.id "send-button")
                , bob.input delay (Dom.id "chat-input") "Bob's second message"
                , bob.click delay (Dom.id "send-button")
                ]
            )

        -- Alice disconnects and reconnects
        , TF.connectFrontend delay
            (sessionIdFromString "alice")
            "/chat"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Alice should see all 4 messages
                  alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Message 1" ]
                    )
                , alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Message 2" ]
                    )
                , alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Hello from Bob!" ]
                    )
                , alice.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Bob's second message" ]
                    )
                ]
            )

        -- Register Charlie first
        , TF.connectFrontend delay
            (sessionIdFromString "charlie")
            "/register"
            { width = 1024, height = 768 }
            (\charlie ->
                [ charlie.input delay (Dom.id "email") "charlie@example.com"
                , charlie.input delay (Dom.id "password") "password"
                , charlie.input delay (Dom.id "confirmPassword") "password"
                , charlie.input delay (Dom.id "name") "Charlie"
                , charlie.input delay (Dom.id "username") "charlie"
                , charlie.click delay (Dom.id "register-button")
                ]
            )

        -- New user connects for the first time
        , TF.connectFrontend delay
            (sessionIdFromString "charlie")
            "/chat"
            { width = 1024, height = 768 }
            (\charlie ->
                [ -- Charlie should see all previous messages
                  charlie.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Message 1" ]
                    )
                , charlie.checkView
                    delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Hello from Bob!" ]
                    )

                -- Check backend state has all messages
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        let
                            messageCount =
                                List.length backendModel.chatMessages

                            expectedMessages =
                                4
                        in
                        if messageCount == expectedMessages then
                            -- Verify message order (oldest first)
                            case backendModel.chatMessages of
                                msg1 :: msg2 :: msg3 :: msg4 :: [] ->
                                    if
                                        msg1.content
                                            == "Message 1"
                                            && msg2.content
                                            == "Message 2"
                                            && msg3.content
                                            == "Hello from Bob!"
                                            && msg4.content
                                            == "Bob's second message"
                                    then
                                        Ok ()

                                    else
                                        Err "Messages not in correct order or have wrong content"

                                _ ->
                                    Err "Unexpected message structure"

                        else
                            Err ("Expected " ++ String.fromInt expectedMessages ++ " messages, got " ++ String.fromInt messageCount)
                    )

                -- Charlie adds a message
                , charlie.input delay (Dom.id "chat-input") "Charlie joins the chat!"
                , charlie.click delay (Dom.id "send-button")

                -- Final verification of persistence
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        if List.length backendModel.chatMessages == 5 then
                            Ok ()

                        else
                            Err ("Expected 5 messages after Charlie's message, got " ++ String.fromInt (List.length backendModel.chatMessages))
                    )
                ]
            )
        ]


{-| Test that logout properly clears the session
-}
testLogoutClearsSession : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testLogoutClearsSession =
    TF.start
        "Logout clears session and prevents access on refresh"
        (Time.millisToPosix 0)
        config
        [ -- Login as admin
          TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/login"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Login
                  client.input delay (Dom.id "email") "admin@example.com"
                , client.input delay (Dom.id "password") "admin123"
                , client.click delay (Dom.id "login-button")

                -- Check that login was successful in backend
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        -- Check that admin session was created
                        case Dict.get (sessionIdFromString "user-session") backendModel.sessions of
                            Just userInfo ->
                                if userInfo.email == "admin@example.com" then
                                    Ok ()

                                else
                                    Err ("Expected admin@example.com, got " ++ userInfo.email)

                            Nothing ->
                                Err "No session created for admin"
                    )
                ]
            )

        -- Navigate directly to admin page after login
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/admin"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Wait for session restoration and admin data load
                  TF.checkBackend
                    delay
                    (\_ -> Ok ())

                -- Verify we can access admin page
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🛠️ Admin Panel" ]
                    )

                -- Verify session exists in backend
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get (sessionIdFromString "user-session") backendModel.sessions of
                            Just userInfo ->
                                if userInfo.email == "admin@example.com" then
                                    Ok ()

                                else
                                    Err "Wrong user in session"

                            Nothing ->
                                Err "No session found"
                    )

                -- Click logout button
                , client.click delay (Dom.id "logout-button")

                -- Wait for logout to process
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        -- Verify session was removed
                        case Dict.get (sessionIdFromString "user-session") backendModel.sessions of
                            Just _ ->
                                Err "Session still exists after logout"

                            Nothing ->
                                Ok ()
                    )
                ]
            )

        -- Reconnect with same session to simulate refresh
        , TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/admin"
            { width = 1024, height = 768 }
            (\client ->
                [ -- Verify session was cleared in backend
                  TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get (sessionIdFromString "user-session") backendModel.sessions of
                            Just _ ->
                                Err "Session still exists after logout"

                            Nothing ->
                                Ok ()
                    )

                -- Verify we see access denied (not logged in)
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Access Denied" ]
                    )

                -- Verify we're not logged in (no logout button)
                , client.checkView delay
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.id "logout-button" ]
                    )
                ]
            )
        ]


{-| Test that password validation works correctly
-}
testPasswordValidation : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testPasswordValidation =
    TF.start
        "Password validation rejects incorrect passwords"
        (Time.millisToPosix 0)
        config
        [ -- First register a new user
          TF.connectFrontend delay
            (sessionIdFromString "user-session")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "testuser@example.com"
                , client.input delay (Dom.id "password") "correctpassword"
                , client.input delay (Dom.id "confirmPassword") "correctpassword"
                , client.input delay (Dom.id "name") "Test User"
                , client.input delay (Dom.id "username") "testuser"
                , client.click delay (Dom.id "register-button")

                -- Wait for registration to complete
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get "testuser@example.com" backendModel.users of
                            Just user ->
                                -- Check password was encrypted and stored
                                case user.encryptedPassword of
                                    Just encryptedPwd ->
                                        if Password.verify "correctpassword" encryptedPwd then
                                            Ok ()

                                        else
                                            Err "Password not encrypted correctly"

                                    Nothing ->
                                        Err "Password not stored"

                            Nothing ->
                                Err "User not created"
                    )
                ]
            )

        -- Now try to login with wrong password
        , TF.connectFrontend delay
            (sessionIdFromString "wrong-password-session")
            "/login"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "testuser@example.com"
                , client.input delay (Dom.id "password") "wrongpassword"
                , client.click delay (Dom.id "login-button")

                -- Check that login failed
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Invalid email or password" ]
                    )

                -- Verify no session was created
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get (sessionIdFromString "wrong-password-session") backendModel.sessions of
                            Just _ ->
                                Err "Session created with wrong password!"

                            Nothing ->
                                Ok ()
                    )
                ]
            )

        -- Try with correct password
        , TF.connectFrontend delay
            (sessionIdFromString "correct-password-session")
            "/login"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "testuser@example.com"
                , client.input delay (Dom.id "password") "correctpassword"
                , client.click delay (Dom.id "login-button")

                -- Check that login succeeded
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get (sessionIdFromString "correct-password-session") backendModel.sessions of
                            Just userInfo ->
                                if userInfo.email == "testuser@example.com" then
                                    Ok ()

                                else
                                    Err "Wrong user in session"

                            Nothing ->
                                Err "Session not created with correct password"
                    )

                -- Should be redirected to home page
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🔄 Counter" ]
                    )
                ]
            )
        ]


{-| Test that registration creates a password-protected account
-}
testRegistrationCreatesPasswordProtectedAccount : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testRegistrationCreatesPasswordProtectedAccount =
    TF.start
        "Registration creates password-protected account"
        (Time.millisToPosix 0)
        config
        [ -- Register a new user
          TF.connectFrontend delay
            (sessionIdFromString "new-user-session")
            "/register"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "newuser@example.com"
                , client.input delay (Dom.id "password") "mypassword123"
                , client.input delay (Dom.id "confirmPassword") "mypassword123"
                , client.input delay (Dom.id "name") "New User"
                , client.input delay (Dom.id "username") "newuser"
                , client.click delay (Dom.id "register-button")

                -- Check registration succeeded and user is logged in
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🔄 Counter" ]
                    )
                ]
            )

        -- Logout
        , TF.connectFrontend delay
            (sessionIdFromString "new-user-session")
            "/"
            { width = 1024, height = 768 }
            (\client ->
                [ client.click delay (Dom.id "logout-button") ]
            )

        -- Try to login with the same email but wrong password
        , TF.connectFrontend delay
            (sessionIdFromString "another-session")
            "/login"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "newuser@example.com"
                , client.input delay (Dom.id "password") "wrongpassword"
                , client.click delay (Dom.id "login-button")

                -- Should see error
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "Invalid email or password" ]
                    )
                ]
            )

        -- Try to login with correct password
        , TF.connectFrontend delay
            (sessionIdFromString "final-session")
            "/login"
            { width = 1024, height = 768 }
            (\client ->
                [ client.input delay (Dom.id "email") "newuser@example.com"
                , client.input delay (Dom.id "password") "mypassword123"
                , client.click delay (Dom.id "login-button")

                -- Should succeed
                , client.checkView delay
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "🔄 Counter" ]
                    )

                -- Verify session contains correct user info
                , TF.checkBackend
                    delay
                    (\backendModel ->
                        case Dict.get (sessionIdFromString "final-session") backendModel.sessions of
                            Just userInfo ->
                                if userInfo.email == "newuser@example.com" && userInfo.name == Just "New User" then
                                    Ok ()

                                else
                                    Err "User info incorrect in session"

                            Nothing ->
                                Err "No session created"
                    )
                ]
            )
        ]
