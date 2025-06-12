module I18n exposing (..)

{-| This module handles internationalization (i18n) for the application.
It provides translations for all UI text in supported languages.
-}


-- TYPES


type Language
    = EN
    | FR


type alias Translation =
    { appTitle : String
    , welcome : String
    , loading : String
    , increment : String
    , decrement : String
    , counter : String
    , lastUpdate : String
    , waitingForUpdate : String
    , counterInitialized : String
    , lastUpdatedBy : String
    , toggleDarkMode : String
    , toggleLightMode : String
    , followSystem : String
    , language : String
    , english : String
    , french : String
    , preferences : String
    , theme : String
    , darkTheme : String
    , lightTheme : String
    , systemTheme : String
    -- Tailwind specific
    , fastDevelopment : String
    , fastDevelopmentDesc : String
    , beautifulDesign : String
    , beautifulDesignDesc : String
    , hotReload : String
    , hotReloadDesc : String
    , buttonExamples : String
    , primaryButton : String
    , successButton : String
    , darkButton : String
    , lightButton : String
    , editMessage : String
    , tailwindMessage : String
    , multiLanguage : String
    , multiLanguageDesc : String
    , tailwindIntegration : String
    , tailwindIntegrationDesc : String
    , testSupport : String
    , testSupportDesc : String
    }



-- FUNCTIONS


{-| Get translations for the current language
-}
translations : Language -> Translation
translations lang =
    case lang of
        EN ->
            { appTitle = "Lamdera App"
            , welcome = "Welcome to your Lamdera application!"
            , loading = "Loading..."
            , increment = "Increment"
            , decrement = "Decrement"
            , counter = "Counter"
            , lastUpdate = "Last update"
            , waitingForUpdate = "Waiting for first update..."
            , counterInitialized = "Counter initialized"
            , lastUpdatedBy = "Last updated by"
            , toggleDarkMode = "Toggle dark mode"
            , toggleLightMode = "Toggle light mode"
            , followSystem = "Follow system"
            , language = "Language"
            , english = "English"
            , french = "Français"
            , preferences = "Preferences"
            , theme = "Theme"
            , darkTheme = "Dark"
            , lightTheme = "Light"
            , systemTheme = "System"
            -- Tailwind specific
            , fastDevelopment = "Fast Development"
            , fastDevelopmentDesc = "Tailwind utilities work seamlessly with Elm's functional approach"
            , beautifulDesign = "Beautiful Design"
            , beautifulDesignDesc = "Create stunning UIs with utility-first CSS classes"
            , hotReload = "Hot Reload"
            , hotReloadDesc = "See your changes instantly with lamdera-dev-watch"
            , buttonExamples = "Button Examples"
            , primaryButton = "Primary Button"
            , successButton = "Success Button"
            , darkButton = "Dark Button"
            , lightButton = "Light Button"
            , editMessage = "Edit src/Frontend.elm to customize this page"
            , tailwindMessage = "Tailwind classes are automatically detected and compiled"
            , multiLanguage = "Multi-Language"
            , multiLanguageDesc = "Built-in internationalization with English and French support"
            , tailwindIntegration = "Tailwind CSS"
            , tailwindIntegrationDesc = "Beautiful, responsive design with utility-first CSS"
            , testSupport = "Test Support"
            , testSupportDesc = "lamdera-program-test integration for reliable testing"
            }

        FR ->
            { appTitle = "Application Lamdera"
            , welcome = "Bienvenue dans votre application Lamdera!"
            , loading = "Chargement..."
            , increment = "Incrémenter"
            , decrement = "Décrémenter"
            , counter = "Compteur"
            , lastUpdate = "Dernière mise à jour"
            , waitingForUpdate = "En attente de la première mise à jour..."
            , counterInitialized = "Compteur initialisé"
            , lastUpdatedBy = "Dernière mise à jour par"
            , toggleDarkMode = "Activer le mode sombre"
            , toggleLightMode = "Activer le mode clair"
            , followSystem = "Suivre le système"
            , language = "Langue"
            , english = "English"
            , french = "Français"
            , preferences = "Préférences"
            , theme = "Thème"
            , darkTheme = "Sombre"
            , lightTheme = "Clair"
            , systemTheme = "Système"
            -- Tailwind specific
            , fastDevelopment = "Développement Rapide"
            , fastDevelopmentDesc = "Les utilitaires Tailwind fonctionnent parfaitement avec l'approche fonctionnelle d'Elm"
            , beautifulDesign = "Design Magnifique"
            , beautifulDesignDesc = "Créez des interfaces superbes avec des classes CSS utilitaires"
            , hotReload = "Rechargement à Chaud"
            , hotReloadDesc = "Voyez vos changements instantanément avec lamdera-dev-watch"
            , buttonExamples = "Exemples de Boutons"
            , primaryButton = "Bouton Principal"
            , successButton = "Bouton Succès"
            , darkButton = "Bouton Sombre"
            , lightButton = "Bouton Clair"
            , editMessage = "Modifiez src/Frontend.elm pour personnaliser cette page"
            , tailwindMessage = "Les classes Tailwind sont automatiquement détectées et compilées"
            , multiLanguage = "Multi-Langues"
            , multiLanguageDesc = "Internationalisation intégrée avec support anglais et français"
            , tailwindIntegration = "Tailwind CSS"
            , tailwindIntegrationDesc = "Design beau et responsive avec CSS utilitaire"
            , testSupport = "Support de Tests"
            , testSupportDesc = "Intégration lamdera-program-test pour des tests fiables"
            }


{-| Convert Language to String for storage
-}
languageToString : Language -> String
languageToString lang =
    case lang of
        EN ->
            "en"

        FR ->
            "fr"


{-| Convert String to Language with fallback to EN
-}
stringToLanguage : String -> Language
stringToLanguage str =
    case str of
        "fr" ->
            FR

        _ ->
            EN


{-| Get locale string for the language (e.g., "en-US", "fr-FR")
-}
languageToLocale : Language -> String
languageToLocale lang =
    case lang of
        EN ->
            "en-US"

        FR ->
            "fr-FR"