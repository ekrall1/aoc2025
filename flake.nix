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
      config = {
        allowUnfree = true;
      };
    };

    beam = pkgs.beam.packages.erlang_27;
    elixir = beam.elixir_1_17;

    vscode = (
      pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          bbenoist.nix
          jnoortheen.nix-ide
          elixir-lsp.vscode-elixir-ls
          phoenixframework.phoenix
          eamodio.gitlens
          editorconfig.editorconfig
        ];
      }
    );
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
      ];

      shellHook = ''
        echo "Entering Elixir dev shell (Erlang: ${beam.erlang.version}, Elixir: ${elixir.version})"
        export MIX_ENV=dev
        mix local.hex --force
        mix local.rebar --force
        mix deps.get
      '';
    };

    packages.${system} = {
      default = self.packages.${system}.aoc2025;

      aoc2025 = pkgs.stdenv.mkDerivation rec {
        pname = "aoc2025";
        version = "0.0.1";
        src = ./.;

        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
        ];

        unpackPhase = "true";

        buildPhase = ''
          export MIX_ENV=prod
          mix local.hex --force
          mix local.rebar --force
          mix deps.get --only prod
          mix compile
          mix escript.build
        '';

        installPhase = ''
          mkdir -p $out/_build
          cp -r _build/* $out/_build/
          mkdir -p $out/bin
          cp ./aoc2025 $out/bin/aoc2025
        '';

        dontFixup = true;
      };
    };

    checks.${system} = {
      aoc2025-test = pkgs.stdenv.mkDerivation {
        name = "mix-test";
        src = ./.;
        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
        ];
        unpackPhase = "true";
        buildPhase = ''
          export MIX_ENV=test
          mix local.hex --force
          mix local.rebar --force
          mix deps.get --only test
          mix compile
          echo "running mix test"
          mix test --color --slowest 10
        '';
        installPhase = "mkdir -p $out && touch $out/done";
      };

      aoc2025-format = pkgs.stdenv.mkDerivation {
        name = "mix-format-check";
        src = ./.;
        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
        ];
        unpackPhase = "true";
        buildPhase = ''
          export MIX_ENV=dev
          mix local.hex --force
          mix local.rebar --force
          mix deps.get
          mix format --check-formatted
        '';
        installPhase = "mkdir -p $out && touch $out/done";
      };

      aoc2025-credo = pkgs.stdenv.mkDerivation {
        name = "mix-credo-check";
        src = ./.;
        nativeBuildInputs = [
          beam.erlang
          elixir
          beam.rebar3
        ];
        unpackPhase = "true";
        buildPhase = ''
          export MIX_ENV=dev
          mix local.hex --force
          mix local.rebar --force
          mix deps.get
          echo "running mix credo --strict"
          mix credo --strict
        '';
        installPhase = "mkdir -p $out && touch $out/done";
      };
    };
  };
}
