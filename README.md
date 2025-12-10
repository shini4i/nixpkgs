# Custom Nix Packages

A collection of custom Nix packages.

## Usage

Add this repository as a flake input in your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    shini4i-pkgs = {
      url = "github:shini4i/nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, shini4i-pkgs, ... }: {
    # ... your configuration
  };
}
```

### Option 1: Use packages directly

Access packages via the flake output:

```nix
environment.systemPackages = [
  shini4i-pkgs.packages.x86_64-linux.kubeseal-auto
];
```

### Option 2: Use as an overlay in NixOS

```nix
nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    {
      nixpkgs.overlays = [ shini4i-pkgs.overlays.default ];
    }
    ./configuration.nix
  ];
};
```

Then in `configuration.nix`:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kubeseal-auto ];
}
```

### Option 3: Use as an overlay in Home Manager

```nix
homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    overlays = [ shini4i-pkgs.overlays.default ];
  };
  modules = [ ./home.nix ];
};
```

Then in `home.nix`:

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.kubeseal-auto ];
}
```

### Option 4: Try without installing

```bash
nix run github:shini4i/nixpkgs#kubeseal-auto
```

## Available Packages

| Package | Description |
|---------|-------------|
| `kd` | A bash script that decodes Kubernetes secrets |
| `kubeseal-auto` | An interactive wrapper for kubeseal binary |

## Adding New Packages

1. Create a new directory under `pkgs/`:
   ```
   pkgs/
   └── my-package/
       └── default.nix
   ```

2. Write your package derivation in `pkgs/my-package/default.nix`:
   ```nix
   { lib, stdenv, fetchurl }:

   stdenv.mkDerivation rec {
     pname = "my-package";
     version = "1.0.0";

     src = fetchurl {
       url = "https://example.com/my-package-${version}.tar.gz";
       hash = "sha256-...";
     };

     meta = with lib; {
       description = "My package description";
       homepage = "https://example.com";
       license = licenses.mit;
       maintainers = [ ];
       platforms = platforms.all;
     };
   }
   ```

3. Add it to `pkgs/default.nix`:
   ```nix
   { pkgs }:
   {
     my-package = pkgs.callPackage ./my-package { };
   }
   ```

4. Test locally:
   ```bash
   nix build .#my-package
   nix flake check
   ```

## Development

```bash
# Build a specific package
nix build .#kd

# Build all packages
nix flake check

# Update flake inputs
nix flake update
```

## License

Each package may have its own license. See individual package definitions for details.
