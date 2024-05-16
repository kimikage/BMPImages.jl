module BMPImagesFileIOExt

isdefined(Base, :get_extension) ? (using FileIO) : (using ..FileIO)

using UUIDs
using BMPImages

function BMPImages.load(f::File{format"BMP"}; kwargs...)
    open(f, "r") do s
        BMPImages.load(s; kwargs...)
    end
end

function BMPImages.load(s::Stream{format"BMP"}; kwargs...)
    read_bmp(stream(s); kwargs...)
end

function BMPImages.save(f::File{format"BMP"}, data; kwargs...)
    open(f, "w") do s
        BMPImages.save(s, data; kwargs...)
    end
end

function BMPImages.save(s::Stream{format"BMP"}, data; kwargs...)
    write_bmp(stream(s), data; kwargs...)
end

function BMPImages.add_bmp_format()
    local loaders = []
    local savers = []
    try
        del_format(format"BMP")
        if isdefined(FileIO, :applicable_loaders)
            list = FileIO.applicable_loaders(:BMP)
            loaders = unique(list)
            resize!(list, 0)
        end
        if isdefined(FileIO, :applicable_savers)
            list = FileIO.applicable_savers(:BMP)
            savers = unique(list)
            resize!(list, 0)
        end
    catch
    end
    add_format(
        format"BMP",
        UInt8[0x42,0x4d],
        [".bmp", ".BMP", ".dib", ".DIB", ".rle", ".RLE"],
        [:BMPImages => UUID("6eb60396-1cd7-48e0-9b1b-c01b15227c0d")]
    )
    try
        if isdefined(FileIO, :applicable_loaders) && !isempty(loaders)
            append!(FileIO.applicable_loaders(:BMP), loaders)
        end
        if isdefined(FileIO, :applicable_savers) && !isempty(savers)
            append!(FileIO.applicable_savers(:BMP), savers)
        end
    catch
    end
end

end # module BMPImagesFileIOExt
