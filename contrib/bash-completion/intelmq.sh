# Thanks to Steve https://debian-administration.org/article/317/An_introduction_to_bash_completion_part_2

_intelmqctl ()
{
    local cur prev opts base;
    COMPREPLY=();
    cur="${COMP_WORDS[COMP_CWORD]}";
    prev="${COMP_WORDS[COMP_CWORD-1]}";

    generic_pre="-h --help -v --version"
    generic_post="--quiet --type"

    if [[ "$prev" == -t ]] || [[ "$prev" == --type ]]; then
        COMPREPLY=( $( compgen -W "json text"  -- "$cur" ) )
        return 0
    fi

    #echo "posice: $COMP_CWORD $COMP_WORDS";
    case $COMP_CWORD in
        1)
            opts="start stop restart reload run status clear list check enable disable";
            COMPREPLY=($(compgen -W "${opts} ${generic_pre} ${generic_post}" -- ${cur}));
            return 0
        ;;
        2)
            pipeline='/opt/intelmq/etc/pipeline.conf';
            case "${COMP_WORDS[1]}" in
                start | stop | restart | status | reload | log | run | enable | disable)
                    runtime='/opt/intelmq/etc/runtime.conf';
                    local bots=$(jq 'keys[]' $runtime);
                    COMPREPLY=($(compgen -W "${bots}" -- ${cur}));
                    return 0
                ;;
                clear)
                    local bots=$(jq '.[] | .["source-queue"]' $pipeline | grep -v '^null$'; jq '.[] | .["destination-queues"]'  $pipeline | grep -v '^null$' | jq '.[]');
                    COMPREPLY=($(compgen -W "${bots}" -- ${cur}));
                    return 0
                ;;
                list)
                    COMPREPLY=($(compgen -W "bots queues queues-and-status" -- ${cur}));
                    return 0
                ;;
                #*)
                #    COMPREPLY=($(compgen -W "${generic_post}" -- ${cur}));
                #    return 0
                #;;
            esac
        ;;
        3)
            case "${COMP_WORDS[1]}" in
                run)
                    COMPREPLY=($(compgen -W "console message process" -- ${cur}));
                    return 0
                ;;
                #*)
                #    COMPREPLY=($(compgen -W "${generic_post}" -- ${cur}));
                #    return 0
                #;;
            esac
        ;;
        4)
            case "${COMP_WORDS[1]}" in
                log)
                    COMPREPLY=( $( compgen -W "DEBUG INFO WARNING ERROR CRITICAL"  -- "$cur" ) )
                    return 0
                ;;
                run)
                    case "${COMP_WORDS[3]}" in
                        console)
                            local consoles=$(pip3 list 2>/dev/null | grep -e 'pdb\|pudb' | cut -d' ' -f1)
                            COMPREPLY=($(compgen -W "pdb ${consoles}" -- ${cur}));
                            return 0
                        ;;
                        message)
                            COMPREPLY=($(compgen -W "get pop send" -- ${cur}));
                            return 0
                        ;;
                        process)
                            COMPREPLY=($(compgen -W "--show-sent --dry-run --msg" -- ${cur}));
                            return 0
                        ;;
                    esac
                ;;
            esac
        ;;
        5)
            if [[ "${COMP_WORDS[1]}" == "run" ]]; then
                    case "${COMP_WORDS[3]}" in
                        message)
                            if [[ "${COMP_WORDS[4]}" == "send" ]]; then
                                COMPREPLY=($(compgen -W "--msg" -- ${cur}));
                                return 0
                            fi
                        ;;
                    esac
                fi
    esac
}
complete -F _intelmqctl intelmqctl

_intelmqdump ()
{
    local cur prev opts base;
    COMPREPLY=();
    cur="${COMP_WORDS[COMP_CWORD]}";
    logpath=/opt/intelmq/var/log;
    # TODO: handle no dumps
    local dumps=$(for filename in $logpath/*.dump; do b=${filename##*/}; echo ${b%%.*}; done);
    COMPREPLY=($(compgen -W "${dumps} -h --help" -- ${cur}))
}
complete -F _intelmqdump intelmqdump
