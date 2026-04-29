# Spaceshit theme.
#
# @version 1.0.0
#
# A small, fast Oh My Zsh theme inspired by Spaceship. Spaceship is great, but
# it checks many runtimes and tools that this setup does not need on every
# prompt render. It keeps Spaceship's familiar colors, but only the useful
# pieces:
#
# - compact path display rooted at the current Git repository
# - Git branch and status via Oh My Zsh's git helpers
# - command duration timer
#
# Requires a Powerline-compatible font for the branch and prompt symbols.

zmodload zsh/datetime

# Configuration defaults
: "${SPACESHIT_TIMER_THRESHOLD:=0}"
: "${SPACESHIT_TIMER_PRECISION:=1}"
: "${SPACESHIT_TIMER_FORMAT:=%d}"

# Colors
SPACESHIT_PATH_COLOR="${SPACESHIT_PATH_COLOR:-%{$fg_bold[cyan]%}}"
SPACESHIT_TEXT_COLOR="${SPACESHIT_TEXT_COLOR:-%{$fg_bold[white]%}}"
SPACESHIT_GIT_BRANCH_COLOR="${SPACESHIT_GIT_BRANCH_COLOR:-%{$fg_bold[magenta]%}}"
SPACESHIT_GIT_STATUS_COLOR="${SPACESHIT_GIT_STATUS_COLOR:-%{$fg_bold[red]%}}"
SPACESHIT_TIMER_COLOR="${SPACESHIT_TIMER_COLOR:-%{$fg_bold[yellow]%}}"
SPACESHIT_SUCCESS_COLOR="${SPACESHIT_SUCCESS_COLOR:-%{$fg_bold[green]%}}"
SPACESHIT_ERROR_COLOR="${SPACESHIT_ERROR_COLOR:-%{$fg_bold[red]%}}"
SPACESHIT_RESET_COLOR="${SPACESHIT_RESET_COLOR:-%{$reset_color%}}"

# Git branch and status
# \uE0A0 is the Powerline branch icon
ZSH_THEME_GIT_PROMPT_PREFIX=" ${SPACESHIT_TEXT_COLOR}on${SPACESHIT_RESET_COLOR} ${SPACESHIT_GIT_BRANCH_COLOR}"$'\uE0A0'" "
ZSH_THEME_GIT_PROMPT_SUFFIX="${SPACESHIT_RESET_COLOR}"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Git Status symbols
ZSH_THEME_GIT_PROMPT_UNTRACKED="${SPACESHIT_GIT_SYMBOL_UNTRACKED:-?}"
ZSH_THEME_GIT_PROMPT_ADDED="${SPACESHIT_GIT_SYMBOL_ADDED:-+}"
ZSH_THEME_GIT_PROMPT_MODIFIED="${SPACESHIT_GIT_SYMBOL_MODIFIED:-!}"
ZSH_THEME_GIT_PROMPT_RENAMED="${SPACESHIT_GIT_SYMBOL_RENAMED:-»}"
ZSH_THEME_GIT_PROMPT_DELETED="${SPACESHIT_GIT_SYMBOL_DELETED:-x}"
ZSH_THEME_GIT_PROMPT_UNMERGED="${SPACESHIT_GIT_SYMBOL_UNMERGED:-=}"
ZSH_THEME_GIT_PROMPT_AHEAD="${SPACESHIT_GIT_SYMBOL_AHEAD:-⇡}"
ZSH_THEME_GIT_PROMPT_BEHIND="${SPACESHIT_GIT_SYMBOL_BEHIND:-⇣}"
ZSH_THEME_GIT_PROMPT_DIVERGED="${SPACESHIT_GIT_SYMBOL_DIVERGED:-⇕}"
ZSH_THEME_GIT_PROMPT_STASHED="${SPACESHIT_GIT_SYMBOL_STASHED:-\$}"

# Timer state
SPACESHIT_LAST_DURATION=""

_spaceshit_format_duration() {
    local elapsed="${1:-0}"
    local -i mins=$(( elapsed / 60 ))
    local secs duration
    local format="${SPACESHIT_TIMER_FORMAT:-%d}"

    (( elapsed < 1 )) && return

    secs=$(printf "%.${SPACESHIT_TIMER_PRECISION:-1}f" "$(( elapsed - (mins * 60) ))")

    if (( mins > 0 )); then
        duration="${mins}m ${secs}s"
    else
        duration="${secs}s"
    fi

    print -r -- " ${SPACESHIT_TEXT_COLOR}took${SPACESHIT_RESET_COLOR} ${SPACESHIT_TIMER_COLOR}${format//\%d/${duration}}${SPACESHIT_RESET_COLOR}"
}

_spaceshit_preexec() {
    SPACESHIT_CMD_START_TIME="$EPOCHREALTIME"
}

_spaceshit_precmd() {
    SPACESHIT_LAST_DURATION=""

    [[ -z "$SPACESHIT_CMD_START_TIME" ]] && return

    local elapsed=$(( EPOCHREALTIME - SPACESHIT_CMD_START_TIME ))
    local threshold="${SPACESHIT_TIMER_THRESHOLD:-0}"
    local last_cmd="${history[$((HISTCMD - 1))]%% *}"

    unset SPACESHIT_CMD_START_TIME

    { (( elapsed < threshold )) || [[ "$last_cmd" == clear ]] } && return

    SPACESHIT_LAST_DURATION="$(_spaceshit_format_duration "$elapsed")"
}

# Git status wrapper
_spaceshit_git_status() {
    local status_prompt
    status_prompt="$(_omz_git_prompt_status)" || return

    if [[ -n "$status_prompt" ]]; then
        print -r -- " ${SPACESHIT_GIT_STATUS_COLOR}[${status_prompt}]${SPACESHIT_RESET_COLOR}"
    fi
}

# Current directory rooted at Git repo
_spaceshit_pwd() {
    local git_root git_prefix git_path

    if git_root="$(__git_prompt_git rev-parse --show-toplevel 2>/dev/null)"; then
        git_prefix="$(__git_prompt_git rev-parse --show-prefix 2>/dev/null)"
        git_path="${git_root:t}"

        if [[ -n "$git_prefix" ]]; then
            git_path+="/${git_prefix%/}"
        fi

        print -r -- "${git_path//\%/%%}"
    else
        print -r -- "%~"
    fi
}

# Prompt definition
PROMPT='${SPACESHIT_PATH_COLOR}$(_spaceshit_pwd)${SPACESHIT_RESET_COLOR}$(git_prompt_info)$(_spaceshit_git_status)${SPACESHIT_LAST_DURATION}'
PROMPT+=$'\n'
PROMPT+="%(?:${SPACESHIT_SUCCESS_COLOR}➜:${SPACESHIT_ERROR_COLOR}➜)${SPACESHIT_RESET_COLOR} "

# Hooks
autoload -U add-zsh-hook
add-zsh-hook preexec _spaceshit_preexec
add-zsh-hook precmd _spaceshit_precmd
