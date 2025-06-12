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


type alias Theme =
    { background : String
    , secondaryBackground : String
    , text : String
    , textSecondary : String
    , primary : String
    , primaryHover : String
    , border : String
    , cardBackground : String
    , surfaceBackground : String
    , success : String
    , danger : String
    , warning : String
    , info : String
    }



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


{-| Get theme colors based on the current mode
-}
getTheme : Mode -> Theme
getTheme mode =
    case mode of
        Light ->
            lightTheme

        Dark ->
            darkTheme


{-| Light theme colors
-}
lightTheme : Theme
lightTheme =
    { background = "#ffffff"
    , secondaryBackground = "#f8f9fa"
    , text = "#212529"
    , textSecondary = "#6c757d"
    , primary = "#0d6efd"
    , primaryHover = "#0b5ed7"
    , border = "#dee2e6"
    , cardBackground = "#ffffff"
    , surfaceBackground = "#f8f9fa"
    , success = "#198754"
    , danger = "#dc3545"
    , warning = "#ffc107"
    , info = "#0dcaf0"
    }


{-| Dark theme colors
-}
darkTheme : Theme
darkTheme =
    { background = "#121212"
    , secondaryBackground = "#1e1e1e"
    , text = "#ffffff"
    , textSecondary = "#adb5bd"
    , primary = "#0d6efd"
    , primaryHover = "#3d8bfd"
    , border = "#495057"
    , cardBackground = "#212529"
    , surfaceBackground = "#343a40"
    , success = "#198754"
    , danger = "#dc3545"
    , warning = "#ffc107"
    , info = "#0dcaf0"
    }


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


{-| Convert Mode to String
-}
modeToString : Mode -> String
modeToString mode =
    case mode of
        Dark ->
            "dark"

        Light ->
            "light"


{-| Convert String to Mode with fallback to Light
-}
stringToMode : String -> Mode
stringToMode str =
    case str of
        "dark" ->
            Dark

        _ ->
            Light