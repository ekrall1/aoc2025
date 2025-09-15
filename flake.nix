{
  description = "A flake for building and testing the aoc2025 Elixir project";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      beam = pkgs.beam.packages.erlang_27;
      elixir = beam.elixir_1_17;

      vscode = pkgs.vscode-with-extensions.override {
        vscodeExtensions =
          (with pkgs.vscode-extensions; [
            bbenoist.nix
            jnoortheen.nix-ide
            elixir-lsp.vscode-elixir-ls
            phoenixframework.phoenix
            eamodio.gitlens
            editorconfig.editorconfig
          ])
          ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [ ];
      };

      srcIncl = ./.;

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          beam.erlang
          beam.rebar3
          elixir
          hex
          inotify-tools
          git
          elixir-ls
          vscode
          bashInteractive
          cacert
          mix2nix
        ];
        shellHook = ''
          echo "Entering Elixir dev shell (OTP: ${beam.erlang.version}, Elixir: ${elixir.version})"
          export MIX_ENV=prod
        '';
      };

      # -------------------- DEFAULT PACKAGE --------------------
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "aoc2025";
        src = srcIncl;
        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
          pkgs.cacert
        ];
        phases = [
          "unpackPhase"
          "patchPhase"
          "buildPhase"
          "installPhase"
        ];

        buildPhase = ''
          set -euo pipefail
          export ELIXIR_ERL_OPTIONS="+fnu"

          mix clean
          mix compile --no-deps-check --no-archives-check
          mix escript.build --no-deps-check --no-archives-check
        '';

        installPhase = ''
            set -euo pipefail
            mkdir -p "$out/bin"
            install -Dm755 ./aoc2025 "$out/bin/aoc2025"
        '';
      };

      # -------------------- CHECKS: doctests work under Nix --------------------
      checks.${system}.aoc2025-test = beam.buildMix rec {
        name = "aoc2025-test";
        version = "0.1.0";
        src = srcIncl;

        doCheck = true;
        checkPhase = ''
          set -eu
          export HOME="$TMPDIR"
          export MIX_ENV=test

          echo "=== Compiling ==="
          mix compile

          echo "=== Running tests ==="
          mix test --color
        '';
        installPhase = ''
          mkdir -p "$out"
          echo ok > "$out/result"
        '';
      };

    };
}
