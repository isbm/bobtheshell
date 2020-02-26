#
# Segment drawing
#
CURRENT_BG='NONE'

#
# color scheme
#
SHELLDER_CONTEXT_BG=${SHELLDER_CONTEXT_BG:-238}
SHELLDER_CONTEXT_FG=${SHELLDER_CONTEXT_FG:-245}

# Directories/path
BTS_DIR_BG=${BTS_DIR_BG:-240}
BTS_DIR_FG=${BTS_DIR_FG:-250}
BTS_DIR_RO_BG=${BTS_DIR_RO_BG:-088}
BTS_DIR_RO_FG=${BTS_DIR_RO_FG:-250}
BTS_DIR_HL_FG=${BTS_DIR_HL_FG:-230}

# Chunk of inner Git repo directory
BTS_AFTER_DIR_BG=${BTS_AFTER_DIR_BG:-237}
BTS_AFTER_DIR_FG=${BTS_AFTER_DIR_FG:-246}

# Clean background
SHELLDER_GIT_CLEAN_BG=${SHELLDER_GIT_CLEAN_BG:-034}
SHELLDER_GIT_CLEAN_FG=${SHELLDER_GIT_CLEAN_FG:-'black'}

SHELLDER_GIT_UNTRACKED_BG=${SHELLDER_GIT_UNTRACKED_BG:-045}
SHELLDER_GIT_UNTRACKED_FG=${SHELLDER_GIT_UNTRACKED_FG:-'black'}

SHELLDER_GIT_UNPUSHED_BG=${SHELLDER_GIT_UNPUSHED_BG:-48}
SHELLDER_GIT_UNPUSHED_FG=${SHELLDER_GIT_UNPUSHED_FG:-'black'}

SHELLDER_GIT_MODIFIED_BG=${SHELLDER_GIT_MODIFIED_BG:-172}
SHELLDER_GIT_MODIFIED_FG=${SHELLDER_GIT_MODIFIED_FG:-'black'}

SHELLDER_GIT_STAGED_BG=${SHELLDER_GIT_STAGED_BG:-196}
SHELLDER_GIT_STAGED_FG=${SHELLDER_GIT_STAGED_FG:-228}

SHELLDER_GIT_ADDED_BG=${SHELLDER_GIT_ADDED_BG:-165}
SHELLDER_GIT_ADDED_FG=${SHELLDER_GIT_ADDED_FG:-015}

SHELLDER_VIRTUALENV_BG=${SHELLDER_VIRTUALENV_BG:-025}
SHELLDER_VIRTUALENV_FG=${SHELLDER_VIRTUALENV_FG:-214}

# Status colors
BTS_STATUS_USER_BG=${BTS_STATUS_USER_BG:-236}
BTS_STATUS_USER_FG=${BTS_STATUS_USER_FG:-'default'}
BTS_STATUS_ROOT_BG=${BTS_STATUS_ROOT_BG:-052}
BTS_STATUS_ROOT_FG=${BTS_STATUS_ROOT_FG:-'default'}

# Special Powerline characters
() {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    SEGMENT_SEPARATOR=$'\ue0b0'
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
    local bg fg
    [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
    [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
    if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
	echo -n " %b%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
    else
	echo -n "%b%{$bg%}%{$fg%} "
    fi
    CURRENT_BG=$1
    [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
    if [[ -n $CURRENT_BG ]]; then
	echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
    else
	echo -n "%{%k%}"
    fi
    echo -n "%{%f%}"
    CURRENT_BG=''
}


#
# Prompt functions
#

# Context: user@hostname (who am I and where am I).
# This shows up only on remote machines or different user (su -).
prompt_context() {
    if [[ "$USER" == "$(whoami)" && ! -n "$SSH_CLIENT" ]]; then
	return
    fi

    local prompt
    if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
	if [[ "$USER" != "$DEFAULT_USER" ]]; then
	    prompt="%(!.%{%F{yellow}%}.)$USER@%m"
	else
	    prompt="%(!.%{%F{yellow}%}.)%m"
	fi
	prompt_segment $SHELLDER_CONTEXT_BG $SHELLDER_CONTEXT_FG $prompt
    fi
}

# Git: branch/detached head, dirty status
prompt_git() {
    local repo_path
    repo_path=$(git rev-parse --git-dir 2>/dev/null)

    if [[ -n $repo_path ]]; then
	local PL_BRANCH_CHAR dirty bgcolor fgcolor mode ref clean

	() {
	    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
	    PL_BRANCH_CHAR=$'\ue0a0' # 
	}

	GIT_STATUS=$(command git status --porcelain | sed -e 's/^ //g' 2>/dev/null)
	modified=$(echo $GIT_STATUS | grep '^M')
	untracked=$(echo $GIT_STATUS | grep '^?')
	added=$(echo $GIT_STATUS | grep '^A')
	staged=$(git diff --name-only --cached | cat)
	unpushed=$(command git cherry 2>/dev/null)

	if [[ -n $added ]]; then
	    bgcolor=$SHELLDER_GIT_ADDED_BG
	    fgcolor=$SHELLDER_GIT_ADDED_FG
	elif [[ -n $staged ]]; then
	    bgcolor=$SHELLDER_GIT_STAGED_BG
	    fgcolor=$SHELLDER_GIT_STAGED_FG
	elif [[ -n $modified ]]; then
	    bgcolor=$SHELLDER_GIT_MODIFIED_BG
	    fgcolor=$SHELLDER_GIT_MODIFIED_FG
	elif [[ -n $untracked ]]; then
	    bgcolor=$SHELLDER_GIT_UNTRACKED_BG
	    fgcolor=$SHELLDER_GIT_UNTRACKED_FG
	elif [[ -n $unpushed ]]; then
	    bgcolor=$SHELLDER_GIT_UNPUSHED_BG
	    fgcolor=$SHELLDER_GIT_UNPUSHED_FG
	else
	    clean="1"
	    bgcolor=$SHELLDER_GIT_CLEAN_BG
	    fgcolor=$SHELLDER_GIT_CLEAN_FG
	fi
	prompt_segment $bgcolor $fgcolor

	if [[ -e "${repo_path}/BISECT_LOG" ]]; then
	    mode=" <B>"
	elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
	    mode=" >M<"
	elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
	    mode=" >R>"
	fi

	autoload -Uz vcs_info
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:*' check-for-changes true
	zstyle ':vcs_info:*' stagedstr '✚'
	zstyle ':vcs_info:*' unstagedstr '●'
	zstyle ':vcs_info:*' formats ' %u%c'
	zstyle ':vcs_info:*' actionformats ' %u%c'
	vcs_info

	ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
	local branch=$(shorten_word ${ref/refs\/heads\//} 15)
	echo -n "$PL_BRANCH_CHAR ${branch}${vcs_info_msg_0_%% }${mode}"
    fi
}

shorten_word() {
    local orig=$1
    local limit=$2
    if [[ ${#orig} -ge $limit ]]; then
	echo "${${orig}:0:$limit}…"
    else
	echo $orig
    fi
}

prompt_hg() {
    local rev status
    if $(hg id >/dev/null 2>&1); then
	if $(hg prompt >/dev/null 2>&1); then
	    if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
		# if files are not added
		prompt_segment red white
		st='±'
	    elif [[ -n $(hg prompt "{status|modified}") ]]; then
		# if any modification
		prompt_segment yellow black
		st='±'
	    else
		# if working copy is clean
		prompt_segment green black
	    fi
	    echo -n $(hg prompt "☿ {rev}@{branch}") $st
	else
	    st=""
	    rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
	    branch=$(hg id -b 2>/dev/null)
	    if `hg st | grep -q "^\?"`; then
		prompt_segment red black
		st='±'
	    elif `hg st | grep -q "^[MA]"`; then
		prompt_segment yellow black
		st='±'
	    else
		prompt_segment green black
	    fi
	    echo -n "☿ $rev@$branch" $st
	fi
    fi
}

# Return Git top level
function git_top_path() {
    # Git top level
    git_top_path=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n $git_top_path ]]; then
	git_top_path="~${git_top_path#$HOME}"
    else
	git_top_path=""
    fi
    echo $git_top_path
}

# Turn "/some/quite/very/long/path" into "/s/q/v/l/path" without
# relying on an external optional plugin
function fish_path() {
    gtp=$1
    local paths=(${PWD/$HOME/\~}) 'cur_dir'

    if [[ ! -z $gtp ]]; then
	paths=$gtp
    fi

    paths=(${(s:/:)paths})

    for idx in {1..$#paths}
    do
      if [[ idx -lt $#paths ]]; then
        cur_dir+="${paths[idx]:0:1}"
      else
        cur_dir+="%B%F{$BTS_DIR_HL_FG}${paths[idx]}"
      fi
      cur_dir+='/'
    done
    if [[ $cur_dir = $'~'* ]]; then
	echo ${cur_dir: :-1}
    else
	echo "/${cur_dir: :-1}"
    fi
}

# Dir: current working directory
prompt_dir() {
    local dir
    local dir_bg

    if [[ ! -w "$(pwd)" ]]; then
	dir_bg=$BTS_DIR_RO_BG
    else
	dir_bg=$BTS_DIR_BG
    fi

    if [[ -n $SHELLDER_KEEP_PATH ]]; then
        dir='%~'
    else
        dir=$(fish_path $(git_top_path))
    fi
  prompt_segment $dir_bg $BTS_DIR_FG $dir
}

prompt_inner_dir() {
    gtp=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ ! -z $gtp ]]; then
	ctp=$(pwd)
	ctp="${ctp#$gtp}"
	if [[ ! -z $ctp ]]; then
	    prompt_segment $BTS_AFTER_DIR_BG $BTS_AFTER_DIR_FG  "${ctp:1:#ctp}" "$symbols"
	fi
    fi
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
    local virtualenv_path="$VIRTUAL_ENV"
    if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
	prompt_segment $SHELLDER_VIRTUALENV_BG $SHELLDER_VIRTUALENV_FG "`basename $virtualenv_path`" "$symbols"
    fi
}

# Status: error + root + background jobs
prompt_status() {
    local symbols
    local status_bg
    local status_fg

    symbols=()

    if [[ $UID -eq 0 ]]; then
	symbols+="%{%F{yellow}%}!"
	status_bg=$BTS_STATUS_ROOT_BG
	status_fg=$BTS_STATUS_ROOT_FG
    else
	status_bg=$BTS_STATUS_USER_BG
	status_fg=$BTS_STATUS_USER_FG
    fi

    if [[ $RETVAL -ne 0 ]]; then
	symbols+="%{%F{196}%}$RETVAL"
    fi

    [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"
    [[ -n "$symbols" ]] && prompt_segment $status_bg $status_fg "$symbols"
}


#
# Prompt
#
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  #prompt_hg
  prompt_inner_dir
  prompt_end
  echo "%b"
}

export VIRTUAL_ENV_DISABLE_PROMPT="true"
PROMPT='%{%f%b%k%}$(build_prompt) '
