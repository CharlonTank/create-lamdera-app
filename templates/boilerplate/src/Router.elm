module Router exposing (Route(..), fromUrl, toPath, toTitle)

import I18n
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


type Route
    = Home
    | About
    | Chat
    | Login
    | Register
    | Admin
    | OAuthCallback String String
    | NotFound


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map About (Parser.s "about")
        , Parser.map Chat (Parser.s "chat")
        , Parser.map Login (Parser.s "login")
        , Parser.map Register (Parser.s "register")
        , Parser.map Admin (Parser.s "admin")
        , Parser.s "login"
            </> Parser.string
            </> Parser.s "callback"
            <?> Query.string "state"
            <?> Query.string "code"
            |> Parser.map
                (\_ maybeState maybeCode ->
                    case ( maybeState, maybeCode ) of
                        ( Just state, Just code ) ->
                            OAuthCallback state code

                        _ ->
                            NotFound
                )
        ]


fromUrl : Url -> Route
fromUrl url =
    Parser.parse parser url
        |> Maybe.withDefault NotFound


toPath : Route -> String
toPath route =
    case route of
        Home ->
            "/"

        About ->
            "/about"

        Chat ->
            "/chat"

        Login ->
            "/login"

        Register ->
            "/register"

        Admin ->
            "/admin"

        OAuthCallback state code ->
            "/login/OAuthGoogle/callback?state=" ++ state ++ "&code=" ++ code

        NotFound ->
            "/not-found"


toTitle : I18n.Translations -> Route -> String
toTitle t route =
    case route of
        Home ->
            t.homeTitle

        About ->
            t.aboutTitle

        Chat ->
            t.chatTitle

        Login ->
            t.loginTitle

        Register ->
            t.registerTitle

        Admin ->
            t.adminTitle

        OAuthCallback _ _ ->
            t.oauthCallbackTitle

        NotFound ->
            t.notFoundTitle
