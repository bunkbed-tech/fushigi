{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkMerge [
    {
      # Defaults
      git-hooks.default_stages = ["pre-push" "manual"];
      git-hooks.hooks = {
        commitizen.enable = true;
        gitleaks = {
          enable = true;
          name = "gitleaks";
          description = "Gitleaks on entire project";
          entry = "${pkgs.gitleaks}/bin/gitleaks protect --redact";
        };
        lychee.enable = true;
        lychee.settings.configPath = builtins.toString ((pkgs.formats.toml {}).generate "lychee.toml" {
          exclude = ["localhost" "file://" "https://shadcn-svelte.com/registry" "http://192.168.11.5:8000" "http://backend:8000"];
        });
        markdownlint.enable = true;
        markdownlint.settings.configuration.MD013.line_length = -1;
        mdsh.enable = true;
        tagref.enable = true;
        typos.enable = true;
        typos.excludes = [".*grammar.json"];
        typos.settings.ignored-words = ["ratatui"];

        # pre-commit builtins
        check-added-large-files.enable = true;
        check-case-conflicts.enable = true;
        check-executables-have-shebangs.enable = true;
        check-merge-conflicts.enable = true;
        check-symlinks.enable = true;
        check-vcs-permalinks.enable = true;
        end-of-file-fixer.enable = true;
        fix-byte-order-marker.enable = true;
        forbid-new-submodules.enable = true;
        mixed-line-endings.enable = true;
        no-commit-to-branch.enable = true;
        no-commit-to-branch.settings.branch = ["main"];
        trim-trailing-whitespace.enable = true;
      };
    }
    {
      # Nix
      languages.nix.enable = true;
      git-hooks.hooks = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        statix.raw.args = [
          "--config"
          ((pkgs.formats.toml {}).generate "statix.toml" {
            disabled = [
              "unquoted_uri"
              "repeated_keys"
            ];
          })
        ];
      };
    }
    {
      # Pocketbase database + backend as a service
      languages.go.enable = true;
      processes.backend = {
        exec = "go run . serve --dev --http=0.0.0.0:8080";
        process-compose = {
          working_dir = "./pocketbase";
          readiness_probe = {
            http_get = {
              host = "127.0.0.1";
              port = 8080;
              path = "/api/health";
            };
            initial_delay_seconds = 5;
            period_seconds = 2;
            timeout_seconds = 5;
            success_threshold = 1;
            failure_threshold = 30;
          };
        };
      };
      git-hooks.hooks = {
        gofmt.enable = true;
        golangci-lint.enable = true;
        govet.enable = true;
      };
    }
    {
      # SvelteKit frontend
      git-hooks.hooks.biome.enable = true;
      processes.frontend.exec = let
        getIpCmd = pkg: "${pkg}/bin/ip route get 1 | ${pkgs.gnused}/bin/sed 's/^.*src \\([^ ]*\\).*$/\\1/;q'";
        pkg =
          if pkgs.stdenv.isLinux
          then pkgs.iproute2
          else if pkgs.stdenv.isDarwin
          then pkgs.iproute2mac
          else throw "${pkgs.stdenv.system} not supported";
      in ''
        export VITE_API_BASE="http://$(${getIpCmd pkg}):8080"
        bun --bun run dev --open
      '';
      processes.frontend.process-compose.working_dir = "./frontend";
      languages = {
        typescript.enable = true;
        javascript = {
          enable = true;
          directory = "./frontend";
          bun.enable = true;
          bun.install.enable = true;
        };
      };
    }
    {
      # TUI
      languages.rust.enable = true;
      git-hooks.hooks = {
        clippy.enable = true;
        rustfmt.enable = true;
      };
    }
    {
      # OCI
      git-hooks.hooks = {
        hadolint.enable = true;
        yamllint.enable = true;
      };
    }
    (lib.mkIf pkgs.stdenv.isDarwin {
      # SwiftUI app
      languages.swift.enable = true;
      packages = with pkgs; [
        swiftformat
        swiftlint
      ];
      git-hooks.hooks = {
        swiftlint = {
          enable = true;
          name = "SwiftLint";
          description = "Enforcing Swift style and conventions";
          files = "\\.swift$";
          entry = "${pkgs.swiftlint}/bin/swiftlint";
        };
        swiftformat = {
          enable = true;
          name = "SwiftFormat";
          description = "Formatting Swift code with conventional style";
          files = "\\.swift$";
          entry = "${pkgs.swiftformat}/bin/swiftformat";
        };
      };
      # Assume all Apple developers have XCode installed.
      # DEVELOPER_DIR env var must be set globally on macOS to run swiftlint
      # env = {
      #   DEVELOPER_DIR = lib.mkForce "/Applications/Xcode.app/Contents/Developer";
      # };
      enterShell = ''
        export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
      '';
    })
  ];
}
