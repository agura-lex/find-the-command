command_not_found_handle() 
{
	local CMD=$1
	local PKGS=$(pacman -Foq /usr/bin/$CMD 2> /dev/null)
	case $(echo $PKGS | wc -w) in
		0) echo "$0: $CMD: command not found"
			return 127 ;;
		1) printf "\"$CMD\" may be found in package \"$PKGS\"\n" ;;
		*)
			printf "\"$CMD\" may be found in the following packages:\n"
			for PKG in `echo -n $PKGS`
			do
			printf "\t$PKG\n"
			done
	esac
}
