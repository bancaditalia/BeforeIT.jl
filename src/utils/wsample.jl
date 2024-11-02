
"""
weighted sampling single implementation
"""
function wsample_single(a, w, wsum)
    stop_w = rand() * wsum
    partial_w = 0.0
    j = 1
    for i in eachindex(w)
        partial_w += w[i]
        if partial_w > stop_w
            j = i
            break
        end
    end
    return @inbounds a[j]
end

"""
weighted sampling single implementation - v2

Based on https://www.aarondefazio.com/tangentially/?p=58
"""
function wsample_single_2(a, w, wmax)
    n = length(w)
    idx = rand(1:n)
    u = wmax * rand()
    while u > w[idx]
	idx = rand(1:n)
	u = wmax * rand()
    end
    return idx
end
