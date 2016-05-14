command_not_found_handler()
{
	local CMD=$1
	local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
	case $(echo $PKGS | wc -w) in
		0) return 127 ;;
		1)
			local ACT PS3="Action (0 to abort): "
			local prompt_install()
			{
				echo -n "Would you like to install this package? (y|n) "
				read -q && (echo;sudo pacman -S $PKGS) || (echo; return 127)
			}
			echo "\n\"$CMD\" may be found in package \"$PKGS\"\n"
			echo "What would you like to do? "
			select ACT in 'install' 'info' 'list files' 'list files (paged)'
			do break
			done
			case $ACT in
				install) sudo pacman -S $PKGS ;;
				info) pacman -Si $PKGS; prompt_install;;
				'list files') pacman -Flq $PKGS; echo; prompt_install;;
				'list files (paged)') [[ -z $PAGER ]] && local PAGER=less
					pacman -Flq $PKGS | $PAGER
					prompt_install ;;
				*) echo; return 127
			esac
	;;
		*)
			local PKG PS3="$(printf "\nSelect a number of package to install (0 to abort):")"
			echo "\"$CMD\" may be found in the following packages:\n"
			select PKG in `echo -n $PKGS`
			do break
			done
			[[ -n $PKG ]] && s pm -S $PKG || return 127
	esac
}
