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

if [[ ${COMMAND:0:5} == "webdev" ]]
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
    tmux new-session -s $SESSIONNAME -n $SESSIONNAME -d
    tmux send-keys -t $SESSIONNAME "cd ~/Documents/$PROJECT_NAME/" C-m
    tmux send-keys -t $SESSIONNAME "clear" C-m
    tmux send-keys -t $SESSIONNAME "nvim" C-m
    tmux split-window -h -t $SESSIONNAME
    tmux send-keys -t $SESSIONNAME "cd ~/Documents/$PROJECT_NAME/" C-m
    tmux send-keys -t $SESSIONNAME "clear" C-m
    tmux send-keys -t $SESSIONNAME "lazygit" C-m 
    tmux split-window -v -t $SESSIONNAME
    tmux send-keys -t $SESSIONNAME "cd ~/Documents/$PROJECT_NAME/" C-m
    tmux send-keys -t $SESSIONNAME "clear" C-m
    tmux send-keys -t $SESSIONNAME "$COMMAND" C-m
    tmux select-pane -t 0
fi

tmux attach -t $SESSIONNAME
