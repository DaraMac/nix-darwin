{
    description = "nix-darwin system flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        nix-darwin.url = "github:LnL7/nix-darwin/master";
        nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ self, nix-darwin, nixpkgs }:
        let
            configuration = { pkgs, ... }: {
                # List packages installed in system profile
                environment.systemPackages =
                    [
                    ];

                nix = {
                    settings = {
                        # Necessary for using flakes on this system.
                        experimental-features = "nix-command flakes";
                        auto-optimise-store = true;
                    };
                    gc.automatic = true;
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
            };
        in
            {
            # Build darwin flake using:
            # $ darwin-rebuild build --flake .#Daras-MacBook-Air
            darwinConfigurations."Daras-MacBook-Air" = nix-darwin.lib.darwinSystem {
                modules = [ configuration ];
            };
        };
}
