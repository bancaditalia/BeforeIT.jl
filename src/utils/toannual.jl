
"""
Calculate the annual sum of values in the input array `ftsa` by grouping them into blocks of size `m=4`.

Parameters
----------
ftsa : Array
    An input array containing the values to be grouped into annual sums.
    
Returns
-------
fts : Array
    An array containing the annual sums of values from `ftsa`. The array has the same number of rows as `ftsa` and a number of columns equal to the number of columns in `ftsa` divided by `m`.
    
Examples
--------
julia
fts = toannual([1 2 3 4 5 6 7 8])
# Output: [10 26]
end
"""
function toannual(ftsa)
    m = 4
    fts = zeros(size(ftsa, 1), div(size(ftsa, 2), m))

    if size(ftsa, 1) > 1
        for i in 1:m:size(ftsa, 2)
            fts[:, div(i, m) + 1] = sum(ftsa[:, i:min(i + m - 1, end)], dims = 2)
        end
    else
        for i in 1:m:size(ftsa, 2)
            fts[div(i, m) + 1] = sum(ftsa[i:min(i + m - 1, end)])
        end
    end

    return fts
end

function toannual_mean(ftsa)
    m = 4
    fts = zeros(size(ftsa, 1), div(size(ftsa, 2), m))

    if size(ftsa, 1) > 1
        for i in 1:m:size(ftsa, 2)
            fts[:, div(i, m) + 1] = mean(ftsa[:, i:min(i + m - 1, end)], dims = 2)
        end
    else
        for i in 1:m:size(ftsa, 2)
            fts[div(i, m) + 1] = mean(ftsa[i:min(i + m - 1, end)])
        end
    end

    return fts
end
