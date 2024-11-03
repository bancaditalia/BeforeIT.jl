
function pos!(A)
    @simd for i in eachindex(A)
        A[i] = ifelse(isnan(A[i]), zero(eltype(A)), max(zero(eltype(A)), A[i]))
    end
    return A
end
