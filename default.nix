{
  fetcherSrc ? (builtins.path { path = ./.; name = "nix-pypi-fetcher"; }),
  pkgs,
  lib
}:

let
  normalizeName = name: (lib.replaceStrings ["_"] ["-"] (lib.toLower name));
  nameToBucket = name:
    let
      pkg_name = normalizeName name;
      pkg_name_first_char = builtins.elemAt (lib.stringToCharacters pkg_name) 0;
      bucket_hash_full = builtins.hashString "sha256" pkg_name;
    in
      builtins.elemAt (lib.stringToCharacters bucket_hash_full) 0
      + builtins.elemAt (lib.stringToCharacters bucket_hash_full) 1;
  releaseInfo = name: ver:
    let
      pkg_name = normalizeName name;
      bucket = nameToBucket name;
      release = (builtins.fromJSON (builtins.readFile (fetcherSrc + /pypi + "/${bucket}.json")))."${pkg_name}"."${ver}";
    in
    {
      inherit pkg_name release;
      pkg_name_first_char = builtins.elemAt (lib.stringToCharacters pkg_name) 0;
    };
  # collect the list of package names inside a derivation for faster reading and proper caching
  allNamesJsonFile = pkgs.runCommand "all-package-names" { buildInputs = [ pkgs.python3 ]; } ''
     ${pkgs.python3}/bin/python -c '
     import json
     from os import environ
     buckets = []
     for a in "0123456789abcdef":
        for b in "0123456789abcdef":
            buckets.append(a + b)
     all_names = []
     for bucket in buckets:
        with open("${fetcherSrc}/pypi/" + bucket + ".json") as f:
          all_names += list(json.load(f).keys())
     with open(environ.get("out"), "w") as out:
        json.dump(all_names, out)
     '
  '';
  allNames = builtins.fromJSON (builtins.readFile allNamesJsonFile);
in
rec {
  inherit allNames;

  fetchPypi = fetchPypiSdist;

  fetchPypiSdist = pkg: ver:
    with releaseInfo pkg ver;
    let
      sha256 = elemAt release."sdist" 0;
      filename = elemAt release."sdist" 1;
      url = "https://files.pythonhosted.org/packages/source/" + pkg_name_first_char + "/" + pkg_name
            + "/" + filename;
    in
    pkgs.fetchurl {
      inherit url sha256;
    };

  fetchPypiWheel = pkg: ver: fn:
    with releaseInfo pkg ver;
    let
      sha256 = elemAt release."wheels"."${fn}" 0;
      pyver = elemAt release."wheels"."${fn}" 1;
      url = "https://files.pythonhosted.org/packages/" + pyver + "/" + pkg_name_first_char + "/"
            + pkg_name + "/" + fn;
    in
    pkgs.fetchurl {
      inherit url sha256;
    };
}
