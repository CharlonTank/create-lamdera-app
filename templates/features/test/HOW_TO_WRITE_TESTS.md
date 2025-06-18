# Comprehensive Documentation for lamdera-program-test

This documentation provides a thorough guide to using the `lamdera/program-test` package for writing end-to-end tests for Lamdera applications.

## Table of Contents

1. [Overview](#overview)
2. [Setup](#setup)
3. [Core Concepts](#core-concepts)
4. [API Reference](#api-reference)
5. [Testing Workflow](#testing-workflow)
6. [Advanced Usage](#advanced-usage)
7. [Troubleshooting](#troubleshooting)

## Overview

The `lamdera-program-test` package allows you to write end-to-end tests that simulate user interactions with your Lamdera application. It provides tools to:

- Simulate frontend connections and disconnections
- Trigger user events (clicks, inputs, keyboard events, etc.)
- Check application state (frontend and backend)
- Test HTTP requests and responses
- Handle file uploads
- Take snapshots for visual regression testing

## Setup

### Prerequisites

Before using this package, you need to modify your application:

1. Replace all `Cmd` with `Command` and `Sub` with `Subscription`
2. Replace standard Elm modules with their Effect equivalents:
   - `Browser.Dom` → `Effect.Browser.Dom`
   - `Browser.Events` → `Effect.Browser.Events`
   - `Browser.Navigation` → `Effect.Browser.Navigation`
   - `File` → `Effect.File`
   - `File.Download` → `Effect.File.Download`
   - `File.Select` → `Effect.File.Select`
   - `Http` → `Effect.Http`
   - `Lamdera` → `Effect.Lamdera`
   - `Process` → `Effect.Process`
   - `Task` → `Effect.Task`
   - `Time` → `Effect.Time`

**Automatic conversion:** Run `npx elm-review --template lamdera/program-test/upgrade --fix-all` in your app's root folder.

### Basic Configuration

```elm
import Backend
import Effect.Test
import Frontend
import Test exposing (Test)
import Url

config : Effect.Test.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
config =
    { frontendApp = Frontend.appFunctions
    , backendApp = Backend.appFunctions
    , handleHttpRequest = \_ -> Effect.Test.UnhandledHttpRequest
    , handlePortToJs = \_ -> Nothing
    , handleFileUpload = \_ -> Effect.Test.UnhandledFileUpload
    , handleMultipleFilesUpload = \_ -> Effect.Test.UnhandledMultiFileUpload
    , domain = unsafeUrl "https://my-app.lamdera.app"
    }

unsafeUrl : String -> Url
unsafeUrl urlText =
    case Url.fromString urlText of
        Just url -> url
        Nothing -> unsafeUrl urlText
```

## Core Concepts

### 1. **Test Structure**

Tests are built using a pipeline of actions:

```elm
test : Test
test =
    Effect.Test.start "Test name" startTime config []
        |> Effect.Test.connectFrontend 0 sessionId "/" { width = 1920, height = 1080 }
            (\frontendActions ->
                [ frontendActions.click 100 { htmlId = "submit-button" }
                , frontendActions.checkModel 200 
                    (\model -> 
                        if model.submitted then Ok ()
                        else Err "Form should be submitted"
                    )
                ]
            )
        |> Effect.Test.toTest
```

### 2. **Actions**

Actions are the building blocks of tests. They represent:

- User interactions (clicks, inputs, etc.)
- State checks
- Time advancement
- Backend updates

### 3. **Frontend Actions**

When you connect a frontend, you get access to a record of actions specific to that frontend:

```elm
type alias FrontendActions =
    { clientId : ClientId
    , click : DelayInMs -> HtmlId -> Action
    , input : DelayInMs -> HtmlId -> String -> Action
    , keyDown : DelayInMs -> HtmlId -> KeyEvent -> List KeyOptions -> Action
    , keyUp : DelayInMs -> HtmlId -> KeyEvent -> List KeyOptions -> Action
    , focus : DelayInMs -> HtmlId -> Action
    , blur : DelayInMs -> HtmlId -> Action
    , clickLink : DelayInMs -> String -> Action
    , resizeWindow : DelayInMs -> { width : Int, height : Int } -> Action
    , checkView : DelayInMs -> (Test.Html.Query.Single frontendMsg -> Expectation) -> Action
    , checkModel : DelayInMs -> (frontendModel -> Result String ()) -> Action
    , update : DelayInMs -> frontendMsg -> Action
    , sendToBackend : DelayInMs -> toBackend -> Action
    , snapshotView : DelayInMs -> { name : String } -> Action
    , custom : DelayInMs -> HtmlId -> String -> Json.Encode.Value -> Action
    , portEvent : DelayInMs -> String -> Json.Encode.Value -> Action
    -- Mouse events
    , mouseDown : DelayInMs -> HtmlId -> MouseEvent -> List PointerOptions -> Action
    , mouseUp : DelayInMs -> HtmlId -> MouseEvent -> List PointerOptions -> Action
    , mouseEnter : DelayInMs -> HtmlId -> MouseEvent -> List PointerOptions -> Action
    , mouseOut : DelayInMs -> HtmlId -> MouseEvent -> List PointerOptions -> Action
    , mouseMove : DelayInMs -> HtmlId -> MouseEvent -> List PointerOptions -> Action
    , mouseLeave : DelayInMs -> HtmlId -> MouseEvent -> List PointerOptions -> Action
    , mouseOver : DelayInMs -> HtmlId -> MouseEvent -> List PointerOptions -> Action
    -- Pointer events
    , pointerDown : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    , pointerUp : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    , pointerEnter : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    , pointerOut : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    , pointerCancel : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    , pointerMove : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    , pointerLeave : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    , pointerOver : DelayInMs -> HtmlId -> PointerEvent -> List PointerOptions -> Action
    -- Touch events
    , touchStart : DelayInMs -> HtmlId -> TouchEvent -> Action
    , touchMove : DelayInMs -> HtmlId -> TouchEvent -> Action
    , touchEnd : DelayInMs -> HtmlId -> TouchEvent -> Action
    , touchCancel : DelayInMs -> HtmlId -> TouchEvent -> Action
    -- Wheel event
    , wheel : DelayInMs -> HtmlId -> Float -> ( Float, Float ) -> List WheelOptions -> List PointerOptions -> Action
    }
```

## API Reference

### Starting a Test

```elm
start : String -> Time.Posix -> Config -> List Action -> EndToEndTest
```

Initializes a new test with the given name, start time, configuration, and initial actions.

### Connecting Frontends

```elm
connectFrontend : 
    DelayInMs 
    -> SessionId 
    -> String 
    -> { width : Int, height : Int }
    -> (FrontendActions -> List Action)
    -> Action
```

Connects a new frontend client with the specified session ID, URL path, and window size.

### State Checking Functions

```elm
checkState : DelayInMs -> (Data frontendModel backendModel -> Result String ()) -> Action
```

Checks the overall application state (both frontend and backend).

```elm
checkBackend : DelayInMs -> (backendModel -> Result String ()) -> Action
```

Checks only the backend model.

```elm
checkFrontend : ClientId -> DelayInMs -> (frontendModel -> Result String ()) -> Action
```

Checks a specific frontend's model.

### Time Control

```elm
fastForward : Duration -> Action
```

Advances time without triggering timer events.

```elm
wait : Duration -> EndToEndTest -> EndToEndTest
```

Waits for the specified duration, triggering any timer events.

### Backend Updates

```elm
backendUpdate : DelayInMs -> backendMsg -> Action
```

Directly triggers a backend update message.

### Grouping and Sequencing

```elm
group : List Action -> Action
```

Groups multiple actions into a single action.

```elm
andThen : DelayInMs -> (Data -> List Action) -> Action
```

Conditionally performs actions based on current state.

### Test Execution

```elm
toTest : EndToEndTest -> Test
```

Converts the end-to-end test into an elm-test Test.

```elm
toSnapshots : EndToEndTest -> List (Snapshot frontendMsg)
```

Extracts all snapshots from a test for visual regression testing.

## Testing Workflow

### 1. Basic Click Test

```elm
clickButtonTest : Test
clickButtonTest =
    Effect.Test.start "User can click submit button" startTime config []
        |> Effect.Test.connectFrontend 0 sessionId "/" windowSize
            (\frontend ->
                [ frontend.click 100 { htmlId = "submit-btn" }
                , frontend.checkModel 200 
                    (\model -> 
                        if model.formSubmitted then Ok ()
                        else Err "Form should be submitted after click"
                    )
                ]
            )
        |> Effect.Test.toTest
```

### 2. Form Input Test

```elm
formInputTest : Test
formInputTest =
    Effect.Test.start "User can fill out form" startTime config []
        |> Effect.Test.connectFrontend 0 sessionId "/" windowSize
            (\frontend ->
                [ frontend.input 100 { htmlId = "name-input" } "John Doe"
                , frontend.input 200 { htmlId = "email-input" } "john@example.com"
                , frontend.click 300 { htmlId = "submit-btn" }
                , frontend.checkView 400 
                    (Test.Html.Query.has 
                        [ Test.Html.Selector.text "Thank you, John Doe!" ])
                ]
            )
        |> Effect.Test.toTest
```

### 3. Multiple Frontend Test

```elm
multiUserTest : Test
multiUserTest =
    Effect.Test.start "Multiple users can interact" startTime config []
        |> Effect.Test.connectFrontend 0 sessionId1 "/" windowSize
            (\user1 ->
                [ user1.sendToBackend 100 (SendMessage "Hello from user 1")
                ]
            )
        |> Effect.Test.connectFrontend 200 sessionId2 "/" windowSize
            (\user2 ->
                [ user2.checkModel 300
                    (\model ->
                        if List.member "Hello from user 1" model.messages then
                            Ok ()
                        else
                            Err "User 2 should see user 1's message"
                    )
                ]
            )
        |> Effect.Test.toTest
```

### 4. HTTP Request Testing

```elm
httpRequestTest : Test
httpRequestTest =
    let
        config2 =
            { config
                | handleHttpRequest = 
                    \{ currentRequest } ->
                        if currentRequest.url == "/api/data" then
                            Effect.Test.JsonHttpResponse
                                { statusCode = 200
                                , headers = []
                                , url = currentRequest.url
                                , statusText = "OK"
                                }
                                (Json.Encode.object 
                                    [ ("data", Json.Encode.string "test data") ])
                        else
                            Effect.Test.UnhandledHttpRequest
            }
    in
    Effect.Test.start "HTTP request handling" startTime config2 []
        |> Effect.Test.connectFrontend 0 sessionId "/" windowSize
            (\frontend ->
                [ frontend.click 100 { htmlId = "fetch-data-btn" }
                , frontend.checkModel 500
                    (\model ->
                        case model.apiData of
                            Just "test data" -> Ok ()
                            _ -> Err "Should have received API data"
                    )
                ]
            )
        |> Effect.Test.toTest
```

### 5. File Upload Testing

```elm
fileUploadTest : Test
fileUploadTest =
    let
        config2 =
            { config
                | handleFileUpload = 
                    \_ ->
                        Effect.Test.UploadFile 
                            (Effect.Test.uploadStringFile 
                                "test.txt" 
                                "text/plain" 
                                "Hello, world!" 
                                (Time.millisToPosix 0))
            }
    in
    Effect.Test.start "File upload" startTime config2 []
        |> Effect.Test.connectFrontend 0 sessionId "/" windowSize
            (\frontend ->
                [ frontend.click 100 { htmlId = "upload-btn" }
                , frontend.checkModel 500
                    (\model ->
                        case model.uploadedFile of
                            Just file -> 
                                if file.name == "test.txt" then Ok ()
                                else Err "Wrong file uploaded"
                            Nothing -> Err "No file uploaded"
                    )
                ]
            )
        |> Effect.Test.toTest
```

## Advanced Usage

### 1. Conditional Testing with andThen

```elm
conditionalTest : Test
conditionalTest =
    Effect.Test.start "Conditional actions" startTime config []
        |> Effect.Test.connectFrontend 0 sessionId "/" windowSize
            (\frontend ->
                [ frontend.click 100 { htmlId = "random-btn" }
                , Effect.Test.andThen 200
                    (\data ->
                        case SeqDict.get frontend.clientId data.frontends of
                            Just model ->
                                if model.randomValue > 0.5 then
                                    [ frontend.click 0 { htmlId = "high-value-btn" } ]
                                else
                                    [ frontend.click 0 { htmlId = "low-value-btn" } ]
                            Nothing ->
                                [ Effect.Test.checkState 0 (\_ -> Err "Frontend not found") ]
                    )
                ]
            )
        |> Effect.Test.toTest
```

### 2. Visual Regression Testing

```elm
visualTest : Test
visualTest =
    Effect.Test.start "Visual regression" startTime config []
        |> Effect.Test.connectFrontend 0 sessionId "/" windowSize
            (\frontend ->
                [ frontend.snapshotView 100 { name = "initial-state" }
                , frontend.click 200 { htmlId = "toggle-theme" }
                , frontend.snapshotView 300 { name = "dark-theme" }
                , frontend.resizeWindow 400 { width = 768, height = 1024 }
                , frontend.snapshotView 500 { name = "tablet-view" }
                ]
            )
        |> Effect.Test.toSnapshots
        |> Effect.Snapshot.uploadSnapshots
```

### 3. Keyboard Navigation Testing

```elm
keyboardTest : Test
keyboardTest =
    Effect.Test.start "Keyboard navigation" startTime config []
        |> Effect.Test.connectFrontend 0 sessionId "/" windowSize
            (\frontend ->
                [ frontend.focus 100 { htmlId = "search-input" }
                , frontend.keyDown 200 { htmlId = "search-input" } "Tab" []
                , frontend.checkView 300
                    (Test.Html.Query.find [ Test.Html.Selector.id "first-result" ]
                        >> Test.Html.Query.has [ Test.Html.Selector.class "focused" ])
                , frontend.keyDown 400 { htmlId = "first-result" } "Enter" []
                ]
            )
        |> Effect.Test.toTest
```

### 4. Test Viewer for Debugging

The test viewer allows you to watch tests execute in a browser:

```elm
main : Program () Model Msg
main =
    Effect.Test.viewerWith
        (\config ->
            [ clickButtonTest config
            , formInputTest config
            , multiUserTest config
            ]
        )
        |> Effect.Test.startViewer
```

### 5. Headless Test Runner

For CI/CD pipelines:

```elm
main : Program () HeadlessModel HeadlessMsg
main =
    Effect.Test.startHeadless
        [ clickButtonTest
        , formInputTest
        , multiUserTest
        ]
```

## Troubleshooting

### Common Issues

1. **"Event not found" errors**
   - Ensure the element has the correct `id` attribute
   - Check that the event listener is properly attached
   - Verify the element is rendered when the event is triggered

2. **Timing issues**
   - Use appropriate delays between actions
   - Consider using `checkModel` or `checkView` to wait for state changes
   - Use `andThen` for conditional timing

3. **HTTP request handling**
   - Ensure your `handleHttpRequest` function matches the exact URL
   - Return appropriate response types (Json, String, Bytes, etc.)
   - Check request method and headers if needed

4. **File upload issues**
   - Implement `handleFileUpload` in your config
   - Use `uploadStringFile` or `uploadBytesFile` helpers
   - Ensure MIME types match expectations

### Debugging Tips

1. Use the test viewer to visually see what's happening
2. Add intermediate `checkModel` or `checkView` calls to verify state
3. Use descriptive test names and snapshot names
4. Break complex tests into smaller, focused tests
5. Use `group` to organize related actions

## Best Practices

1. **Keep tests focused**: Each test should verify one specific behavior
2. **Use meaningful delays**: Allow time for updates to propagate
3. **Clean test data**: Use unique IDs and clean state between tests
4. **Descriptive assertions**: Provide clear error messages in checks
5. **Snapshot strategically**: Take snapshots at key visual states
6. **Test edge cases**: Include tests for error states and edge conditions
7. **Reuse test helpers**: Create helper functions for common test patterns

## Non-Lamdera Applications

The package also supports testing non-Lamdera Elm applications:

- `configForApplication`: For Browser.application apps
- `configForDocument`: For Browser.document apps
- `configForElement`: For Browser.element apps
- `configForSandbox`: For Browser.sandbox apps

Each provides a simplified configuration without backend functionality.

## Summary

The `lamdera-program-test` package provides a comprehensive testing framework for Lamdera applications. By simulating user interactions and checking application state, you can ensure your app behaves correctly across various scenarios. The key is to:

1. Set up proper configuration
2. Connect frontends as needed
3. Trigger user interactions
4. Check resulting state
5. Use time control for async operations
6. Leverage snapshots for visual testing

With these tools, you can build robust test suites that give confidence in your application's behavior.