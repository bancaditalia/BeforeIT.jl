
"""
weighted sampling single implementation
"""
function wsample_single(a, w)
    stop_w = rand() * sum(w)
    partial_w = first(w)
    j = 1
    for i in 2:length(w)
        @inbounds partial_w += w[i]
        if partial_w > stop_w
            j = i - 1
            break
        end
    end
    return a[j]
end
