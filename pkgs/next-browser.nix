{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  chromium,
  makeWrapper,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "next-browser";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "next-browser";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8d5FHe8WtMim4OUSE+VqSTQ5K/xv7VoUOhU6f1mJ76Y=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-zmiB9fPbqvSY17DR7vyJQBuUmNe9aQGExoanioMxfNY=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpm_10
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  postBuild = ''
    substituteInPlace dist/browser.js \
      --replace-fail 'headless: false,' $'headless: false,\n        executablePath: process.env.NEXT_BROWSER_CHROMIUM_EXECUTABLE,'
    substituteInPlace dist/browser.js \
      --replace-fail 'headless,' $'headless,\n        executablePath: process.env.NEXT_BROWSER_CHROMIUM_EXECUTABLE,'
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/bin" "$out/lib/node_modules/${finalAttrs.pname}"
    cp -r dist extensions node_modules package.json "$out/lib/node_modules/${finalAttrs.pname}"

    makeWrapper ${nodejs}/bin/node "$out/bin/next-browser" \
      --add-flags "$out/lib/node_modules/${finalAttrs.pname}/dist/cli.js" \
      --set HOME /tmp \
      --set XDG_CONFIG_HOME /tmp \
      --set XDG_CACHE_HOME /tmp \
      --set-default NEXT_BROWSER_CHROMIUM_EXECUTABLE "${chromium}/bin/chromium" \
      --set-default PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true \
      --unset PLAYWRIGHT_BROWSERS_PATH

    runHook postInstall
  '';

  meta = {
    description = "Headed Playwright browser for Next.js agent workflows";
    homepage = "https://github.com/vercel-labs/next-browser";
    changelog = "https://github.com/vercel-labs/next-browser/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mainProgram = "next-browser";
    platforms = lib.platforms.all;
  };
})
