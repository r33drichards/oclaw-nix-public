{
  description = "oclaw-nix-public — slot2 NixOS config: public-info OpenClaw agent (aldo prefix)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, comin }:
  let
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    unstable = nixpkgs-unstable.legacyPackages.${system};
    openclaw = unstable.callPackage ./pkgs/openclaw {};
  in {
    nixosConfigurations.slot2 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        self.nixosModules.default
        ({ ... }: {
          networking.hostName = "slot2";
          networking.useNetworkd = true;
          systemd.network.enable = true;
          systemd.network.networks."10-lan" = {
            matchConfig.Type = "ether";
            networkConfig = {
              Address = "10.2.0.2/24";
              Gateway = "10.2.0.1";
              DNS = "10.2.0.1";
            };
          };

          services.openssh.enable = true;
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJNEMM9i3WgPeA5dDmU7KMWTCcwLLi4EWfX8CKXuK7s robertwendt@Roberts-Laptop.local"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlI6KJHGNUzVJV/OpBQPrcXQkYylvhoM3XvWJI1/tiZ"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBlj6rlbIbhrnBIGBx7Kg5lCFcG5Kx7IdoCxCLpoSGF root@hypervisor"
          ];

          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          system.stateVersion = "24.05";

          boot.loader.grub.enable = false;
          fileSystems."/" = { device = "/dev/vdb"; fsType = "ext4"; };
        })
      ];
    };

    nixosModules.default = { pkgs, lib, ... }: {
      imports = [ comin.nixosModules.comin ];

      services.dbus.enable = true;

      # GitOps: Comin polls this repo and applies nixosConfigurations.<hostname>
      services.comin = {
        enable = true;
        remotes = [{
          name = "origin";
          url = "https://github.com/r33drichards/oclaw-nix-public.git";
          branches.main.name = "main";
          poller.period = 15;
        }];
      };

      # XFCE desktop + RDP for debugging
      services.xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
        displayManager.lightdm.enable = true;
      };
      services.xrdp = {
        enable = true;
        defaultWindowManager = "xfce4-session";
        openFirewall = false;
      };

      # OpenClaw gateway — public-info agent, no private credentials
      # Responds only to messages starting with "aldo" (enforced via agent instructions)
      users.users.openclaw = {
        isSystemUser = true;
        group = "openclaw";
        home = "/var/lib/openclaw";
        createHome = true;
        shell = pkgs.bash;
      };
      users.groups.openclaw = {};

      # Deploy workspace files (agent identity/soul docs) into openclaw home
      systemd.services.openclaw-workspace-init = {
        description = "Initialize OpenClaw workspace files (aldo agent)";
        wantedBy = [ "multi-user.target" ];
        before = [ "openclaw-gateway.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "openclaw";
        };
        script = ''
          mkdir -p /var/lib/openclaw/.openclaw/workspace
          cp -n ${./workspace/IDENTITY.md} /var/lib/openclaw/.openclaw/workspace/IDENTITY.md || true
          cp -n ${./workspace/SOUL.md} /var/lib/openclaw/.openclaw/workspace/SOUL.md || true
          cp -n ${./workspace/AGENTS.md} /var/lib/openclaw/.openclaw/workspace/AGENTS.md || true
          cp -n ${./workspace/BOOTSTRAP.md} /var/lib/openclaw/.openclaw/workspace/BOOTSTRAP.md || true
        '';
      };

      systemd.services.openclaw-gateway = {
        description = "OpenClaw gateway (public agent — aldo prefix)";
        after = [ "network.target" "openclaw-workspace-init.service" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          OPENCLAW_STATE_DIR = "/var/lib/openclaw/state";
          HOME = "/var/lib/openclaw";
          LITELLM_API_KEY = "dummy";
        };
        serviceConfig = {
          User = "openclaw";
          WorkingDirectory = "/var/lib/openclaw";
          ExecStartPre = pkgs.writeShellScript "openclaw-init" ''
            mkdir -p /var/lib/openclaw/state
          '';
          ExecStart = "${openclaw}/bin/openclaw gateway --port 18789";
          Restart = "always";
          RestartSec = "10s";
          StateDirectory = "openclaw";
        };
      };

      environment.systemPackages = with pkgs; [
        chromium
        git
        nodejs
        openclaw
      ];
    };
  };
}
