module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import I18n exposing (Language)
import LocalStorage exposing (LocalStorage)
import Theme exposing (UserPreference)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , localStorage : LocalStorage
    , message : String
    }


type alias BackendModel =
    { message : String
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | ReceivedLocalStorage LocalStorage
    | ChangeLanguage Language
    | ChangeTheme UserPreference


type ToBackend
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend