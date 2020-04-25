## Easy-to-use python package source fetcher for nix
Tired of manually finding the right url and sha256 hash for a pypi package? This project makes your life easier while still providing the same reproducibility / security.

### What it does:
This package comes with a full copy of `url + sha256` for each python package ever published on pypi.org as of 2020-01-08. By importing this project you will download around 130 MB (370MB uncompressed) of pypi metadata. Afterwards you can just fetch pypi sources within your nix expressions like this:
```nix
# pseudo example not including the necessary imports

buildPythonPackage {
  src = fetchPypi "requests" "2.22.0";
  ...
}
```
This is possible because combinations of name and version on pypi are unique. You will have the same reproducibility like when specifying the url and sha256 manually. You are not relying on pypi for integrity since all hashes for downloads are here in this project.

### What it doesn't
This project does not solve any dependency issues you might face during the build. You still need to manually specify build and runtime dependencies of the package via `buildInputs` and `propagatedBuildInputs`.

### Full usage example
The following expression will fetch the source tarball for requests 2.22.0
```nix
let
  commit = "bb760a77a1df8718c49b1fd5423d37823e8e403f";
  fetchPypi = import (builtins.fetchTarball {
    name = "nix-pypi-fetcher";
    url = "https://github.com/DavHau/nix-pypi-fetcher/tarball/${commit}";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0bkc2hwp785p0ljrhyhhnjkjpz801369d74rc3jz48hxlbdz8sqw";
  });
in
fetchPypi "requests" "2.22.0"
```
