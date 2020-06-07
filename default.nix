with import <nixpkgs> {};
with builtins;
with lib;
let
  releaseInfo = name: ver:
    let
      pkg_name = (replaceStrings ["_"] ["-"] (toLower name));
      pkg_name_first_char = elemAt (stringToCharacters pkg_name) 0;
      bucket_hash_full = hashString "sha256" pkg_name;
      bucket =
          elemAt (stringToCharacters bucket_hash_full) 0
          + elemAt (stringToCharacters bucket_hash_full) 1;
      release = (fromJSON (readFile (./pypi + "/${bucket}.json")))."${pkg_name}"."${ver}";
    in
    {
      inherit pkg_name pkg_name_first_char release;
    };
in
rec {
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
