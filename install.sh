#!/bin/bash

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# get apps if not installed

# run install scripts

# append to bashrc/tcshrc

touch "$HOME/.bashrc"
touch "$HOME/.tcshrc"

if [ ! -d "$HOME/.bash-git-prompt/" ]; then
  git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1
  cp "$SCRIPTPATH/Single_line_Minimalist_notime.bgptheme" ~/.bash-git-prompt/
fi

if conda -V; then
    echo "Conda already installed"
else
    echo "Conda not installed. This is recommended for personal python but it will remove access to star.herts.ac.uk python packages"
    echo "You will need to install these packages yourself"
    echo "It is advisable to install anaconda to your local drive since it can have too many files sometimes"
 #    if grep -q Microsoft /proc/version; then
	# 	echo "You are using linux for windows. Installing conda or using python for science here is not recommended. You should use conda for windows directly."
	# 	echo -n "Are you sure you want to install? [y/n]"
	# 	read install_conda
	# else
	echo -n "Install miniconda for personal use (you can choose where later)? [y/n]"
	read -r install_conda
	# fi

    if [[ $install_conda = 'y' ]]; then
    	echo -n "Which python should I use as your default? 2 or 3:"
    	read -r version
	    unameOut="$(uname -s)"
		case "${unameOut}" in
		    Linux*)    
				machine=Linux
				;;
		    Darwin*)
		    	machine=Mac
		    	;;
		    CYGWIN*)
		    	machine=Linux
		    	;;
		    MINGW*)
		        machine=Linux
		        ;;
		    *)  
		    	echo "unknown machine type. "
		    	exit 1
		esac

		if [[ "$machine" = "Linux" ]]; then
			fname="Miniconda$version-latest-Linux-x86_64.sh"
		else
			fname="Miniconda$version-latest-MacOSX-x86_64.sh"
		fi
		wget "https://repo.continuum.io/miniconda/$fname"
		chmod +x "$fname"
		sh "$fname"
		eval "$(register-python-argcomplete conda)"
		conda install jupyter
		conda_dir="$(dirname $(dirname $(which conda)))"
		echo "source $conda_dir/etc/profile.d/conda.csh" >> ~/.tcshrc
		echo "conda activate" >> ~/.bashrc
		echo "conda activate" >> ~/.tcshrc
		echo "unsetenv PYTHONPATH" >> ~/.tcshrc
		echo "unset PYTHONPATH" >> ~/.bashrc
		echo "Conda has been installed and the base environment activated by default"
		echo "You will need to source your tcshrc/bashrc files to make these changes now"
		echo
		echo "You can create separate conda environments by using the command: conda create -n name-of-environment python=python-version-number"
		echo "You can activate these environments by using the command: conda activate name-of-environment"
		echo "You can return to the base python by using the command: conda deactivate"
		echo "You can install stuff using either: conda install pkg1 pkg2  or pip install pkg1 pkg2"
	fi

fi

ps1_string="source $SCRIPTPATH/ps1_stuff.sh"
if grep -Fxq "$ps1_string" ~/.bashrc
then
	echo "ps1 already installed in bash"
else
	echo "$ps1_string" >> ~/.bashrc
fi

herts_string="source $SCRIPTPATH/herts.sh"
echo -n "What is your work username?"
read -r username 
echo "setenv UHUSERNAME $username" >> ~/.tcshrc
echo "export UHUSERNAME=$username" >> ~/.bashrc
echo -n "What is your work pc name (something like uhppc60)?"
read -r pcname
echo "setenv UHPCNAME $pcname" >> ~/.tcshrc
echo "export UHPCNAME=$pcname" >> ~/.bashrc

if grep -Fxq "$herts_string" ~/.bashrc
then
	echo "herts already installed in bash"
else
	echo "$herts_string" >> ~/.bashrc
fi

project_string="source $SCRIPTPATH/project.sh"
if grep -Fxq "$project_string" ~/.bashrc
then
	echo "project already installed in bash"
else
	echo "$project_string" >> ~/.bashrc
fi


tcsh_prompt="source $SCRIPTPATH/tcsh_prompt.csh"
if grep -Fxq "$tcsh_prompt" ~/.tcshrc
then
	echo "prompt already installed in tcsh"
else
	echo "$tcsh_prompt" >> ~/.tcshrc
fi

if jupyter --version; then
	if [ ! -f "$HOME/.jupyter/jupyter_notebook.py" ]; then
		jupyter notebook --generate-config
	fi
	jupyter notebook password
	if [[ "$(cat /proc/sys/kernel/hostname)" == *"uhppc"* ]]; then
		echo -n "You are on a university machine, shall I setup jupyter remote access?[y/n]"
		read -r do_jupyter
		if [[ $do_jupyter = 'y' ]]; then
			mkdir "$HOME/certificates"
			mkdir "$HOME/certificates/jupyter"
			openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$HOME/certificates/jupyter/mykey.key" -out "$HOME/certificates/jupyter/mycert.pem"
			echo "c.NotebookApp.certfile = "'"'"$HOME/certificates/jupyter/mycert.pem"'"' >> "$HOME/.jupyter/jupyter_notebook_config.py"
			echo "c.NotebookApp.keyfile = "'"'"$HOME/certificates/jupyter/mykey.key"'"' >> "$HOME/.jupyter/jupyter_notebook_config.py"
			echo "c.NotebookApp.ip = '*'" >> "$HOME/.jupyter/jupyter_notebook_config.py"
			echo "c.NotebookApp.open_browser = False" >> "$HOME/.jupyter/jupyter_notebook_config.py"
			echo "c.NotebookApp.port = 9999" >> "$HOME/.jupyter/jupyter_notebook_config.py"
			chmod +x jupyter_autostart.sh
			echo "bash $SCRIPTPATH/jupyter_autostart.sh" >> "$HOME/.login"
			echo "Jupyter notebook will start automatically on your work pc and can be accessed on any machine where this script has been run."
			echo "You can access the jupyter notebook by running 'herts start'"
		fi
	fi
else
	echo "Jupyter is not installed skipping jupyter external setup. You will need to run this script on your work computer to get jupyter notebook access"
fi

echo -n "Shall I personalise git?[y/n] "
read -r personal_git
if [[ $personal_git == 'y' ]]; then
	echo -n "Github email: "
	read -r git_email
	echo -n "Your first name "
	read -r firstname
	echo -n "Your last name "
	read -r lastname
	git config --global user.name "$firstname $lastname"
	git config --global user.email "$git_email"
	git config --global core.editor nano 
fi

if [[ ! -f "$HOME/.ssh/id_rsa.pub" ]]; then 
	echo -n "Shall I add a new ssh key for passwordless ssh?[y/n] "
	read -r keys
	if [[ $keys ]]; then
		echo -n "What is your email? (this should be the same one you used with github) "
		read -r email
		ssh-keygen -t rsa -b 4096 -C "$email" -f "$HOME/.ssh/id_rsa.pub"
		eval "$(ssh-agent -s)" || echo agent already started
		ssh-add "$HOME/.ssh/id_rsa"
		echo Now add the following PUBLIC key to github
		echo 
		cat "$HOME/.ssh/id_rsa.pub"
		echo 
		echo "https://github.com/settings/keys"
		echo "You should now use ssh instead of https when cloning repositories because it doesn't need a password!"
	fi
fi

echo -n "Shall I install code-review.sh?[y/n] "
read -r code_review
if [[ $code_review == 'y' ]]; then
	git clone https://github.com/herts-astrostudents/code-review.sh "$HOME/code-review.sh"
	chmod +x "$HOME/code-review.sh/code-review.sh"
	"$HOME/code-review.sh/code-review.sh" install
	echo -n "Where shall I put the code-review repository where you will fill in tasks? "
	read -r review_dir
	git clone https://github.com/herts-astrostudents/code-review "$review_dir/code-review"
fi

echo "The command libraries herts and project have been installed in bash and tcsh"
echo "The command: project start/create/sync will not work in tcsh. This requires bash"
echo "You can use either bash or tcsh to work in now. However, bash is preferred by modern workflows."
