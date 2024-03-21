# ArtifactWrappers.jl

A simple package to guide users in creating new Julia artifacts from a
collection of files.

## Use

``` julia
using ArtifactWrappers

datadir = "path with the files"

create_add_artifact_guided(datadir)
```

This will start a guided processes that looks like:
```
julia> create_add_artifact_guided("aerosol_artifact")
First, we will create the artifact tarball
You will upload it to the Caltech Data Archive and provide the direct link
Archiving artifact (might take a while)
Artifact archived!
Now, upload /home/sbozzolo/repos/all/ClimaAtmos.jl/artifacts/aerosol/aerosol_artifact.tar.gz to the Caltech Data Archive, paste here the link, and press ENTER
> https://caltech.box.com/shared/static/chmel1vdthfvfac0yl61ayw2jqnjzr2c.gz
What's the name of your artifact? Write it here, and press ENTER (no spaces/special symbols)
> aerosol
We will add the artifact to /home/sbozzolo/repos/all/ArtifactWrappers.jl/src/Artifact.toml. You can copy and edit the relevant configuration from there
I will try to download your freshly minted artifact to check that it works (might take a while)
Here is your artifact string. Copy and past it to your Artifacts.toml

[aerosol]
git-tree-sha1 = "2323df92429a10d215fe80a62ab9702a448033cf"

    [[aerosol.download]]
    sha256 = "0d8e8a02aad6291cf4aa1b96f02b6b5f8622b19bd9a3d76196a5c0d23dd83506"
    url = "https://caltech.box.com/shared/static/chmel1vdthfvfac0yl61ayw2jqnjzr2c.gz"


Done! Enjoy the rest of your day!
```
