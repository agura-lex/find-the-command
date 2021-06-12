function __cnf_print --argument-names message
    echo -e 1>&2 "$message"
end

set __cnf_action
set __cnf_force_su
set __cnf_noprompt 0
set __cnf_verbose 1

set __cnf_actions_joined "install:info:list files:list files (paged)"
set __cnf_actions (string split : "$__cnf_actions_joined")

for opt in $argv
    echo "$opt"
    if test (string length "$opt") -gt 0
        switch "$opt"
            case noprompt
                set __cnf_noprompt 1
            case su
                set __cnf_force_su
            case quiet
                set __cnf_verbose 0
            case install
                set __cnf_action "$__cnf_actions[1]"
            case info
                set __cnf_action "$__cnf_actions[2]"
            case list_files
                set __cnf_action "$__cnf_actions[3]"
            case list_files_paged
                set __cnf_action "$__cnf_actions[4]"
            case '*'
                __cnf_print "find-the-command: unknown option: $opt"
        end
    end
end

if test "$__cnf_verbose" -ne 0
    function __cnf_pre_search_warn --argument-names cmd
        __cnf_print "find-the-command: \"$cmd\" is not found locally, searching in repositories...\n"
    end

    function __cnf_cmd_not_found --argument-names cmd
        __cnf_print "find-the-command: command not found: $cmd"
        return 127
    end
else
    function __cnf_pre_search_warn
    end

    function __cnf_cmd_not_found
        return 127
    end
end

if test "$__cnf_noprompt" -eq 1
    function fish_command_not_found
        set cmd "$argv[1]"
        __cnf_pre_search_warn "$cmd"

        set packages (pkgfile --binaries -- "$cmd" ^/dev/null)
        switch (echo "$packages" | wc -w)
            case 0
                __cnf_cmd_not_found "$cmd"
            case 1
                __cnf_print "\"$cmd\" may be found in package \"$packages\"\n"
            case '*'
                __cnf_print "\"$cmd\" may be found in the following packages:\n"
                for package in "$packages"
                    __cnf_print "\t$package"
                end
        end
    end
else
    set __cnf_asroot
    if test (id -u) -ne 0
        if set --query "$__cnf_force_su"
            set __cnf_asroot "su -c"
        else
            set __cnf_asroot "sudo"
        end
    end
    function fish_command_not_found
        set cmd "$argv[1]"
        __cnf_pre_search_warn "$cmd"
        set packages (pkgfile --binaries -- "$cmd" ^/dev/null)
        switch (echo "$packages" | wc -w)
            case 0
                __cnf_cmd_not_found "$cmd"
            case 1
                function __prompt_install --argument-names packages
                    read --prompt="echo \"Would you like to install this package? (y|n) \"" result
                    switch "$result"
                    case 'y*'
                    case 'Y*'
                        "$__cnf_asroot" pacman -S "$packages"
                    case '*'
                        return 127
                    end
                end

                set action
                if test -z "$__cnf_action"
                    __cnf_print "\"$cmd\" may be found in package \"$packages\"\n"
                    __cnf_print "What would you like to do? "
                    set action (echo "$__cnf_actions_joined" | tr ":" "\n" | fzf --prompt "Action (\"esc\" to abort):")
                else
                    set action "$__cnf_action"
                end

                switch "$action"
                    case 'install'
                        "$__cnf_asroot" pacman -S "$packages"
                    case 'info'
                        pacman -Si "$packages"
                        __prompt_install "$packages"
                    case 'list files'
                        pacman -Flq "$packages"
                        __prompt_install "$packages"
                    case 'list files (paged)'
                        test -z "$pager"; and set --local pager less
                        pacman -Flq "$packages" | "$pager"
                        __prompt_install "$packages"
                    case '*'
                        return 127
                end
            case '*'
                __cnf_print "\"$cmd\" may be found in the following packages:\n"
                set --local package (echo "$packages" | tr " " "\n" | fzf --prompt "Select a package to install (\"esc\" to abort):")
                test -n "$package" and "$__cnf_asroot" pacman -S "$package" or return 127
        end
    end
end

function __fish_command_not_found_handler \
    --on-event fish_command_not_found
    fish_command_not_found "$argv"
end
