{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
  nodejs,
  yarn-berry_4,
  nixosTests,
}:
stdenv.mkDerivation (
  finalAttrs:
  let
    yarn-berry = yarn-berry_4;
    yarnOfflineCache = yarn-berry.fetchYarnBerryDeps {
      inherit (finalAttrs) src missingHashes;
      hash = "sha256-Q6UfMdiZHJrBPTyimrjVgTT7SGLq4weHF+hdZfGhtRI=";
    };
  in
  {
    pname = "outline";
    version = "1.4.0";

    src = fetchFromGitHub {
      owner = "outline";
      repo = "outline";
      rev = "v${finalAttrs.version}";
      hash = "sha256-AxTgD5zqJ9PFdhvfbiHLDjEHzhMLPOsjGtjrzTle4qw=";
    };

    missingHashes = ./missing-hashes.json;

    nativeBuildInputs = [
      makeWrapper
      yarn-berry
      yarn-berry.yarnBerryConfigHook
      nodejs
    ];

    inherit yarnOfflineCache;

    buildPhase = ''
      runHook preBuild
      export NODE_OPTIONS=--openssl-legacy-provider

      # yarnBerryConfigHook handles yarn install automatically
      # apply upstream patches with `patch-package`
      yarn run postinstall
      yarn build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/outline
      mv build server public node_modules $out/share/outline/

      node_modules=$out/share/outline/node_modules
      build=$out/share/outline/build
      server=$out/share/outline/server

      makeWrapper ${nodejs}/bin/node $out/bin/outline-server \
        --add-flags $build/server/index.js \
        --set NODE_ENV production \
        --set NODE_PATH $node_modules \
        --prefix PATH : ${lib.makeBinPath [ nodejs ]} # required to run migrations

      runHook postInstall
    '';

    passthru = {
      tests = {
        basic-functionality = nixosTests.outline;
      };

      # run with: nix-shell ./maintainers/scripts/update.nix --argstr package outline
      updateScript = ./update.sh;
      # alias for nix-update to be able to find and update this attribute
      offlineCache = yarnOfflineCache;
    };

    meta = {
      description = "Fastest wiki and knowledge base for growing teams. Beautiful, feature rich, and markdown compatible";
      homepage = "https://www.getoutline.com/";
      changelog = "https://github.com/outline/outline/releases";
      license = lib.licenses.bsl11;
      maintainers = with lib.maintainers; [
        cab404
        e1mo
        xanderio
        yrd
      ];
      platforms = lib.platforms.linux;
    };
  }
)
