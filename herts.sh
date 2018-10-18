#! /usr/bin/bash

socket_proxy="ssh -D 1234 -o ServerAliveInterval=30 sread@star.herts.ac.uk -fN"
port_forward="ssh -NfXY -t -o ServerAliveInterval=30 -L 2121:uhppc60:21 -L 2020:uhppc60:20 -L 2222:uhppc60:22 sread@star.herts.ac.uk"
alias uhppc60="ssh -XY -o ServerAliveInterval=30 -o TCPKeepAlive=yes -t sread@star.herts.ac.uk ssh -XY -o ServerAliveInterval=30 -o TCPKeepAlive=yes -t uhppc60"
alias uhhpc="ssh -XY -o ServerAliveInterval=30 -o TCPKeepAlive=yes -t sread@uhhpc.herts.ac.uk"

function herts {
        if [ "$1" == "start" ]
        then
         eval "$socket_proxy"
         echo "socket proxy started for notebook access"
         eval "$port_forward"
         echo "ports forwarded: 21->2121(sftp) 20->2020 22->2222(ssh)"
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
