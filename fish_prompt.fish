# prompt name: lolfish
# prompt requires: jobs (fish builtin), git, hostname, sed

function lolfish -d "such rainbow. wow"
    # xterm-256color RGB color values
    set -l colors ff0000 ff5700 ff8700 ffaf00 ffd700\
                  ffff00 d7ff00 afff00 87ff00 57ff00\
                  00ff00 00ff57 00ff87 00ffaf 00ffd7\
                  00ffff 00d7ff 00afff 0087ff 0057ff\
                  0000ff 5700ff 8700ff af00ff d700ff\
                  ff00ff ff00d7 ff00af ff0087 ff0057

    if test -z "$lolfish_next_color"; or \
       test $lolfish_next_color -gt (count $colors); or \
       test $lolfish_next_color -le 0
         # set to red
         set -g lolfish_next_color 1
    end

    set -l color_step 1

    # start the printing process
    for arg in $argv
        # print these special characters in normal color
        switch $arg
            case ' ' \( \) \[ \] \: \@ \{ \} \/
                set_color normal
                echo -n -s $arg
                continue
        end

        # safety checks
        if test -z "$color"
            set color $lolfish_next_color
        else if test $color -gt (count $colors); or test $color -le 0
            set color 1
        end

        set_color $colors[$color]
        echo -n -s $arg
        set color (math $color + $color_step)
    end

    # increment lolfish_next_color
    set -g lolfish_next_color (math $lolfish_next_color + $color_step)
    set_color normal
end

function fish_prompt
    # last command had an error? display the return value
    set -l exit_status $status
    if test $exit_status -ne 0
        set error '(' $exit_status ')'
    end

    # abbreviated home directory
    if command -sq sed
        set current_dir (echo $PWD | sed "s|$HOME|~|" 2>/dev/null)
    else
        set current_dir $PWD
    end

    # git information
    if command -sq git
        if git rev-parse --git-dir 2>/dev/null >/dev/null
            set -l git_branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)
            set -l git_status (count (git status -s --ignore-submodules 2>/dev/null))
            if test $git_status -gt 0
                set git_dir '[' $git_branch ':' $git_status ']'
            else
                set git_dir '[' $git_branch ']'
            end
        end
    end

    # hashtag prompt for root user
    switch $USER
        case root
            set prompt '#'
        case '*'
            set prompt '>>'
    end

    # print the prompt
    lolfish $USER '@' (hostname -s) ':' $current_dir $git_dir $error $prompt ' '
end

function fish_right_prompt
    # background jobs
    set -l background_jobs (count (jobs -p 2>/dev/null))
    if test $background_jobs -gt 0
        set background_jobs_prompt '[' '&' ':' $background_jobs ']'
    end

    # tmux sessions
    if test -z "$TMUX"
        if command -sq tmux
            set -l tmux_sessions (count (tmux list-sessions 2>/dev/null))
            if test $tmux_sessions -gt 0
                set tmux_sessions_prompt '[' 'tmux' ':' $tmux_sessions ']'
            end
        end
    end

    # time and date
    if command -sq date
        set time (date '+%H:%M')
        set date (date '+%d-%m-%Y')
    end

    lolfish $background_jobs_prompt $tmux_sessions_prompt $time ' ' $date
end