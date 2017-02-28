if echo $* | grep -q 'noprompt'
then
	command_not_found_handle() {
		local CMD=$1
		local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
		case $(echo $PKGS | wc -w) in
			0) echo "$0: $CMD: command not found"
				return 127 ;;
			1) printf "\"$CMD\" may be found in package \"$PKGS\"\n" ;;
			*)
				local PKG
				printf "\"$CMD\" may be found in the following packages:\n"
				for PKG in `echo -n $PKGS`
				do
				printf "\t$PKG\n"
				done
		esac
	}
else
	if [[ $EUID == 0 ]]
	then _asroot(){ $*; }
	else
		if $* | grep -q 'su'
		then _asroot() { su -c "$*"; }
		else _asroot() { sudo $*; }
		fi
	fi
	command_not_found_handle() {
		local CMD=$1
		local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
		case $(echo $PKGS | wc -w) in
			0) echo "$0: $CMD: command not found"
				return 127 ;;
			1) local ACT PS3="Action (0 to abort): "
				printf "\n\"$CMD\" may be found in package \"$PKGS\"\n\n"
				echo "What would you like to do? "
				select ACT in 'install' 'info' 'list files' 'list files (paged)'
				do
				break
				done
				case $ACT in
					install) _asroot pacman -S $PKGS ;;
					info) pacman -Si $PKGS ;;
					'list files') pacman -Flq $PKGS ;;
					'list files (paged)') [[ -z $PAGER ]] && local PAGER=less
						pacman -Flq $PKGS | $PAGER ;;
					*) echo
						return 127;;
				esac ;;
				*) local PKG PS3="$(printf "\nSelect a number of package to install (0 to abort):")" 
					printf "\"$CMD\" may be found in the following packages:\n\n"
					select PKG in `echo -n $PKGS`
					do
					break
					done
					[[ -n $PKG ]] && _asroot pacman -S $PKG || return 127 ;;
		esac
	}
fi
