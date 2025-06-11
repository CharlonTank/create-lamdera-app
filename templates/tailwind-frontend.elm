module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (class, src)
import Lamdera
import Types exposing (..)
import Url


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \m -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    ( { key = key
      , message = "Welcome to Lamdera with Tailwind CSS!"
      }
    , Cmd.none
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            ( model, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Lamdera + Tailwind"
    , body =
        [ div [ class "min-h-screen bg-gradient-to-br from-purple-400 via-pink-500 to-red-500" ]
            [ div [ class "container mx-auto px-4 py-16" ]
                [ -- Header
                  div [ class "text-center mb-12" ]
                    [ img [ src "https://lamdera.app/lamdera-logo-black.png", class "h-20 mx-auto mb-8 drop-shadow-lg" ] []
                    , h1 [ class "text-5xl font-bold text-white mb-4 drop-shadow-lg" ] 
                        [ text "Lamdera + Tailwind CSS" ]
                    , p [ class "text-xl text-white/90" ] 
                        [ text model.message ]
                    ]
                
                -- Cards Section
                , div [ class "grid md:grid-cols-3 gap-6 mb-12" ]
                    [ -- Card 1
                      div [ class "bg-white rounded-lg shadow-xl p-6 transform hover:scale-105 transition-transform duration-200" ]
                        [ div [ class "text-purple-600 mb-4" ]
                            [ h2 [ class "text-2xl font-semibold" ] [ text "🚀 Fast Development" ]
                            ]
                        , p [ class "text-gray-600" ]
                            [ text "Tailwind utilities work seamlessly with Elm's functional approach" ]
                        ]
                    
                    -- Card 2
                    , div [ class "bg-white rounded-lg shadow-xl p-6 transform hover:scale-105 transition-transform duration-200" ]
                        [ div [ class "text-pink-600 mb-4" ]
                            [ h2 [ class "text-2xl font-semibold" ] [ text "🎨 Beautiful Design" ]
                            ]
                        , p [ class "text-gray-600" ]
                            [ text "Create stunning UIs with utility-first CSS classes" ]
                        ]
                    
                    -- Card 3
                    , div [ class "bg-white rounded-lg shadow-xl p-6 transform hover:scale-105 transition-transform duration-200" ]
                        [ div [ class "text-red-600 mb-4" ]
                            [ h2 [ class "text-2xl font-semibold" ] [ text "⚡ Hot Reload" ]
                            ]
                        , p [ class "text-gray-600" ]
                            [ text "See your changes instantly with lamdera-dev-watch" ]
                        ]
                    ]
                
                -- Button Examples
                , div [ class "text-center space-y-4" ]
                    [ h2 [ class "text-3xl font-bold text-white mb-6" ] [ text "Button Examples" ]
                    , div [ class "flex flex-wrap gap-4 justify-center" ]
                        [ button [ class "px-6 py-3 bg-blue-500 text-white font-semibold rounded-lg shadow-md hover:bg-blue-700 transform hover:scale-105 transition-all duration-200" ]
                            [ text "Primary Button" ]
                        , button [ class "px-6 py-3 bg-green-500 text-white font-semibold rounded-lg shadow-md hover:bg-green-700 transform hover:scale-105 transition-all duration-200" ]
                            [ text "Success Button" ]
                        , button [ class "px-6 py-3 bg-gray-800 text-white font-semibold rounded-lg shadow-md hover:bg-gray-900 transform hover:scale-105 transition-all duration-200" ]
                            [ text "Dark Button" ]
                        , button [ class "px-6 py-3 bg-white text-purple-600 font-semibold rounded-lg shadow-md hover:bg-gray-100 transform hover:scale-105 transition-all duration-200" ]
                            [ text "Light Button" ]
                        ]
                    ]
                
                -- Footer
                , div [ class "mt-16 text-center text-white/80" ]
                    [ p [ class "mb-2" ] [ text "Edit src/Frontend.elm to customize this page" ]
                    , p [ class "text-sm" ] 
                        [ text "Tailwind classes are automatically detected and compiled" ]
                    ]
                ]
            ]
        ]
    }