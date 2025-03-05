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
                environment.systemPackages = with pkgs;
                    [
                        anki-bin
                        bat
                        fastfetch
                        fd
                        firefox
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
                        "inkscape"
                        "rustdesk"
                    ];
                };


                fonts.packages = [ ] ++ builtins.filter pkgs.lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

                programs = {
                    gnupg.agent.enable = true;
                    zsh.enableSyntaxHighlighting = true;
                };

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
                        home-manager = {
                            useGlobalPkgs = true;
                            useUserPackages = true;
                            users.daramac = {
                            };
                        };
                    }
                ];
            };
        };
}
