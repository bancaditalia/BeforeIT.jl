
"""
weighted sampling single implementation
"""
function wsample_single(a, w)
    stop_w = rand() * sum(w)
    partial_w = 0.0
    j = 1
    for i in 1:length(w)
        @inbounds partial_w += w[i]
        if partial_w > stop_w
            j = i
            break
        end
    end
    return @inbounds a[j]
end
