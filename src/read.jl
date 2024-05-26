"""
    BMPImages.read_rgb888(io, C) -> C

Read an RGB888 color from `io`, and return it as `AbstractRGB` color `C`.
"""
function read_rgb888(io::IO, ::Type{C}) where {C <: AbstractRGB}
    b = reinterpret(N0f8, read(io, UInt8))
    g = reinterpret(N0f8, read(io, UInt8))
    r = reinterpret(N0f8, read(io, UInt8))
    return C(r, g, b)
end

"""
    BMPImages.read_xrgb8888(io, C) -> C

Read an XRGB8888 color from `io`, and return it as `AbstractRGB` color `C`.

!!! note
    This function does not care about the X8 value, i.e., does not actively mask
    it.

# Examples
```jldoctest
julia> using Colors;

julia> io = IOBuffer([0x12, 0x34, 0x56, 0xab]);

julia> reinterpret(UInt32, BMPImages.read_xrgb8888(io, RGB24))
0xab563412
```
"""
function read_xrgb8888(io::IO, ::Type{C}) where {C <: AbstractRGB}
    xrgb = ltoh(read(io, UInt32))
    return xrgb8888_to_rgb(C, xrgb)
end

"""
    BMPImages.read_argb8888(io, C) -> C

Read an ARGB8888 color from `io`, and return it as `TransparentRGB` color `C`.
"""
function read_argb8888(io::IO, ::Type{C}) where {C <: TransparentRGB}
    argb = ltoh(read(io, UInt32))
    return C(reinterpret(ARGB32, argb))
end

"""
    BMPImages.read_xrgb1555(io, C) -> C

Read an XRGB1555 color from `io`, and return it as `AbstractRGB` color `C`.

!!! note
    This function does not care about the X1 value, i.e., does not actively mask
    it.

# Examples
```jldoctest
julia> using Colors;

julia> io = IOBuffer([0x00, 0x80]);

julia> reinterpret(UInt32, BMPImages.read_xrgb1555(io, RGB24))
0xff000000
```
"""
function read_xrgb1555(io::IO, ::Type{C}) where {C <: AbstractRGB}
    xrgb = ltoh(read(io, UInt16))
    return xrgb8888_to_rgb(C, argb1555_to_argb8888(xrgb)) # keeps X1
end

"""
    read_bmp_header(filepath::AbstractString) -> BMPImageHeader
    read_bmp_header(io::IO) -> BMPImageHeader

Read the BMP image header from the specified file or `IO` object.
"""
function read_bmp_header(filepath::AbstractString)
    open(filepath, "r") do f
        return read_bmp_header(f)
    end
end

function read_bmp_header(io::IO)
    u16() = ltoh(read(io, UInt16))
    i32() = ltoh(read(io, Int32))
    u32() = ltoh(read(io, UInt32))
    q1f30() = reinterpret(Q1f30, u32())
    local h = BMPImageHeader()

    h.signature = u16()
    h.signature === BMP_MAGIC || error("invalid signature: " * repr(h.signature))
    h.filesize = u32()
    reserved32 = u32()
    reserved32 === UInt32(0) || error_broken_header()
    h.offset = u32()
    h.headersize = u32()
    local version = get_version(h.headersize)
    if version === :unknown
        error("unsupported info header size: " * repr(h.headersize))
    end
    h.offset >= (h.headersize + 0xe) || error("invalid offset")

    function read_infoheader()
        if version === :BITMAPCOREHEADER
            h.width = Int32(u16())
            h.height = Int32(u16())
        else
            h.width = i32()
            h.height = i32()
        end
        h.planes = u16()
        h.planes === 0x0001 || error("unsupported planes: $(h.planes)")
        h.bitcount = u16()
        if !(h.bitcount in (1, 4, 8, 16, 24, 32))
            error("unsupported bitcount: $(h.bitcount)")
        end
        version === :BITMAPCOREHEADER && return

        comp32 = u32()
        h.compression = Compression{comp32}()
        if h.height < 0
            if h.compression in (BI_RGB, BI_BITFIELDS)
            else
                error("invalid compression mode: " * repr(comp32))
            end
        end
        if h.compression === BI_RGB
        elseif h.compression === BI_RLE8 && h.bitcount == 8
        elseif h.compression === BI_RLE4 && h.bitcount == 4
        else
            error("unsupported compression mode: " * repr(comp32))
        end
        h.imagesize = u32()
        h.xppm = i32()
        h.yppm = i32()
        h.colors_used = u32()
        h.colors_important= u32()

        if version === :BITMAPINFOHEADER && h.compression === BI_BITFIELDS
            h.red_mask = u32()
            h.green_mask = u32()
            h.blue_mask = u32()
            return
        end
    end
    read_infoheader()

    if h.compression in (BI_RGB, BI_RLE8, BI_RLE4)
        max_table_size = h.offset - h.headersize - 0xe
        ncolors_max = Int64(1) << h.bitcount
        ncolors = iszero(h.colors_used) ? ncolors_max : Int(h.colors_used)
        if version !== :BITMAPCOREHEADER && max_table_size >= ncolors * 4
            table = [read_xrgb8888(io, RGB{N0f8}) for _ in 1:ncolors]
        elseif version === :BITMAPCOREHEADER && max_table_size >= ncolors * 3
            table = [read_rgb888(io, RGB{N0f8}) for _ in 1:ncolors]
        else
            table = RGB{N0f8}[]
        end
        # special handling for grayscale images
        C = eltype(table)
        if length(table) == ncolors_max && C <: AbstractRGB
            if all(c -> red(c) === green(c) === blue(c), table)
                if h.bitcount == 1
                    bw = Gray{Bool}[blue.(table)...]
                    if bw == Gray{Bool}[0, 1] || bw == Gray{Bool}[1, 0]
                        table = bw
                    end
                else
                    grayscale = grayscaletable(h.bitcount)
                    if all(((c, g),) -> blue(c) == gray(g), zip(table, grayscale))
                        table = grayscale
                    end
                end
            end
        end
        h.colortable = table
    end
    return h
end


"""
    BMPImages.read_bmp_rgb888!(io, image, header)

Load 24-bit RGB bitmap image from `io` to `image`.
"""
function read_bmp_rgb888!(io::IO,
    image::Matrix{C}, header::BMPImageHeader) where {C <: AbstractRGB}

    check_mat_size(image, header)

    for y in axis_y(image, header)
        for x in axes(image, 2)
            @inbounds image[y, x] = read_rgb888(io, C)
        end
        skip(io, pad32(header.width * 3))
    end
end

"""
    BMPImages.read_bmp_xrgb8888!(io, image, header)

Load 32-bit XRGB bitmap image from `io` to `image`.
"""
function read_bmp_xrgb8888!(io::IO,
    image::Matrix{C}, header::BMPImageHeader) where {C <: AbstractRGB}

    check_mat_size(image, header)

    for y in axis_y(image, header)
        for x in axes(image, 2)
            @inbounds image[y, x] = read_xrgb8888(io, C)
        end
    end
end

"""
    BMPImages.read_bmp_xrgb1555!(io, image, header)

Load 16-bit XRGB (X1 R5 G5 B5) bitmap image from `io` to `image`.
"""
function read_bmp_xrgb1555!(io::IO,
    image::Matrix{C}, header::BMPImageHeader) where {C <: AbstractRGB}

    check_mat_size(image, header)

    for y in axis_y(image, header)
        for x in axes(image, 2)
            @inbounds image[y, x] = read_xrgb1555(io, C)
        end
        skip(io, pad32(header.width * 2))
    end
end


"""
    BMPImages.gen_colortable(C, header) -> Vector{C}

Return a `Vector{C}` with the length of `2^n`, where `n` is the bit depth.
This function guards against out-of-range memory accesses caused by broken
bitmap files.
"""
function gen_colortable(::Type{C}, header::BMPImageHeader) where {C <: Colorant}
    table = Vector{C}(undef, 1 << header.bitcount)
    for (i, c) in enumerate(header.colortable)
        @inbounds table[i] = C(c)
    end
    return table
end

"""
    BMPImages.read_bmp_idx8!(io, image, header)

Load 8-bit indexed color image from `io` to `image`.
"""
function read_bmp_idx8!(io::IO,
    image::Matrix{C},
    header::BMPImageHeader) where {C <: Union{AbstractRGB, AbstractGray}}

    check_mat_size(image, header)
    table = gen_colortable(C, header)

    for y in axis_y(image, header)
        for x in axes(image, 2)
            idx = read(io, UInt8)
            @inbounds image[y, x] = table[idx + 1]
        end
        skip(io, pad32(header.width))
    end
end

"""
    BMPImages.read_bmp_idx4!(io, image, header)

Load 4-bit indexed color image from `io` to `image`.
"""
function read_bmp_idx4!(io::IO,
    image::Matrix{C},
    header::BMPImageHeader) where {C <: Union{AbstractRGB, AbstractGray}}

    check_mat_size(image, header)
    table = gen_colortable(C, header)

    for y in axis_y(image, header)
        i = 0x0
        idx = 0x00
        for x in axes(image, 2)
            idx = iszero(i & 0x1) ? read(io, UInt8) : idx << 0x4
            i += 0x1
            @inbounds image[y, x] = table[idx >> 0x4 + 1]
        end
        skip(io, pad32_cld2(header.width))
    end
end

"""
    BMPImages.read_bmp_idx1!(io, image, header)

Load 1-bit (binary) image from `io` to `image`.
"""
function read_bmp_idx1!(io::IO,
    image::Matrix{C},
    header::BMPImageHeader) where {C <: Union{AbstractRGB, AbstractGray}}

    check_mat_size(image, header)
    table = gen_colortable(C, header)

    for y in axis_y(image, header)
        i = 0x0
        idx = 0x00
        for x in axes(image, 2)
            idx = iszero(i & 0x7) ? read(io, UInt8) : idx << 0x1
            i += 0x1
            @inbounds image[y, x] = table[idx >> 0x7 + 1]
        end
        skip(io, pad32_cld8(header.width))
    end
end

function _read_bmp_rle!(depth::Union{Val{4}, Val{8}}, io::IO,
    image::Matrix{C},
    header::BMPImageHeader) where {C <: Union{AbstractRGB, AbstractGray}}

    check_mat_size(image, header)
    table = gen_colortable(C, header)

    local run::UInt8 = 0x00
    local runcount::UInt8 = 0x00
    local idx::UInt8 = 0x00
    local absolute::Bool = false
    local eob::Bool = false
    local eol::Bool = false
    local deltay::UInt8 = 0x00
    local dest_x::UInt32 = 0
    local i::UInt32 = 0
    function reset_ctx()
        absolute = false
        deltay = 0x00
        dest_x = 0
        run = 0x00
        runcount = 0x00
    end
    skipping() = (eol | eob) || deltay > 0x0 || i < dest_x
    function skip_pad()
        nbytes = depth === Val(4) ? (run + 0x1) >> 0x1 : run
        absolute && isodd(nbytes) && skip(io, 1)
    end

    for y in axis_y(image, header)
        eol = false
        absolute = false
        runcount = run # force reset
        deltay -= deltay > 0x00
        i = 0
        for x in axes(image, 2)
            if skipping()
            elseif run === runcount
                skip_pad()
                reset_ctx()
                b1 = read(io, UInt8)
                if b1 === 0x00
                    idx = 0x00
                    b2 = read(io, UInt8)
                    if b2 === 0x00 # end of line (before the actual EOL)
                        eol = true
                    elseif b2 === 0x01 # end of bitmap (before the actual EOB)
                        eob = true
                    elseif b2 === 0x02
                        deltax = read(io, UInt8)
                        deltay = read(io, UInt8)
                        iszero(deltax | deltay) && error("delta (0, 0) is not supported.")
                        dest_x = deltax + i - 0x1
                    else # absolute mode
                        absolute = true
                        run = b2
                        idx = read(io, UInt8)
                    end
                else # encoding mode
                    run = b1
                    idx = read(io, UInt8)
                end
            elseif absolute
                if depth === Val(4) && isodd(runcount)
                else
                    idx = read(io, UInt8)
                end
            end

            if depth === Val(4)
                idxn = isodd(runcount) ? idx & 0xf : idx >> 0x4
            else
                idxn = idx
            end
            @inbounds image[y, x] = table[idxn + 1]
            runcount += run > runcount
            i += 0x1
        end
        if !skipping()
            # For 4-bit images, some encoder implementations seem to extend
            # the buffer to an even width.
            if run === runcount || (depth === Val(4) && run === ((runcount + 0x1) & 0xfe))
                skip_pad()
            else
                error("invalid line termination")
            end
            b1 = read(io, UInt8)
            b2 = b1 === 0x00 ? read(io, UInt8) : 0xff
            b2 <= 0x01 || error("invalid line termination")
            eob = b2 === 0x01
        end
    end
    if !eob
        b1 = read(io, UInt8)
        b2 = b1 === 0x00 ? read(io, UInt8) : 0xff
        b2 === 0x01 || error("invalid bitmap termination")
    end
end

"""
    read_bmp_rle8!(io, image, header)

Load 8-bit RLE image from `io` to `image`.

!!! note
    In the RLE mode, some pixel value settings can be skipped.
    However, there is no clear specification on handling the skipped pixels.
    In this function, the skipped pixels are filled with the color of index `0`.
"""
function read_bmp_rle8!(io::IO,
    image::Matrix{C},
    header::BMPImageHeader) where {C <: Union{AbstractRGB, AbstractGray}}

    _read_bmp_rle!(Val(8), io, image, header)
end

"""
    read_bmp_rle4!(io, image, header)

Load 4-bit RLE image from `io` to `image`.

See also [`read_bmp_rle8!`](@ref).
"""
function read_bmp_rle4!(io::IO,
    image::Matrix{C},
    header::BMPImageHeader) where {C <: Union{AbstractRGB, AbstractGray}}

    _read_bmp_rle!(Val(4), io, image, header)
end

"""
    read_bmp(filepath::AbstractString; kwargs...)
    read_bmp(io::IO; kwargs...)

Read a BMP image from the specified file or `IO` object.

# Keyword arguments
not supported yet

# Return types
- `Matrix{RGB{N0f8}}`: default
- `Matrix{Gray{N0f8}}`: for 4-bit or 8-bit indexed grayscale images
- `Matrix{Gray{Bool}}`: for binary grayscale (black and white) images
"""
function read_bmp(filepath::AbstractString; kwargs...)
    open(filepath, "r") do f
        return read_bmp(f, kwargs...)
    end
end

function read_bmp(io::IO; kwargs...)
    b0 = _peek(io)
    pos = position(io)
    if b0 !== 0x42 && pos >= 2
        skip(io, -2)
        _peek(io) === 0x42 || seekstart(io)
        pos = position(io)
    end

    header = read_bmp_header(io)

    seek(io, pos + header.offset)

    C = eltype(header.colortable)
    image = Matrix{C}(undef, abs(header.height), header.width)

    bpp = Int(header.bitcount)
    compress = header.compression
    if bpp == 24
        read_bmp_rgb888!(io, image, header)
    elseif bpp == 8 && compress === BI_RGB
        read_bmp_idx8!(io, image, header)
    elseif bpp == 8 && compress === BI_RLE8
        read_bmp_rle8!(io, image, header)
    elseif bpp == 4 && compress === BI_RGB
        read_bmp_idx4!(io, image, header)
    elseif bpp == 4 && compress === BI_RLE4
        read_bmp_rle4!(io, image, header)
    elseif bpp == 1
        read_bmp_idx1!(io, image, header)
    elseif bpp == 32 && compress === BI_RGB
        read_bmp_xrgb8888!(io, image, header)
    elseif bpp == 16 && compress === BI_RGB
        read_bmp_xrgb1555!(io, image, header)
    else
        error("unsupported format")
    end
    return image
end

@noinline function check_mat_size(@nospecialize(image::AbstractMatrix), header::BMPImageHeader)
    h, w = size(image)
    h == abs(header.height) && w == header.width && return true
    error("size mismatch")
end

@noinline error_broken_header() = error("broken bitmap header")
