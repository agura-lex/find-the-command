# Print to stderr
alias _cnf_print='echo -e 1>&2'

_cnf_actions=('install' 'info' 'list files' 'list files (paged)')

# Parse options
for opt in $*
do
    case $opt in
        noprompt) cnf_noprompt=1 ;;
        su) cnf_force_su=1 ;;
        quiet) cnf_verbose=0 ;;
        install) cnf_action=$_cnf_actions[1] ;;
        info) cnf_action=$_cnf_actions[2] ;;
        list_files) cnf_action=$_cnf_actions[3] ;;
        list_files_paged) cnf_action=$_cnf_actions[4] ;;
        *) _cnf_print "find-the-command: unknown option: $opt"
    esac
done

# Don't show pre-search warning if 'quiet' option is not set
if [[ $cnf_verbose != 0 ]]
then
    _cnf_pre_search_warn(){
        _cnf_print "find-the-command: \"$CMD\" is not found locally, searching in repositories..." 
    }
    _cnf_cmd_not_found(){
        _cnf_print "find-the-command: command not found: $CMD"
        return 127
    }
else
    _cnf_pre_search_warn(){ : Do nothing; }
    _cnf_cmd_not_found(){ return 127; }
fi

# Without installation prompt
if [[ $cnf_noprompt == 1 ]]
then
    command_not_found_handler(){
        local CMD=$1
        _cnf_pre_search_warn
        local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
        case $(echo $PKGS | wc -w) in
            0) _cnf_cmd_not_found ;;
            1) _cnf_print "\"$CMD\" may be found in package \"$PKGS\"" ;;
            *)
                local PKG
                _cnf_print "\"$CMD\" may be found in the following packages:"
                for PKG in `echo -n $PKGS`
                do
                _cnf_print "\t$PKG"
                done
        esac
    }
else
# With installation prompt (default)
    if [[ $EUID == 0 ]]
    then _cnf_asroot(){ $*; }
    else
        if [[ $cnf_force_su == 1 ]]
        then _cnf_asroot() { su -c "$*"; }
        else _cnf_asroot() { sudo $*; }
        fi
    fi
    command_not_found_handler(){
        local CMD=$1
        _cnf_pre_search_warn
        local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
        case $(echo $PKGS | wc -w) in
            0) _cnf_cmd_not_found ;;
            1)
                local ACT PS3="Action (0 to abort): "
                local prompt_install(){
                    _cnf_print -n "Would you like to install this package? (y|n) "
                read -q && (_cnf_print;_cnf_asroot pacman -S $PKGS) || (_cnf_print; return 127)
                }

                if [[ -z $cnf_action ]]
                then
                    _cnf_print "\n\"$CMD\" may be found in package \"$PKGS\"\n"
                    _cnf_print "What would you like to do? "
                    select ACT in $_cnf_actions
                    do break
                    done
                else
                    ACT=$cnf_action
                fi

                _cnf_print
                case $ACT in
                    install) _cnf_asroot pacman -S $PKGS ;;
                    info) pacman -Si $PKGS; prompt_install;;
                    'list files') pacman -Flq $PKGS; _cnf_print; prompt_install;;
                    'list files (paged)') [[ -z $PAGER ]] && local PAGER=less
                        pacman -Flq $PKGS | $PAGER
                        prompt_install ;;
                    *) _cnf_print; return 127
                esac
        ;;
            *)
                local PKG PS3="$(echo -en "\nSelect a number of package to install (0 to abort): ")"
                _cnf_print "\"$CMD\" may be found in the following packages:\n"
                select PKG in `echo -n $PKGS`
                do break
                done
                [[ -n $PKG ]] && _cnf_asroot pacman -S $PKG || return 127
        esac
    }
fi

# Clean up environment
unset opt cnf_force_su cnf_noprompt cnf_verbose
