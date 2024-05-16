barbara = "barbara_gray_512.bmp"
barbara_path = joinpath(@__DIR__, "bmp", barbara)

isfile(barbara_path) || setindex!(ENV, "CI", "true")

if get(ENV, "CI", false) != false
    using Pkg
    @static if VERSION < v"1.3"
        Pkg.add(PackageSpec(name="ColorTypes", version="0.10.12"))
        Pkg.pin("ColorTypes")
        Pkg.add(PackageSpec(name="Images", version="0.23.3"))
    else
        Pkg.add("Images")
    end
end

using Test, BMPImages

@testset "ext FileIO" begin
    include("fileio.jl")
end

if !isfile(barbara_path)
    using TestImages
    if VERSION >= v"1.3"
        img_path = testimage(barbara; download_only=true)
    else
        testimage(barbara)
        img_path = joinpath(dirname(pathof(TestImages)), "..", "images", barbara)
    end
    cp(img_path, barbara_path, force=true)
end

if get(ENV, "CI", false) != false
    using Images
    using Aqua

    @testset "Aqua" begin
        Aqua.test_all(BMPImages; ambiguities = false)
        Aqua.test_ambiguities([BMPImages, ColorTypes, Base, Core])
    end
end

@testset "utilities" begin
    include("utilities.jl")
end

@testset "read" begin
    include("read.jl")
end

@testset "write" begin
    include("write.jl")
end

open(joinpath(@__DIR__, "out", "results.html"), "w") do f
    write(f, """
        <html>
        <head>
          <style>
            body {
                background: #cccccc;
            }
            img {
                width: 130;
                height: 110;
                image-rendering: pixelated;
            }
          </style>
        </head>
        <body>
        <h1>Test Results</h1>
        <p>the source bmp, the `read_bmp` result, and the `write_bmp` result.</p>
        """)
    for filename in readdir(joinpath(@__DIR__, "bmp"))
        basename, ext = splitext(filename)
        ext == ".bmp" || continue
        write(f, """
            <h2>$basename</h2>
            <img src="../bmp/$basename.bmp" />
            <img src="$basename.png" />
            """)
        if isfile(joinpath(@__DIR__, "out", filename))
            write(f, """<img src="$basename.bmp" />\n""")
        end
    end
    write(f, """
        </body>
        </html>
        """)
end
