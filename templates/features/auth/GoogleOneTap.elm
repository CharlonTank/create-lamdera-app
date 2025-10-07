port module GoogleOneTap exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode



-- PORTS


port initializeGoogleOneTap : Encode.Value -> Cmd msg


port googleOneTapSignOut : () -> Cmd msg


port googleOneTapResponse : (Decode.Value -> msg) -> Sub msg


port googleOneTapStatus : (Decode.Value -> msg) -> Sub msg



-- TYPES


type alias OneTapResponse =
    { credential : String
    }


type OneTapStatus
    = NotDisplayed String
    | Skipped
    | Unknown



-- ENCODERS


encodeInit : String -> Encode.Value
encodeInit clientId =
    Encode.object
        [ ( "clientId", Encode.string clientId )
        ]



-- DECODERS


decodeOneTapResponse : Decode.Decoder OneTapResponse
decodeOneTapResponse =
    Decode.map OneTapResponse
        (Decode.field "credential" Decode.string)


decodeOneTapStatus : Decode.Decoder OneTapStatus
decodeOneTapStatus =
    Decode.field "status" Decode.string
        |> Decode.andThen
            (\status ->
                case status of
                    "not_displayed" ->
                        Decode.map NotDisplayed (Decode.field "reason" Decode.string)

                    "skipped" ->
                        Decode.succeed Skipped

                    _ ->
                        Decode.succeed Unknown
            )



-- Port wrappers for Lamdera


initializeGoogleOneTapWrapper : Encode.Value -> Cmd msg
initializeGoogleOneTapWrapper value =
    initializeGoogleOneTap value


googleOneTapSignOutWrapper : Encode.Value -> Cmd msg
googleOneTapSignOutWrapper _ =
    googleOneTapSignOut ()
