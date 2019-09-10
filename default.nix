let
  projtmpl = {
    lib, runCommand, makeWrapper, shellcheck,
    glibcLocales, coreutils, gnused, gnugrep, findutils
  }: let
    path = lib.makeBinPath [
      coreutils gnused gnugrep findutils
    ];
    name = "projtmpl-${version}";
    version = "0.0.0";
  in runCommand name {
    nativeBuildInputs = [ makeWrapper shellcheck ];
    meta = with lib; {
      description = "Project directory templates";
      homepage = https://github.com/andrejlamov/project-templates;
      license = licenses.unlicense;
      inherit version;
    };
  } ''
    shellcheck -x "${./template.sh}" || true
    mkdir -p $out/bin
    makeWrapper "${./template.sh}" "$out/bin/projtmpl" \
      --argv0 projtmpl \
      --set PATH "${path}"
  '';
in { pkgs ? import <nixpkgs> {} }: pkgs.callPackage projtmpl {}
