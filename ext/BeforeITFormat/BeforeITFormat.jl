
module BeforeITFormat

import BeforeIT as Bit

using Runic

function Bit.format_package()
    for (root, dirs, files) in walkdir(".")
        for file in files
            endswith(file, ".jl") && Runic.format_file(joinpath(root, file); inplace = true)
        end
    end
    return
end

end
