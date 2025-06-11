module Types exposing (..)

import Browser exposing (UrlRequest)
import Effect.Browser.Navigation exposing (Key)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , counter : Int
    , clientId : String
    }


type alias BackendModel =
    { counter : Int
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | Increment
    | Decrement
    | NoOpFrontendMsg


type ToBackend
    = UserIncrement
    | UserDecrement
    | GetCounter


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = CounterNewValue Int String -- value and clientId who triggered it