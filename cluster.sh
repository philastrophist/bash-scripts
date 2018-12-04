#! /usr/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

socket_proxy="ssh -D $socket -o ServerAliveInterval=30 $UHUSERNAME@star.herts.ac.uk -fN"
port_forward="ssh -NfXY -t -o ServerAliveInterval=30 -L 2121:$UHPCNAME:21 -L 2020:$UHPCNAME:20 -L 2222:$UHPCNAME:22 $UHUSERNAME@star.herts.ac.uk"
alias uhpc="ssh -XY -o ServerAliveInterval=30 -o TCPKeepAlive=yes -t $UHUSERNAME@star.herts.ac.uk ssh -XY -o ServerAliveInterval=30 -o TCPKeepAlive=yes -t $UHPCNAME"
alias uhhpc="ssh -XY -o ServerAliveInterval=30 -o TCPKeepAlive=yes -t $UHUSERNAME@uhhpc.herts.ac.uk"

function cluster {
        if [ "$1" == "start" ]
        then
            eval "$socket_proxy"
            echo "socket proxy started for notebook access"
            eval "$port_forward"
            echo "ports forwarded: 21->2121(sftp) 20->2020 22->2222(ssh)"
            echo "You will need to setup an autoswitch proxy in your browser (the extension SwitchyOmega works well)"
            echo "Add a proxy server with the following options to your browser/browser-extension:"
            echo "Protocol: SOCKS5"
            echo "Server: localhost"
            echo "Port: 1234"
            echo "Your jupyter notebooks will always be available at 'https://$UHPCNAME:9999'"
        elif [[ "$1" == "submit" ]]; then
            if [ -z "$2" ]; then
                echo "specify -l arguments for cluster submission"
                return 1;
            fi
            cd $SCRIPTPATH
            qsub -X cluster-jupyter.qsub "$2"
        else
            if [ "$1" == "kill" ]
            then
             pkill -f "$socket_proxy"
             pkill -f "$port_forward"
            else
            if [ "$1" == "status" ]
            then
             if [ "$(pgrep -fx "$socket_proxy")" ]
             then
              echo "socket proxy active"
             else
              echo "socket proxy inactive"
             fi
             if [ "$(pgrep -fx "$port_forward")" ]
             then
              echo "ftp/ssh port forwarding active"
             else
              echo "ftp/ssh port forwarding inactive"
             fi
            else
             echo "unknown command"
            fi
            fi
        fi
}
