/**
  * @name pkgs/brave/default.nix
  * @description Brave browser repackaged from the official GitHub release assets:
  * the .deb on Linux (x86_64, aarch64) and the .zip app bundle on aarch64 Darwin.
  * Adapted from the derivation nixpkgs removed (last present at NixOS/nixpkgs@9bb52223).
  * The pname must stay "brave": consumers' OpenSnitch rules match the "-brave-" store path.
  * Version and per-system hashes live in sources.json, rewritten by
  * .github/workflows/brave-update.yml, which opens a PR per new stable release.
  * Manual bump: set version, then each hash to its asset's sha256 from the release, in SRI form.
*/
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  unzip,
  buildPackages,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  qt6,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libdrm,
  libkrb5,
  libuuid,
  libxkbcommon,
  libxshmfence,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  snappy,
  udev,
  wayland,
  xdg-utils,
  coreutils,
  libxcb,
  zlib,
  libpulseaudio, # USB audio devices
  libGL, # GPU acceleration on Wayland
  libva, # VA-API video acceleration
}:
let
  pname = "brave";
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;

  releaseUrl = "https://github.com/brave/brave-browser/releases/download/v${version}";
  assetNames = {
    x86_64-linux = "brave-browser_${version}_amd64.deb";
    aarch64-linux = "brave-browser_${version}_arm64.deb";
    aarch64-darwin = "brave-v${version}-darwin-arm64.zip";
  };
  system = stdenv.hostPlatform.system;

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libx11
    libGL
    libxkbcommon
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxshmfence
    libxtst
    libuuid
    libgbm
    nspr
    nss
    pango
    pipewire
    udev
    wayland
    libxcb
    zlib
    snappy
    libkrb5
    qt6.qtbase
    libpulseaudio
    libva
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
  binpath = lib.makeBinPath deps;

  enableFeatures = [
    "AcceleratedVideoDecodeLinuxGL"
    "AcceleratedVideoEncoder"
  ];

  # OutdatedBuildDetector stays on: it flags a bump that never got merged.
  # UseChromeOSDirectVideoDecoder: VA-API breaks without it (brave/brave-browser#20935).
  disableFeatures = [ "UseChromeOSDirectVideoDecoder" ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "${releaseUrl}/${assetNames.${system}}";
    hash = sources.hashes.${system};
  };

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  doInstallCheck = stdenv.hostPlatform.isLinux;

  nativeBuildInputs =
    if stdenv.hostPlatform.isLinux then
      [
        dpkg
        # makeShellWrapper from buildPackages, since override drops splicing (NixOS/nixpkgs#132651).
        (buildPackages.wrapGAppsHook3.override { makeWrapper = buildPackages.makeShellWrapper; })
      ]
    else
      [
        unzip
        makeWrapper
      ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib # GSETTINGS_SCHEMAS_PATH
    gsettings-desktop-schemas
    gtk3
    gtk4
    adwaita-icon-theme # XDG_ICON_DIRS
  ];

  installPhase =
    if stdenv.hostPlatform.isDarwin then
      ''
        runHook preInstall

        mkdir -p $out/{Applications,bin}
        cp -r . "$out/Applications/Brave Browser.app"
        makeWrapper "$out/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" $out/bin/brave

        runHook postInstall
      ''
    else
      ''
        runHook preInstall

        mkdir -p $out $out/bin

        cp -R usr/share $out
        cp -R opt/ $out/opt

        export BINARYWRAPPER=$out/opt/brave.com/brave/brave-browser

        substituteInPlace $BINARYWRAPPER \
            --replace-fail /bin/bash ${stdenv.shell} \
            --replace-fail 'CHROME_WRAPPER' 'WRAPPER'

        ln -sf $BINARYWRAPPER $out/bin/brave

        for exe in $out/opt/brave.com/brave/{brave,chrome_crashpad_handler}; do
            patchelf \
                --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
                --set-rpath "${rpath}" $exe
        done

        substituteInPlace $out/share/applications/{brave-browser,com.brave.Browser}.desktop \
            --replace-fail /usr/bin/brave-browser-stable $out/bin/brave
        substituteInPlace $out/share/gnome-control-center/default-apps/brave-browser.xml \
            --replace-fail /opt/brave.com $out/opt/brave.com
        substituteInPlace $out/opt/brave.com/brave/default-app-block \
            --replace-fail /opt/brave.com $out/opt/brave.com

        for size in 16 24 32 48 64 128 256; do
            mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
            ln -s $out/opt/brave.com/brave/product_logo_$size.png \
                $out/share/icons/hicolor/''${size}x''${size}/apps/brave-browser.png
        done

        ln -sf ${xdg-utils}/bin/xdg-settings $out/opt/brave.com/brave/xdg-settings
        ln -sf ${xdg-utils}/bin/xdg-mime $out/opt/brave.com/brave/xdg-mime

        runHook postInstall
      '';

  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${rpath}
      --prefix PATH : ${binpath}
      --suffix PATH : ${
        lib.makeBinPath [
          xdg-utils
          coreutils
        ]
      }
      --set CHROME_WRAPPER ${pname}
      --add-flags "--enable-features=${lib.concatStringsSep "," enableFeatures}\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+,WaylandWindowDecorations --enable-wayland-ime=true}}"
      --add-flags "--disable-features=${lib.concatStringsSep "," disableFeatures}"
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
    )
  '';

  # Calls the ELF directly: the upstream shell wrapper swallows errors.
  installCheckPhase = ''
    $out/opt/brave.com/brave/brave --version
  '';

  meta = {
    homepage = "https://brave.com/";
    description = "Privacy-oriented browser for Desktop and Laptop computers";
    changelog =
      "https://github.com/brave/brave-browser/blob/master/CHANGELOG_DESKTOP.md#"
      + lib.replaceStrings [ "." ] [ "" ] version;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.mpl20;
    platforms = builtins.attrNames assetNames;
    mainProgram = "brave";
  };
}
