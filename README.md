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

### Use packages directly

Access packages via the flake output:

```nix
environment.systemPackages = [
  shini4i-pkgs.packages.${system}.kubeseal-auto
];
```

### Try without installing

```bash
nix run github:shini4i/nixpkgs#kubeseal-auto
```

## Available Packages

| Package | Description |
|---------|-------------|
| `argo-compare` | Comparison tool for ArgoCD Application manifests between Git branches |
| `asd-brightness-daemon` | D-Bus daemon for Apple Studio Display brightness control via USB HID |
| `gnome-shell-extension-apple-studio-display` | GNOME Shell extension for Apple Studio Display brightness control |
| `gnome-shell-extension-elgato-lights` | GNOME Shell extension for controlling Elgato Key Lights |
| `kd` | A bash script that decodes Kubernetes secrets |
| `kubeseal-auto` | An interactive wrapper for kubeseal binary |
| `openfortivpn-gui` | GTK4/libadwaita GUI client for Fortinet SSL VPN |

## Available Modules

NixOS modules for service configuration. Import via `nixosModules.<name>`.

| Module | Description |
|--------|-------------|
| `apple-studio-display` | Apple Studio Display brightness control with systemd service and udev rules |
| `openfortivpn-gui` | OpenFortiVPN GUI with optional privileged helper daemon |

### Example: Apple Studio Display

```nix
{ inputs, ... }: {
  imports = [ inputs.shini4i-pkgs.nixosModules.apple-studio-display ];

  programs.apple-studio-display.enable = true;
}
```

### Example: OpenFortiVPN GUI

```nix
{ inputs, ... }: {
  imports = [ inputs.shini4i-pkgs.nixosModules.openfortivpn-gui ];

  programs.openfortivpn-gui = {
    enable = true;
    helper.enable = true;  # Optional privileged helper
  };

  users.users.youruser.extraGroups = [ "openfortivpn-gui" ];
}
```

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
   { pkgs, p2nix }:
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
