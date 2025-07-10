module Pages.About exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class)
import I18n exposing (Translations)
import Types exposing (..)


view : Translations -> Html FrontendMsg
view _ =
    div []
        [ div [ class "text-center mb-12 mt-8" ]
            [ h1 [ class "text-5xl font-bold text-white mb-4 drop-shadow-lg" ]
                [ text "📄 About" ]
            , p [ class "text-xl text-white/90" ]
                [ text "Learn more about this Lamdera application" ]
            ]

        -- About Content
        , div [ class "max-w-4xl mx-auto" ]
            [ div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl p-8 mb-8" ]
                [ h2 [ class "text-3xl font-bold text-purple-600 dark:text-purple-400 mb-6" ]
                    [ text "About This App" ]
                , div [ class "prose dark:prose-invert max-w-none" ]
                    [ p [ class "text-lg text-gray-700 dark:text-gray-300 mb-4" ]
                        [ text "This is a Lamdera application with routing, built using the create-lamdera-app boilerplate. It demonstrates:" ]
                    , ul [ class "list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2 mb-6" ]
                        [ li [] [ text "Client-server synchronization with Lamdera" ]
                        , li [] [ text "Multi-language support (English and French)" ]
                        , li [] [ text "Dark/light theme switching" ]
                        , li [] [ text "Tailwind CSS styling" ]
                        , li [] [ text "Client-side routing" ]
                        , li [] [ text "LocalStorage integration" ]
                        ]
                    ]
                ]

            -- Tech Stack
            , div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl p-8" ]
                [ h2 [ class "text-3xl font-bold text-purple-600 dark:text-purple-400 mb-6" ]
                    [ text "Tech Stack" ]
                , div [ class "grid md:grid-cols-2 gap-6" ]
                    [ div []
                        [ h3 [ class "text-xl font-semibold text-gray-800 dark:text-gray-200 mb-3" ]
                            [ text "Frontend" ]
                        , ul [ class "list-disc list-inside text-gray-700 dark:text-gray-300 space-y-1" ]
                            [ li [] [ text "Elm" ]
                            , li [] [ text "Tailwind CSS" ]
                            , li [] [ text "Client-side routing" ]
                            ]
                        ]
                    , div []
                        [ h3 [ class "text-xl font-semibold text-gray-800 dark:text-gray-200 mb-3" ]
                            [ text "Backend" ]
                        , ul [ class "list-disc list-inside text-gray-700 dark:text-gray-300 space-y-1" ]
                            [ li [] [ text "Lamdera" ]
                            , li [] [ text "Real-time synchronization" ]
                            , li [] [ text "Persistent state" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
