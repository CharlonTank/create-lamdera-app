module Pages.Login exposing (view)

import Auth.Common
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import I18n exposing (Translations)
import Json.Decode
import Types exposing (..)


view : Translations -> FrontendModel -> Html FrontendMsg
view t model =
    div [ class "max-w-md mx-auto" ]
        [ div [ class "bg-white/20 dark:bg-black/30 backdrop-blur-md rounded-lg p-8 shadow-xl" ]
            [ h2 [ class "text-3xl font-bold text-white mb-6 text-center" ]
                [ text t.login ]
            , viewAuthError model.authFlow
            , viewLoginForm model.loginForm
            , div [ class "mt-6 text-center" ]
                [ p [ class "text-white/80" ]
                    [ text "Don't have an account? "
                    , a [ href "/register", class "text-white underline hover:text-white/80" ]
                        [ text "Register here" ]
                    ]
                ]
            ]
        ]


viewAuthError : Auth.Common.Flow -> Html msg
viewAuthError authFlow =
    case authFlow of
        Auth.Common.Errored error ->
            div [ class "mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded text-white" ]
                [ text ("Authentication error: " ++ authErrorToString error) ]

        _ ->
            text ""


authErrorToString : Auth.Common.Error -> String
authErrorToString error =
    case error of
        Auth.Common.ErrStateMismatch ->
            "State mismatch - please try logging in again"

        Auth.Common.ErrAuthorization authError ->
            "Authorization error - " ++ Maybe.withDefault "Unknown error" authError.errorDescription

        Auth.Common.ErrAuthentication authError ->
            "Authentication error - " ++ Maybe.withDefault "Unknown error" authError.errorDescription

        Auth.Common.ErrHTTPGetAccessToken ->
            "Failed to get access token"

        Auth.Common.ErrHTTPGetUserInfo ->
            "Failed to get user information"

        Auth.Common.ErrAuthString str ->
            str


viewLoginForm : LoginForm -> Html FrontendMsg
viewLoginForm form =
    Html.form [ onSubmit (BasicFrontendMsg SignInRequested) ]
        [ -- Email field
          div [ class "mb-4" ]
            [ label [ class "block text-white mb-2", for "email" ]
                [ text "Email" ]
            , input
                [ type_ "email"
                , id "email"
                , class "w-full px-4 py-2 rounded bg-white/20 text-white placeholder-white/50 backdrop-blur-sm border border-white/30 focus:outline-none focus:border-white/60"
                , placeholder "you@example.com"
                , value form.email
                , onInput (\email -> BasicFrontendMsg (UpdateLoginForm { form | email = email }))
                , required True
                ]
                []
            ]

        -- Password field
        , div [ class "mb-6" ]
            [ label [ class "block text-white mb-2", for "password" ]
                [ text "Password" ]
            , input
                [ type_ "password"
                , id "password"
                , class "w-full px-4 py-2 rounded bg-white/20 text-white placeholder-white/50 backdrop-blur-sm border border-white/30 focus:outline-none focus:border-white/60"
                , placeholder "••••••••"
                , value form.password
                , onInput (\password -> BasicFrontendMsg (UpdateLoginForm { form | password = password }))
                , required True
                ]
                []
            ]

        -- Error message
        , case form.error of
            Just error ->
                div [ class "mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded text-white" ]
                    [ text error ]

            Nothing ->
                text ""

        -- Submit button
        , button
            [ type_ "submit"
            , id "login-button"
            , onClick (BasicFrontendMsg SignInRequested)
            , class "w-full py-3 bg-white/20 hover:bg-white/30 text-white font-semibold rounded transition-colors backdrop-blur-sm border border-white/30"
            , disabled form.isSubmitting
            ]
            [ if form.isSubmitting then
                text "Logging in..."

              else
                text "Login"
            ]

        -- Google OAuth Sign In Button
        , button
            [ onClick (BasicFrontendMsg SignInWithGoogle)
            , type_ "button"
            , class "w-full mt-3 py-3 bg-red-600 hover:bg-red-700 text-white font-semibold rounded transition-colors flex items-center justify-center gap-2"
            ]
            [ text "🔐 Sign in with Google"
            ]

        -- GitHub OAuth Sign In Button
        , button
            [ onClick (BasicFrontendMsg SignInWithGithub)
            , type_ "button"
            , class "w-full mt-3 py-3 bg-gray-800 hover:bg-gray-900 text-white font-semibold rounded transition-colors flex items-center justify-center gap-2"
            ]
            [ text "🐙 Sign in with GitHub"
            ]

        -- Development notice
        , div
            [ class "mt-4 p-3 bg-yellow-100/10 border border-yellow-300/30 rounded" ]
            [ p [ class "text-yellow-100 text-xs" ]
                [ text "💡 For OAuth: Configure client IDs and secrets in "
                , span [ class "font-mono bg-black/20 px-1 rounded" ] [ text "src/Env.elm" ]
                , text ". See "
                , span [ class "font-mono bg-black/20 px-1 rounded" ] [ text "GOOGLE_ONE_TAP_SETUP.md" ]
                , text " and "
                , span [ class "font-mono bg-black/20 px-1 rounded" ] [ text "GITHUB_OAUTH_SETUP.md" ]
                , text " for instructions."
                ]
            ]
        ]


onSubmit : msg -> Attribute msg
onSubmit msg =
    Html.Events.preventDefaultOn "submit" (Json.Decode.succeed ( msg, True ))
