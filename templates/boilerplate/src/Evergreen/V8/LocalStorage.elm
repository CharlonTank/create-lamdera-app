module Evergreen.V8.LocalStorage exposing (..)

import Evergreen.V8.I18n
import Evergreen.V8.Theme


type alias LocalStorage =
    { language : Evergreen.V8.I18n.Language
    , userPreference : Evergreen.V8.Theme.UserPreference
    , systemMode : Evergreen.V8.Theme.Mode
    }
