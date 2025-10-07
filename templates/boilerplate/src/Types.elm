module Types exposing (..)

import Auth.Common
import Browser exposing (UrlRequest)
import Effect.Browser.Navigation exposing (Key)
import Effect.Http
import Effect.Lamdera exposing (ClientId, SessionId)
import GoogleOneTap
import I18n exposing (Language)
import LocalStorage exposing (LocalStorage)
import Password exposing (EncryptedPassword)
import RemoteData exposing (RemoteData)
import Router exposing (Route)
import SeqDict exposing (SeqDict)
import Theme exposing (UserPreference)
import Time
import Url exposing (Url)


type alias Email =
    String


type alias Username =
    String


type LoginState
    = JustArrived
    | NotLogged Bool
    | LoggedIn Auth.Common.UserInfo


type alias User =
    { email : Email
    , name : Maybe String
    , username : Maybe Username
    , profilePicture : Maybe String
    , createdAt : Time.Posix
    , isAdmin : Bool
    , encryptedPassword : Maybe EncryptedPassword
    }


type alias ChatMessage =
    { id : String
    , content : String
    , author : String
    , authorEmail : Email
    , timestamp : Time.Posix
    }


type alias FrontendModel =
    { key : Key
    , localStorage : LocalStorage
    , counter : RemoteData String Int
    , lastUpdatedBy : Maybe ClientId
    , route : Route
    , chatMessages : List ChatMessage
    , chatInput : String

    -- Auth fields
    , authFlow : Auth.Common.Flow
    , authRedirectBaseUrl : Url
    , loginState : LoginState
    , currentUser : Maybe Auth.Common.UserInfo
    , sessionId : Maybe SessionId

    -- Login form fields
    , loginForm : LoginForm
    , registerForm : RegisterForm

    -- Admin data
    , adminUsers : RemoteData String (List User)
    , adminMessages : RemoteData String (List ChatMessage)
    , editingUser : Maybe ( Email, User )
    , editingMessage : Maybe ( String, ChatMessage )

    -- Time and timezone
    , timezone : Time.Zone
    
    -- Config panel
    , configPanelOpen : Bool
    , maintenanceMode : Bool
    }


type alias LoginForm =
    { email : String
    , password : String
    , isSubmitting : Bool
    , error : Maybe String
    }


type alias RegisterForm =
    { email : String
    , password : String
    , confirmPassword : String
    , name : String
    , username : String
    , isSubmitting : Bool
    , error : Maybe String
    }


type alias BackendModel =
    { -- Counter
      counter : Int
    , lastUpdatedBy : Maybe ClientId

    -- Chat messages
    , chatMessages : List ChatMessage

    -- Auth fields
    , sessions : SeqDict SessionId Auth.Common.UserInfo
    , users : SeqDict Email User
    , pendingAuths : SeqDict SessionId Auth.Common.PendingAuth
    }



-- Access level specific message types


type BasicFrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | Increment
    | Decrement
    | NoOpFrontendMsg
    | ReceivedLocalStorage LocalStorage
    | ChangeLanguage Language
    | ChangeTheme UserPreference
    | GotTimezone Time.Zone
      -- Auth messages (available to everyone)
    | SignInRequested
    | SignInWithGoogle
    | SignInWithGithub
    | RegisterRequested
    | UpdateLoginForm LoginForm
    | UpdateRegisterForm RegisterForm
    | GoogleOneTapResponseReceived String
    | GoogleOneTapStatusReceived GoogleOneTap.OneTapStatus
      -- Config panel
    | CloseConfigPanel
    | ToggleMaintenanceMode


type LoggedInUserFrontendMsg
    = UpdateChatInput String
    | SendChatMessage
    | LogoutRequested


type LoggedInAdminFrontendMsg
    = ResetCounter
    | ClearChatMessages
    | AdminDeleteUser Email
    | AdminDeleteMessage String
    | StartEditingUser Email User
    | StartEditingMessage String ChatMessage
    | CancelEditing
    | SaveUserEdit Email User
    | SaveMessageEdit String ChatMessage
    | SendTestEmail



-- Main FrontendMsg with access level wrappers


type FrontendMsg
    = BasicFrontendMsg BasicFrontendMsg
    | LoggedInUserFrontendMsg LoggedInUserFrontendMsg
    | LoggedInAdminFrontendMsg LoggedInAdminFrontendMsg



-- Access level specific backend message types


type BasicToBackend
    = UserIncrementToBackend
    | UserDecrementToBackend
    | GetCounterToBackend
    | AuthToBackendToBackend Auth.Common.ToBackend
    | EmailPasswordLoginToBackend String String -- email, password
    | EmailPasswordRegisterToBackend String String String String -- email, password, name, username
    | GoogleOneTapTokenToBackend String -- ID token from Google One Tap


type LoggedInUserToBackend
    = SendMessageToBackend String
    | GetChatMessagesToBackend
    | GetUserToBackend


type LoggedInAdminToBackend
    = AdminResetCounterToBackend
    | AdminClearChatMessagesToBackend
    | AdminDeleteUserToBackend Email
    | AdminDeleteMessageToBackend String
    | AdminEditUserToBackend Email (Maybe User)
    | AdminEditMessageToBackend String (Maybe ChatMessage)
    | GetAdminDataToBackend
    | SendTestEmailToBackend



-- Main ToBackend with access level wrappers


type ToBackend
    = BasicToBackend BasicToBackend
    | LoggedInUserToBackend LoggedInUserToBackend
    | LoggedInAdminToBackend LoggedInAdminToBackend


type BackendMsg
    = AuthBackendMsg Auth.Common.BackendMsg
    | UserConnected SessionId ClientId
    | GotTimeForMessage SessionId ClientId String Time.Posix
    | EmailSent (Result Effect.Http.Error String)



-- Access level specific frontend response types


type BasicToFrontend
    = CounterNewValueToFrontend Int (Maybe ClientId)
      -- Auth messages (available to everyone)
    | AuthToFrontendToFrontend Auth.Common.ToFrontend
    | AuthSuccessToFrontend Auth.Common.UserInfo
    | AuthLogoutToFrontend


type LoggedInUserToFrontend
    = NewChatMessageToFrontend ChatMessage
    | AllChatMessagesToFrontend (List ChatMessage)
    | UserInfoResponseToFrontend (Maybe User)


type LoggedInAdminToFrontend
    = AdminUsersUpdatedToFrontend (Maybe (List User))
    | AdminMessagesUpdatedToFrontend (Maybe (List ChatMessage))
    | AdminOperationResultToFrontend String (Maybe String) -- operation name, error message if any



-- Main ToFrontend with access level wrappers


type ToFrontend
    = BasicToFrontend BasicToFrontend
    | LoggedInUserToFrontend LoggedInUserToFrontend
    | LoggedInAdminToFrontend LoggedInAdminToFrontend
