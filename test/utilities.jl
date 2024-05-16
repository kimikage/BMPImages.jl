using Test, BMPImages

@testset "_peek" begin
    io = IOBuffer([0x00, 0x01])
    read(io, UInt8)
    @test BMPImages._peek(io) === 0x01
    @test position(io) == 1
end

@testset "align32" begin
    expected = UInt32[0, 4, 4, 4, 4, 8, 8, 8, 8, 12, 12, 12, 12, 16, 16, 16, 16, 20]
    @test all(BMPImages.align32.(0:17) .=== expected)

    expected_cld2 = UInt32[0, 4, 4, 4, 4, 4, 4, 4, 4, 8, 8, 8, 8, 8, 8, 8, 8, 12]
    @test all(BMPImages.align32_cld2.(0:17) .=== expected_cld2)

    expected_cld8 = UInt32[0; fill(4, 32); 8]
    @test all(BMPImages.align32_cld8.(0:33) .=== expected_cld8)
end

@testset "pad32" begin
    expected = UInt32[0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3]
    @test all(BMPImages.pad32.(0:17) .=== expected)

    expected_cld2 = UInt32[0, 3, 3, 2, 2, 1, 1, 0, 0, 3, 3, 2, 2, 1, 1, 0, 0, 3]
    @test all(BMPImages.pad32_cld2.(0:17) .=== expected_cld2)

    expected_cld8 = UInt32.(b"0333333332222222211111111000000003" .- UInt8('0'))
    @test all(BMPImages.pad32_cld8.(0:33) .=== expected_cld8)
end

@testset "by_raw" begin
    table = [RGB24(0, 0, 0), RGB24(0, 0.6, 0), RGB24(0.4, 0, 0), RGB24(0, 0, 1)]
    stable = sort(table, by = BMPImages.by_raw)
    @test stable == [RGB24(0, 0, 0), RGB24(0, 0, 1), RGB24(0, 0.6, 0), RGB24(0.4, 0, 0)]
end

@testset "grayscaletable" begin
    @test all(d -> BMPImages.grayscaletable(d) isa Vector{Gray{N0f8}}, (1, 4, 8))
    @test all(d -> length(BMPImages.grayscaletable(d)) == 2^d, (1, 4, 8))
    @test_throws Exception BMPImages.grayscaletable(2)
end

@testset "_clamp01nan" begin
    @test BMPImages._clamp01nan(-Inf) === 0.0
    @test BMPImages._clamp01nan(NaN32) === 0.0f0
    @test BMPImages._clamp01nan(Float16(-0.0)) === Float16(0.0)
    @test BMPImages._clamp01nan(0.0) === 0.0
    @test BMPImages._clamp01nan(prevfloat(1.0f0)) === prevfloat(1.0f0)
    @test BMPImages._clamp01nan(Float16(1.0)) === Float16(1.0)
    @test BMPImages._clamp01nan(nextfloat(1.0)) === 1.0
    @test BMPImages._clamp01nan(Inf32) === 1.0f0
end

@testset "xrgb1888 <-> xrgb8888" begin
    c16_to_c32 = BMPImages.xrgb1555_to_xrgb8888
    c32_to_c16 = BMPImages.xrgb8888_to_xrgb1555

    @test c32_to_c16(0xff8000) === 0b0_11111_10000_00000
    @test c32_to_c16(0x04fa7f) === 0b0_00000_11110_01111
    @test c32_to_c16(0x05fb88) === 0b0_00001_11111_10001

    @test all(c -> c32_to_c16(c16_to_c32(c)) === c & 0x7fff, 0x0000:0xffff)
end

@testset "argb1888 <-> argb8888" begin
    c16_to_c32 = BMPImages.argb1555_to_argb8888
    c32_to_c16 = BMPImages.argb8888_to_argb1555

    @test c32_to_c16(0x7fffffff) === 0b0_11111_11111_11111
    @test c32_to_c16(0x80000000) === 0b1_00000_00000_00000

    @test all(c -> c32_to_c16(c16_to_c32(c)) === c, 0x0000:0xffff)
end

@testset "xrgb8888_to_rgb" begin
    to_rgb = BMPImages.xrgb8888_to_rgb
    u32 = 0x99ff6600
    @test @inferred(to_rgb(RGB{N0f8}, u32)) === RGB{N0f8}(1, 0.4, 0)
    @test @inferred(to_rgb(BGR{Float32}, u32)) === BGR{Float32}(1, 0.4, 0)
    @test @inferred(to_rgb(RGB24, u32)) === reinterpret(RGB24, 0x99ff6600)
    @test @inferred(to_rgb(XRGB, u32)) == XRGB{N0f8}(1, 0.4, 0)
    @test @inferred(to_rgb(RGBX{Float32}, u32)) == RGBX{Float32}(1, 0.4, 0)
    xrgb = [to_rgb(XRGB{Float64}, u32)]
    @test reinterpret(ARGB{Float64}, xrgb)[1] === ARGB{Float64}(1, 0.4, 0, 0.6)
    rgbx = [to_rgb(RGBX, u32)]
    @test reinterpret(RGBA{N0f8}, rgbx)[1] === RGBA{N0f8}(1, 0.4, 0, 0.6)
end
