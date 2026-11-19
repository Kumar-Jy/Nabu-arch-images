#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Terminal Prompt matching tablet setup
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='\[\e[0m\]╭─ \[\e[1m\]\u\[\e[0m\]  \[\e[38;2;220;223;228m\]\[\e[48;2;220;223;228m\e[38;2;18;18;18m\]  \w \[\e[0m\e[38;2;220;223;228m\]\n\[\e[0m\]╰─)) '
fi
