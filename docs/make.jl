using Documenter, BMPImages
using Colors
using ImageShow

DocMeta.setdocmeta!(BMPImages, :DocTestSetup, :(using BMPImages;); recursive=true)

makedocs(
    clean=false,
    checkdocs=:exports,
    modules=[BMPImages],
    format=Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                           assets = ["assets/favicon.ico"]),
    sitename="BMPImages",
    pages=[
        "Introduction" => "index.md",
        "API Reference" => "api.md",
    ]
)

deploydocs(
    repo="github.com/kimikage/BMPImages.jl.git",
    devbranch = "main",
    push_preview = true
)
