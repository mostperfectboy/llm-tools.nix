{
  coreutils,
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
    substituteInPlace dist/paths.js \
      --replace-fail 'const dir = join(homedir(), ".next-browser");' 'const dir = process.env.NEXT_BROWSER_RUNTIME_DIR ?? join(homedir(), ".next-browser");'
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/bin" "$out/lib/node_modules/${finalAttrs.pname}"
    cp -r dist extensions node_modules package.json "$out/lib/node_modules/${finalAttrs.pname}"

    makeWrapper ${nodejs}/bin/node "$out/bin/next-browser" \
      --add-flags "$out/lib/node_modules/${finalAttrs.pname}/dist/cli.js" \
      --run 'runtime_root="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/next-browser"' \
      --run 'project_root="''${NEXT_BROWSER_PROJECT_ROOT:-$PWD}"' \
      --run 'project_key="$(${coreutils}/bin/printf %s "$project_root" | ${coreutils}/bin/sha256sum | ${coreutils}/bin/cut -c1-16)"' \
      --run 'runtime_dir="$runtime_root/$project_key"' \
      --run '${coreutils}/bin/mkdir -p "$runtime_dir" "$runtime_dir/config" "$runtime_dir/cache"' \
      --run 'export NEXT_BROWSER_RUNTIME_DIR="$runtime_dir"' \
      --run 'export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$runtime_dir/config}"' \
      --run 'export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$runtime_dir/cache}"' \
      --run 'if [ -z "''${NEXT_BROWSER_HEADLESS:-}" ] && [ -z "''${DISPLAY:-}" ] && [ -z "''${WAYLAND_DISPLAY:-}" ]; then export NEXT_BROWSER_HEADLESS=1; fi' \
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
