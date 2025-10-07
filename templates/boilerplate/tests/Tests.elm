module Tests exposing (tests)

import Backend
import Effect.Test as TF
import Frontend
import Types exposing (..)


tests : List (TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    []
