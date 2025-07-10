module Theme exposing (..)

{-| This module handles theming (dark/light mode) for the application.
It provides color schemes and manages user theme preferences.
-}

-- TYPES


type UserPreference
    = DarkMode
    | LightMode
    | SystemMode


type Mode
    = Dark
    | Light



-- FUNCTIONS


{-| Get the actual mode based on user preference and system mode
-}
getMode : UserPreference -> Mode -> Mode
getMode preference systemMode =
    case preference of
        DarkMode ->
            Dark

        LightMode ->
            Light

        SystemMode ->
            systemMode


{-| Convert UserPreference to String for storage
-}
userPreferenceToString : UserPreference -> String
userPreferenceToString preference =
    case preference of
        DarkMode ->
            "dark"

        LightMode ->
            "light"

        SystemMode ->
            "system"


{-| Convert String to UserPreference with fallback to SystemMode
-}
stringToUserPreference : String -> UserPreference
stringToUserPreference str =
    case str of
        "dark" ->
            DarkMode

        "light" ->
            LightMode

        _ ->
            SystemMode


{-| Convert String to Mode with fallback to Light
-}
stringToMode : String -> Mode
stringToMode str =
    case str of
        "dark" ->
            Dark

        _ ->
            Light
