module I18n exposing (..)

{-| This module handles internationalization (i18n) for the application.
It provides translations for all UI text in supported languages.
-}

-- TYPES


type Language
    = EN
    | FR


type alias Translations =
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

    -- Navigation
    , home : String
    , about : String
    , chat : String
    , login : String
    , register : String
    , admin : String
    , logout : String

    -- Authentication
    , email : String
    , password : String
    , username : String
    , fullName : String
    , confirmPassword : String
    , emailPlaceholder : String
    , passwordPlaceholder : String
    , usernamePlaceholder : String
    , namePlaceholder : String
    , confirmPasswordPlaceholder : String
    , loggingIn : String
    , creatingAccount : String
    , loginDemoMode : String
    , signInWithGoogle : String
    , signInWithGithub : String
    , dontHaveAccount : String
    , registerHere : String
    , alreadyHaveAccount : String
    , loginHere : String
    , authenticationError : String
    , stateMismatch : String
    , authorizationError : String
    , authenticationErrorGeneric : String
    , failedToGetAccessToken : String
    , failedToGetUserInfo : String
    , unknownError : String
    , passwordsDoNotMatch : String
    , oauthConfigNotice : String
    , oauthSeeInstructions : String
    , oauthAnd : String
    , oauthForInstructions : String

    -- Chat
    , chatHeading : String
    , chatDescription : String
    , privateChatHeading : String
    , privateChatMessage : String
    , liveChatHeading : String
    , connectedAs : String
    , noMessagesYet : String
    , typeMessage : String
    , send : String
    , messagesCount : String
    , messagesSync : String

    -- Admin
    , accessDenied : String
    , mustBeLoggedIn : String
    , goToLogin : String
    , noAdminPrivileges : String
    , goHome : String
    , error : String
    , adminPanel : String
    , totalUsers : String
    , chatMessages : String
    , counterValue : String
    , adminActions : String
    , resetCounter : String
    , clearChatMessages : String
    , usersManagement : String
    , messagesManagement : String
    , currentAdminUser : String
    , profile : String
    , name : String
    , actions : String
    , adminBadge : String
    , userBadge : String
    , edit : String
    , delete : String
    , save : String
    , cancel : String
    , noMessagesFound : String
    , id : String
    , author : String
    , content : String
    , messageContent : String
    , usersDataNotRequested : String
    , loadingUsers : String
    , errorLoadingUsers : String
    , messagesDataNotRequested : String
    , loadingMessages : String
    , errorLoadingMessages : String

    -- About page
    , aboutHeading : String
    , aboutDescription : String
    , aboutThisApp : String
    , aboutAppDescription : String
    , clientServerSync : String
    , multiLanguageSupport : String
    , darkLightTheme : String
    , tailwindStyling : String
    , clientSideRouting : String
    , localStorageIntegration : String
    , techStack : String
    , frontend : String
    , backend : String
    , elm : String
    , realTimeSync : String
    , persistentState : String

    -- Error pages
    , pageNotFound : String
    , pageNotFoundMessage : String
    , goHomeButton : String

    -- Page titles
    , homeTitle : String
    , aboutTitle : String
    , chatTitle : String
    , loginTitle : String
    , registerTitle : String
    , adminTitle : String
    , oauthCallbackTitle : String
    , notFoundTitle : String

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
    
    -- Maintenance mode
    , maintenanceModeLabel : String
    , maintenanceTitle : String
    , maintenanceMessage : String
    }



-- FUNCTIONS


{-| Get translations for the current language
-}
translations : Language -> Translations
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

            -- Navigation
            , home = "🏠 Home"
            , about = "📄 About"
            , chat = "💬 Chat"
            , login = "Login"
            , register = "Register"
            , admin = "🛠️ Admin"
            , logout = "Logout"

            -- Authentication
            , email = "Email"
            , password = "Password"
            , username = "Username"
            , fullName = "Full Name"
            , confirmPassword = "Confirm Password"
            , emailPlaceholder = "you@example.com"
            , passwordPlaceholder = "••••••••"
            , usernamePlaceholder = "johndoe"
            , namePlaceholder = "John Doe"
            , confirmPasswordPlaceholder = "••••••••"
            , loggingIn = "Logging in..."
            , creatingAccount = "Creating account..."
            , loginDemoMode = "Login (Demo Mode)"
            , signInWithGoogle = "🔐 Sign in with Google"
            , signInWithGithub = "🐙 Sign in with GitHub"
            , dontHaveAccount = "Don't have an account? "
            , registerHere = "Register here"
            , alreadyHaveAccount = "Already have an account? "
            , loginHere = "Login here"
            , authenticationError = "Authentication error: "
            , stateMismatch = "State mismatch - please try logging in again"
            , authorizationError = "Authorization error - "
            , authenticationErrorGeneric = "Authentication error - "
            , failedToGetAccessToken = "Failed to get access token"
            , failedToGetUserInfo = "Failed to get user information"
            , unknownError = "Unknown error"
            , passwordsDoNotMatch = "Passwords do not match"
            , oauthConfigNotice = "💡 For OAuth: Configure client IDs and secrets in "
            , oauthSeeInstructions = ". See "
            , oauthAnd = " and "
            , oauthForInstructions = " for instructions."

            -- Chat
            , chatHeading = "💬 Chat"
            , chatDescription = "Real-time chat with other users"
            , privateChatHeading = "🔒 Private Chat"
            , privateChatMessage = "Chat is only for logged in users. Please log in to access the chat."
            , liveChatHeading = "💬 Live Chat"
            , connectedAs = "Connected as: "
            , noMessagesYet = "🌟 No messages yet. Be the first to say hello!"
            , typeMessage = "Type your message..."
            , send = "Send"
            , messagesCount = "Messages: "
            , messagesSync = "Messages sync in real-time across all connected clients"

            -- Admin
            , accessDenied = "Access Denied"
            , mustBeLoggedIn = "You must be logged in to access the admin panel."
            , goToLogin = "Go to Login"
            , noAdminPrivileges = "You don't have admin privileges."
            , goHome = "Go Home"
            , error = "Error"
            , adminPanel = "🛠️ Admin Panel"
            , totalUsers = "Total Users"
            , chatMessages = "Chat Messages"
            , counterValue = "Counter Value"
            , adminActions = "Admin Actions"
            , resetCounter = "🔄 Reset Counter"
            , clearChatMessages = "🗑️ Clear Chat Messages"
            , usersManagement = "👥 Users Management"
            , messagesManagement = "💬 Messages Management"
            , currentAdminUser = "Current Admin User"
            , profile = "Profile"
            , name = "Name"
            , actions = "Actions"
            , adminBadge = "Admin"
            , userBadge = "User"
            , edit = "✏️ Edit"
            , delete = "🗑️ Delete"
            , save = "💾 Save"
            , cancel = "❌ Cancel"
            , noMessagesFound = "No messages found"
            , id = "ID"
            , author = "Author"
            , content = "Content"
            , messageContent = "Message content"
            , usersDataNotRequested = "Users data not requested yet"
            , loadingUsers = "Loading users..."
            , errorLoadingUsers = "Error loading users: "
            , messagesDataNotRequested = "Messages data not requested yet"
            , loadingMessages = "Loading messages..."
            , errorLoadingMessages = "Error loading messages: "

            -- About page
            , aboutHeading = "📄 About"
            , aboutDescription = "Learn more about this Lamdera application"
            , aboutThisApp = "About This App"
            , aboutAppDescription = "This is a Lamdera application with routing, built using the create-lamdera-app boilerplate. It demonstrates:"
            , clientServerSync = "Client-server synchronization with Lamdera"
            , multiLanguageSupport = "Multi-language support (English and French)"
            , darkLightTheme = "Dark/light theme switching"
            , tailwindStyling = "Tailwind CSS styling"
            , clientSideRouting = "Client-side routing"
            , localStorageIntegration = "LocalStorage integration"
            , techStack = "Tech Stack"
            , frontend = "Frontend"
            , backend = "Backend"
            , elm = "Elm"
            , realTimeSync = "Real-time synchronization"
            , persistentState = "Persistent state"

            -- Error pages
            , pageNotFound = "404 - Page Not Found"
            , pageNotFoundMessage = "Sorry, the page you're looking for doesn't exist."
            , goHomeButton = "← Go Home"

            -- Page titles
            , homeTitle = "Home"
            , aboutTitle = "About"
            , chatTitle = "Chat"
            , loginTitle = "Login"
            , registerTitle = "Register"
            , adminTitle = "Admin"
            , oauthCallbackTitle = "OAuth Callback"
            , notFoundTitle = "Page Not Found"

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
            
            -- Maintenance mode
            , maintenanceModeLabel = "Maintenance Mode"
            , maintenanceTitle = "Maintenance"
            , maintenanceMessage = "This site is under maintenance"
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

            -- Navigation
            , home = "🏠 Accueil"
            , about = "📄 À propos"
            , chat = "💬 Chat"
            , login = "Connexion"
            , register = "Inscription"
            , admin = "🛠️ Admin"
            , logout = "Déconnexion"

            -- Authentication
            , email = "Email"
            , password = "Mot de passe"
            , username = "Nom d'utilisateur"
            , fullName = "Nom complet"
            , confirmPassword = "Confirmer le mot de passe"
            , emailPlaceholder = "vous@exemple.com"
            , passwordPlaceholder = "••••••••"
            , usernamePlaceholder = "johndoe"
            , namePlaceholder = "Jean Dupont"
            , confirmPasswordPlaceholder = "••••••••"
            , loggingIn = "Connexion en cours..."
            , creatingAccount = "Création du compte..."
            , loginDemoMode = "Connexion (Mode Démo)"
            , signInWithGoogle = "🔐 Se connecter avec Google"
            , signInWithGithub = "🐙 Se connecter avec GitHub"
            , dontHaveAccount = "Vous n'avez pas de compte ? "
            , registerHere = "Inscrivez-vous ici"
            , alreadyHaveAccount = "Vous avez déjà un compte ? "
            , loginHere = "Connectez-vous ici"
            , authenticationError = "Erreur d'authentification : "
            , stateMismatch = "Erreur d'état - veuillez réessayer de vous connecter"
            , authorizationError = "Erreur d'autorisation - "
            , authenticationErrorGeneric = "Erreur d'authentification - "
            , failedToGetAccessToken = "Échec de l'obtention du jeton d'accès"
            , failedToGetUserInfo = "Échec de l'obtention des informations utilisateur"
            , unknownError = "Erreur inconnue"
            , passwordsDoNotMatch = "Les mots de passe ne correspondent pas"
            , oauthConfigNotice = "💡 Pour OAuth : Configurez les ID client et secrets dans "
            , oauthSeeInstructions = ". Voir "
            , oauthAnd = " et "
            , oauthForInstructions = " pour les instructions."

            -- Chat
            , chatHeading = "💬 Chat"
            , chatDescription = "Chat en temps réel avec d'autres utilisateurs"
            , privateChatHeading = "🔒 Chat Privé"
            , privateChatMessage = "Le chat est réservé aux utilisateurs connectés. Veuillez vous connecter pour accéder au chat."
            , liveChatHeading = "💬 Chat en Direct"
            , connectedAs = "Connecté en tant que : "
            , noMessagesYet = "🌟 Aucun message pour l'instant. Soyez le premier à dire bonjour !"
            , typeMessage = "Tapez votre message..."
            , send = "Envoyer"
            , messagesCount = "Messages : "
            , messagesSync = "Les messages se synchronisent en temps réel sur tous les clients connectés"

            -- Admin
            , accessDenied = "Accès Refusé"
            , mustBeLoggedIn = "Vous devez être connecté pour accéder au panneau d'administration."
            , goToLogin = "Aller à la Connexion"
            , noAdminPrivileges = "Vous n'avez pas les privilèges d'administrateur."
            , goHome = "Aller à l'Accueil"
            , error = "Erreur"
            , adminPanel = "🛠️ Panneau d'Administration"
            , totalUsers = "Utilisateurs Totaux"
            , chatMessages = "Messages de Chat"
            , counterValue = "Valeur du Compteur"
            , adminActions = "Actions Administrateur"
            , resetCounter = "🔄 Réinitialiser le Compteur"
            , clearChatMessages = "🗑️ Effacer les Messages de Chat"
            , usersManagement = "👥 Gestion des Utilisateurs"
            , messagesManagement = "💬 Gestion des Messages"
            , currentAdminUser = "Utilisateur Admin Actuel"
            , profile = "Profil"
            , name = "Nom"
            , actions = "Actions"
            , adminBadge = "Admin"
            , userBadge = "Utilisateur"
            , edit = "✏️ Modifier"
            , delete = "🗑️ Supprimer"
            , save = "💾 Sauvegarder"
            , cancel = "❌ Annuler"
            , noMessagesFound = "Aucun message trouvé"
            , id = "ID"
            , author = "Auteur"
            , content = "Contenu"
            , messageContent = "Contenu du message"
            , usersDataNotRequested = "Données utilisateurs non demandées"
            , loadingUsers = "Chargement des utilisateurs..."
            , errorLoadingUsers = "Erreur lors du chargement des utilisateurs : "
            , messagesDataNotRequested = "Données messages non demandées"
            , loadingMessages = "Chargement des messages..."
            , errorLoadingMessages = "Erreur lors du chargement des messages : "

            -- About page
            , aboutHeading = "📄 À propos"
            , aboutDescription = "En savoir plus sur cette application Lamdera"
            , aboutThisApp = "À propos de cette App"
            , aboutAppDescription = "Il s'agit d'une application Lamdera avec routage, construite avec le boilerplate create-lamdera-app. Elle démontre :"
            , clientServerSync = "Synchronisation client-serveur avec Lamdera"
            , multiLanguageSupport = "Support multi-langues (anglais et français)"
            , darkLightTheme = "Basculement thème sombre/clair"
            , tailwindStyling = "Stylisation Tailwind CSS"
            , clientSideRouting = "Routage côté client"
            , localStorageIntegration = "Intégration LocalStorage"
            , techStack = "Stack Technique"
            , frontend = "Frontend"
            , backend = "Backend"
            , elm = "Elm"
            , realTimeSync = "Synchronisation temps réel"
            , persistentState = "État persistant"

            -- Error pages
            , pageNotFound = "404 - Page Non Trouvée"
            , pageNotFoundMessage = "Désolé, la page que vous cherchez n'existe pas."
            , goHomeButton = "← Retour à l'Accueil"

            -- Page titles
            , homeTitle = "Accueil"
            , aboutTitle = "À propos"
            , chatTitle = "Chat"
            , loginTitle = "Connexion"
            , registerTitle = "Inscription"
            , adminTitle = "Admin"
            , oauthCallbackTitle = "Callback OAuth"
            , notFoundTitle = "Page Non Trouvée"

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
            
            -- Maintenance mode
            , maintenanceModeLabel = "Mode Maintenance"
            , maintenanceTitle = "Maintenance"
            , maintenanceMessage = "Ce site est en maintenance"
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
