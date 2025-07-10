module Evergreen.V8.Router exposing (..)


type Route
    = Home
    | About
    | Chat
    | Login
    | Register
    | Admin
    | OAuthCallback String String
    | NotFound
