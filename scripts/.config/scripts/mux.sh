#!usr/bin/env bash
while getopts "n:p:c:" flag
do
  case "${flag}" in
    n) PROJECT_NAME=${OPTARG};;
    p) PORT=${OPTARG};;
    c) COMMAND=${OPTARG};;
  esac
done

if [[ $PROJECT_NAME == "" ]]
  then
    echo "Project name not specified"
    exit 1
fi

if [[ $PORT == "" ]]
  then
    PORT="8080"
    echo "Port not specified, defaulting to 8080"
fi

if [[ $COMMAND == "" ]]
  then
    COMMAND="webdev serve web"
    echo "Command not specified, defaulting to 'webdev serve web'"
fi

if [[ ${COMMAND:0:6} == "webdev" ]]
then
  COMMAND=$COMMAND:$PORT
fi

if [[ ${COMMAND:0:3} == "npx" ]]
then
  COMMAND="$COMMAND -l $PORT"
fi

if [[ ${COMMAND:0:3} == "npm" ]]
then
  COMMAND="PORT=$PORT $COMMAND"
fi

echo "NAME: $PROJECT_NAME";
echo "PORT: $PORT";
echo "COMMAND: $COMMAND";

SESSIONNAME="$PROJECT_NAME"

tmux has-session -t $SESSIONNAME &> /dev/null

if [ $? != 0 ] 
 then
    tmux new-session -d -s $SESSIONNAME
    window=0
    tmux rename-window -t $SESSIONNAME:$window 'nvim'
    tmux send-keys -t $SESSIONNAME "cd ~/Documents/$PROJECT_NAME/" C-m
    tmux send-keys -t $SESSIONNAME "clear" C-m
    tmux send-keys -t $SESSIONNAME "nvim" C-m

    window=1
    tmux new-window -t $SESSIONNAME:$window -n "server"
    tmux send-keys -t $SESSIONNAME "cd ~/Documents/$PROJECT_NAME/" C-m
    tmux send-keys -t $SESSIONNAME "clear" C-m
    tmux send-keys -t $SESSIONNAME "$COMMAND" C-m

    window=2
    tmux new-window -t $SESSIONNAME:$window -n "git"
    tmux send-keys -t $SESSIONNAME "cd ~/Documents/$PROJECT_NAME/" C-m
    tmux send-keys -t $SESSIONNAME "clear" C-m
    tmux send-keys -t $SESSIONNAME "lazygit" C-m 

    tmux select-window -t $SESSIONNAME:0
fi

tmux attach-session -t $SESSIONNAME
