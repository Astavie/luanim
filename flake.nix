{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;

  inputs.astapkgs.url = github:Astavie/astapkgs;
  inputs.astapkgs.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, astapkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
  in {
    overlays.default = final: prev: let
      odin = (astapkgs.overlays.default final prev).odin;
    in {
      luanim_desktop = final.stdenv.mkDerivation {
        name = "luanim-desktop";
	buildInputs = [ odin final.lua5_4 ];
        buildPhase = ''
	  make desktop
	'';
	installPhase = ''
	  mkdir -p $out/bin
          cp luanim $out/bin/luanim-desktop
	'';
	src = ./.;
      };
      luanim_wasm = final.stdenv.mkDerivation {
        name = "luanim-wasm";
	buildInputs = [ final.emscripten ];
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
      inherit (pkgs) luanim_desktop luanim_wasm;
      default = luanim_desktop;
    };
  };
}
