{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
    apkgs = import nixpkgs {
      system = "x86_64-linux";
    };
  in {
    overlays.default = final: prev: {
      luanim_wasm = final.stdenv.mkDerivation {
        name = "luanim-wasm";
        buildInputs = with final; [
          emscripten
          nodePackages.npm
        ];
        configurePhase = ''
          export EM_CACHE=$(pwd)/.emcache
        '';
        buildPhase = ''
          make wasm
        '';
        installPhase = ''
          mkdir -p $out/
          cp build/wasm/* $out/
        '';
        src = ./.;
      };
    };
    packages.x86_64-linux = rec {
      inherit (pkgs) luanim_wasm;
    };
    devShells.x86_64-linux.default = with apkgs; mkShell {
      buildInputs = [
        emscripten
        nodePackages.npm

        php
      ];
      shellHook = ''
          export EM_CACHE=$(pwd)/.emcache
      '';
    };
  };
}
