{
  description = "A flake for building the aoc2025 Elixir project";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    beam   = pkgs.beam.packages.erlang_27;
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
          saoudrizwan.claude-dev
        ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [ ];
    };

    # Use the repo state as-is (you said lib/ is committed)
    src = ./.;

    # Common env for mix tasks in derivations
    mixEnv = ''
      export LC_ALL=C.UTF-8
      export HOME="$TMPDIR"
      export MIX_XDG=1
      export MIX_HOME="$TMPDIR/.mix"
      export HEX_HOME="$TMPDIR/.hex"
      mkdir -p "$MIX_HOME/archives" "$HEX_HOME"

      # CA bundle (harmless even when offline)
      export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export SSL_CERT_DIR=${pkgs.cacert}/etc/ssl/certs
      export HEX_CACERTS_PATH=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export ERL_SSL_PATH=${pkgs.cacert}/etc/ssl/certs

      # Avoid name-encoding warning from OTP
      export ELIXIR_ERL_OPTIONS="+fnu"
    '';

    listTree = ''
      echo "===== TREE SNAPSHOT ====="
      (find . -maxdepth 3 -type f | sort) || true
      echo "--- lib/ ---"
      (find lib -maxdepth 5 -type f | sort) 2>/dev/null || true
      echo "--- tests/ ---"
      (find tests -maxdepth 5 -type f | sort) 2>/dev/null || true
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
        # You can keep these commented unless you add deps:
        # mix local.hex --force || true
        # mix local.rebar --force || true
        # mix deps.get || true
      '';
    };

    checks.${system} = {
      aoc2025-test = pkgs.stdenv.mkDerivation {
        name = "aoc2025-test";
        pname = "aoc2025-test";
        inherit src;

        nativeBuildInputs = [ beam.erlang elixir beam.rebar3 pkgs.cacert ];

        # Only run the phases we need; put everything in checkPhase
        phases = [ "unpackPhase" "patchPhase" "checkPhase" "installPhase" ];

        checkPhase = ''
          set -euo pipefail
          ${listTree}
          export MIX_ENV=test
          ${mixEnv}

          # 1) Clean, then compile the app for :test (no deps/network)
          mix clean
          mix compile --no-deps-check

          # 2) Put compiled EBINs on the Erlang code path BEFORE test files are compiled
          ERL_AFLAGS=""
          while IFS= read -r -d "" ebin; do
            ERL_AFLAGS="$ERL_AFLAGS -pa $ebin"
          done < <(find _build/test/lib -type d -name ebin -print0 || true)
          export ERL_AFLAGS

          # 3) Run tests WITHOUT compiling again, so doctest expands with modules already on path
          mix test --no-compile --no-deps-check --color --slowest 10 --trace
        '';

        installPhase = "mkdir -p $out && echo ok > $out/done";
      };
    };
  };
}
