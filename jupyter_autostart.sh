#! /bin/bash

if [[ $(hostname) == *"uhppc"* ]];
then
    #ssh -D 1234 sread@star.herts.ac.uk -N -f;
    if [[ "$(jupyter notebook list | grep 9999)" ]];
    then
        echo "Jupyter notebook running at :9999"
    else
        jupyter notebook &> /dev/null &
        echo "started jupyter notebook at :9999"
    fi
        
else
    echo "Jupyter Server not run on this machine"
fi
