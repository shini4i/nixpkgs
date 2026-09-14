# argo-compare - comparison tool for ArgoCD Application manifests
# Shows differences between applications in different Git branches
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  mockgen,
  git,
}:

buildGoModule rec {
  pname = "argo-compare";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "argo-compare";
    rev = "v${version}";
    hash = "sha256-VeDqbih+KXhi/9PX8kDDt2DXowbT13eEZx3zQwGWB+Q=";
  };

  vendorHash = "sha256-EgdPPJW6POoeqQUfP2Pg/w8ylb32bgajhTCx9pquEcY=";

  nativeBuildInputs = [ mockgen ];
  nativeCheckInputs = [ git ];

  preBuild = ''
    # Generate mocks required for tests
    mkdir -p cmd/argo-compare/mocks
    mockgen --source=internal/ports/ports.go --destination=cmd/argo-compare/mocks/interfaces.go --package=mocks
  '';

  # Some tests resolve the repository root from the working directory; fetchFromGitHub
  # ships no .git, so they fail before reaching what they actually assert.
  preCheck = ''
    git init -q
  '';

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "Comparison tool for ArgoCD Application manifests between Git branches";
    longDescription = ''
      argo-compare shows what would be changed in manifests rendered by helm
      after changes to specific ArgoCD Applications are merged into the target branch.
      It renders helm templates from both source and target branches and displays
      the differences, making it easier to review changes before merging.
    '';
    homepage = "https://github.com/shini4i/argo-compare";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "argo-compare";
  };
}
