_rm_trash()
{
    local cur prev opts origin_rm

    if [ -x '/bin/rm' ]; then
        origin_rm='/bin/rm'
    elif [ -x '/usr/bin/rm' ]; then
        origin_rm='/usr/bin/rm'
    fi

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-v -d -R -r -i -h --help --color --colour --no-color --no-colour"

    if [ -n "$origin_rm" ]; then
        opts="$opts --rm"
    fi

    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}
complete -F _rm_trash rm
