# kubeseal-auto - an interactive wrapper for kubeseal binary
# Uses poetry2nix to build with exact dependency versions from poetry.lock.
{
  lib,
  p2nix,
  fetchFromGitHub,
  kubeseal,
  python312,
}:

let
  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "kubeseal-auto";
    rev = "v0.7.0";
    hash = "sha256-hqtUgh5jRX821j9PyhXoPCWzcdfQm/fYGYY75Ve/hb4=";
  };
in
p2nix.mkPoetryApplication {
  pname = "kubeseal-auto";
  version = "0.7.0";
  projectDir = src;
  python = python312;

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
