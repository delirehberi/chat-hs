{pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/4c2e84394c0f372c019e941e95d6fbe21835719b.tar.gz") {}, mkDerivation,stdenv,base,text, bytestring,cabal-install,lib, websockets}:
let
  inherit (pkgs) callPackage fetchFromGitHub;
  easy-hls-src = fetchFromGitHub {
    owner  = "jkachmar";
    repo   = "easy-hls-nix";
    rev    = "ecb85ab6ba0aab0531fff32786dfc51feea19370";
    sha256 = "14v0jx8ik40vpkcq1af1b3377rhkh95f4v2cl83bbzpna9aq6hn2";
  };
  easy-hls =  callPackage easy-hls-src {
        ghcVersions = [ "9.0.2" ];
  };
in 

mkDerivation {
  pname = "chat7cups";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    base text bytestring websockets
  ];
  extraLibraries = [easy-hls cabal-install];
  homepage = "https://7cups.com";
  description = "";
  license = with lib.licenses; [gpl3Plus];
}
