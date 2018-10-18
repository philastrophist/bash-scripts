alias __git_current_branch 'git rev-parse --abbrev-ref HEAD >& /dev/null && echo "{`git rev-parse --abbrev-ref HEAD`}"'
alias __conda_current_env 'echo "("`which python | rev | cut -d/ -f 3 | rev`") " | sed -e "s/(anaconda) //g"'
alias precmd 'set prompt="`__conda_current_env`%m [%c1]`__git_current_branch`> "'
source $ANACONDA_DIR/etc/profile.d/conda.csh
