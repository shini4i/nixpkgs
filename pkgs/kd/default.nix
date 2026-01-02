# kd - Kubernetes secrets decoder
# A bash script that decodes Kubernetes secrets
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  kubectl,
  yq-go,
}:

stdenv.mkDerivation rec {
  pname = "kd";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "kd";
    rev = "v${version}";
    hash = "sha256-MrATJ6y//qUGzVcdQ3jggJZpriPLewYEy7IMJD3Clpk=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install the main script
    install -Dm755 $src/src/kd.sh $out/bin/kd

    # Install Zsh completion
    install -Dm644 $src/completion/_kd.zsh $out/share/zsh/site-functions/_kd

    wrapProgram $out/bin/kd \
      --prefix PATH : ${lib.makeBinPath [ kubectl yq-go ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "A bash script that decodes Kubernetes secrets";
    longDescription = ''
      kd is a bash script that decodes Kubernetes secrets. It makes it easy
      to view the contents of secrets stored in a Kubernetes cluster.
    '';
    homepage = "https://github.com/shini4i/kd";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
    mainProgram = "kd";
  };
}
