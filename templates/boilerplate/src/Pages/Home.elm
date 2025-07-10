module Pages.Home exposing (view)

import Effect.Lamdera exposing (ClientId)
import Html exposing (..)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick)
import I18n exposing (Translations)
import RemoteData exposing (RemoteData)
import Types exposing (..)


view : Translations -> FrontendModel -> Html FrontendMsg
view t model =
    div []
        [ div [ class "text-center mb-12 mt-8" ]
            [ h1 [ class "text-5xl font-bold text-white mb-4 drop-shadow-lg" ]
                [ text ("🔄 " ++ t.counter) ]
            , p [ class "text-xl text-white/90" ]
                [ text t.welcome ]
            ]

        -- Counter Card
        , div [ class "max-w-md mx-auto mb-12" ]
            [ div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl p-8" ]
                [ viewCounter model.counter t

                -- Counter Buttons
                , div [ class "flex gap-4 justify-center mb-6" ]
                    [ button
                        [ onClick (BasicFrontendMsg Decrement)
                        , class "px-8 py-4 bg-red-500 dark:bg-red-600 text-white text-2xl font-semibold rounded-lg shadow-md hover:bg-red-600 dark:hover:bg-red-700 transform hover:scale-105 transition-all duration-200"
                        , Attr.id "decrement-button"
                        ]
                        [ text t.decrement ]
                    , button
                        [ onClick (BasicFrontendMsg Increment)
                        , class "px-8 py-4 bg-green-500 dark:bg-green-600 text-white text-2xl font-semibold rounded-lg shadow-md hover:bg-green-600 dark:hover:bg-green-700 transform hover:scale-105 transition-all duration-200"
                        , Attr.id "increment-button"
                        ]
                        [ text t.increment ]
                    ]

                -- Last Update Info
                , viewUpdateInfo model.counter model.lastUpdatedBy t
                ]
            ]

        -- Feature Cards
        , div [ class "grid md:grid-cols-3 gap-6 mb-12" ]
            [ viewCard "🌍" t.multiLanguage t.multiLanguageDesc "blue"
            , viewCard "🎨" t.tailwindIntegration t.tailwindIntegrationDesc "purple"
            , viewCard "🧪" t.testSupport t.testSupportDesc "green"
            ]
        ]


viewCounter : RemoteData String Int -> Translations -> Html msg
viewCounter counterData _ =
    div
        [ class "text-7xl font-bold text-center mb-8 text-purple-600 dark:text-purple-400"
        , Attr.id "counter-value"
        ]
        [ case counterData of
            RemoteData.NotAsked ->
                text "..."

            RemoteData.Loading ->
                text "⏳"

            RemoteData.Failure error ->
                div [ class "text-2xl text-red-500" ]
                    [ text ("Error: " ++ error) ]

            RemoteData.Success value ->
                text (String.fromInt value)
        ]


viewUpdateInfo : RemoteData String Int -> Maybe ClientId -> Translations -> Html msg
viewUpdateInfo counterData lastUpdatedBy t =
    div [ class "text-center text-gray-600 dark:text-gray-400 text-sm" ]
        [ case counterData of
            RemoteData.NotAsked ->
                text t.waitingForUpdate

            RemoteData.Loading ->
                text t.waitingForUpdate

            RemoteData.Failure error ->
                text ("Error: " ++ error)

            RemoteData.Success _ ->
                text
                    (case lastUpdatedBy of
                        Nothing ->
                            t.waitingForUpdate

                        Just clientId ->
                            t.lastUpdatedBy ++ ": " ++ Effect.Lamdera.clientIdToString clientId
                    )
        ]


viewCard : String -> String -> String -> String -> Html msg
viewCard icon title description colorName =
    div [ class "bg-white dark:bg-gray-800 rounded-lg shadow-xl p-6 transform hover:scale-105 transition-all duration-200" ]
        [ div [ class ("text-" ++ colorName ++ "-600 dark:text-" ++ colorName ++ "-400 mb-4") ]
            [ h2 [ class "text-2xl font-semibold flex items-center gap-2" ]
                [ span [ class "text-3xl" ] [ text icon ]
                , text title
                ]
            ]
        , p [ class "text-gray-600 dark:text-gray-300" ]
            [ text description ]
        ]
