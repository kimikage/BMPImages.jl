using Test, BMPImages
using Colors
using Colors.FixedPointNumbers

@testset "w/o FileIO" begin
    @test length(methods(BMPImages.load)) == 0
end

using FileIO

@testset "w/ FileIO" begin
    @test length(methods(BMPImages.load)) == 2

    dib = joinpath(@__DIR__, "bmp", "rgb888_idx8_55_v3.dib")
    bmp = joinpath(@__DIR__, "bmp", "rgb888_idx8_55_v3.bmp")
    out = joinpath(@__DIR__, "out", "fileio.bmp")

    @test query(dib) isa File{format"BMP"}
    @test !(query(dib, checkfile=false) isa File{format"BMP"})

    add_bmp_format()

    @test query(dib, checkfile=false) isa File{format"BMP"}

    @test FileIO.info(format"BMP") isa Tuple

    broken = IOBuffer([0x42; 0x4d; zeros(UInt8, 14)])
    @test query(broken) isa Stream{format"BMP"}

    @info "FileIO outputs error messages"
    @test_throws Exception load(broken)

    img = load(bmp)

    @test img isa Matrix{RGB{N0f8}}
    @test size(img) == (11, 13)

    save(out, img; ppi=96.0)

    @test read(bmp) == read(out)

    skip = open(File{format"BMP"}(bmp), "r") do s
        skipmagic(s)
        BMPImages.load(s)
    end

    @test skip == img
end
