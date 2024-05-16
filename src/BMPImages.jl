"""
BMPImages provides the I/O support for Windows Bitmap (*.bmp) files.

# APIs
- [`read_bmp`](@ref)
- [`read_bmp_header`](@ref)
- [`write_bmp`](@ref)
- [`add_bmp_format`](@ref)
"""
module BMPImages

@static if !isdefined(Base, :get_extension)
    using Requires
end

using Colors
using Colors.FixedPointNumbers

export BMPImageHeader, read_bmp, read_bmp_header, write_bmp
export add_bmp_format

include("utilities.jl")

const BMP_MAGIC = 0x4d42 # "BM"

"""
    BMPImages.XYZq1f30 <: Color3{Q1f30}

XYZ color type with component type `Q1f30`.

# Fields
```julia
x :: Q1f30
y :: Q1f30
z :: Q1f30
```

# Examples
```jldoctest; filter=r"([01]\\.\\d)(?=[^,\\)]*,?\\s?)" => s"\\1,"
julia> using Colors;

julia> d65 = BMPImages.XYZq1f30(0.95047, 1.0, 1.08883)
XYZq1f30(0.9504699996Q1f30,1.0Q1f30,1.0888299998Q1f30)

julia> XYZ(d65.x, d65.y, d65.z)
XYZ{Float32}(0.95047f0,1.0f0,1.08883f0)
```
"""
struct XYZq1f30 <: Color3{Q1f30}
    x::Q1f30
    y::Q1f30
    z::Q1f30
end
XYZq1f30() = XYZq1f30(0, 0, 0)

"""
    BMPImages.XYZTriple

A type for RGB color primaries.

# Fields
```julia
red :: XYZq1f30
green :: XYZq1f30
blue :: XYZq1f30
```
"""
struct XYZTriple
    red::XYZq1f30
    green::XYZq1f30
    blue::XYZq1f30
end
XYZTriple() = XYZTriple(XYZq1f30(), XYZq1f30(), XYZq1f30())

"""
    BMPImages.Compression{id}

A singleton type for compression mode.

# Defined instances
- `BI_RGB`
- `BI_RLE8`
- `BI_RLE4`
- `BI_BITFIELDS`
- `BI_JPEG`
- `BI_PNG`
"""
struct Compression{id} end
const BI_RGB = Compression{0x00000000}()
const BI_RLE8 = Compression{0x00000001}()
const BI_RLE4 = Compression{0x00000002}()
const BI_BITFIELDS = Compression{0x00000003}()
const BI_JPEG = Compression{0x00000004}()
const BI_PNG = Compression{0x00000005}()

id(::Compression{i}) where {i} = i::UInt32

"""
    BMPImageHeader

A mutable struct that holds the file header, information header, and color table
for a bitmap.

The order and type of fields roughly follow the original specifications.

For details, see
[the document](https://learn.microsoft.com/windows/win32/gdi/bitmap-storage)
provided by Microsoft

# Fields
```julia
signature :: UInt16
filesize :: UInt32
offset :: UInt32
headersize :: UInt32
width :: Int32
height :: Int32
planes :: UInt16
bitcount :: UInt16
compression :: BMPImages.Compression
imagesize :: UInt32
xppm :: Int32
yppm :: Int32
colors_used :: UInt32
colors_important :: UInt32
red_mask :: UInt32
green_mask :: UInt32
blue_mask :: UInt32
alpha_mask :: UInt32
colorspace :: UInt32
endpoints :: XYZTriple
gamma_red :: Q15f16
gamma_green :: Q15f16
gamma_blue :: Q15f16
intent :: UInt32
profile_offset :: UInt32
profile_size :: UInt32
colortable :: Vector{<:Colorant}
profile :: Vector{UInt8}
```
"""
Base.@kwdef mutable struct BMPImageHeader
    # BITMAPFILEHEADER
    signature::UInt16 = BMP_MAGIC
    filesize::UInt32 = 0
    offset::UInt32 = 0
    # BITMAPCOREHEADER
    headersize::UInt32 = 0
    width::Int32 = 0
    height::Int32 = 0
    planes::UInt16 = 0
    bitcount::UInt16 = 0
    # BITMAPINFOHEADER
    compression::Compression = BI_RGB
    imagesize::UInt32 = 0
    xppm::Int32 = 0
    yppm::Int32 = 0
    colors_used::UInt32 = 0
    colors_important::UInt32 = 0
    # BITMAPV4HEADER
    red_mask::UInt32 = 0
    green_mask::UInt32 = 0
    blue_mask::UInt32 = 0
    alpha_mask::UInt32 = 0
    colorspace::UInt32 = 0
    endpoints::XYZTriple = XYZTriple()
    gamma_red::Q15f16 = 0
    gamma_green::Q15f16 = 0
    gamma_blue::Q15f16 = 0
    # BITMAPV5HEADER
    intent::UInt32 = 0
    profile_offset::UInt32 = 0
    profile_size::UInt32 = 0

    colortable::Vector{<:Colorant} = RGB{N0f8}[]
    profile::Vector{UInt8} = UInt8[]
end

function get_version(headersize::UInt32)
    headersize == 0x0c && return :BITMAPCOREHEADER
    headersize == 0x28 && return :BITMAPINFOHEADER
    headersize == 0x6c && return :BITMAPV4HEADER
    headersize == 0x7c && return :BITMAPV5HEADER
    return :unknown
end

function axis_y(image, header)
    header.height < 0 ? axes(image, 1) : Iterators.reverse(axes(image, 1))
end

include("read.jl")
include("write.jl")

"""
    BMPImages.load(f::File{format"BMP"}; kwargs...)
    BMPImages.load(s::Stream{format"BMP"}; kwargs...)

This function is an interface for `FileIO` and is available only if `FileIO` is
loaded.
Use [`read_bmp`](@ref) instead if there is no special reason.
"""
function load end

"""
    BMPImages.save(f::File{format"BMP"}, image; kwargs...)
    BMPImages.save(s::Stream{format"BMP"}, image; kwargs...)

This function is an interface for `FileIO` and is available only if `FileIO` is
loaded.
Use [`write_bmp`](@ref) instead if there is no special reason.
"""
function save end

"""
    add_bmp_format()

Register `format"BMP"` to `FileIO` specifying `BMPImages` as the primary
provider of the loader/saver.

!!! warning
    This function forcefully rewrites the internal registry of `FileIO`.
"""
function add_bmp_format end


@static if !isdefined(Base, :get_extension)
    function __init__()
        @require FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549" include("../ext/BMPImagesFileIOExt.jl")
    end
end

end # module BMPImages
