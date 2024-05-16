"""
    BMPImages.write_rgb888(io, c)

Write the color `c` to `io` as RGB888.
"""
function write_rgb888(io::IO, c::Colorant)
    rgb24 = reinterpret(UInt32, convert(RGB24, c))
    write(io, htol(rgb24 % UInt16))
    write(io, (rgb24 >> 0x10) % UInt8)
    return 3
end

"""
    BMPImages.write_xrgb8888(io, c)

Write the color `c` to `io` as XRGB8888.
"""
function write_xrgb8888(io::IO, c::Colorant)
    rgb24 = reinterpret(UInt32, convert(RGB24, c))
    write(io, htol(rgb24))
end

"""
    BMPImages.write_argb8888(io, c)

Write the color `c` to `io` as ARGB8888.
"""
function write_argb8888(io::IO, c::Colorant)
    argb32 = reinterpret(UInt32, convert(ARGB32, c))
    write(io, htol(argb32))
end

"""
    BMPImages.write_xrgb1555(io, c)

Write the color `c` to `io` as XRGB1555.
"""
function write_xrgb1555(io::IO, c::Colorant)
    rgb = convert(RGB{Float32}, c)
    r, g, b = _clamp01nan.((red(rgb), green(rgb), blue(rgb)) .* Float32(31 * 256 / 255))
    r5, g5, b5 = unsafe_trunc.(UInt16, (r, g, b))
    rgb16 = (r5 << 0xa) | (g5 << 0x5) | b5
    write(io, htol(rgb16))
end

function write_xrgb1555(io::IO, c::Union{AbstractRGB{N0f8}, AbstractGray{N0f8}})
    rgb24 = reinterpret(UInt32, convert(RGB24, c))
    rgb16 = xrgb8888_to_xrgb1555(rgb24)
    write(io, htol(rgb16))
end

function write_xrgb1555(io::IO, c::Union{AbstractRGB{N3f5}, AbstractGray{N3f5}})
    rgb = c isa AbstractGray ? RGB{N3f5}(c) : c
    r5, g5, b5 = UInt16.(min.(reinterpret.(UInt8, (red(rgb), green(rgb), blue(rgb))), 0x1f))
    rgb16 = (r5 << 0xa) | (g5 << 0x5) | b5
    write(io, htol(rgb16))
end

"""
    BMPImages.gen_colortable_from_image(image) -> Vector{C}

Generate a color table based on the colors used in `image`.

The element type `C` of the return value is selected from `RGB24`, `Gray{N0f8}`,
or `Gray{Bool}`.

If more than 256 colors are used, an empty array is returned.
"""
function gen_colortable_from_image(image::AbstractMatrix{C}) where {C <: Colorant}
    RGB24[]
end

function gen_colortable_from_image(image::AbstractMatrix{C}) where {C <: Color}
    table = resize!(Vector{RGB24}(undef, 256), 0)
    for c in image
        rgb24 = convert(RGB24, c)
        i = searchsortedfirst(table, rgb24; by=by_raw)
        if i <= length(table)
            @inbounds table[i] === rgb24 && continue
        end
        length(table) < 256 || return RGB24[]
        insert!(table, i, rgb24)
    end
    return table
end

function gen_colortable_from_image(image::AbstractMatrix{C}) where {C <: AbstractGray}
    depth = 1
    for g in image
        u8 = reinterpret(UInt8, gray(Gray{N0f8}(g)))
        if depth == 1
            (u8 === 0x00 || u8 === 0xff) && continue
            depth = 4
        end
        u8 === (u8 & 0xf) * 0x11 && continue
        depth = 8
        break
    end
    return grayscaletable(depth)
end

function gen_colortable_from_image(image::AbstractMatrix{C}) where {C <: AbstractGray{Bool}}
    return Gray{Bool}[0, 1]
end

"""
    BMPImages.write_bmp_rgb888(io, image, header)

Save the `image` to `io` as 24-bit RGB bitmap image.
"""
function write_bmp_rgb888(io::IO,
    image::AbstractMatrix{C}, header::BMPImageHeader) where {C <: Colorant}

    pad = fill(0x00, pad32(header.width * 3))

    for y in axis_y(image, header)
        for x in axes(image, 2)
            write_rgb888(io, @inbounds image[y, x])
        end
        write(io, pad)
    end
    return align32(header.width * 3) % Int * abs(header.height)
end

"""
    BMPImages.write_bmp_xrgb8888(io, image, header)

Save the `image` to `io` as 32-bit XRGB bitmap image.
"""
function write_bmp_xrgb8888(io::IO,
    image::AbstractMatrix{C}, header::BMPImageHeader) where {C <: Colorant}

    for y in axis_y(image, header)
        for x in axes(image, 2)
            write_xrgb8888(io, @inbounds image[y, x])
        end
    end
    return align32(header.width * 4) % Int * abs(header.height)
end

"""
    BMPImages.write_bmp_xrgb1555(io, image, header)

Save the `image` to `io` as 16-bit XRGB (X1 R5 G5 B5) bitmap image.
"""
function write_bmp_xrgb1555(io::IO,
    image::AbstractMatrix{C}, header::BMPImageHeader) where {C <: Colorant}

    pad = fill(0x00, pad32(header.width * 2))

    for y in axis_y(image, header)
        for x in axes(image, 2)
            write_xrgb1555(io, @inbounds image[y, x])
        end
        write(io, pad)
    end
    return align32(header.width * 2) % Int * abs(header.height)
end

"""
    BMPImages.write_bmp_idx8(io, image, header)

Save the `image` to `io` as 8-bit indexed color image.
"""
function write_bmp_idx8(io::IO,
    image::AbstractMatrix{C}, header::BMPImageHeader) where {C <: Colorant}

    pad = fill(0x00, pad32(header.width))
    if C <: AbstractGray
    else
        table = header.colortable::Vector{RGB24}
    end

    for y in axis_y(image, header)
        for x in axes(image, 2)
            if C <: AbstractGray
                g = convert(Gray{N0f8}, @inbounds image[y, x])
                write(io, reinterpret(UInt8, gray(g)))
            else
                rgb24 = convert(RGB24, @inbounds image[y, x])
                write(io, (searchsortedfirst(table, rgb24; by=by_raw) - 1) % UInt8)
            end
        end
        write(io, pad)
    end
    return align32(header.width) % Int * abs(header.height)
end

"""
    BMPImages.write_bmp_idx4(io, image, header)

Save the `image` to `io` as 4-bit indexed color image.
"""
function write_bmp_idx4(io::IO,
    image::AbstractMatrix{C}, header::BMPImageHeader) where {C <: Colorant}

    pad = fill(0x00, pad32_cld2(header.width))
    if C <: AbstractGray
    else
        table = header.colortable::Vector{RGB24}
    end

    for y in axis_y(image, header)
        i = 0x0
        idx = 0x00
        for x in axes(image, 2)
            i += 0x1
            if C <: AbstractGray
                g = convert(Gray{N0f8}, @inbounds image[y, x])
                idx |= reinterpret(UInt8, gray(g)) & 0xf
            else
                rgb24 = convert(RGB24, @inbounds image[y, x])
                idx |= (searchsortedfirst(table, rgb24; by=by_raw) - 1) % UInt8
            end
            iszero(i & 0x01) && write(io, idx)
            idx <<= 0x4
        end
        iszero(i & 0x01) || write(io, idx)
        write(io, pad)
    end
    return align32_cld2(header.width) % Int * abs(header.height)
end

"""
    BMPImages.write_bmp_idx1(io, image, header)

Save the `image` to `io` as 1-bit (binary) image.
"""
function write_bmp_idx1(io::IO,
    image::AbstractMatrix{C}, header::BMPImageHeader) where {C <: Colorant}

    pad = fill(0x00, pad32_cld8(header.width))
    if C <: AbstractGray
    else
        table = header.colortable::Vector{RGB24}
    end

    for y in axis_y(image, header)
        i = 0x0
        idx = 0x00
        for x in axes(image, 2)
            i += 0x1
            if C <: AbstractGray
                g = convert(Gray{Bool}, @inbounds image[y, x])
                idx |= gray(g)
            else
                rgb24 = convert(RGB24, @inbounds image[y, x])
                idx |= first(table) !== rgb24
            end
            iszero(i & 0x07) && write(io, idx)
            idx <<= 0x1
        end
        iszero(i & 0x07) || write(io, idx << (~i & 0x7))
        write(io, pad)
    end
    return align32_cld8(header.width) % Int * abs(header.height)
end

"""
    write_bmp(filepath::AbstractString, image; kwargs...)
    write_bmp(io::IO, image; kwargs...)

Write a image as a BMP image to the specified file or `IO` object.

# Keyword arguments
- `ppi::Real`: pixel density in pixels per inch
- `expand_paletted::Bool`: If `true`, the color table is not used regardless of
  the number of colors used. Default to `false`.

"""
function write_bmp(filepath::AbstractString, image; kwargs...)
    open(filepath, "w") do f
        write_bmp(f, image; kwargs...)
    end
end

function write_bmp(io::IO, image::AbstractMatrix{C};
    header::Union{BMPImageHeader, Nothing} = nothing,
    ppi::Real = 0.0,
    expand_paletted::Bool = false,
    kwargs...) where {C <: Colorant}

    u16(v::UInt16) = write(io, htol(v))
    u32(v::UInt32) = write(io, htol(v))
    i32(v::Int32) = write(io, htol(v))

    local h = BMPImageHeader()

    if expand_paletted
    else
        h.colortable = gen_colortable_from_image(image)
    end

    h.headersize = C <: Color ? 0x28 : 0x6c
    if header !== nothing
        h.headersize = header.headersize
    end
    local version = get_version(h.headersize)

    h.height, h.width = size(image)
    if version === :BITMAPCOREHEADER
        max(h.height, h.width) <= typemax(UInt16) || error("`image` is too large.")
    end

    h.planes = 0x0001
    ncolors = length(h.colortable)
    if ncolors == 0
        if C <: AbstractRGB{N3f5}
            h.bitcount = 16
            linesize = align32(h.width * 2)
        elseif C === RGB24
            h.bitcount = 32
            linesize = align32(h.width * 4)
        else
            h.bitcount = 24
            linesize = align32(h.width * 3)
        end
    elseif ncolors <= 2
        h.bitcount = 1
        linesize = align32_cld8(h.width)
    elseif ncolors <= 16
        h.bitcount = 4
        linesize = align32_cld2(h.width)
    else
        h.bitcount = 8
        linesize = align32(h.width)
    end
    tablesize = version === :BITMAPCOREHEADER ? ncolors * 3 : ncolors * 4
    h.offset = 0xe + h.headersize + tablesize

    coreimagesize = linesize * h.height
    h.filesize = align32(coreimagesize + h.offset)
    filepad = pad32(coreimagesize + h.offset)
    h.imagesize = UInt32(coreimagesize + filepad)

    if header !== nothing
        h.height = copysign(h.height, header.height)
    end

    if header !== nothing
        h.xppm = header.xppm
        h.yppm = header.yppm
    else
        # Some of the typical implementations do not seem to use `RoundNearest`.
        ppm = round(Int32, ppi * 1000 / 25.4, RoundToZero)
        h.xppm = ppm
        h.yppm = ppm
    end

    u16(h.signature)
    u32(h.filesize)
    u32(UInt32(0))
    u32(h.offset)

    function write_infoheader()
        u32(h.headersize)
        if version === :BITMAPCOREHEADER
            u16(h.width)
            u16(h.height)
        else
            i32(h.width)
            i32(h.height)
        end
        u16(h.planes)
        u16(h.bitcount)
        u32(id(h.compression))
        u32(h.imagesize)
        i32(h.xppm)
        i32(h.yppm)
        ncolors_max = 1 << h.bitcount
        colors_used = ncolors == ncolors_max ? UInt32(0) : UInt32(ncolors)
        colors_important = colors_used
        u32(colors_used)
        u32(colors_important)
    end
    write_infoheader()
    if h.compression === BI_RGB && ncolors > 0
        if version === :BITMAPCOREHEADER
            foreach(c -> write_rgb888(io, c), h.colortable)
        else
            foreach(c -> write_xrgb8888(io, c), h.colortable)
        end
    end
    bpp = Int(h.bitcount)
    if bpp == 24
        write_bmp_rgb888(io, image, h)
    elseif bpp == 8
        write_bmp_idx8(io, image, h)
    elseif bpp == 4
        write_bmp_idx4(io, image, h)
    elseif bpp == 1
        write_bmp_idx1(io, image, h)
    elseif bpp == 32 && h.compression === BI_RGB
        write_bmp_xrgb8888(io, image, h)
    elseif bpp == 16 && h.compression === BI_RGB
        write_bmp_xrgb1555(io, image, h)
    else
        error("unsupported bitcount: ": h.bitcount)
    end

    foreach(_ -> write(io, 0x00), 1:filepad)

    return h.filesize
end
