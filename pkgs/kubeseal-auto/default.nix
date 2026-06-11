# kubeseal-auto - an interactive wrapper for kubeseal binary
# Built from uv.lock with uv2nix (the project migrated from poetry to uv in v0.7.1).
{
  lib,
  callPackage,
  runCommand,
  makeWrapper,
  fetchFromGitHub,
  kubeseal,
  kubectl,
  python312,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:

let
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "kubeseal-auto";
    rev = "v${version}";
    hash = "sha256-9/+k1FD9QDvX+/+HpKW9ppbOfZzti7ihwt7eeOORZfk=";
  };

  # Load the uv workspace from uv.lock and build a pyproject.nix overlay.
  # sourcePreference = "wheel" pulls prebuilt wheels, so none of the pure-Python
  # dependencies need compilation or build overrides.
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  python = python312;

  # Compose the Python package set: build-system bootstrap + the workspace overlay.
  pythonSet = (callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      overlay
    ]
  );

  venv = pythonSet.mkVirtualEnv "kubeseal-auto-env" workspace.deps.default;
in
# kubeseal and kubectl are required at runtime; wrap them onto PATH.
runCommand "kubeseal-auto-${version}"
  {
    nativeBuildInputs = [ makeWrapper ];

    meta = with lib; {
      description = "An interactive wrapper for kubeseal binary";
      longDescription = ''
        kubeseal-auto is a CLI tool that simplifies the process of creating
        sealed secrets for Kubernetes. It provides an interactive interface
        to encrypt secrets using kubeseal.
      '';
      homepage = "https://github.com/shini4i/kubeseal-auto";
      license = licenses.mit;
      maintainers = [ ];
      mainProgram = "kubeseal-auto";
    };
  }
  ''
    # Smoke-check that the uv2nix-built venv imports and the entrypoint runs.
    # The upstream suite is redundant here: the source is a pinned tag already
    # tested in CI, and uv2nix builds the identical locked deps.
    ${venv}/bin/kubeseal-auto --version

    mkdir -p $out/bin
    makeWrapper ${venv}/bin/kubeseal-auto $out/bin/kubeseal-auto \
      --prefix PATH : ${lib.makeBinPath [ kubeseal kubectl ]}
  ''
