module ArtifactWrappers

using ArtifactUtils
using REPL.TerminalMenus

using Downloads
using Pkg.Artifacts

export create_add_artifact_guided

export ArtifactWrapper, ArtifactFile, get_data_folder

if VERSION >= v"1.6"
    download_method = Downloads.download
else
    download_method = Artifacts.download
end

"""
    ArtifactFile

A single data file to be downloaded, containing both the url and the
name to use locally.

# Fields
 - `url` URL pointing to data to be downloaded
 - `filename` Local name used for downloaded online data
"""
Base.@kwdef struct ArtifactFile
    "URL pointing to data to be downloaded"
    url::AbstractString = ""
    "Local name used for downloaded online data"
    filename::AbstractString = ""
end

"""
    ArtifactWrapper

A set of data files to be downloaded, grouped by `data_name`. Example:

```
dataset = ArtifactWrapper(
    @__DIR__,
    isempty(get(ENV, "CI", "")),
    "MyDataSet",
    ArtifactFile[
        ArtifactFile(
            url="https://..../SomeNetCDF1.nc",
            filename="experiment1.nc",
        ),
        ArtifactFile(
            url="https://..../SomeNetCDF2.nc",
            filename="experiment2.nc",
        ),
    ]
)
```

# Fields
 - `artifact_dir` Directory to store artifact / data
 - `lazy_download` Lazily download data. Set to false to eagerly download data.
 - `artifact_toml` Path to the used Artifacts.toml
 - `data_name` Unique name of dataset
 - `artifact_files` Array of `ArtifactFile`'s, grouped by this dataset
"""
struct ArtifactWrapper
    "Directory to store artifact / data"
    artifact_dir::AbstractString
    "Lazily download data. Set to false to eagerly download data."
    lazy_download::Bool
    "Path to the used Artifacts.toml"
    artifact_toml::AbstractString
    "Unique name of dataset"
    data_name::AbstractString
    "Array of `ArtifactFile`'s, grouped by this dataset"
    artifact_files::Vector{ArtifactFile}
end
function ArtifactWrapper(
    artifact_dir,
    data_name,
    artifact_files;
    lazy_download = true,
)
    Base.depwarn(
        "ArtifactWrapper is deprecated. Use Julia artifacts instead.",
        :ArtifactWrapper,
        force = true,
    )
    artifact_toml = joinpath(artifact_dir, "Artifacts.toml")
    return ArtifactWrapper(
        artifact_dir,
        lazy_download,
        artifact_toml,
        data_name,
        artifact_files,
    )
end


"""
    get_data_folder(art_wrap::ArtifactWrapper)

Get local folder of dataset defined in `art_wrap`.

Example:

```julia
dataset_path = get_data_folder(dataset)
```
"""
function get_data_folder(art_wrap::ArtifactWrapper)
    Base.depwarn(
        "ArtifactWrapper is deprecated. Use Julia artifacts instead.",
        :get_data_folder,
        force = true,
    )
    if !art_wrap.lazy_download
        # When running multiple jobs, create_artifact
        # has a race condition when creating/moving
        # files. So, when using CI, just download
        # the data files:
        filenames = [af.filename for af in art_wrap.artifact_files]
        urls = [af.url for af in art_wrap.artifact_files]
        for (url, filename) in zip(urls, filenames)
            Downloads.download(
                "$(url)",
                joinpath(art_wrap.artifact_dir, filename),
            )
        end
        return art_wrap.artifact_dir
    else
        # Query the `Artifacts.toml` file for the hash bound to the name
        # data_name (returns `nothing` if no such binding exists)
        data_hash = artifact_hash(art_wrap.data_name, art_wrap.artifact_toml)

        # If the name was not bound, or the hash it was bound to does not
        # exist, create it!
        if data_hash == nothing || !artifact_exists(data_hash)
            # create_artifact() returns the content-hash of the artifact
            # directory once we're finished creating it
            data_hash = create_artifact() do artifact_dir
                # We create the artifact by simply downloading a few files
                # into the new artifact directory
                filenames = [af.filename for af in art_wrap.artifact_files]
                urls = [af.url for af in art_wrap.artifact_files]
                for (url, filename) in zip(urls, filenames)
                    Downloads.download("$(url)", joinpath(artifact_dir, filename))
                end
            end

            # Now bind that hash within our `Artifacts.toml`. `force = true`
            # means that if it already exists, just overwrite with the new
            # content-hash.  Unless the source files change, we do not expect
            # the content hash to change, so this should not cause
            # unnecessary version control churn.
            bind_artifact!(
                art_wrap.artifact_toml,
                art_wrap.data_name,
                data_hash,
                force = true,
            )
        end

        # Get the path of the dataset, either newly created or
        # previously generated. This should be something like:
        # `~/.julia/artifacts/dbd04e28be047a54fbe9bf67e934be5b5e0d357a`
        dataset_path = artifact_path(data_hash)
        return dataset_path
    end
end


"""
    create_tarball(artifact_dir)

Create a `tar.gz` from the given directory. Return the path.
"""
function create_tarball(artifact_dir; tar_path = artifact_dir * ".tar.gz")
    artifact_id = ArtifactUtils.artifact_from_directory(artifact_dir)
    ArtifactUtils.archive_artifact(artifact_id, tar_path)
    return tar_path
end

"""
    create_add_artifact_guided(artifact_dir,
                               artifact_toml = joinpath(pwd(), "Artifact.toml"))

Start a guided process to create an artifact from a directory of files.
"""
function create_add_artifact_guided(
    artifact_dir;
    artifact_toml = joinpath(pwd(), "Artifact.toml"),
)
    println("First, we will create the artifact tarball")
    println(
        "You will upload it to the Caltech Data Archive and provide the direct link",
    )
    println("Archiving artifact (might take a while)")
    tar_path = create_tarball(artifact_dir)
    println("Artifact archived!")

    println(
        "Now, upload $tar_path to the Caltech Data Archive, paste here the link, and press ENTER",
    )
    print("> ")
    tarball_url = readline()

    println(
        "What's the name of your artifact? Write it here, and press ENTER (no spaces/special symbols)",
    )
    print("> ")
    artifact_name = readline()

    println(
        "We will add the artifact to $artifact_toml. You can copy and edit the relevant configuration from there",
    )
    println(
        "I will try to download your freshly minted artifact to check that it works (might take a while)",
    )

    # Bind the artifact, retrieve the Artifact.toml, and print it
    mktempdir() do path
        artifact_toml = joinpath(path, "Artifacts.toml")
        ArtifactUtils.add_artifact!(artifact_toml, artifact_name, tarball_url)
        open(artifact_toml, "r") do file
            artifact_str = read(file, String)
            println(
                "Here is your artifact string. Copy and past it to your Artifacts.toml",
            )
            println()
            println(artifact_str)
        end
    end

    println()
    println("Done! Enjoy the rest of your day!")
end

end # module
