module Backend exposing (..)

import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Effect.Subscription as Subscription exposing (Subscription)
import Lamdera
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
    ( { counter = 0 }
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
        UserIncrement ->
            let
                newModel =
                    { model | counter = model.counter + 1 }
            in
            ( newModel
            , broadcast (CounterNewValue newModel.counter (Effect.Lamdera.clientIdToString clientId))
            )

        UserDecrement ->
            let
                newModel =
                    { model | counter = model.counter - 1 }
            in
            ( newModel
            , broadcast (CounterNewValue newModel.counter (Effect.Lamdera.clientIdToString clientId))
            )
        
        GetCounter ->
            ( model
            , sendToFrontend clientId (CounterNewValue model.counter "")
            )


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    Subscription.none