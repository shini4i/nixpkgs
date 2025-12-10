# kubeseal-auto - an interactive wrapper for kubeseal binary
# Uses buildPythonApplication with poetry-core for building from GitHub source.
{
  lib,
  python313,
  fetchFromGitHub,
  kubeseal,
}:

let
  python = python313;
in
python.pkgs.buildPythonApplication rec {
  pname = "kubeseal-auto";
  version = "v0.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "kubeseal-auto";
    rev = "v0.7.0";
    hash = "sha256-hqtUgh5jRX821j9PyhXoPCWzcdfQm/fYGYY75Ve/hb4=";
  };

  build-system = [ python.pkgs.poetry-core ];

  dependencies = with python.pkgs; [
    pyyaml
    requests
    kubernetes
    click
    icecream
    questionary
    rich
  ];

  # Relax click version constraint for nixpkgs compatibility
  pythonRelaxDeps = [ "click" ];

  # kubeseal binary is required at runtime
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${kubeseal}/bin"
  ];

  # Skip tests as they require cluster access
  doCheck = false;

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
