using Test, BMPImages
using Colors
using Colors.FixedPointNumbers

using ImageMagick

if !isdefined(Main, :bmppath)
    bmppath(name) = joinpath(@__DIR__, "bmp", name * ".bmp")
    outpath(name) = joinpath(@__DIR__, "out", name)
end

@testset "gen_colortable_from_image" begin
    img24 = rand(RGB{N0f8}, 1000, 1000)
    table_img24 = BMPImages.gen_colortable_from_image(img24)
    @test isempty(table_img24)

    idx8_55 = read_bmp(bmppath("rgb888_idx8_55_v3"))
    table_idx8_55 = BMPImages.gen_colortable_from_image(idx8_55)
    @test table_idx8_55 isa Vector{RGB24}
    @test length(table_idx8_55) == 55

    idx8_gray = read_bmp(bmppath("rgb888_idx8_gray_v3"))
    table_idx8_gray = BMPImages.gen_colortable_from_image(idx8_gray)
    @test table_idx8_gray isa Vector{Gray{N0f8}}
    @test length(table_idx8_gray) == 256
end

@testset "rgb888_v3" begin
    img = read_bmp(bmppath("rgb888_v3"))
    write_bmp(outpath("rgb888_v3.bmp"), img; ppi=96.0, expand_paletted=true)

    @test read(outpath("rgb888_v3.bmp")) == read(bmppath("rgb888_v3"))
end

@testset "rgb888_idx8_55_v3" begin
    img = read_bmp(bmppath("rgb888_idx8_55_v3"))
    write_bmp(outpath("rgb888_idx8_55_v3.bmp"), img; ppi=96.0)

    @test read(outpath("rgb888_idx8_55_v3.bmp")) == read(bmppath("rgb888_idx8_55_v3"))
end

@testset "rgb888_idx4_16_v3" begin
    img = read_bmp(bmppath("rgb888_idx4_16_v3"))
    write_bmp(outpath("rgb888_idx4_16_v3.bmp"), img; ppi=96.0)

    @test read(outpath("rgb888_idx4_16_v3.bmp")) == read(bmppath("rgb888_idx4_16_v3"))
end

@testset "rgb888_idx1_2_v3" begin
    img = read_bmp(bmppath("rgb888_idx1_2_v3"))
    write_bmp(outpath("rgb888_idx1_2_v3.bmp"), img; ppi=96.0)

    @test read(outpath("rgb888_idx1_2_v3.bmp")) == read(bmppath("rgb888_idx1_2_v3"))
end

@testset "rgb888_idx8_gray_v3" begin
    img = read_bmp(bmppath("rgb888_idx8_gray_v3"))
    write_bmp(outpath("rgb888_idx8_gray_v3.bmp"), img; ppi=96.0)

    @test read(outpath("rgb888_idx8_gray_v3.bmp")) == read(bmppath("rgb888_idx8_gray_v3"))
end

@testset "rgb888_idx4_gray_v3" begin
    img = read_bmp(bmppath("rgb888_idx4_gray_v3"))
    write_bmp(outpath("rgb888_idx4_gray_v3.bmp"), img; ppi=96.0)

    @test read(outpath("rgb888_idx4_gray_v3.bmp")) == read(bmppath("rgb888_idx4_gray_v3"))
end

@testset "rgb888_idx1_bw_v3" begin
    img = read_bmp(bmppath("rgb888_idx1_bw_v3"))
    write_bmp(outpath("rgb888_idx1_bw_v3.bmp"), img; ppi=96.0)

    @test read(outpath("rgb888_idx1_bw_v3.bmp")) == read(bmppath("rgb888_idx1_bw_v3"))
end

@testset "xrgb8888_v3" begin
    img = RGB24.(read_bmp(bmppath("xrgb8888_v3")))
    write_bmp(outpath("xrgb8888_v3.bmp"), img; ppi=96.0, expand_paletted=true)

    @test read(outpath("xrgb8888_v3.bmp")) == read(bmppath("xrgb8888_v3"))
end

@testset "xrgb1555_v3" begin
    img = RGB{N3f5}.(read_bmp(bmppath("xrgb1555_v3")))
    write_bmp(outpath("xrgb1555_v3.bmp"), img; ppi=96.0, expand_paletted=true)

    @test read(outpath("xrgb1555_v3.bmp")) == read(bmppath("xrgb1555_v3"))
end

@testset "HSV" begin
    img = HSV{Float32}.(read_bmp(bmppath("rgb888_v3")))
    write_bmp(outpath("rgb888_v3_hsv.bmp"), img; ppi=96.0, expand_paletted=true)

    @test read(outpath("rgb888_v3_hsv.bmp")) == read(bmppath("rgb888_v3"))
end
