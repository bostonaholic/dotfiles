# https://github.com/bostonaholic/nodenv.plugin.zsh

# This plugin loads nodenv into the current shell and provides prompt info via
# the 'nodenv_prompt_info' function.

FOUND_NODENV=$+commands[nodenv]

if [[ $FOUND_NODENV -ne 1 ]]; then
    nodenvdirs=("$HOME/.nodenv" "/usr/local/nodenv" "/opt/nodenv" "/usr/local/opt/nodenv")
    for dir in $nodenvdirs; do
        if [[ -d $dir/bin ]]; then
            export PATH="$dir/bin:$PATH"
            FOUND_NODENV=1
            breakp
        fi
    done
fi

if [[ $FOUND_NODENV -ne 1 ]]; then
    if (( $+commands[brew] )) && dir=$(brew --prefix nodenv 2>/dev/null); then
        if [[ -d $dir/bin ]]; then
            export PATH="$dir/bin:$PATH"
            FOUND_NODENV=1
        fi
    fi
fi

if [[ $FOUND_NODENV -eq 1 ]]; then
    eval "$(nodenv init --no-rehash - zsh)"

    function current_node() {
        echo "$(nodenv version-name)"
    }

    function nodenv_prompt_info() {
        echo "$(current_node)"
    }
else
    function current_node() { echo "not supported" }
    function nodenv_prompt_info() {
        echo -n "system: $(node --version)"
    }
fi

unset FOUND_NODENV nodenvdirs dir
