#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# android studio paths
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/28.2.13676358
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='\W\n> '

# pywal
# (cat ~/.cache/wal/sequences &)

. "$HOME/.local/bin/env"


# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init --path)"
export PATH="$HOME/flutter/bin:$PATH"
