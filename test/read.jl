using Test, BMPImages
using Colors
using Colors.FixedPointNumbers

using ImageMagick

if !isdefined(Main, :bmppath)
    bmppath(name) = joinpath(@__DIR__, "bmp", name * ".bmp")
    outpath(name) = joinpath(@__DIR__, "out", name)
end

@testset "rgb888_v3" begin
    h = read_bmp_header(bmppath("rgb888_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_01f0
    @test h.offset === 0x0000_0036
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(24)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (13 * 3 + 1) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0)
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 0

    img = read_bmp(bmppath("rgb888_v3"))
    ImageMagick.save(outpath("rgb888_v3.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_v3"))
end

@testset "rgb888_v3_td" begin
    h = read_bmp_header(bmppath("rgb888_v3_td"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_01f0
    @test h.offset === 0x0000_0036
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(-11) # top-down
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(24)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (13 * 3 + 1) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0)
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 0

    img = read_bmp(bmppath("rgb888_v3_td"))
    ImageMagick.save(outpath("rgb888_v3_td.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_v3_td"))
end

@testset "rgb888_idx8_256_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx8_256_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_04e8
    @test h.offset === 0x0000_0036 + UInt32(256 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(8)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (13 + 3) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0) # => 256
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 256
    @test h.colortable[1] === RGB{N0f8}(0, 0, 0)
    @test h.colortable[256] === RGB{N0f8}(1, 1, 1)

    img = read_bmp(bmppath("rgb888_idx8_256_v3"))
    ImageMagick.save(outpath("rgb888_idx8_256_v3.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_idx8_256_v3"))
end

@testset "rgb888_idx8_55_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx8_55_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_01c4
    @test h.offset === 0x0000_0036 + UInt32(55 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(8)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (13 + 3) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(55)
    @test h.colors_important === UInt32(55)

    @test length(h.colortable) == 55
    @test h.colortable[1] === RGB{N0f8}(0.22, 0.596, 0.149)
    @test h.colortable[55] === RGB{N0f8}(1, 1, 1)

    img = read_bmp(bmppath("rgb888_idx8_55_v3"))
    ImageMagick.save(outpath("rgb888_idx8_55_v3.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_idx8_55_v3"))
end

@testset "rgb888_idx4_16_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx4_16_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_00d0
    @test h.offset === 0x0000_0036 + UInt32(16 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(4)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (cld(13, 2) + 1) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0) # => 16
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 16
    @test h.colortable[1] === RGB{N0f8}(0.278, 0.627, 0.212)
    @test h.colortable[16] === RGB{N0f8}(1, 1, 1)

    img = read_bmp(bmppath("rgb888_idx4_16_v3"))
    ImageMagick.save(outpath("rgb888_idx4_16_v3.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_idx4_16_v3"))
end

@testset "rgb888_idx1_2_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx1_2_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_006c
    @test h.offset === 0x0000_0036 + UInt32(2 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(1)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * 4 + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0) # => 2
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 2
    @test h.colortable[1] === RGB{N0f8}(0.584, 0.345, 0.698)
    @test h.colortable[2] === RGB{N0f8}(1, 1, 1)

    img = read_bmp(bmppath("rgb888_idx1_2_v3"))
    ImageMagick.save(outpath("rgb888_idx1_2_v3.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_idx1_2_v3"))
end

@testset "rgb888_idx8_gray_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx8_gray_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_04e8
    @test h.offset === 0x0000_0036 + UInt32(256 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(8)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (13 + 3) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0) # => 256
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 256
    @test h.colortable[1] === Gray{N0f8}(0)
    @test h.colortable[256] === Gray{N0f8}(1)

    img = read_bmp(bmppath("rgb888_idx8_gray_v3"))
    @test img isa Matrix{Gray{N0f8}}
    ImageMagick.save(outpath("rgb888_idx8_gray_v3.png"), img)

    @test RGB{N0f8}.(img) == ImageMagick.load(bmppath("rgb888_idx8_gray_v3"))
end

@testset "rgb888_idx4_gray_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx4_gray_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_00d0
    @test h.offset === 0x0000_0036 + UInt32(16 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(4)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (cld(13, 2) + 1) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0) # => 16
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 16
    @test h.colortable[1] === Gray{N0f8}(0)
    @test h.colortable[16] === Gray{N0f8}(1)

    img = read_bmp(bmppath("rgb888_idx4_gray_v3"))
    @test img isa Matrix{Gray{N0f8}}
    # ImageMagick.save(outpath("rgb888_idx4_gray_v3.png"), img) # Some versions have bugs.
    save(outpath("rgb888_idx4_gray_v3.png"), img)

    @test RGB{N0f8}.(img) == ImageMagick.load(bmppath("rgb888_idx4_gray_v3"))
end

@testset "rgb888_idx1_bw_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx1_bw_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_006c
    @test h.offset === 0x0000_0036 + UInt32(2 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(1)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * 4 + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0) # => 2
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 2
    @test h.colortable[1] === Gray{Bool}(0)
    @test h.colortable[2] === Gray{Bool}(1)

    img = read_bmp(bmppath("rgb888_idx1_bw_v3"))
    @test img isa Matrix{Gray{Bool}}
    ImageMagick.save(outpath("rgb888_idx1_bw_v3.png"), img)

    @test RGB{N0f8}.(img) == ImageMagick.load(bmppath("rgb888_idx1_bw_v3"))
end

@testset "rgb888_idx1_wb_v3" begin
    h = read_bmp_header(bmppath("rgb888_idx1_wb_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_006c
    @test h.offset === 0x0000_0036 + UInt32(2 * 4)
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(1)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * 4 + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0) # => 2
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 2
    @test h.colortable[1] === Gray{Bool}(1)
    @test h.colortable[2] === Gray{Bool}(0)

    img = read_bmp(bmppath("rgb888_idx1_wb_v3"))
    @test img isa Matrix{Gray{Bool}}
    ImageMagick.save(outpath("rgb888_idx1_wb_v3.png"), img)

    @test RGB{N0f8}.(img) == ImageMagick.load(bmppath("rgb888_idx1_wb_v3"))
end

@testset "xrgb8888_v3" begin
    h = read_bmp_header(bmppath("xrgb8888_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_0274
    @test h.offset === 0x0000_0036
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(32)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (13 * 4) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0)
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 0

    img = read_bmp(bmppath("xrgb8888_v3"))
    ImageMagick.save(outpath("xrgb8888_v3.png"), img)

    @test img == ImageMagick.load(bmppath("xrgb8888_v3"))
end

@testset "xrgb1555_v3" begin
    h = read_bmp_header(bmppath("xrgb1555_v3"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_016c
    @test h.offset === 0x0000_0036
    @test h.headersize === UInt32(40)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(16)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(11 * (13 * 2 + 2) + 2)
    @test h.xppm === h.yppm === Int32(fld(96 * 1000, 25.4))
    @test h.colors_used === UInt32(0)
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 0

    img = read_bmp(bmppath("xrgb1555_v3"))
    ImageMagick.save(outpath("xrgb1555_v3.png"), img)

    imgr = ImageMagick.load(bmppath("xrgb1555_v3"))
    # ImageMagick seems to have inaccurate rounding.
    @test all(img .≈ ImageMagick.load(bmppath("xrgb1555_v3")))
end

@testset "rgb888_os2" begin
    h = read_bmp_header(bmppath("rgb888_os2"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_01d4
    @test h.offset === 0x0000_001a
    @test h.headersize === UInt32(12)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(24)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(0)
    @test h.xppm === Int32(0)
    @test h.yppm === Int32(0)
    @test h.colors_used === UInt32(0)
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 0

    img = read_bmp(bmppath("rgb888_os2"))
    ImageMagick.save(outpath("rgb888_os2.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_os2"))
end

@testset "rgb888_idx8_55x_os2" begin
    h = read_bmp_header(bmppath("rgb888_idx8_55x_os2"))

    @test h.signature === UInt16('B') | bswap(UInt16('M'))
    @test h.filesize === 0x0000_03cc
    @test h.offset === 0x0000_031a
    @test h.headersize === UInt32(12)
    @test h.width === Int32(13)
    @test h.height === Int32(11)
    @test h.planes === 0x0001
    @test h.bitcount === UInt16(8)
    @test h.compression === BMPImages.BI_RGB
    @test h.imagesize === UInt32(0)
    @test h.xppm === Int32(0)
    @test h.yppm === Int32(0)
    @test h.colors_used === UInt32(0) # => 256
    @test h.colors_important === UInt32(0)

    @test length(h.colortable) == 256
    @test h.colortable[1] === RGB{N0f8}(0.22, 0.596, 0.149)
    @test h.colortable[55] === RGB{N0f8}(1, 1, 1)
    @test h.colortable[256] === RGB{N0f8}(1, 1, 1)

    img = read_bmp(bmppath("rgb888_idx8_55x_os2"))
    ImageMagick.save(outpath("rgb888_idx8_55x_os2.png"), img)

    @test img == ImageMagick.load(bmppath("rgb888_idx8_55x_os2"))
end

@testset "testimages" begin
    img = read_bmp(bmppath("barbara_gray_512"))
    @test img isa Matrix{RGB{N0f8}}
    @test size(img) == (512, 512)
    ImageMagick.save(outpath("barbara_gray_512.png"), img)

    @test img == ImageMagick.load(bmppath("barbara_gray_512"))
end

@testset "safety against wrong values" begin
    wrong = IOBuffer(read(bmppath("rgb888_v3")), read=true, write=true)
    write(seek(wrong, 0x0002), 0x01:0x04) # filesize
    write(seek(wrong, 0x0022), 0x0a:0x0d) # imagesize
    write(seek(wrong, 0x00d5), 0x55) # padding

    h = read_bmp_header(seekstart(wrong))
    @test h.filesize === 0x04030201
    @test h.imagesize === 0x0d0c0b0a

    img = read_bmp(seekstart(wrong))

    @test img == read_bmp(bmppath("rgb888_v3"))
end

@testset "broken header" begin
    header = read(bmppath("rgb888_v3"), 0x36)
    E = ErrorException
    rh(io) = read_bmp_header(seekstart(io))

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x0000), [0x4d, 0x42])
    @test_throws E("invalid signature: 0x424d") rh(broken)

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x0006), 0x00100000)
    @test_throws E("broken bitmap header") rh(broken)

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x000a), 0x35)
    @test_throws E("invalid offset") rh(broken)

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x000e), 0x20)
    @test_throws E("unsupported info header size: 0x00000020") rh(broken)

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x001a), 0x02)
    @test_throws E("unsupported planes: 2") rh(broken)

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x001c), 0x02)
    @test_throws E("unsupported bitcount: 2") rh(broken)

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x0016), 0xffffffff)
    write(seek(broken, 0x001e), 0x01)
    @test_throws E("invalid compression mode: 0x00000001") rh(broken)

    broken = IOBuffer(copy(header), read=true, write=true)
    write(seek(broken, 0x001e), 0x05)
    @test_throws E("unsupported compression mode: 0x00000005") rh(broken)

    @test_throws EOFError read_bmp(IOBuffer(header))
end
