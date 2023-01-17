{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;

  inputs.astapkgs.url = github:Astavie/astapkgs;
  inputs.astapkgs.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, astapkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
    apkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ astapkgs.overlays.default ];
    };
  in {
    overlays.default = final: prev: let
      odin = (astapkgs.overlays.default final prev).odin;
    in {
      luanim_wasm = final.stdenv.mkDerivation {
        name = "luanim-wasm";
        buildInputs = [ odin final.lua5_4 final.pkg-config final.emscripten ];
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
      buildInputs = [ odin ols lua5_4 emscripten pkg-config php ];
      shellHook = ''
          export EM_CACHE=$(pwd)/.emcache
      '';
    };
  };
}
