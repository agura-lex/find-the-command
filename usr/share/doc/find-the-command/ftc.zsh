# Print to stderr
alias _cnf_print='echo -e 1>&2'

# Parse options
for opt in $*
do
    case $opt in
        noprompt) noprompt=1 ;;
        su) force_su=1 ;;
        *) _cnf_print "find-the-command: unknown option: $opt"
    esac
done

# Without installation prompt
if [[ $noprompt == 1 ]]
then
    command_not_found_handler(){
        local CMD=$1
        local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
        case $(echo $PKGS | wc -w) in
            0) _cnf_print "$0: $CMD: command not found"
                return 127 ;;
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
    then _asroot(){ $*; }
    else
        if [[ $force_su == 1 ]]
        then _asroot() { su -c "$*"; }
        else _asroot() { sudo $*; }
        fi
    fi
    command_not_found_handler(){
        local CMD=$1
        local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
        case $(echo $PKGS | wc -w) in
            0) return 127 ;;
            1)
                local ACT PS3="Action (0 to abort): "
                local prompt_install(){
                    _cnf_print -n "Would you like to install this package? (y|n) "
                read -q && (_cnf_print;_asroot pacman -S $PKGS) || (_cnf_print; return 127)
                }
                _cnf_print "\n\"$CMD\" may be found in package \"$PKGS\"\n"
                _cnf_print "What would you like to do? "
                select ACT in 'install' 'info' 'list files' 'list files (paged)'
                do break
                done
                case $ACT in
                    install) _asroot pacman -S $PKGS ;;
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
                [[ -n $PKG ]] && _asroot pacman -S $PKG || return 127
        esac
    }
fi

# Clean up environment
unset opt force_su noprompt
