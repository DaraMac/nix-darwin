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

        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, mac-app-util }:
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
                            fastfetch
                            fd
                            fzf
                            hledger
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
                            thunderbird-latest
                            tmux
                            uv
                            vesktop
                            yazi
                            zotero
                            zoxide
                            zsh-completions
                        ];

                    variables.EDITOR = "nvim";
                };

                homebrew = {
                    enable = true;
                    onActivation = {
                        autoUpdate = true;
                        cleanup = "zap";
                        upgrade = true;
                    };

                    brews = [
                        "runtimeverification/k/kframework"
                    ];

                    casks = [
                        "breaktimer"
                        "ferdium"
                        "firefox"
                        "inkscape"
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

                                    # .oh-my-zsh/themes/dracula.zsh-theme
                                    # .oh-my-zsh/themes/lib/async.zsh
                                    zsh = {
                                        enable = true;
                                        autosuggestion.enable = true;
                                        dotDir = ".config/zsh";
                                        oh-my-zsh.enable = true;
                                        syntaxHighlighting.enable = true;
                                        shellAliases = {
                                            # fzf
                                            v = "fzf --bind 'enter:become(nvim {})'";

                                            # ls
                                            la = "lsd -lA";
                                            ll = "lsd -l";
                                            lr = "lsd -lr";
                                            ls = "lsd";
                                            lt = "lsd --tree";
                                        };
                                    };
                                };
                            };
                        };
                    }
                ];
            };
        };
}
