module Tests exposing (..)

import Test exposing (..)


suite : Test
suite =
    describe "Placeholder Tests"
        [ test "placeholder test" <|
            \_ ->
                1
                    |> Basics.identity
                    |> Expect.equal 1
        ]
