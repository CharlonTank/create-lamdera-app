module RouterTests exposing (..)

import Expect
import I18n
import Router
import Test exposing (..)
import Url


suite : Test
suite =
    describe "Router Tests"
        [ describe "fromUrl"
            [ test "parses home route"
                (\_ ->
                    makeUrl "/"
                        |> Router.fromUrl
                        |> Expect.equal Router.Home
                )
            , test "parses about route"
                (\_ ->
                    makeUrl "/about"
                        |> Router.fromUrl
                        |> Expect.equal Router.About
                )
            , test "handles unknown routes as NotFound"
                (\_ ->
                    makeUrl "/unknown"
                        |> Router.fromUrl
                        |> Expect.equal Router.NotFound
                )
            , test "parses chat route"
                (\_ ->
                    makeUrl "/chat"
                        |> Router.fromUrl
                        |> Expect.equal Router.Chat
                )
            , test "handles complex unknown routes as NotFound"
                (\_ ->
                    makeUrl "/users/123/settings"
                        |> Router.fromUrl
                        |> Expect.equal Router.NotFound
                )
            ]
        , describe "toPath"
            [ test "converts Home to path"
                (\_ ->
                    Router.Home
                        |> Router.toPath
                        |> Expect.equal "/"
                )
            , test "converts About to path"
                (\_ ->
                    Router.About
                        |> Router.toPath
                        |> Expect.equal "/about"
                )
            , test "converts Chat to path"
                (\_ ->
                    Router.Chat
                        |> Router.toPath
                        |> Expect.equal "/chat"
                )
            , test "converts NotFound to path"
                (\_ ->
                    Router.NotFound
                        |> Router.toPath
                        |> Expect.equal "/not-found"
                )
            ]
        , describe "toTitle"
            [ test "provides Home title"
                (\_ ->
                    let
                        translations =
                            I18n.translations I18n.EN
                    in
                    Router.Home
                        |> Router.toTitle translations
                        |> Expect.equal "Home"
                )
            , test "provides About title"
                (\_ ->
                    let
                        translations =
                            I18n.translations I18n.EN
                    in
                    Router.About
                        |> Router.toTitle translations
                        |> Expect.equal "About"
                )
            , test "provides Chat title"
                (\_ ->
                    let
                        translations =
                            I18n.translations I18n.EN
                    in
                    Router.Chat
                        |> Router.toTitle translations
                        |> Expect.equal "Chat"
                )
            , test "provides NotFound title"
                (\_ ->
                    let
                        translations =
                            I18n.translations I18n.EN
                    in
                    Router.NotFound
                        |> Router.toTitle translations
                        |> Expect.equal "Page Not Found"
                )
            , test "provides French Home title"
                (\_ ->
                    let
                        translations =
                            I18n.translations I18n.FR
                    in
                    Router.Home
                        |> Router.toTitle translations
                        |> Expect.equal "Accueil"
                )
            ]
        ]


makeUrl : String -> Url.Url
makeUrl path =
    { protocol = Url.Http
    , host = "localhost"
    , port_ = Just 8000
    , path = path
    , query = Nothing
    , fragment = Nothing
    }
