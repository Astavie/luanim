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
      onimate_desktop = final.stdenv.mkDerivation {
        name = "onimate-desktop";
	buildInputs = [ odin final.lua5_4 ];
        buildPhase = ''
	  make desktop
	'';
	installPhase = ''
	  mkdir -p $out/bin
          cp onimate $out/bin/onimate-desktop
	'';
	src = ./.;
      };
      onimate_wasm = final.stdenv.mkDerivation {
        name = "onimate-wasm";
	buildInputs = [ odin final.emscripten ];
	configurePhase = ''
	  export EM_CACHE=$(pwd)/.emcache
	'';
        buildPhase = ''
	  make wasm
	'';
	installPhase = ''
	  mkdir -p $out/lib
          cp -r build/wasm $out/lib
	'';
	src = ./.;
      };
    };
    packages.x86_64-linux = rec {
      inherit (pkgs) onimate_desktop onimate_wasm;
      default = onimate_desktop;
    };
  };
}
