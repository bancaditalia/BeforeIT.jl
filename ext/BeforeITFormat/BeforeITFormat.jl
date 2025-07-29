module BeforeITFormat

import BeforeIT as Bit

using Runic

function Bit.format_package()
    root_dir = joinpath(@__DIR__, "..", "..")
    for (root, dirs, files) in walkdir(root_dir)
        for file in files
            endswith(file, ".jl") && Runic.format_file(joinpath(root, file); inplace = true)
        end
    end
    return
end

end
