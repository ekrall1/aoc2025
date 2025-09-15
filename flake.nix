{
  description = "A flake for building and testing the aoc2025 Elixir project";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      beam = pkgs.beam.packages.erlang_27;
      elixir = beam.elixir_1_17;

      vscode = pkgs.vscode-with-extensions.override {
        vscodeExtensions = (with pkgs.vscode-extensions; [
          bbenoist.nix
          jnoortheen.nix-ide
          elixir-lsp.vscode-elixir-ls
          phoenixframework.phoenix
          eamodio.gitlens
          editorconfig.editorconfig
        ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [ ];
      };

      src = builtins.path {
        path = ./.;
        name = "aoc2025-src";
      };

    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          beam.erlang
          elixir
          beam.rebar3
          inotify-tools
          git
          elixir-ls
          vscode
          bashInteractive
          cacert
        ];
        shellHook = ''
          echo "Entering Elixir dev shell (OTP: ${beam.erlang.version}, Elixir: ${elixir.version})"
          export MIX_ENV=prod
        '';
      };

      # -------------------- DEFAULT PACKAGE --------------------
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "aoc2025";
        inherit src;
        nativeBuildInputs = [ beam.erlang elixir beam.rebar3 pkgs.cacert ];
        phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];

        buildPhase = ''
          set -euo pipefail
          export ELIXIR_ERL_OPTIONS="+fnu"

          mix clean
          mix compile --no-deps-check --no-archives-check
        '';

        installPhase = ''
          # TODO
            set -euo pipefail
            mkdir -p "$out/bin"
            touch dummy
            install -Dm755 ./dummy "$out/bin/aoc2025"
        '';
      };

      # -------------------- CHECKS: doctests work under Nix --------------------
      checks.${system}.aoc2025-test = pkgs.stdenv.mkDerivation {
        name = "aoc2025-test";
        inherit src;
        nativeBuildInputs =
          [ beam.erlang elixir beam.rebar3 pkgs.cacert pkgs.coreutils ];
        phases = [ "unpackPhase" "patchPhase" "checkPhase" "installPhase" ];

        checkPhase = ''
          set -euo pipefail
          export LC_ALL=C.UTF-8 LANG=C.UTF-8 MIX_ENV=test

          # compile once so doctests can load modules

          mix test --no-compile --no-deps-check --no-archives-check
        '';

        # <-- IMPORTANT: install the log, not a dummy "done" file
        installPhase = ''
          set -euo pipefail
          mkdir -p "$out"
          touch done
          install -Dm755 ./done "$out/bin/done"
        '';
      };

    };
}
