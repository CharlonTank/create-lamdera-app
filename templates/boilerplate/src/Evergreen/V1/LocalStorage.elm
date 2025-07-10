module Evergreen.V1.LocalStorage exposing (..)

import Evergreen.V1.I18n
import Evergreen.V1.Theme


type alias LocalStorage =
    { language : Evergreen.V1.I18n.Language
    , userPreference : Evergreen.V1.Theme.UserPreference
    , systemMode : Evergreen.V1.Theme.Mode
    }
