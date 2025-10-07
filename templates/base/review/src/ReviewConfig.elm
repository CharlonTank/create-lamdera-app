module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import NoUnused.CustomTypeConstructors
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
-- import NoUnused.Dependencies
import OpaqueTypes
import Review.Rule exposing (Rule)
import ReviewPipelineStyles
import ReviewPipelineStyles.Fixes


config : List Rule
config =
    [ OpaqueTypes.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Variables.rule
    , NoUnused.Patterns.rule
    , NoUnused.Exports.rule
    , NoUnused.Modules.rule
    , NoUnused.Parameters.rule
    -- , NoUnused.Dependencies.rule
    , ReviewPipelineStyles.rule
        [ ReviewPipelineStyles.forbid ReviewPipelineStyles.leftPizzaPipelines
            |> ReviewPipelineStyles.andTryToFixThemBy ReviewPipelineStyles.Fixes.convertingToParentheticalApplication
            |> ReviewPipelineStyles.andCallThem "forbidden <| pipeline"
        , ReviewPipelineStyles.forbid ReviewPipelineStyles.leftCompositionPipelines
            |> ReviewPipelineStyles.andTryToFixThemBy ReviewPipelineStyles.Fixes.convertingToRightComposition
            |> ReviewPipelineStyles.andCallThem "forbidden << composition"
        ]
    ]
        |> List.map (Review.Rule.ignoreErrorsForDirectories [ "src/Evergreen", "elm-auth" ])
