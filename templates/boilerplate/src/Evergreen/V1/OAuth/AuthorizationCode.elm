module Evergreen.V1.OAuth.AuthorizationCode exposing (..)

import Evergreen.V1.OAuth


type alias AuthorizationError =
    { error : Evergreen.V1.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    , state : Maybe String
    }


type alias AuthenticationError =
    { error : Evergreen.V1.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    }
