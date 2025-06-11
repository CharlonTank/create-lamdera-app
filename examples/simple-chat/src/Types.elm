module Types exposing (..)

import Browser exposing (UrlRequest)
import Effect.Browser.Navigation exposing (Key)
import Time
import Url exposing (Url)


type alias ChatMessage =
    { id : Int
    , author : String
    , content : String
    , timestamp : Time.Posix
    }


type alias FrontendModel =
    { key : Key
    , username : String
    , currentMessage : String
    , messages : List ChatMessage
    , isUsernameSet : Bool
    }


type alias BackendModel =
    { messages : List ChatMessage
    , nextMessageId : Int
    , users : List String
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | UsernameChanged String
    | SetUsername
    | MessageChanged String
    | SendMessage
    | NoOpFrontendMsg


type ToBackend
    = UserJoined String
    | UserSentMessage String String -- username, message
    | RequestMessages


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NewMessage ChatMessage
    | AllMessages (List ChatMessage)
    | UserListUpdate (List String)