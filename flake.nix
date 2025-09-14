{
  description = "A flake for building the aoc2025 Elixir project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Use an Erlang that exists in this nixpkgs
    beam = pkgs.beam.packages.erlang_27;
    elixir = beam.elixir_1_17;

    vscode = (
      pkgs.vscode-with-extensions.override {
        vscodeExtensions =
          with pkgs.vscode-extensions;
          [
            bbenoist.nix
            jnoortheen.nix-ide
            elixir-lsp.vscode-elixir-ls
            phoenixframework.phoenix
            eamodio.gitlens
            editorconfig.editorconfig
            saoudrizwan.claude-dev
          ]
          ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [ ];
      }
    );

    # Include working tree (tracked + untracked) for local iteration,
    # and drop build artifacts so they don't pollute the derivation.
    rawSrc = builtins.path { path = ./.; name = "aoc2025-src"; };
    src = builtins.path { path = ./.; name = "aoc2025-src"; };

    # ---- CERT & MIX ENV FIX ----
    # OTP 27's public_key tries OS certs; tell it exactly where.
    # Hex also respects HEX_CACERTS_PATH. Many tools on Nix respect NIX_SSL_CERT_FILE.
    mixEnv = ''
      export LC_ALL=C.UTF-8
      export MIX_XDG=1
      export HOME="$TMPDIR"
      export MIX_HOME="$TMPDIR/.mix"
      export HEX_HOME="$TMPDIR/.hex"
      mkdir -p "$MIX_HOME/archives" "$HEX_HOME"

      # CA locations (belt-and-suspenders for Erlang/Hex/httpc/curl-like tools)
      export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export SSL_CERT_DIR=${pkgs.cacert}/etc/ssl/certs
      export HEX_CACERTS_PATH=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      # ERL_SSL_PATH is sometimes consulted; keep it too
      export ERL_SSL_PATH=${pkgs.cacert}/etc/ssl/certs

      export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export ELIXIR_ERL_OPTIONS="+fnu"
    '';

    listTree = ''
      echo "===== TREE SNAPSHOT ====="
      (find . -maxdepth 2 -type f | sort) || true
      echo "========================="
    '';
  in
  {
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
        export MIX_ENV=dev
        ${mixEnv}
        # harmless when no deps
        mix local.hex --force || true
        mix local.rebar --force || true
        mix deps.get || true
      '';
    };

    packages.${system} = {
      default = self.packages.${system}.aoc2025;

      aoc2025 = pkgs.stdenv.mkDerivation {
        pname = "aoc2025";
        version = "0.0.1";
        inherit src;

        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
          pkgs.cacert
        ];

        buildPhase = ''
          set -euo pipefail
          ${listTree}
          export MIX_ENV=prod
          ${mixEnv}
          mix local.hex --force
          mix local.rebar --force
          mix deps.get || true
          mix compile --no-protocol-consolidation --no-deps-check
        '';

        installPhase = ''
          mkdir -p $out/_build
          cp -r _build/* $out/_build/ || true
        '';

        dontFixup = true;
      };
    };

    checks.${system} = {
      aoc2025-test = pkgs.stdenv.mkDerivation {
        name = "mix-test";
        inherit src;
        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
          pkgs.cacert
        ];
        buildPhase = ''
          set -euo pipefail
          ${listTree}
          export MIX_ENV=test
          ${mixEnv}
          mix --version
          elixir --version
          mix local.hex --force
          mix local.rebar --force
          mix deps.get || true
          echo "Compiling…"
          mix compile --no-protocol-consolidation --no-deps-check
          echo "Running tests…"
          mix test --color --slowest 10 --no-deps-check --trace
        '';
        installPhase = "mkdir -p $out && touch $out/done";
      };

      aoc2025-format = pkgs.stdenv.mkDerivation {
        name = "mix-format-check";
        inherit src;
        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
          pkgs.cacert
        ];
        buildPhase = ''
          set -euo pipefail
          ${listTree}
          export MIX_ENV=dev
          ${mixEnv}
          mix format --check-formatted "lib/**/*.{ex,exs}" "mix.exs"
        '';
        installPhase = "mkdir -p $out && touch $out/done";
      };
    };
  };
}
