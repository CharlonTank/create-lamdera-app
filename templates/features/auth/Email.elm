module Email exposing (sendWelcomeEmail)

import Effect.Command exposing (BackendOnly, Command)
import Effect.Http
import Effect.Task as Task
import Env
import Json.Encode as Encode
import Types exposing (User)


sendWelcomeEmail : User -> Command BackendOnly Types.ToFrontend Types.BackendMsg
sendWelcomeEmail user =
    if Env.environment == "development" then
        -- In development, the Lamdera proxy strips request bodies
        -- So we'll just log a success message instead of sending real emails
        let
            _ =
                Debug.log "Development Mode" ("Would send welcome email to: " ++ user.email)
        in
        Task.succeed "Email simulated in development mode"
            |> Task.attempt Types.EmailSent

    else
        -- In production, send real emails
        let
            baseUrl =
                "https://boilerplate.lamdera.app"

            emailData =
                Encode.object
                    [ ( "from", Encode.string Env.resendFromEmail )
                    , ( "to", Encode.list Encode.string [ user.email ] )
                    , ( "subject", Encode.string "Welcome to Boilerplate!" )
                    , ( "html", Encode.string (welcomeEmailHtml user baseUrl) )
                    ]

            bodyString =
                Encode.encode 0 emailData
        in
        Effect.Http.riskyRequest
            { method = "POST"
            , headers =
                [ Effect.Http.header "Authorization" ("Bearer " ++ Env.resendApiKey)
                , Effect.Http.header "Content-Type" "application/json"
                , Effect.Http.header "Accept" "application/json"
                ]
            , url = "https://api.resend.com/emails"
            , body = Effect.Http.stringBody "application/json" bodyString
            , expect = Effect.Http.expectString (httpStringToResult >> Types.EmailSent)
            , timeout = Nothing
            , tracker = Nothing
            }


httpStringToResult : Result Effect.Http.Error String -> Result Effect.Http.Error String
httpStringToResult result =
    result


welcomeEmailHtml : User -> String -> String
welcomeEmailHtml user baseUrl =
    let
        userName =
            Maybe.withDefault user.email user.name

        loginUrl =
            baseUrl ++ "/login"
    in
    """
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 16px; overflow: hidden;">
        <div style="padding: 30px 40px; background: #fff; margin: 6px; border-radius: 12px;">
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #667eea; font-size: 28px; margin-top: 15px;">Welcome to Boilerplate!</h1>
            </div>

            <p style="font-size: 16px; line-height: 1.6; color: #333;">Hello """ ++ userName ++ """,</p>

            <p style="font-size: 16px; line-height: 1.6; color: #333;">We're excited to have you on board! Your account has been successfully created.</p>

            <div style="background-color: #f7fafc; border-radius: 10px; padding: 20px; margin: 30px 0;">
                <h2 style="color: #667eea; font-size: 18px; margin-top: 0;">Get started in 3 simple steps:</h2>
                <ol style="padding-left: 20px; color: #333;">
                    <li style="margin-bottom: 10px;"><strong>Create your account</strong> ✓ Already done!</li>
                    <li style="margin-bottom: 10px;"><strong>Explore the features</strong> - Check out what you can do</li>
                    <li style="margin-bottom: 0;"><strong>Start building</strong> - Create something amazing</li>
                </ol>
            </div>

            <div style="text-align: center; margin: 40px 0 30px;">
                <a href=\"""" ++ loginUrl ++ """" style="display: inline-block; background-color: #667eea; color: white; text-decoration: none; padding: 12px 30px; border-radius: 50px; font-weight: bold; font-size: 16px;">Access My Account</a>
            </div>

            <p style="font-size: 16px; line-height: 1.6; color: #333;">If you have any questions or need assistance, our support team is here to help.</p>

            <p style="font-size: 16px; line-height: 1.6; color: #333;">Best regards,<br>The Boilerplate Team</p>
        </div>
        <div style="text-align: center; padding: 20px; font-size: 12px; color: white;">
            © 2025 Boilerplate - All rights reserved<br>
            <a href=\"""" ++ baseUrl ++ """/privacy" style="color: white; text-decoration: underline;">Privacy Policy</a> ·
            <a href=\"""" ++ baseUrl ++ """/terms" style="color: white; text-decoration: underline;">Terms of Service</a>
        </div>
    </div>
    """
