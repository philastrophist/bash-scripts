#!/bin/bash
set -e

./install.sh yes-silent "$(python -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")" username uhppc00 y "$HOME" y "me@me.com" firstname lastname y $HOME y
python ~/.jupyter/jupyter_notebook_config.py
source ~/.bashrc
