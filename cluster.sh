#! /usr/bin/bash

socket=9998
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

function get_node {
    echo "$(ssh $UHUSERNAME@uhhpc.herts.ac.uk "cat ~/.current_jupyter_node")"
}

function get_eval {
    node="$(get_node)"
    socket_proxy="ssh -NfXY -t -o ServerAliveInterval=30 -L $socket:$node:$socket $UHUSERNAME@uhhpc.herts.ac.uk"
    echo "$socket_proxy"
}


function cluster {
        if [ "$1" == "start" ]
        then
            node="$(get_node)"
            socket_proxy="$(get_eval)"
            eval "$socket_proxy"
            echo "socket proxy started for notebook access"
            echo "You will need to setup an autoswitch proxy in your browser (the extension SwitchyOmega works well)"
            echo "Add a proxy server with the following options to your browser/browser-extension:"
            echo "Protocol: SOCKS5"
            echo "Server: localhost"
            echo "Port: 9998"
            echo "Your jupyter notebooks will always be available at 'https://$node:9998'"
        elif [[ "$1" == "submit" ]]; then
            cd $SCRIPTPATH
            ssh $UHUSERNAME@uhhpc.herts.ac.uk "qsub -X cluster-jupyter.qsub "$2""
        else
            if [ "$1" == "kill" ]
            then
             pkill -f "$socket_proxy"
            else
            if [ "$1" == "status" ]
            then
             if [ "$(pgrep -fx "$socket_proxy")" ]
             then
              echo "socket proxy active"
             else
              echo "socket proxy inactive"
             fi
            else
             echo "unknown command"
            fi
            fi
        fi
}
