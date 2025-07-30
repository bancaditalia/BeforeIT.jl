module BeforeITFormat

import BeforeIT as Bit

using Runic

function Bit.format_package(; check=false)
    root_dir = joinpath(@__DIR__, "..", "..")
    for (root, dirs, files) in walkdir(root_dir)
        for file in files
            if endswith(file, ".jl")
                if check
                    if Runic.main(["--check", "$(joinpath(root, file))"]) == 1
                        return false
                    end
                else
                    Runic.format_file(joinpath(root, file); inplace = true)
                end
            end
        end
    end
    return true
end

end
