
@static if VERSION >= v"1.5"
    _peek(io::IO) = peek(io)
else
    function _peek(io::IO)
        b = read(io, UInt8)
        skip(io, -1)
        return b
    end
end

align32(nbytes) = (UInt32(nbytes) + 0x3) >> 0x2 << 0x2
align32_cld2(width) = align32((UInt32(width) + 0x1) >> 0x1)
align32_cld8(width) = align32((UInt32(width) + 0x7) >> 0x3)

pad32(nbytes) = -UInt32(nbytes) & 0x3
pad32_cld2(width) = pad32((UInt32(width) + 0x1) >> 0x1)
pad32_cld8(width) = pad32((UInt32(width) + 0x7) >> 0x3)

# for sort functions
by_raw(c::RGB24) = reinterpret(UInt32, c)

function grayscaletable(depth)
    depth == 1 && return [Gray{N0f8}(0), Gray{N0f8}(1)]
    depth == 4 && return [Gray{N0f8}(reinterpret(N0f8, i)) for i in 0x00:0x11:0xff]
    depth == 8 && return [Gray{N0f8}(reinterpret(N0f8, i)) for i in 0x00:0xff]
    error("unsupported bit depth")
end

_clamp01nan(x) = x > zero(x) ? min(x, oneunit(x)) : zero(x)

function xrgb1555_to_xrgb8888(rgb16::UInt16)
    r = (rgb16 >> 0xa) % UInt8
    g = (rgb16 >> 0x5) % UInt8
    b = (rgb16 >> 0x0) % UInt8
    rgb555 = (r, g, b) .& 0x1f
    r8, g8, b8 = ((rgb555 .* 0x083a .+ 0x0080) .>> 0x8) .% UInt8
    return (UInt32(r8) << 0x10) | (UInt32(g8) << 0x8) | UInt32(b8)
end

function xrgb8888_to_xrgb1555(rgb32::UInt32)
    r8 = (rgb32 >> 0x10) % UInt8
    g8 = (rgb32 >> 0x08) % UInt8
    b8 = (rgb32 >> 0x00) % UInt8
    r5, g5, b5 = ((r8, g8, b8) .* 0x00f9 .+ 0x0400) .>> 0xb
    return (r5 << 0xa) | (g5 << 0x5) | b5
end

function argb1555_to_argb8888(rgb16::UInt16)
    alpha = ((rgb16 % Int16) >> 0xf) % UInt8
    return xrgb1555_to_xrgb8888(rgb16) | bswap(UInt32(alpha))
end

function argb8888_to_argb1555(rgb32::UInt32)
    alpha = ((rgb32 >> 0x1f) % UInt16) << 0xf
    return xrgb8888_to_xrgb1555(rgb32) | alpha
end


function xrgb8888_to_rgb(::Type{C}, xrgb::UInt32) where {C <: AbstractRGB}
    C(reinterpret(RGB24, xrgb))
end

function xrgb8888_to_rgb(::Type{C}, xrgb::UInt32) where {C <: Union{XRGB, RGBX}}
    CC =  isconcretetype(C) ? C : base_color_type(C){N0f8}
    A = ccolor(C <: XRGB ? ARGB : RGBA, CC)
    argb = A(reinterpret(ARGB32, xrgb))
    GC.@preserve argb begin
        p::Ptr{CC} = pointer_from_objref(Ref(argb))
        return unsafe_load(p)
    end
end
