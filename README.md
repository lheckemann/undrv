# undrv

This is a tool that can generate the necessary bits and bobs for
evaluating a drv in Nix -- from already-instantiated drvs in your
store!

Status: it works, but only if `toFile` isn't used in the original
expressions.

## Sample usage

```
$ drv=$(nix-instantiate '<nixpkgs>' -A bash | tee /dev/stderr)
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
/nix/store/1zqjwafvqbdj5l0ahb35bq4lmbxq54hv-bash-5.1-p16.drv

$ bash undrv.sh "$drv"
warning: The interpretation of store paths arguments ending in `.drv` recently changed. If this command is now failing try again with '/nix/store/1zqjwafvqbdj5l0ahb35bq4lmbxq54hv-bash-5.1-p16.drv!*'
Wrote output to undrv-output. Checking if it evaluates to the originally given drv...

$ nix-instantiate undrv-output/default.nix
/nix/store/1zqjwafvqbdj5l0ahb35bq4lmbxq54hv-bash-5.1-p16.drv

$ du -hd0 --apparent-size undrv-output $(nix-instantiate --find-file nixpkgs)/
warning: unknown setting 'structured-drv-logs'
856K    undrv-output
119M    /var/lib/nixpkgs/

$ du -hd0 undrv-output $(nix-instantiate --find-file nixpkgs)/
warning: unknown setting 'structured-drv-logs'
1.1M    undrv-output
210M    /var/lib/nixpkgs/

$ # Wow! It's more than 100x smaller!
```
