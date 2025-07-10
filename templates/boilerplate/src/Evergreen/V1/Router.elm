module Evergreen.V1.Router exposing (..)


type Route
    = Home
    | About
    | Chat
    | Login
    | Register
    | Admin
    | OAuthCallback String String
    | NotFound
