{
  description = "A flake for building and testing the aoc2025 Elixir project";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

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

    src = ./.;

    mixEnv = ''
      export LC_ALL=C.UTF-8
      export HOME="$TMPDIR"
      export MIX_XDG=1
      export MIX_HOME="$TMPDIR/.mix"
      export HEX_HOME="$TMPDIR/.hex"
      mkdir -p "$MIX_HOME/archives" "$HEX_HOME"

      export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export SSL_CERT_DIR=${pkgs.cacert}/etc/ssl/certs
      export HEX_CACERTS_PATH=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export ERL_SSL_PATH=${pkgs.cacert}/etc/ssl/certs

      # avoid OTP name-encoding warning
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
      '';
    };

    # ---------- DEFAULT PACKAGE (builds escript -> $out/bin/aoc2025) ----------
packages.${system}.default = pkgs.stdenv.mkDerivation {
  name = "aoc2025";
  inherit src;
  nativeBuildInputs = [ beam.erlang elixir beam.rebar3 pkgs.cacert ];
  phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];

  buildPhase = ''
    set -euo pipefail
    ${listTree}
    export MIX_ENV=prod
    ${mixEnv}

    # Clean & compile first (no deps/network assumed)
    mix clean
    mix compile --no-deps-check --no-archives-check

    # Ensure the CLI module is on the code path when escript.build runs
    ERL_AFLAGS=""
    while IFS= read -r -d "" ebin; do
      ERL_AFLAGS="$ERL_AFLAGS -pa $ebin"
    done < <(find _build/prod/lib -type d -name ebin -print0 || true)
    export ERL_AFLAGS

    # Build the escript
    mix escript.build --no-deps-check --no-archives-check
  '';

  installPhase = ''
    set -euo pipefail
    mkdir -p $out/bin
    install -Dm755 ./aoc2025 $out/bin/aoc2025
  '';
};

    # ---------- CHECKS (doctests working under Nix) ----------
    checks.${system}.aoc2025-test = pkgs.stdenv.mkDerivation {
      name = "aoc2025-test";
      inherit src;
      nativeBuildInputs = [ beam.erlang elixir beam.rebar3 pkgs.cacert ];
      phases = [ "unpackPhase" "patchPhase" "checkPhase" "installPhase" ];

      checkPhase = ''
        set -euo pipefail
        ${listTree}
        export MIX_ENV=test
        ${mixEnv}

        # 1) Clean & compile app for :test (no deps/network)
        mix clean
        mix compile --no-deps-check --no-archives-check

        # 2) Put compiled EBINs on BEAM path BEFORE doctest expands
        ERL_AFLAGS=""
        while IFS= read -r -d "" ebin; do
          ERL_AFLAGS="$ERL_AFLAGS -pa $ebin"
        done < <(find _build/test/lib -type d -name ebin -print0 || true)
        export ERL_AFLAGS

        # 3) Run tests without recompiling
        mix test --no-compile --no-deps-check --no-archives-check --color --slowest 10 --trace
      '';

      installPhase = "mkdir -p $out && echo ok > $out/done";
    };
  };
}
