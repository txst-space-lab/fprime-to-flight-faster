{
  description = "Typst toolchain for the F Prime HIL CI poster";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Fonts referenced by name in the Typst source. Pinning them here means
      # the poster renders identically on every machine and in CI — a poster
      # that falls back to a substitute font reflows and breaks the layout.
      fontsFor = pkgs: with pkgs; [
        inter
        source-sans
        source-serif
        jetbrains-mono
        liberation_ttf # last-resort sans fallback named in poster.typ
        dejavu_fonts # last-resort mono fallback named in poster.typ
      ];

      # Typst discovers fonts through TYPST_FONT_PATHS.
      fontPathFor = pkgs:
        pkgs.lib.concatStringsSep ":"
          (map (p: "${p}/share/fonts") (fontsFor pkgs));
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = (with pkgs; [
            # Core
            typst # compiler
            tinymist # language server (Zed / VS Code / Neovim)
            typstyle # formatter

            # Figure handling
            imagemagick # convert / downscale photos
            librsvg # rsvg-convert, for SVG diagrams
            qrencode # QR code for the repo link
            poppler-utils # pdftoppm, to proof a raster preview

            # CI data analysis -> data/*.csv and figures/*.svg
            (python3.withPackages (ps: with ps; [ pandas matplotlib ]))
          ]) ++ fontsFor pkgs;

          TYPST_FONT_PATHS = fontPathFor pkgs;

          shellHook = ''
            echo "typst $(typst --version | cut -d' ' -f2) — poster toolchain"
            echo "  typst watch poster.typ               live preview"
            echo "  typst compile poster.typ poster.pdf  build poster.pdf"
            echo "  typstyle -i poster.typ               format"
            echo "  typst fonts                          list available fonts"
          '';
        };
      });

      # nix build  ->  result/poster.pdf
      # Requires poster.typ to exist at the repo root.
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "fprime-hil-poster";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.typst ];
          TYPST_FONT_PATHS = fontPathFor pkgs;

          buildPhase = ''
            runHook preBuild
            typst compile poster.typ poster.pdf
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp poster.pdf $out/
            runHook postInstall
          '';
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
