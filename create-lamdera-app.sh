#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) is not installed. Please install it to use the GitHub repository creation feature.${NC}"
    echo -e "${BLUE}You can continue without GitHub repository creation.${NC}"
fi

# Check if lamdera is installed
if ! command -v lamdera &> /dev/null; then
    echo -e "${RED}Lamdera is not installed. Please install it first.${NC}"
    exit 1
fi

# Ask for project name
echo -e "${CYAN}Enter your project name:${NC}"
read project_name

# Create project directory
mkdir "$project_name"
cd "$project_name"

# Initialize Lamdera project
echo -e "${BLUE}Initializing Lamdera project...${NC}"
lamdera init

# Install default packages
echo -e "${BLUE}Installing default packages...${NC}"
yes | lamdera install elm/http
yes | lamdera install elm/time
yes | lamdera install elm/json

# Create utility files
echo -e "${BLUE}Creating utility files...${NC}"

# Create .cursorrules
cat > .cursorrules << 'EOL'
An action by a user/player will always be a FrontendMsg.
Then, as a side effect, it's possible that we want to talk to the backend, for that we will use Lamdera.sendToBackend with a ToBackend variant.
After making some modifications you must run `lamdera make src/Frontend.elm src/Backend.elm` so see the compilation errors.
If you're making some tests: use elm-test to test the tests!
When you want to create a migration first run lamdera check, then complete the migrations that have been generated.
When you need to add a dependency, please use yes | lamdera install instead of modifying directly the elm.json
When you fix compilation errors, look around before going straight to try to fix. Avoid to use anonymous fonctions, because most of the time when you do, it's because you don't understand the compilation error.
When you're fixing compilation errors from lamdera make, just fix ONE, then compile again to see if you fixed it before going to the next one

DO NOT ADD/MODIFY SOMETHING I DIDN'T ASKED YOU TO DO
EOL

# Create lamdera-dev-watch.sh
cat > lamdera-dev-watch.sh << 'EOL'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PORT=8000

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port=*) PORT="${1#*=}" ;;
        *) echo -e "${RED}Unknown parameter: $1${NC}"; exit 1 ;;
    esac
    shift
done

export GREEN BLUE YELLOW CYAN RED NC PORT

show_banner() {
    clear
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════╗" 
    echo "║         Lamdera Development Server        ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}
export -f show_banner

file_changed_message() {
    echo -e "\n${YELLOW}File changed: ${CYAN}$1${NC}"
    echo -e "${BLUE}Restarting Lamdera server...${NC}\n"
}
export -f file_changed_message

start_lamdera() {
    if [ -f /tmp/lamdera.pid ]; then
        local pid=$(cat /tmp/lamdera.pid)
        kill $pid 2>/dev/null || true
        sleep 0.2
        kill -9 $pid 2>/dev/null || true
        rm -f /tmp/lamdera.pid
    fi

    lamdera live --port=$PORT > /tmp/lamdera.log 2>&1 &
    echo $! > /tmp/lamdera.pid
    
    for i in {1..10}; do
        if lsof -ti:$PORT >/dev/null 2>&1; then
            echo -e "${GREEN}Server started on ${CYAN}http://localhost:$PORT${NC}\n"
            return 0
        fi
        sleep 0.1
    done
}
export -f start_lamdera

stop_lamdera() {
    if [ -f /tmp/lamdera.pid ]; then
        local pid=$(cat /tmp/lamdera.pid)
        kill $pid 2>/dev/null || true
        sleep 0.2
        kill -9 $pid 2>/dev/null || true
        rm -f /tmp/lamdera.pid
    fi
}
export -f stop_lamdera

cleanup() {
    stop_lamdera
    rm -f /tmp/lamdera.pid /tmp/lamdera.log
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

show_banner
echo -e "${BLUE}Watching for changes in elm-pkg-js/*.js${NC}\n"
start_lamdera

if command -v inotifywait >/dev/null 2>&1; then
    while true; do
        inotifywait -q -e modify -r elm-pkg-js/ 2>/dev/null | while read -r directory events filename; do
            if [[ "$filename" == *.js ]]; then
                show_banner
                file_changed_message "$directory$filename"
                start_lamdera
            fi
        done
    done
else
    touch /tmp/last_check
    while true; do
        find elm-pkg-js -name "*.js" -newer /tmp/last_check 2>/dev/null | while read file; do
            if [ -n "$file" ]; then
                show_banner
                file_changed_message "$file"
                start_lamdera
            fi
        done
        touch /tmp/last_check
        sleep 0.2
    done
fi
EOL

# Create openeditor.sh
cat > openeditor.sh << 'EOL'
#!/bin/bash
/usr/local/bin/cursor -g "$1:$2:$3"
EOL

# Create toggle_debugger.py
cat > toggle_debugger.py << 'EOL'
#!/usr/bin/env python3

import os
import subprocess
import random
import string
import webbrowser


def check_toggling_state():
    return os.path.exists("src/Debuggy/App.elm")


def toggle_debugger_backend(toggling_on=False):
    file_path = "src/Backend.elm"
    with open(file_path, "r") as file:
        lines = file.readlines()

    if toggling_on:
        # Add Debuggy.App import if it doesn't exist
        if "import Debuggy.App" not in "".join(lines):
            lines.insert(1, "import Debuggy.App\n")

        # Replace Lamdera.backend with Debuggy.App.backend
        new_token = "".join(random.choices(string.ascii_letters + string.digits, k=16))
        for i, line in enumerate(lines):
            if "Lamdera.backend" in line:
                lines[i] = line.replace(
                    "Lamdera.backend",
                    f'Debuggy.App.backend NoOpBackendMsg "{new_token}"',
                )

        print(f"New token generated: {new_token}")
        webbrowser.open(f"https://backend-debugger.lamdera.app/{new_token}")
    else:
        # Remove Debuggy.App import
        lines = [
            line for line in lines if not line.strip().startswith("import Debuggy.App")
        ]

        # Replace Debuggy.App.backend with Lamdera.backend
        for i, line in enumerate(lines):
            if "Debuggy.App.backend" in line:
                lines[i] = line.replace(
                    "Debuggy.App.backend NoOpBackendMsg", "Lamdera.backend"
                )
                lines[i + 1] = ""

    with open(file_path, "w") as file:
        file.writelines(lines)

    subprocess.run(["elm-format", file_path, "--yes"])


def toggle_debugger_app(toggling_on):
    file_path = "src/Debuggy/App.elm"
    if toggling_on:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, "w") as file:
            file.write(
                """module Debuggy.App exposing (backend)

import Http
import Json.Encode
import Lamdera exposing (ClientId, SessionId)
import Task
import Time


backend :
    backendMsg
    -> String
    ->
        { init : ( backendModel, Cmd backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
        , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
        , subscriptions : backendModel -> Sub backendMsg
        }
    ->
        { init : ( backendModel, Cmd backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
        , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
        , subscriptions : backendModel -> Sub backendMsg
        }
backend backendNoOp sessionName { init, update, updateFromFrontend, subscriptions } =
    { init =
        let
            ( model, cmd ) =
                init
        in
        ( model
        , Cmd.batch
            [ cmd
            , sendToViewer
                backendNoOp
                (Init { sessionName = sessionName, model = Debug.toString model })
            ]
        )
    , update =
        \\msg model ->
            let
                ( newModel, cmd ) =
                    update msg model
            in
            ( newModel
            , Cmd.batch
                [ cmd
                , if backendNoOp == msg then
                    Cmd.none

                  else
                    sendToViewer
                        backendNoOp
                        (Update
                            { sessionName = sessionName
                            , msg = Debug.toString msg
                            , newModel = Debug.toString newModel
                            }
                        )
                ]
            )
    , updateFromFrontend =
        \\sessionId clientId msg model ->
            let
                ( newModel, cmd ) =
                    updateFromFrontend sessionId clientId msg model
            in
            ( newModel
            , Cmd.batch
                [ cmd
                , sendToViewer
                    backendNoOp
                    (UpdateFromFrontend
                        { sessionName = sessionName
                        , msg = Debug.toString msg
                        , newModel = Debug.toString newModel
                        , sessionId = sessionId
                        , clientId = clientId
                        }
                    )
                ]
            )
    , subscriptions = subscriptions
    }


type DataType
    = Init { sessionName : String, model : String }
    | Update { sessionName : String, msg : String, newModel : String }
    | UpdateFromFrontend { sessionName : String, msg : String, newModel : String, sessionId : String, clientId : String }


sendToViewer : msg -> DataType -> Cmd msg
sendToViewer backendNoOp data =
    Time.now
        |> Task.andThen
            (\\time ->
                Http.task
                    { method = "POST"
                    , headers = []
                    , url = "http://localhost:8001/https://backend-debugger.lamdera.app/_r/data"
                    , body = Http.jsonBody (encodeDataType time data)
                    , resolver = Http.bytesResolver (\\_ -> Ok ())
                    , timeout = Just 10000
                    }
            )
        |> Task.attempt (\\_ -> backendNoOp)


encodeTime : Time.Posix -> Json.Encode.Value
encodeTime time =
    Time.posixToMillis time |> Json.Encode.int


encodeDataType : Time.Posix -> DataType -> Json.Encode.Value
encodeDataType time data =
    Json.Encode.list
        identity
        (case data of
            Init { sessionName, model } ->
                [ Json.Encode.int 0
                , Json.Encode.string sessionName
                , Json.Encode.string model
                , Json.Encode.null
                , encodeTime time
                ]

            Update { sessionName, msg, newModel } ->
                [ Json.Encode.int 1
                , Json.Encode.string sessionName
                , Json.Encode.string msg
                , Json.Encode.string newModel
                , Json.Encode.null
                , encodeTime time
                ]

            UpdateFromFrontend { sessionName, msg, newModel, sessionId, clientId } ->
                [ Json.Encode.int 2
                , Json.Encode.string sessionName
                , Json.Encode.string msg
                , Json.Encode.string newModel
                , Json.Encode.string sessionId
                , Json.Encode.string clientId
                , Json.Encode.null
                , encodeTime time
                ]
        )
"""
            )

    else:
        if os.path.exists(file_path):
            os.remove(file_path)


def main():
    toggling_on = not check_toggling_state()
    toggle_debugger_backend(toggling_on=toggling_on)
    toggle_debugger_app(toggling_on)
    print(f"Debugger {'enabled' if toggling_on else 'disabled'}.")


if __name__ == "__main__":
    main()
EOL

# Make scripts executable
chmod +x lamdera-dev-watch.sh openeditor.sh toggle_debugger.py

# Ask if user wants to create a GitHub repository
echo -e "${CYAN}Do you want to create a GitHub repository? (y/n)${NC}"
read create_repo

if [ "$create_repo" = "y" ] || [ "$create_repo" = "Y" ]; then
    if command -v gh &> /dev/null; then
        echo -e "${CYAN}Do you want the repository to be public or private? (pub/priv)${NC}"
        read repo_visibility
        
        visibility_flag="--private"
        if [ "$repo_visibility" = "pub" ]; then
            visibility_flag="--public"
        fi
        
        echo -e "${BLUE}Creating GitHub repository...${NC}"
        git init
        git add .
        git commit -m "Initial commit"
        gh repo create "$project_name" $visibility_flag --source=. --remote=origin --push
        echo -e "${GREEN}GitHub repository created and code pushed!${NC}"
    else
        echo -e "${RED}GitHub CLI (gh) is not installed. Skipping repository creation.${NC}"
    fi
fi

echo -e "${GREEN}Project setup complete!${NC}"
echo -e "${BLUE}To start development server:${NC}"
echo -e "${CYAN}cd $project_name${NC}"
echo -e "${CYAN}./lamdera-dev-watch.sh${NC}" 