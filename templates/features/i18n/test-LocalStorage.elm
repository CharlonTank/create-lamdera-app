port module LocalStorage exposing (..)

{-| This module handles local storage for user preferences with lamdera-program-test.
It manages language and theme preferences persistence using Effect modules.
-}

import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import I18n exposing (Language)
import Json.Decode as D
import Json.Decode.Pipeline as D
import Json.Encode as E
import Lamdera.Json as Json
import Theme exposing (Mode, UserPreference)



-- TYPES


type alias LocalStorage =
    { language : Language
    , userPreference : UserPreference
    , systemMode : Mode
    }


type LocalStorageUpdate
    = UpdateLanguage Language
    | UpdateUserPreference UserPreference
    | UpdateSystemMode Mode



-- PORTS


port storeLocalStorageValue_ : Json.Value -> Cmd msg


port receiveLocalStorage_ : (Json.Value -> msg) -> Sub msg


port getLocalStorage_ : Json.Value -> Cmd msg



-- COMMANDS


{-| Request localStorage data from JavaScript
-}
getLocalStorage : Command FrontendOnly toMsg msg
getLocalStorage =
    Command.sendToJs "getLocalStorage_" getLocalStorage_ E.null


{-| Store a value in localStorage
-}
storeValue : LocalStorageUpdate -> Command FrontendOnly toMsg msg
storeValue update =
    let
        ( key, value ) =
            case update of
                UpdateLanguage lang ->
                    ( "language", I18n.languageToString lang )

                UpdateUserPreference pref ->
                    ( "userPreference", Theme.userPreferenceToString pref )

                UpdateSystemMode mode ->
                    ( "systemMode", Theme.modeToString mode )
    in
    Command.sendToJs "storeLocalStorageValue_"
        storeLocalStorageValue_
        (E.object
            [ ( "key", E.string key )
            , ( "value", E.string value )
            ]
        )



-- SUBSCRIPTIONS


{-| Subscribe to localStorage updates
-}
receiveLocalStorage : (LocalStorage -> msg) -> Subscription FrontendOnly msg
receiveLocalStorage msg =
    Subscription.fromJs "receiveLocalStorage_"
        receiveLocalStorage_
        (Json.decodeValue (D.field "localStorage" localStorageDecoder)
            >> Result.withDefault defaultLocalStorage
            >> msg
        )



-- DECODERS


localStorageDecoder : Json.Decoder LocalStorage
localStorageDecoder =
    D.succeed LocalStorage
        |> D.required "language" (D.string |> D.map I18n.stringToLanguage)
        |> D.required "userPreference" (D.string |> D.map Theme.stringToUserPreference)
        |> D.required "systemMode" (D.string |> D.map Theme.stringToMode)



-- DEFAULTS


defaultLocalStorage : LocalStorage
defaultLocalStorage =
    { language = I18n.EN
    , userPreference = Theme.SystemMode
    , systemMode = Theme.Light
    }