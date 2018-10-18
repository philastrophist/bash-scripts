#! bin/bash

export PROJECTS_DIR="/local/home/sread/Dropbox/"
export CLUSTER_DATA_DIR="/car-data/sread/"
export CLUSTER_BEEGFS_DIR="/beegfs/car/sread/"
export CLUSTER_HOME_DIR="/home/sread/code/"
#export RSYNC_SSH="ssh -o ServerAliveInterval=2"
project(){
	case "$1" in 
		"start")
			cd "$PROJECTS_DIR$2" || return; activate "$2" || (echo "no environment for $2" && return)
			;;
		"make")
			cd "$PROJECTS_DIR" || return; mkdir "$2" || return; cd "2" || return; 
			echo -e "- .*\n- .snakemake/*\n+ *" > "sync-list.txt"; 
			conda create -n "$2" python=3 numpy scipy matplotlib seaborn jupyter snakemake "$3" -y;
			activate "$2"; git init
			;;
		"sync")
			if [[ "$#" -lt 3 ]]; then
				echo "need arguments: PROJECT CLUSTER_DIR [optional rsync stuff...]" 
				return
			fi
			export previous="$(pwd)";
			cd "$PROJECTS_DIR$2/" || return
			rsync -chavzm --progress --stats --partial-dir=.rsync-partial --delete --include-from sync-list.txt --dry-run "${@:4}" ./ stri-cluster:"$3$2" || return
			echo "=====DRY RUN====="
			read -rp "Continue to sync? [enter] ";
			rsync -chavzm --progress --stats --partial-dir=.rsync-partial --delete --include-from sync-list.txt "${@:4}" ./ stri-cluster:"$3$2";
			cd "$previous"; unset previous; unset CLUSTER_DIR;
			;;
		*)
		echo "Not a valid argument"
		return 1
		;;
	esac
			
}

function abs_path {
  (cd "$(dirname '$1')" &>/dev/null && printf "%s/%s" "$PWD" "${1##*/}")
}

function fetch_cluster(){
	if [[ "$#" -lt 2 ]]; then
		echo "need arguments: CLUSTER_STUFF TO_WHERE [optional rsync stuff...]"
		return
	fi
	WHICH=$1
	FOLDER=$2
	echo "transferring to $FOLDER"
	rsync -chavzm --progress --stats --partial-dir=.rsync-partial --dry-run "${@:4}" stri-cluster:"$WHICH" "$FOLDER" || return
	echo "=====DRY RUN====="
	read -rp "Continue to sync? [enter] ";
	rsync -chavzm --progress --stats --partial-dir=.rsync-partial "${@:4}" stri-cluster:"$WHICH" "$FOLDER";
}

function transfer_environment {
	# Builds the conda environment on the cluster by using environment.yml files
	# Requires that your project packages are on github!
	current="$(conda env list | grep "*" | cut -d" " -f 1)"
	if echo "$current" | grep -qE "(root|base)"; then
		echo "Cannot transfer root/base environment. Activate an environment first"
		conda env list
		return
	fi

	if grep -q "$current" <<< "$(ssh uhhpc "bash -c 'conda env list'")"; then
		read -p "The environment <$current> is already installed, continuing will delete it and reinstall it. Continue? [enter]"
		echo "Removing the <$current> environment from the cluster"
		ssh uhhpc bash -c "'""conda env remove --name $current --yes""'"
	fi

	to_pip="$(pip -q freeze | grep github.com)"
	to_pip="${to_pip//git@github.com:/https://github.com/}"
	if grep -q  '## !! Could not determine repository location' <<< "$(pip -q freeze)"; then
		echo "Could not determine some repository locations. See pip freeze for a list"
		return
	fi
	github="$(echo "$to_pip" | awk -F"#egg=" '{print $2}' | tr '\n' '|')" &&
	github="${github%?}" &&
	github="${github/_/(-|_)}"
	github="${github/-/(-|_)}"
	conda="$(conda env export)"
	name_line="$(echo -e "$conda" | head -n 1)"
	name="$(echo -e "$name_line" | awk -F": " '{print $2}')"
	echo -e "$name_line" > ~/.transferred_environment.yml &&
	echo -e "$(echo -e "$conda" | tail -n +2 | grep -vE "($github)"| head -n -1)"  >> ~/.transferred_environment.yml
	echo "transferring the $name environment to the cluster" &&
	scp "$HOME/.transferred_environment.yml" uhhpc:"$CLUSTER_HOME_DIR" &&
	echo "building environment on cluster side" &&
	ssh uhhpc "bash -c" '"'"conda env create -f $CLUSTER_HOME_DIR.transferred_environment.yml"'"' &&
	if grep -q 'git' <<< "$to_pip"; then
		echo "installing git+pip dependencies on cluster side" &&
		pip_command="'""source activate $name" 
		while read -r line; do
			pip_command="$pip_command && pip install $line --no-dependencies"
		done <<< "${to_pip//-e/}"
		pip_command="$pip_command""'"
		ssh uhhpc bash -c "$pip_command"
	else
		echo "No git+pip dependencies to install"
	fi
	echo "$name environment transferred successfully"
}


function update_transferred_package {
	current="$(conda env list | grep "*" | cut -d" " -f 1)"
	# ssh uhhpc bash -c "'"" source activate $current && cd "$(dirname "$(python -c "import $1; print($1.__file__)")")" && git fetch --all && git pull "$2"  ""'"
	ssh uhhpc bash -c "'""soure activate $current && pip uninstall $1""'"

}

function withcluster {
	if [ "$#" -lt 2 ]; then
		echo "Need arguments"
		return 1
	fi
	if grep -qvE "(pip|conda)" <<< "$1"; then
		echo "$1 is not an allowed conda to mirror on the cluster environment. Only pip/conda"
		return 1
	fi

	current="$(conda env list | grep "*" | cut -d" " -f 1)"

	if echo "$current" | grep -qE "(root|base)"; then
		echo "Cannot interact with root/base environment. Activate an environment first"
		conda env list
		return 1
	fi
	if echo "$(ssh uhhpc bash -c '"conda env list"')" | grep -Eq "/$current$"; then
		shift
		eval "${@:2}" && echo "Now on the cluster:" 
		if [ "$?" -eq 0 ]; then
			ssh uhhpc bash -c '"'"${@:2}""'"
		else
			echo "${@:2} returned exit status $?"
		fi
	else
		echo "Environment <$current> not found not cluster"
		echo "Cluster environments:"
		ssh uhhpc bash -c 'conda env list'
		return 1
	fi
}