module Backend exposing (..)

import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Effect.Subscription as Subscription exposing (Subscription)
import Lamdera
import Time
import Types exposing (..)


app =
    Effect.Lamdera.backend
        Lamdera.broadcast
        Lamdera.sendToFrontend
        app_


app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    ( { messages = []
      , nextMessageId = 1
      , users = []
      }
    , Command.none
    )


update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Command.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        UserJoined username ->
            let
                updatedUsers =
                    if List.member username model.users then
                        model.users
                    else
                        username :: model.users
                
                newModel =
                    { model | users = updatedUsers }
            in
            ( newModel
            , Command.batch
                [ sendToFrontend clientId (AllMessages model.messages)
                , broadcast (UserListUpdate updatedUsers)
                ]
            )
        
        UserSentMessage username messageContent ->
            let
                newMessage =
                    { id = model.nextMessageId
                    , author = username
                    , content = messageContent
                    , timestamp = Time.millisToPosix 0 -- In real app, get actual time
                    }
                
                newModel =
                    { model 
                    | messages = model.messages ++ [newMessage]
                    , nextMessageId = model.nextMessageId + 1
                    }
            in
            ( newModel
            , broadcast (NewMessage newMessage)
            )
        
        RequestMessages ->
            ( model
            , sendToFrontend clientId (AllMessages model.messages)
            )


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    Subscription.none