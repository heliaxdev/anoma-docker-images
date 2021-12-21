{ pkgs ? import (anoma.inputs.nixpkgs or <nixpkgs>) { }
, lib ? pkgs.lib
, system ? pkgs.system
, anoma ? null # anoma flake
, anomaSrc ? null # anoma source (when not flake)
, cargoNix ? null # path to generated Cargo.nix (when not flake)
, ANOMA_CHAIN_ID ? ""
, ANOMA_FEATURES ? "default"
}:
let

  anomaPackages = if anoma ? outputs then anoma.outputs.packages.${system} else
  let
    src = pkgs.runCommand "src" {
      passAsFile = [ "anomaSrc" "cargoNix" ];
      inherit anomaSrc cargoNix;
    } ''
      cp -r -t "$out/" "${anomaSrc}"/*
      cat ${cargoNix} > $out/Cargo.nix
    '';
  in
  import "${src}/default.nix" (lib.optionalAttrs (ANOMA_FEATURES != "") { features = lib.splitString " " ANOMA_FEATURES; });

  joinNetworkScript = pkgs.writeShellScript "join-network" ''
    echo "Joining network '$ANOMA_CHAIN_ID'" >&2
    anomac utils join-network --chain-id=''${ANOMA_CHAIN_ID}
  '';

  entrypoint = pkgs.writeShellScriptBin "docker-entrypoint.sh" (builtins.readFile ./entrypoint.sh);
in
pkgs.dockerTools.streamLayeredImage {
  name = "heliaxdev/anoma";
  tag = anoma.rev or null;

  contents = [
    entrypoint
    pkgs.busybox
    pkgs.cacert
    anomaPackages.anoma
    anomaPackages.wasm
  ];

  extraCommands = ''
    mkdir docker-entrypoint.d
    cp -a ${joinNetworkScript} docker-entrypoint.d/20-join-network.sh

    # `anomac utils join-network` doesn't fully respect the base-dir setting
    ln -s /data .anoma
  '';

  config = {
    Entrypoint = "docker-entrypoint.sh";

    Cmd = [ "anoman" "ledger" "run" ];

    ExposedPorts = {
      "26656/tcp" = { }; # Ledger P2P
      "26657/tcp" = { }; # Ledger RPC
      "26659/tcp" = { }; # P2P intent gossip
      "26660/tcp" = { }; # RPC intent gossip
    };

    WorkingDir = "/";

    Env = [
      "ANOMA_CHAIN_ID=${ANOMA_CHAIN_ID}"
      "ANOMA_BASE_DIR=/data"
      "ANOMA_WASM_DIR=/wasm"
    ];
  };
}
