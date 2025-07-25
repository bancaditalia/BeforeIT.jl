
function fshuffle!(vec)
    rng = Random.default_rng()
    for i in 2:length(vec)
        endi = (i-1) % UInt
        j = @inline rand(rng, Random.Sampler(rng, UInt(0):endi, Val(1))) % Int + 1
        vec[i], vec[j] = vec[j], vec[i]
    end
    vec
end

function ufilter!(cond, vec)
    @inbounds for i in length(vec):-1:1
        if !cond(vec[i])
            vec[i], vec[end] = vec[end], vec[i]
            pop!(vec)
        end
    end
    return vec
end
