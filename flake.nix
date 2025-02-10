{
    description = "nix-darwin system flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        nix-darwin.url = "github:LnL7/nix-darwin/master";
        nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
        mac-app-util.url = "github:hraban/mac-app-util";
    };

    outputs = inputs@{ self, nix-darwin, nixpkgs, mac-app-util }:
        let
            configuration = { pkgs, ... }: {
                # List packages installed in system profile
                environment.systemPackages = with pkgs;
                    [
                        anki-bin
                        bat
                        fzf
                        hledger
                        hledger-iadd
                        iina
                        iterm2
                        lsd
                        neovim
                        net-news-wire
                        ripgrep
                        vesktop
                        yazi
                        zoxide
                    ];

                homebrew = {
                    enable = true;
                    onActivation = {
                        autoUpdate = true;
                        cleanup = "zap";
                        upgrade = true;
                    };

                    casks = [
                        "ferdium"
                        "rustdesk"
                    ];
                };

                programs.zsh.enableSyntaxHighlighting = true;

                nix = {
                    settings = {
                        # Necessary for using flakes on this system.
                        experimental-features = "nix-command flakes";
                    };
                    gc.automatic = true;
                    optimise.automatic = true;
                };

                system = {
                    # Set Git commit hash for darwin-version.
                    configurationRevision = self.rev or self.dirtyRev or null;

                    # Used for backwards compatibility, please read the changelog before changing.
                    # $ darwin-rebuild changelog
                    stateVersion = 6;
                };

                # The platform the configuration will be used on.
                nixpkgs.hostPlatform = "aarch64-darwin";

                security.pam.enableSudoTouchIdAuth = true;
            };
        in
            {
            # Build darwin flake using:
            # $ darwin-rebuild build --flake .#Daras-MacBook-Air
            darwinConfigurations."Daras-MacBook-Air" = nix-darwin.lib.darwinSystem {
                modules = [
                    configuration
                    mac-app-util.darwinModules.default
                ];
            };
        };
}
