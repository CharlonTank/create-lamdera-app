port module LocalStorage exposing (..)

{-| This module handles local storage for user preferences.
It manages language and theme preferences persistence.
-}

import I18n exposing (Language)
import Json.Decode as D
import Json.Encode as E
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


port storeLocalStorageValue_ : E.Value -> Cmd msg


port receiveLocalStorage_ : (E.Value -> msg) -> Sub msg


port getLocalStorage_ : () -> Cmd msg



-- COMMANDS


{-| Request localStorage data from JavaScript
-}
getLocalStorage : Cmd msg
getLocalStorage =
    getLocalStorage_ ()


{-| Store a value in localStorage
-}
storeValue : LocalStorageUpdate -> Cmd msg
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
    storeLocalStorageValue_
        (E.object
            [ ( "key", E.string key )
            , ( "value", E.string value )
            ]
        )



-- SUBSCRIPTIONS


{-| Subscribe to localStorage updates
-}
receiveLocalStorage : (LocalStorage -> msg) -> Sub msg
receiveLocalStorage msg =
    receiveLocalStorage_
        (\value ->
            case D.decodeValue (D.field "localStorage" localStorageDecoder) value of
                Ok localStorage ->
                    msg localStorage

                Err _ ->
                    msg defaultLocalStorage
        )



-- DECODERS


localStorageDecoder : D.Decoder LocalStorage
localStorageDecoder =
    D.map3 LocalStorage
        (D.field "language" (D.string |> D.map I18n.stringToLanguage))
        (D.field "userPreference" (D.string |> D.map Theme.stringToUserPreference))
        (D.field "systemMode" (D.string |> D.map Theme.stringToMode))



-- DEFAULTS


defaultLocalStorage : LocalStorage
defaultLocalStorage =
    { language = I18n.EN
    , userPreference = Theme.SystemMode
    , systemMode = Theme.Light
    }