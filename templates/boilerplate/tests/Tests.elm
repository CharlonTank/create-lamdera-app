module Tests exposing (..)

import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Placeholder Tests"
        [ test "placeholder test" <|
            \_ ->
                Expect.equal 1 1
        ]
