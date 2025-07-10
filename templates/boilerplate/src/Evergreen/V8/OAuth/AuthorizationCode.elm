module Evergreen.V8.OAuth.AuthorizationCode exposing (..)

import Evergreen.V8.OAuth


type alias AuthorizationError =
    { error : Evergreen.V8.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    , state : Maybe String
    }


type alias AuthenticationError =
    { error : Evergreen.V8.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    }
