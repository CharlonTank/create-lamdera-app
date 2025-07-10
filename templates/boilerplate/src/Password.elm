module Password exposing
    ( EncryptedPassword
    , encrypt
    , verify
    )

{-| Password encryption and verification module.

In a real application, you would use bcrypt or similar.
For this demo, we'll use a simple salted hash approach.

-}

import SHA256


type EncryptedPassword
    = EncryptedPassword String


{-| A fixed salt for demo purposes. In production, use a random salt per password.
-}
salt : String
salt =
    "lamdera-demo-salt-2024"


{-| Encrypt a plain text password
-}
encrypt : String -> EncryptedPassword
encrypt plainPassword =
    EncryptedPassword (SHA256.toHex (SHA256.fromString (salt ++ plainPassword)))


{-| Verify a plain text password against an encrypted one
-}
verify : String -> EncryptedPassword -> Bool
verify plainPassword (EncryptedPassword encrypted) =
    SHA256.toHex (SHA256.fromString (salt ++ plainPassword)) == encrypted
