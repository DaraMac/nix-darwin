{
    description = "nix-darwin system flake";

    inputs = {
        home-manager = {
            inputs.nixpkgs.follows = "nixpkgs";
            url = "github:nix-community/home-manager";
        };

        mac-app-util.url = "github:hraban/mac-app-util";

        nix-darwin = {
            inputs.nixpkgs.follows = "nixpkgs";
            url = "github:LnL7/nix-darwin/master";
        };

        # Homebrew installation
        nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

        # Optional: Declarative tap management
        homebrew-core = {
            url = "github:homebrew/homebrew-core";
            flake = false;
        };
        homebrew-cask = {
            url = "github:homebrew/homebrew-cask";
            flake = false;
        };
        homebrew-bundle = {
            url = "github:homebrew/homebrew-bundle";
            flake = false;
        };

        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    outputs = inputs@{ self, nix-darwin, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, nixpkgs, home-manager, mac-app-util }:
        let
            configuration = { pkgs, ... }: {
                # List packages installed in system profile
                environment = {
                    systemPackages = with pkgs;
                        [
                            anki-bin
                            bartib
                            bat
                            btop
                            dua
                            evil-helix
                            fastfetch
                            fd
                            fzf
                            gnupg
                            hledger-iadd
                            iina
                            imagemagick
                            iterm2
                            lsd
                            neovim
                            net-news-wire
                            obsidian
                            pass
                            pinentry_mac
                            renameutils
                            ripgrep
                            # texliveFull
                            thunderbird-latest
                            tmux
                            uv
                            yazi
                            zotero
                            zoxide
                            zsh-completions
                        ];

                    variables = {
                        BARTIB_FILE = "/Users/daramac/.local/share/bartib/2025.bartib";
                        EDITOR = "nvim";
                        LEDGER_FILE="/Users/daramac/Documents/accounts/2025.journal";

                        # Use bat for highighted manual
                        MANPAGER = "sh -c 'col -bx | bat -l man -p'";
                        MANROFFOPT = "-c";
                    };
                };

                homebrew = {
                    enable = true;
                    onActivation = {
                        autoUpdate = true;
                        cleanup = "zap";
                        upgrade = true;
                    };

                    brews = [
                        "hledger"
                    ];

                    casks = [
                        "breaktimer"
                        "calibre"
                        "discord"
                        "ferdium"
                        "firefox"
                        "heroic"
                        "rustdesk"
                    ];
                };


                fonts.packages = [ ] ++ builtins.filter pkgs.lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

                programs.gnupg.agent.enable = true;

                nix = {
                    gc.automatic = true;
                    optimise.automatic = true;

                    # Necessary for using flakes on this system.
                    settings.experimental-features = "nix-command flakes";
                };

                system = {
                    # Set Git commit hash for darwin-version.
                    configurationRevision = self.rev or self.dirtyRev or null;

                    primaryUser = "daramac";

                    # Used for backwards compatibility, please read the changelog before changing.
                    # $ darwin-rebuild changelog
                    stateVersion = 6;
                };

                nixpkgs = {
                    config.allowUnfree = true;

                    # The platform the configuration will be used on.
                    hostPlatform = "aarch64-darwin";
                };

                security.pam.services.sudo_local.touchIdAuth = true;
            };
        in
            {
            darwinConfigurations."Daras-MacBook-Air" = nix-darwin.lib.darwinSystem {
                modules = [
                    configuration
                    mac-app-util.darwinModules.default

                    nix-homebrew.darwinModules.nix-homebrew
                    {
                        nix-homebrew = {
                            # Install Homebrew under the default prefix
                            enable = true;

                            # User owning the Homebrew prefix
                            user = "daramac";

                            # Optional: Declarative tap management
                            taps = {
                                "homebrew/homebrew-bundle" = homebrew-bundle;
                                "homebrew/homebrew-cask" = homebrew-cask;
                                "homebrew/homebrew-core" = homebrew-core;
                            };

                            # Optional: Enable fully-declarative tap management
                            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
                            mutableTaps = false;

                            # Automatically migrate existing Homebrew installations
                            autoMigrate = true;
                        };
                    }

                    home-manager.darwinModules.home-manager
                    {
                        # Need this line or else it just breaks
                        # https://github.com/nix-community/home-manager/issues/6036#issuecomment-2466986456
                        users.users.daramac.home = "/Users/daramac";
                        home-manager = {
                            useGlobalPkgs = true;
                            useUserPackages = true;
                            users.daramac = {
                                home = {
                                    homeDirectory = "/Users/daramac";
                                    stateVersion = "25.05";
                                    username = "daramac";

                                    file."hledger-iadd".target = ".config/hledger-iadd/config.conf";
                                    file."hledger-iadd".text = ''date-format = "%Y-%m-%d"'';
                                };

                                programs = {
                                    home-manager.enable = true;

                                    fzf.enable = true;
                                    git = {
                                        enable = true;
                                        userEmail = "DaraMac@users.noreply.github.com";
                                        userName  = "dmac";
                                        extraConfig = {
                                            core.editor = "nvim";
                                            diff.algorithm = "histogram";
                                            init.defaultBranch = "main";
                                            log.date = "iso";
                                            merge.conflictstyle = "diff3";
                                            pull.rebase = "true";
                                            push.autoSetupRemote = "true";
                                        };
                                    };

                                    lsd = {
                                        enable = true;
                                        settings = {
                                            # date = "+%Y-%m-%d %H:%M";
                                            date = "relative";
                                            sorting.dir-grouping = "first";
                                            symlink-arrow = "→";
                                        };
                                    };

                                    starship = {
                                        enable = true;
                                        enableZshIntegration = true;
                                    };

                                    tmux = {
                                        enable = true;
                                        keyMode = "vi";
                                        mouse = true;
                                        terminal = "screen-256color"; # this was needed on Mac, maybe not on linux
                                        extraConfig = ''
                                            set -g status off
                                            bind -Tcopy-mode MouseDragEnd1Pane send -X copy-selection

                                            # To make new splits open in the same directory as current
                                            # https://unix.stackexchange.com/a/109255
                                            bind  %  split-window -h -c "#{pane_current_path}"
                                            bind '"' split-window -v -c "#{pane_current_path}"
                                        '';
                                    };

                                    zoxide.enable = true;

                                    zsh = {
                                        enable = true;
                                        autosuggestion.enable = true;
                                        dotDir = ".config/zsh";
                                        oh-my-zsh.enable = true;
                                        syntaxHighlighting.enable = true;
                                        shellAliases = {
                                            # Neovim
                                            vi = ''nvim'';
                                            vim = ''nvim'';

                                            # fzf
                                            v = "fzf --bind 'enter:become(nvim {})'";

                                            # ls
                                            # The other aliases are provided automatically by home manager
                                            lr = "lsd -lr";

                                            # start git aliases
                                            ggpur="ggu";
                                            g="git";
                                            ga="git add";
                                            gaa="git add --all";
                                            gapa="git add --patch";
                                            gau="git add --update";
                                            gav="git add --verbose";
                                            gwip=''git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'';
                                            gam="git am";
                                            gama="git am --abort";
                                            gamc="git am --continue";
                                            gamscp="git am --show-current-patch";
                                            gams="git am --skip";
                                            gap="git apply";
                                            gapt="git apply --3way";
                                            gbs="git bisect";
                                            gbsb="git bisect bad";
                                            gbsg="git bisect good";
                                            gbsn="git bisect new";
                                            gbso="git bisect old";
                                            gbsr="git bisect reset";
                                            gbss="git bisect start";
                                            gbl="git blame -w";
                                            gb="git branch";
                                            gba="git branch --all";
                                            gbd="git branch --delete";
                                            gbD="git branch --delete --force";

                                            ###

                                            gbgd=''LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '"'"'{print $1}'"'"' | xargs git branch -d'';
                                            gbgD=''LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '"'"'{print $1}'"'"' | xargs git branch -D'';
                                            gbm="git branch --move";
                                            gbnm="git branch --no-merged";
                                            gbr="git branch --remote";
                                            ggsup="git branch --set-upstream-to=origin/$(git_current_branch)";
                                            gbg=''LANG=C git branch -vv | grep ": gone\]"'';
                                            gco="git checkout";
                                            gcor="git checkout --recurse-submodules";
                                            gcb="git checkout -b";
                                            gcB="git checkout -B";
                                            gcd="git checkout $(git_develop_branch)";
                                            gcm="git checkout $(git_main_branch)";
                                            gcp="git cherry-pick";
                                            gcpa="git cherry-pick --abort";
                                            gcpc="git cherry-pick --continue";
                                            gclean="git clean --interactive -d";
                                            gcl="git clone --recurse-submodules";
                                            gclf="git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules";

                                            ###

                                            gcam="git commit --all --message";
                                            gcas="git commit --all --signoff";
                                            gcasm="git commit --all --signoff --message";
                                            gcs="git commit --gpg-sign";
                                            gcss="git commit --gpg-sign --signoff";
                                            gcssm="git commit --gpg-sign --signoff --message";
                                            gcmsg="git commit --message";
                                            gcsm="git commit --signoff --message";
                                            gc="git commit --verbose";
                                            gca="git commit --verbose --all";
                                            "gca!" ="git commit --verbose --all --amend";
                                            "gcan!" ="git commit --verbose --all --no-edit --amend";
                                            "gcans!" ="git commit --verbose --all --signoff --no-edit --amend";
                                            "gcann!" ="git commit --verbose --all --date=now --no-edit --amend";
                                            "gc!" ="git commit --verbose --amend";
                                            gcn="git commit --verbose --no-edit";
                                            "gcn!" ="git commit --verbose --no-edit --amend";
                                            gcf="git config --list";
                                            gdct="git describe --tags $(git rev-list --tags --max-count=1)";
                                            gd="git diff";
                                            gdca="git diff --cached";
                                            gdcw="git diff --cached --word-diff";
                                            gds="git diff --staged";
                                            gdw="git diff --word-diff";

                                            gdup="git diff @{upstream}";

                                            gdt="git diff-tree --no-commit-id --name-only -r";
                                            gf="git fetch";
                                            gfa="git fetch --all --tags --prune --jobs=10";
                                            gfo="git fetch origin";
                                            gg="git gui citool";
                                            gga="git gui citool --amend";
                                            ghh="git help";
                                            glgg="git log --graph";
                                            glgga="git log --graph --decorate --all";
                                            glgm="git log --graph --max-count=10";
                                            glods=''git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'';
                                            glod=''git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'';
                                            glola=''git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'';
                                            glols=''git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'';
                                            glol=''git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'';
                                            # modified version of https://stackoverflow.com/a/9463536 and lines above here
                                            glo=''git log --pretty="format:%C(yellow)%h %Creset%s %Cblue%>(12)%ad" --date=relative'';
                                            glog="git log --oneline --decorate --graph";
                                            gloga="git log --oneline --decorate --graph --all";

                                            glp="_git_log_prettily";
                                            glg="git log --stat";
                                            glgp="git log --stat --patch";
                                            gignored=''git ls-files -v | grep "^[[:lower:]]"'';
                                            gfg="git ls-files | grep";
                                            gm="git merge";
                                            gma="git merge --abort";
                                            gmc="git merge --continue";
                                            gms="git merge --squash";
                                            gmff="git merge --ff-only";
                                            gmom="git merge origin/$(git_main_branch)";
                                            gmum="git merge upstream/$(git_main_branch)";
                                            gmtl="git mergetool --no-prompt";
                                            gmtlvim="git mergetool --no-prompt --tool=vimdiff";

                                            gl="git pull";
                                            gpr="git pull --rebase";
                                            gprv="git pull --rebase -v";
                                            gpra="git pull --rebase --autostash";
                                            gprav="git pull --rebase --autostash -v";

                                            gprom="git pull --rebase origin $(git_main_branch)";
                                            gpromi="git pull --rebase=interactive origin $(git_main_branch)";
                                            gprum="git pull --rebase upstream $(git_main_branch)";
                                            gprumi="git pull --rebase=interactive upstream $(git_main_branch)";
                                            ggpull=''git pull origin "$(git_current_branch)"'';

                                            gluc="git pull upstream $(git_current_branch)";
                                            glum="git pull upstream $(git_main_branch)";
                                            gp="git push";
                                            gpd="git push --dry-run";

                                            "gpf!"="git push --force";
                                            gpf="git push --force-with-lease --force-if-includes";

                                            gpsup="git push --set-upstream origin $(git_current_branch)";
                                            gpsupf="git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes";
                                            gpv="git push --verbose";
                                            gpoat="git push origin --all && git push origin --tags";
                                            gpod="git push origin --delete";
                                            ggpush=''git push origin "$(git_current_branch)"'';

                                            gpu=''git push upstream'';
                                            grb=''git rebase'';
                                            grba=''git rebase --abort'';
                                            grbc=''git rebase --continue'';
                                            grbi=''git rebase --interactive'';
                                            grbo=''git rebase --onto'';
                                            grbs=''git rebase --skip'';
                                            grbd=''git rebase $(git_develop_branch)'';
                                            grbm=''git rebase $(git_main_branch)'';
                                            grbom=''git rebase origin/$(git_main_branch)'';
                                            grbum=''git rebase upstream/$(git_main_branch)'';
                                            grf=''git reflog'';
                                            gr=''git remote'';
                                            grv=''git remote --verbose'';
                                            gra=''git remote add'';
                                            grrm=''git remote remove'';
                                            grmv=''git remote rename'';
                                            grset=''git remote set-url'';
                                            grup=''git remote update'';
                                            grh=''git reset'';
                                            gru=''git reset --'';
                                            grhh=''git reset --hard'';
                                            grhk=''git reset --keep'';
                                            grhs=''git reset --soft'';
                                            gpristine=''git reset --hard && git clean --force -dfx'';
                                            gwipe=''git reset --hard && git clean --force -df'';
                                            groh=''git reset origin/$(git_current_branch) --hard'';
                                            grs=''git restore'';
                                            grss=''git restore --source'';
                                            grst=''git restore --staged'';
                                            gunwip=''git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'';
                                            grev=''git revert'';
                                            greva=''git revert --abort'';
                                            grevc=''git revert --continue'';
                                            grm=''git rm'';
                                            grmc=''git rm --cached'';
                                            gcount=''git shortlog --summary --numbered'';
                                            gsh=''git show'';
                                            gsps=''git show --pretty=short --show-signature'';
                                            gstall=''git stash --all'';
                                            gstaa=''git stash apply'';
                                            gstc=''git stash clear'';
                                            gstd=''git stash drop'';
                                            gstl=''git stash list'';
                                            gstp=''git stash pop'';
                                            gsta=''git stash push'';
                                            gsts=''git stash show --patch'';
                                            gst=''git status'';
                                            gss=''git status --short'';
                                            gsb=''git status --short --branch'';
                                            gsi=''git submodule init'';
                                            gsu=''git submodule update'';
                                            gsd=''git svn dcommit'';
                                            git-svn-dcommit-push=''git svn dcommit && git push github $(git_main_branch):svntrunk'';
                                            gsr=''git svn rebase'';
                                            gsw=''git switch'';
                                            gswc=''git switch --create'';
                                            gswd=''git switch $(git_develop_branch)'';
                                            gswm=''git switch $(git_main_branch)'';
                                            gta=''git tag --annotate'';
                                            gts=''git tag --sign'';
                                            gtv=''git tag | sort -V'';
                                            gignore=''git update-index --assume-unchanged'';
                                            gunignore=''git update-index --no-assume-unchanged'';
                                            gwch=''git whatchanged -p --abbrev-commit --pretty=medium'';
                                            gwt=''git worktree'';
                                            gwta=''git worktree add'';
                                            gwtls=''git worktree list'';
                                            gwtmv=''git worktree move'';
                                            gwtrm=''git worktree remove'';
                                            gstu=''gsta --include-untracked'';
                                            gtl=''gtl(){ git tag --sort=-v:refname -n --list "''${1}*" }; noglob gtl'';
                                            gk=''\gitk --all --branches &!'';
                                            gke=''\gitk --all $(git log --walk-reflogs --pretty=%h) &!'';
                                            # end git aliases

                                        };

                                        initContent = ''
                                            # start git functions

                                            # Check for develop and similarly named branches
                                            function git_develop_branch() {
                                                command git rev-parse --git-dir &>/dev/null || return
                                                local branch
                                                for branch in dev devel develop development; do
                                                    if command git show-ref -q --verify refs/heads/$branch; then
                                                        echo $branch
                                                        return 0
                                                    fi
                                                done

                                                echo develop
                                                return 1
                                            }

                                            function grename() {
                                                if [[ -z "$1" || -z "$2" ]]; then
                                                    echo "Usage: $0 old_branch new_branch"
                                                    return 1
                                                fi

                                                # Rename branch locally
                                                git branch -m "$1" "$2"
                                                # Rename branch in origin remote
                                                if git push origin :"$1"; then
                                                    git push --set-upstream origin "$2"
                                                fi
                                            }

                                            function gbda() {
                                                git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
                                            }

                                            # https://github.com/jmaroeder/plugin-git/blob/216723ef4f9e8dde399661c39c80bdf73f4076c4/functions/gbda.fish
                                            function gbds() {
                                                local default_branch=$(git_main_branch)
                                                (( ! $? )) || default_branch=$(git_develop_branch)

                                                git for-each-ref refs/heads/ "--format=%(refname:short)" | \
                                                while read branch; do
                                                    local merge_base=$(git merge-base $default_branch $branch)
                                                        if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]; then
                                                            git branch -D $branch
                                                        fi
                                                    done
                                            }

                                            function gccd() {
                                                setopt localoptions extendedglob

                                                # get repo URI from args based on valid formats: https://git-scm.com/docs/git-clone#URLS
                                                local repo="''${''${@[(r)(ssh://*|git://*|ftp(s)#://*|http(s)#://*|*@*)(.git/#)#]}:-$_}"

                                                # clone repository and exit if it fails
                                                command git clone --recurse-submodules "$@" || return

                                                # if last arg passed was a directory, that's where the repo was cloned
                                                # otherwise parse the repo URI and use the last part as the directory
                                                [[ -d "$_" ]] && cd "$_" || cd "''${''${repo:t}%.git/#}"
                                            }
                                            compdef _git gccd=git-clone

                                            function gdv() { git diff -w "$@" | view - }
                                            compdef _git gdv=git-diff

                                            function gdnolock() {
                                                git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
                                            }
                                            compdef _git gdnolock=git-diff

                                            # Pretty log messages
                                            function _git_log_prettily(){
                                                if ! [ -z $1 ]; then
                                                    git log --pretty=$1
                                                fi
                                            }
                                            compdef _git _git_log_prettily=git-log

                                            function ggu() {
                                                [[ "$#" != 1 ]] && local b="$(git_current_branch)"
                                                git pull --rebase origin "''${b:=$1}"
                                            }
                                            compdef _git ggu=git-checkout

                                            function ggl() {
                                                if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
                                                    git pull origin "''${*}"
                                                else
                                                    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
                                                    git pull origin "''${b:=$1}"
                                                fi
                                            }
                                            compdef _git ggl=git-checkout

                                            function ggf() {
                                                [[ "$#" != 1 ]] && local b="$(git_current_branch)"
                                                git push --force origin "''${b:=$1}"
                                            }
                                            compdef _git ggf=git-checkout

                                            function ggfl() {
                                                [[ "$#" != 1 ]] && local b="$(git_current_branch)"
                                                git push --force-with-lease origin "''${b:=$1}"
                                            }
                                            compdef _git ggfl=git-checkout

                                            function ggp() {
                                                if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
                                                    git push origin "''${*}"
                                                else
                                                    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
                                                    git push origin "''${b:=$1}"
                                                fi
                                            }
                                            compdef _git ggp=git-checkout

                                            ### end git functions


                                            source ~/opt/bartibCompletion.sh

                                            # Setup yazi alias
                                            function y() {
                                                local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
                                                yazi "$@" --cwd-file="$tmp"
                                                if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                                                builtin cd -- "$cwd"
                                                fi
                                                rm -f -- "$tmp"
                                            }

                                        '';
                                    };
                                };
                            };
                        };
                    }
                ];
            };
        };
}
