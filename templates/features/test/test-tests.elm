module Tests exposing (..)

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
    describe "Counter App Tests" (List.map TF.toTest tests)


tests : List (TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    [ testSingleClientIncrement
    , testMultipleClientSync
    ]


{-| Test that a single client can increment the counter
-}
testSingleClientIncrement : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
testSingleClientIncrement =
    TF.start
        "Single client increment"
        (Time.millisToPosix 0)
        config
        [ TF.connectFrontend
            0
            (sessionIdFromString "alice")
            "/"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Click increment button
                  alice.click 100 (Dom.id "increment-button")
                
                -- Click again
                , alice.click 200 (Dom.id "increment-button")
                
                -- Check the counter value
                , alice.checkView
                    300
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
          TF.connectFrontend
            0
            (sessionIdFromString "alice")
            "/"
            { width = 1024, height = 768 }
            (\alice ->
                [ -- Alice increments counter
                  alice.click 100 (Dom.id "increment-button")
                ]
            )
        
        -- Connect second client (Bob)
        , TF.connectFrontend
            200
            (sessionIdFromString "bob")
            "/"
            { width = 1024, height = 768 }
            (\bob ->
                [ -- Bob should see counter at 1 (from Alice's increment)
                  bob.checkView
                    300
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text "1" ]
                    )
                
                -- Bob increments counter
                , bob.click 400 (Dom.id "increment-button")
                
                -- Check backend state
                , TF.checkBackend
                    500
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