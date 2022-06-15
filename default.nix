{pkgs  ? import <nixpkgs> {}}:
  pkgs.haskellPackages.callPackage ./chat.nix {}
