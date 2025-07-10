module Evergreen.V8.Types exposing (..)

import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V8.Auth.Common
import Evergreen.V8.GoogleOneTap
import Evergreen.V8.I18n
import Evergreen.V8.LocalStorage
import Evergreen.V8.Password
import Evergreen.V8.Router
import Evergreen.V8.Theme
import RemoteData
import SeqDict
import Time
import Url


type alias Email =
    String


type alias ChatMessage =
    { id : String
    , content : String
    , author : String
    , authorEmail : Email
    , timestamp : Time.Posix
    }


type LoginState
    = JustArrived
    | NotLogged Bool
    | LoggedIn Evergreen.V8.Auth.Common.UserInfo


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


type alias Username =
    String


type alias User =
    { email : Email
    , name : Maybe String
    , username : Maybe Username
    , profilePicture : Maybe String
    , createdAt : Time.Posix
    , isAdmin : Bool
    , encryptedPassword : Maybe Evergreen.V8.Password.EncryptedPassword
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , localStorage : Evergreen.V8.LocalStorage.LocalStorage
    , counter : RemoteData.RemoteData String Int
    , lastUpdatedBy : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V8.Router.Route
    , chatMessages : List ChatMessage
    , chatInput : String
    , authFlow : Evergreen.V8.Auth.Common.Flow
    , authRedirectBaseUrl : Url.Url
    , loginState : LoginState
    , currentUser : Maybe Evergreen.V8.Auth.Common.UserInfo
    , sessionId : Maybe Effect.Lamdera.SessionId
    , loginForm : LoginForm
    , registerForm : RegisterForm
    , adminUsers : RemoteData.RemoteData String (List User)
    , adminMessages : RemoteData.RemoteData String (List ChatMessage)
    , editingUser : Maybe ( Email, User )
    , editingMessage : Maybe ( String, ChatMessage )
    , timezone : Time.Zone
    }


type alias BackendModel =
    { counter : Int
    , lastUpdatedBy : Maybe Effect.Lamdera.ClientId
    , chatMessages : List ChatMessage
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V8.Auth.Common.UserInfo
    , users : SeqDict.SeqDict Email User
    , pendingAuths : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V8.Auth.Common.PendingAuth
    }


type BasicFrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Increment
    | Decrement
    | NoOpFrontendMsg
    | ReceivedLocalStorage Evergreen.V8.LocalStorage.LocalStorage
    | ChangeLanguage Evergreen.V8.I18n.Language
    | ChangeTheme Evergreen.V8.Theme.UserPreference
    | GotTimezone Time.Zone
    | SignInRequested
    | SignInWithGoogle
    | SignInWithGithub
    | RegisterRequested
    | UpdateLoginForm LoginForm
    | UpdateRegisterForm RegisterForm
    | GoogleOneTapResponseReceived String
    | GoogleOneTapStatusReceived Evergreen.V8.GoogleOneTap.OneTapStatus


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


type FrontendMsg
    = BasicFrontendMsg BasicFrontendMsg
    | LoggedInUserFrontendMsg LoggedInUserFrontendMsg
    | LoggedInAdminFrontendMsg LoggedInAdminFrontendMsg


type BasicToBackend
    = UserIncrementToBackend
    | UserDecrementToBackend
    | GetCounterToBackend
    | AuthToBackendToBackend Evergreen.V8.Auth.Common.ToBackend
    | EmailPasswordLoginToBackend String String
    | EmailPasswordRegisterToBackend String String String String
    | GoogleOneTapTokenToBackend String


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


type ToBackend
    = BasicToBackend BasicToBackend
    | LoggedInUserToBackend LoggedInUserToBackend
    | LoggedInAdminToBackend LoggedInAdminToBackend


type BackendMsg
    = AuthBackendMsg Evergreen.V8.Auth.Common.BackendMsg
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | GotTimeForMessage Effect.Lamdera.SessionId Effect.Lamdera.ClientId String Time.Posix
    | EmailSent (Result Effect.Http.Error String)


type BasicToFrontend
    = CounterNewValueToFrontend Int (Maybe Effect.Lamdera.ClientId)
    | AuthToFrontendToFrontend Evergreen.V8.Auth.Common.ToFrontend
    | AuthSuccessToFrontend Evergreen.V8.Auth.Common.UserInfo
    | AuthLogoutToFrontend


type LoggedInUserToFrontend
    = NewChatMessageToFrontend ChatMessage
    | AllChatMessagesToFrontend (List ChatMessage)
    | UserInfoResponseToFrontend (Maybe User)


type LoggedInAdminToFrontend
    = AdminUsersUpdatedToFrontend (Maybe (List User))
    | AdminMessagesUpdatedToFrontend (Maybe (List ChatMessage))
    | AdminOperationResultToFrontend String (Maybe String)


type ToFrontend
    = BasicToFrontend BasicToFrontend
    | LoggedInUserToFrontend LoggedInUserToFrontend
    | LoggedInAdminToFrontend LoggedInAdminToFrontend
