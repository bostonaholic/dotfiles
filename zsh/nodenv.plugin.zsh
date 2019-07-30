# https://github.com/bostonaholic/nodenv.plugin.zsh

_homebrew-installed() {
    type brew &> /dev/null
}

FOUND_NODENV=0
nodenvdirs=("$HOME/.nodenv" "$HOME/.local/nodenv" "/usr/local/nodenv" "/opt/nodenv" "/usr/local/opt/nodenv")
if _homebrew-installed && nodenv_homebrew_path=$(brew --prefix nodenv 2>/dev/null); then
    nodenvdirs=($nodenv_homebrew_path "${nodenvdirs[@]}")
    unset nodenv_homebrew_path
    if [[ $NODENV_ROOT = '' ]]; then
        NODENV_ROOT="$HOME/.nodenv"
    fi
fi

for nodenvdir in "${nodenvdirs[@]}" ; do
    if [ -d $nodenvdir/bin -a $FOUND_NODENV -eq 0 ] ; then
        FOUND_NODENV=1
        if [[ $NODENV_ROOT = '' ]]; then
            NODENV_ROOT=$nodenvdir
        fi
        export NODENV_ROOT
        export PATH=${nodenvdir}/bin:$PATH
        eval "$(nodenv init --no-rehash - zsh)"

        function current_node() {
            echo "$(nodenv version-name)"
        }

        function nodenv_prompt_info() {
            echo "$(current_node)"
        }
    fi
done
unset nodenvdir

if [ $FOUND_NODENV -eq 0 ] ; then
    function nodenv_prompt_info() { echo "system: $(node --version)" }
fi
