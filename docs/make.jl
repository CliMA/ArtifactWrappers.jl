using Documenter, ArtifactWrappers

format = Documenter.HTML(
    prettyurls = !isempty(get(ENV, "CI", "")),
    collapselevel = 1,
)

makedocs(
    sitename = "ArtifactWrappers.jl",
    strict = true,
    format = format,
    checkdocs = :exports,
    clean = true,
    doctest = true,
    modules = [ArtifactWrappers],
    pages = Any["Home" => "index.md",],
)

deploydocs(
    repo = "github.com/CliMA/ArtifactWrappers.jl.git",
    target = "build",
    push_preview = true,
    devbranch = "main",
    forcepush = true,
)
