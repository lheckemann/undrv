# undrv

This is a tool that can generate the necessary bits and bobs for
evaluating a drv in Nix -- from already-instantiated drvs in your
store!

Status: it works, but only if any uses of `toFile` in the original
expressions don't write strings with references to the file.

## Sample usage

```
$ drv=$(nix-instantiate "<nixpkgs>" -A firefox | tee /dev/stderr)
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
/nix/store/rkzxfbm7zabvij245qbcsr203ngkccaq-firefox-110.0.1.drv

$ bash undrv.sh "$drv"
Wrote output to undrv-output. Checking if it evaluates to the originally given drv...

$ nix-instantiate undrv-output/default.nix
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
/nix/store/rkzxfbm7zabvij245qbcsr203ngkccaq-firefox-110.0.1.drv

$ du -hd0 --apparent-size undrv-output $(nix-instantiate --find-file nixpkgs)/
9.7M    undrv-output
119M    /var/lib/nixpkgs/

$ du -hd0 undrv-output $(nix-instantiate --find-file nixpkgs)/
11M     undrv-output
210M    /var/lib/nixpkgs/

$ # Wow! It's ~10x smaller!
```
