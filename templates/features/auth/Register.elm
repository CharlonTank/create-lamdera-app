module Pages.Register exposing (view)

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
                [ text t.register ]
            , viewRegisterForm model.registerForm
            , div [ class "mt-6 text-center" ]
                [ p [ class "text-white/80" ]
                    [ text t.alreadyHaveAccount
                    , a [ href "/login", class "text-white underline hover:text-white/80" ]
                        [ text t.loginHere ]
                    ]
                ]
            ]
        ]


viewRegisterForm : RegisterForm -> Html FrontendMsg
viewRegisterForm form =
    Html.form [ onSubmit (BasicFrontendMsg RegisterRequested) ]
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
                , onInput (\email -> BasicFrontendMsg (UpdateRegisterForm { form | email = email }))
                , required True
                ]
                []
            ]

        -- Username field
        , div [ class "mb-4" ]
            [ label [ class "block text-white mb-2", for "username" ]
                [ text "Username" ]
            , input
                [ type_ "text"
                , id "username"
                , class "w-full px-4 py-2 rounded bg-white/20 text-white placeholder-white/50 backdrop-blur-sm border border-white/30 focus:outline-none focus:border-white/60"
                , placeholder "johndoe"
                , value form.username
                , onInput (\username -> BasicFrontendMsg (UpdateRegisterForm { form | username = username }))
                , required True
                ]
                []
            ]

        -- Name field
        , div [ class "mb-4" ]
            [ label [ class "block text-white mb-2", for "name" ]
                [ text "Full Name" ]
            , input
                [ type_ "text"
                , id "name"
                , class "w-full px-4 py-2 rounded bg-white/20 text-white placeholder-white/50 backdrop-blur-sm border border-white/30 focus:outline-none focus:border-white/60"
                , placeholder "John Doe"
                , value form.name
                , onInput (\name -> BasicFrontendMsg (UpdateRegisterForm { form | name = name }))
                , required True
                ]
                []
            ]

        -- Password field
        , div [ class "mb-4" ]
            [ label [ class "block text-white mb-2", for "password" ]
                [ text "Password" ]
            , input
                [ type_ "password"
                , id "password"
                , class "w-full px-4 py-2 rounded bg-white/20 text-white placeholder-white/50 backdrop-blur-sm border border-white/30 focus:outline-none focus:border-white/60"
                , placeholder "••••••••"
                , value form.password
                , onInput (\password -> BasicFrontendMsg (UpdateRegisterForm { form | password = password }))
                , required True
                , minlength 6
                ]
                []
            ]

        -- Confirm Password field
        , div [ class "mb-6" ]
            [ label [ class "block text-white mb-2", for "confirmPassword" ]
                [ text "Confirm Password" ]
            , input
                [ type_ "password"
                , id "confirmPassword"
                , class "w-full px-4 py-2 rounded bg-white/20 text-white placeholder-white/50 backdrop-blur-sm border border-white/30 focus:outline-none focus:border-white/60"
                , placeholder "••••••••"
                , value form.confirmPassword
                , onInput (\confirmPassword -> BasicFrontendMsg (UpdateRegisterForm { form | confirmPassword = confirmPassword }))
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
            , id "register-button"
            , onClick (BasicFrontendMsg RegisterRequested)
            , class "w-full py-3 bg-white/20 hover:bg-white/30 text-white font-semibold rounded transition-colors backdrop-blur-sm border border-white/30"
            , disabled form.isSubmitting
            ]
            [ if form.isSubmitting then
                text "Creating account..."

              else
                text "Register"
            ]
        ]


onSubmit : msg -> Attribute msg
onSubmit msg =
    Html.Events.preventDefaultOn "submit" (Json.Decode.succeed ( msg, True ))
