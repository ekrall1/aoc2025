{
  description = "A flake for building the aoc2025 Elixir project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      beam = pkgs.beam.packages.erlang_26;
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
            ++
              pkgs.vscode-utils.extensionsFromVscodeMarketplace
                [
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
          bashInteractive
          cacert
        ];

        shellHook = ''
          echo "Entering Elixir dev shell (Erlang: ${beam.erlang.version}, Elixir: ${elixir.version})"
          export MIX_ENV=dev
          export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
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
            beam.hex
            pkgs.cacert
          ];

          buildPhase = ''
            export MIX_ENV=prod
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            export ERL_SSL_PATH=${pkgs.cacert}/etc/ssl/certs
            export ELIXIR_ERL_OPTIONS="+fnu"
            
            # Set up home directory for Mix
            export HOME=$TMPDIR
            mkdir -p $HOME/.mix/archives
            
            # Install hex and rebar with proper SSL configuration
            mix local.hex --force
            mix local.rebar --force
            
            # Get dependencies (even though there are none, this ensures proper setup)
            mix deps.get
            
            # Compile only (skip escript build to avoid protocol consolidation issues)
            mix compile --no-protocol-consolidation
          '';

          installPhase = ''
            mkdir -p $out/_build
            cp -r _build/* $out/_build/
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
            pkgs.cacert
          ];
          buildPhase = ''
            export MIX_ENV=test
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            export ERL_SSL_PATH=${pkgs.cacert}/etc/ssl/certs
            export ELIXIR_ERL_OPTIONS="+fnu"
            
            # Set up home directory for Mix
            export HOME=$TMPDIR
            mkdir -p $HOME/.mix/archives
            
            # Skip hex entirely and compile directly
            echo "Compiling project without hex..."
            mix compile --no-protocol-consolidation --no-deps-check
            echo "Compilation complete. Running tests..."
            mix test --no-deps-check
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
            beam.hex
            pkgs.cacert
          ];
          buildPhase = ''
            export MIX_ENV=dev
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            export ERL_SSL_PATH=${pkgs.cacert}/etc/ssl/certs
            export ELIXIR_ERL_OPTIONS="+fnu"
            
            # Skip network operations - use pre-installed hex and rebar
            export HEX_OFFLINE=1
            export MIX_XDG=1
            
            # Create mix directories
            mkdir -p .mix/archives
            
            # Try to run format check without installing hex/rebar
            # Specify the files directly since .formatter.exs might not be found
            mix format --check-formatted "lib/**/*.{ex,exs}" "mix.exs"
          '';
          installPhase = "mkdir -p $out && touch $out/done";
        };
      };
    };
}
