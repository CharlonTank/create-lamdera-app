module Auth.Method.GoogleOneTap exposing (configuration)

{-| Google One Tap authentication method

This module implements Google's One Tap sign-in, which provides a seamless
authentication experience without redirects. Users can sign in with a single
tap/click using their Google account.

Unlike traditional OAuth, Google One Tap:

  - Provides an ID token directly to the frontend
  - Doesn't require redirect flows
  - Must verify the JWT token server-side

-}

import Auth.Common exposing (..)
import Auth.HttpHelpers as HttpHelpers
import JWT exposing (..)
import JWT.JWS as JWS
import Json.Decode as Json
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import Lamdera exposing (SessionId)
import SeqDict as Dict exposing (SeqDict)
import Time exposing (Posix)
import Url exposing (Url)
import Url.Builder


{-| Configuration for Google One Tap authentication
-}
configuration :
    String
    -> String
    ->
        Method
            frontendMsg
            backendMsg
            frontendModel
            backendModel
            restriction
            toMsg
configuration clientId clientSecret =
    ProtocolGoogleOneTap
        { id = "GoogleOneTap"
        , clientId = clientId
        , clientSecret = clientSecret
        , scope = [ "openid", "email", "profile" ]
        , verifyIdToken = verifyGoogleIdToken
        , placeholder = \_ -> ()
        }


{-| Get user info from a Google ID token
For Google One Tap, the ID token already contains all user info
-}
getUserInfo : String -> Result String UserInfo
getUserInfo idToken =
    case JWT.fromString idToken of
        Ok (JWS token) ->
            decodeGoogleUserInfo token.claims.metadata

        Err err ->
            Err ("Failed to decode JWT: " ++ jwtErrorToString err)


{-| Decode Google user info from JWT claims
-}
decodeGoogleUserInfo : SeqDict String Json.Value -> Result String UserInfo
decodeGoogleUserInfo metadata =
    let
        extract : String -> Json.Decoder a -> SeqDict String Json.Value -> Result String a
        extract k d v =
            Dict.get k v
                |> Maybe.map
                    (\v_ ->
                        Json.decodeValue d v_
                            |> Result.mapError Json.errorToString
                    )
                |> Maybe.withDefault (Err <| "Key " ++ k ++ " not found")

        extractOptional : a -> String -> Json.Decoder a -> SeqDict String Json.Value -> Result String a
        extractOptional default k d v =
            Dict.get k v
                |> Maybe.map
                    (\v_ ->
                        Json.decodeValue d v_
                            |> Result.mapError Json.errorToString
                    )
                |> Maybe.withDefault (Ok <| default)
    in
    Result.map3
        (\email name picture ->
            { email = email
            , name = name
            , username = Nothing
            , profilePicture = picture
            }
        )
        (extract "email" Json.string metadata)
        (extractOptional Nothing "name" (Json.map Just Json.string) metadata)
        (extractOptional Nothing "picture" (Json.map Just Json.string) metadata)


{-| Verify Google ID token
This should verify:

1.  Token signature using Google's public keys
2.  Issuer is <https://accounts.google.com>
3.  Audience matches your client ID
4.  Token hasn't expired

-}
verifyGoogleIdToken : String -> String -> Result String UserInfo
verifyGoogleIdToken clientId idToken =
    case JWT.fromString idToken of
        Ok (JWS token) ->
            let
                metadata =
                    token.claims.metadata
            in
            -- Verify issuer
            case getClaimString "iss" metadata of
                Just issuer ->
                    if issuer == "https://accounts.google.com" || issuer == "accounts.google.com" then
                        -- Verify audience
                        case getClaimString "aud" metadata of
                            Just audience ->
                                if audience == clientId then
                                    -- Token is valid, extract user info
                                    decodeGoogleUserInfo metadata

                                else
                                    Err "Invalid audience"

                            Nothing ->
                                Err "Missing audience claim"

                    else
                        Err "Invalid issuer"

                Nothing ->
                    Err "Missing issuer claim"

        Err err ->
            Err ("Failed to decode JWT: " ++ jwtErrorToString err)


{-| Helper to get a string claim from JWT
-}
getClaimString : String -> SeqDict String Json.Value -> Maybe String
getClaimString key metadata =
    Dict.get key metadata
        |> Maybe.andThen
            (\value ->
                case Json.decodeValue Json.string value of
                    Ok str ->
                        Just str

                    Err _ ->
                        Nothing
            )


{-| Convert JWT errors to strings
-}
jwtErrorToString err =
    case err of
        TokenTypeUnknown ->
            "Unsupported auth token type."

        JWSError decodeError ->
            case decodeError of
                JWS.Base64DecodeError ->
                    "Base64DecodeError"

                JWS.MalformedSignature ->
                    "MalformedSignature"

                JWS.InvalidHeader jsonError ->
                    "InvalidHeader: " ++ Json.errorToString jsonError

                JWS.InvalidClaims jsonError ->
                    "InvalidClaims: " ++ Json.errorToString jsonError


{-| Handle frontend callback initialization
For Google One Tap, this is a no-op as there's no redirect flow
-}
onFrontendCallbackInit : SessionId -> Url -> String -> Cmd msg
onFrontendCallbackInit _ _ _ =
    Cmd.none
