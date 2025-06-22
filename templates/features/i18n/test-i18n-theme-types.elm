module Types exposing (..)

import Browser exposing (UrlRequest)
import Effect.Browser.Navigation exposing (Key)
import I18n exposing (Language, Translation)
import LocalStorage exposing (LocalStorage)
import Theme exposing (Theme, UserPreference)
import Url exposing (Url)


type alias UserConfig =
    { t : Translation
    , c : Theme
    }


type alias FrontendModel =
    { key : Key
    , localStorage : LocalStorage
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
    | ReceivedLocalStorage LocalStorage
    | ChangeLanguage Language
    | ChangeTheme UserPreference


type ToBackend
    = UserIncrement
    | UserDecrement
    | GetCounter


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = CounterNewValue Int String -- value and clientId who triggered it