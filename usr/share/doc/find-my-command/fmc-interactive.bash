command_not_found_handle() 
{
	local CMD=$1 
	local PKGS=$(pm -Foq /usr/bin/$CMD 2> /dev/null)
	not_found() (echo "$0: command \"$CMD\" not found"; return 127)
	case $(echo $PKGS | wc -w) in
		0) not_found ;;
		1) local ACT PS3="Action (0 to abort): " 
			echo -e "\n\"$CMD\" may be found in package \"$PKGS\"\n"
			echo "What would you like to do? "
			select ACT in 'install' 'info' 'list files' 'list files (paged)'
			do
			break
			done
			case $ACT in
				install) sudo pacman -S $PKGS ;;
				info) pacman -Si $PKGS ;;
				'list files') pacman -Flq $PKGS ;;
				'list files (paged)') [[ -z $PAGER ]] && local PAGER=less
					pacman -Flq $PKGS | $PAGER ;;
				*) echo
					return 127;;
			esac ;;
			*) local PKG PS3="$(printf "\nSelect a number of package to install (0 to abort):")" 
				echo "\"$CMD\" may be found in the following packages:\n"
				select PKG in `echo -n $PKGS`
				do
				break
				done
				[[ -n $PKG ]] && sudo pacman -S $PKG || return 127 ;;
	esac
}
