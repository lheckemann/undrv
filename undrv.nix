{ top, lib, depsDir, drvsJSON }:
let
  raw = builtins.fromJSON (builtins.readFile drvsJSON);
  restoredDrvs = lib.mapAttrs (drvPath: drvData: drv drvPath) raw;
  drv = drvPath: let
    drvData = raw.${drvPath};

    # Attrset mapping contextless store path strings to the same
    # string but with the context of that path
    inputSrcs = lib.genAttrs drvData.inputSrcs (storepath: let
      match = builtins.match "/nix/store/([a-z0-9]+)-(.*)" storepath;
      hash = builtins.elemAt match 0;
      name = builtins.elemAt match 1;
    in "${depsDir + "/${hash}/${name}"}");

    inputSrcValues = map (name: inputSrcs.${name}) drvData.inputSrcs;

    # Attrset mapping input drv paths to lists of output paths (with context)
    inputDrvOutputs = lib.mapAttrs
      (inputDrvPath: outputNames:
        let
          inputDrv = restoredDrvs.${inputDrvPath};
        in
          map (outputName: inputDrv.${outputName}.outPath) outputNames
      )
      drvData.inputDrvs;

    inputDrvOutputList = lib.concatLists (lib.attrValues inputDrvOutputs);

    restoreReferences = str:
      (builtins.replaceStrings inputDrvOutputList inputDrvOutputList
        (builtins.replaceStrings inputSrcValues inputSrcValues str));

    env = lib.mapAttrs (key: value: restoreReferences value) drvData.env;

    result = assert builtins.match ".*libcxxabi-static.*" drvPath == null; derivation (env // {
      inherit (drvData) system;
      name = builtins.elemAt (builtins.match "/nix/store/[a-z0-9]+-(.*)\.drv" drvPath) 0;
      builder = restoreReferences drvData.builder;
      args = map restoreReferences drvData.args;
    } // lib.optionalAttrs (drvData.env ? outputs) {
      # using drvData.outputs here discards order. Eugh.
      outputs = lib.splitString " " drvData.env.outputs;
    });
  in
    result;
in
restoredDrvs.${top}
