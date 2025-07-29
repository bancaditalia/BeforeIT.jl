"""

    randpl(n, alpha, N)

Generates n observations distributed as powerlaw
"""
function randpl(n::Integer, alpha::Float64, N::Integer)
    @assert alpha>=1 "alpha must be greater than or equal to 1"

    exponent = (-1 / (alpha - 1))
    x = (1 .- rand(n)) .^ exponent
    x = round.(Int, x ./ sum(x) * N)
    x[x .< 1] .= 1
    dx = sum(x) - N

    while dx != 0
        if dx < 0
            id = randperm(length(x))[1:abs(dx)]
            x[id] .+= 1
        elseif dx > 0
            id = findall(x .> 1)
            id = id[randperm(length(id))[1:Int(min(abs(dx), length(id)))]]
            x[id] .-= 1
        end
        dx = sum(x) - N
    end

    return x
end
