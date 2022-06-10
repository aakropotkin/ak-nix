# ak-nix
Various `nix` and NixOS extensions

# Outputs
## REPL Extensions
The output `ak-nix#repl` holds convenience functions for use in a Nix REPL.
The highlights are `ls` which behaves like your shell's `ls` command, `pwd`
which does exactly what you think, and `show` which uses `builtins.trace` to
print values or lists of values to the console.

```nix
nix-repl> :a ( builtins.getFlake "ak-nix" ).repl
nix-repl> pwd
/home/sally/src/ak-nix
nix-repl> ls "./*"
trace: 
./attrsets.nix
./debug.nix
./default.nix
./filesystem.nix
./json.nix
./lists.nix
./paths.nix
./repl.nix
./stdenv.nix
./strings.nix
true
nix-repl> show ["oh" "dip" ( it: "is" ) 420]
trace:
oh
dip
<LAMBDA>
420
true
```

# Lib
A set of extensions to `nixpkgs.lib`.
This is constructed using `nixpkgs.lib.extend`, so it can be used as an
alternate in existing expressions which already take `lib` as an argument.

The lib attribute contains `librepl` and is available as at the top-level, or
as a subdir flake:
```nix
nix-repl> lib = builtins.getFlake "github:aakropotkin/ak-nix?dir=lib"
nix-repl> :a lib.librepl
nix-repl> pwd
/home/sally/src/ak-nix
nix-repl> add = curryDefaultSystems' ( system:
                  { x, y }: builtins.trace system ( x + y ) )
nix-repl> add { x = 1; y = 2; }
{ __functor      = <lambda>;
  aarch64-darwin = 3; trace: aarch64-darwin
  aarch64-linux  = 3; trace: aarch64-linux
  i686-linux     = 3; trace: i686-linux
  x86_64-darwin  = 3; trace: x86_64-darwin
  x86_64-linux   = 3; trace: x86_64-linux
}
nix-repl> ( add { x = 2; y = 2; } ).x86_64-linux
3
nix-repl> ( add { x = 3; y = 2; } ) "x86_64-linux"
trace: x86_64-linux
5
nix-repl> add "x86_64-linux" { x = 4; y = 20; }
trace: x86_64-linux
24
```
