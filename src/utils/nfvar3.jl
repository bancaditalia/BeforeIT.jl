using LinearAlgebra

"""
This algorithm goes for accuracy without worrying about memory requirements. (simplified version from Dynare)
- `ydata`: dependent variable data matrix
- `xdata`: exogenous variable data matrix
- `lags`: number of lags
- `breaks`: rows in ydata and xdata after which there is a break. This allows for discontinuities in the data (e.g. war years) and for the possibility of adding dummy observations to implement a prior. This must be a column vector. Note that a single dummy observation becomes lags+1 rows of the data matrix, with a break separating it from the rest of the data. The function treats the first lags observations at the top and after each "break" in ydata and xdata as initial conditions.
- `lambda`: weight on "co-persistence" prior dummy observations. This expresses belief that when data on *all* y's are stable at their initial levels, they will tend to persist at that level. lambda=5 is a reasonable first try. With lambda<0, the constant term is not included in the dummy observation, so that stationary models with means equal to initial ybar do not fit the prior mean. With lambda>0, the prior implies that large constants are unlikely if unit roots are present.
- `mu`: weight on "own persistence" prior dummy observation. Expresses belief that when y_i has been stable at its initial level, it will tend to persist at that level, regardless of the values of other variables. There is one of these for each variable. A reasonable first guess is mu=2.
The program assumes that the first lags rows of ydata and xdata are real data, not dummies. Dummy observations should go at the end, if any. If pre-sample x's are not available, repeating the initial xdata(lags+1,:) row or copying xdata(lags+1:2*lags,:) into xdata(1:lags,:) are reasonable substitutes. These values are used in forming the persistence priors.
- `var.snglty`: 0 usually. If the rhs variable matrix is less than full column rank, this is the amount by which it falls short. Coefficients and residuals are computed with a form of generalized inverse in this case.
"""
function rfvar3(ydata::Matrix, lags::Union{Int, Int64}, xdata::Matrix)
    T, nvar = size(ydata)
    nox = isempty(xdata)
    T2, _ = size(xdata)
    # note that x must be same length as y, even though first part of x will not be used.
    # This is so that the lags parameter can be changed without reshaping the xdata matrix.
    if T2 != T
        println("Mismatch of x and y data lengths")
    end
    smpl = [((lags + 1):T);]
    Tsmpl = size(smpl, 1)
    X = zeros(typeFloat, Tsmpl, nvar, lags)

    for is in eachindex(smpl)
        X[is, :, :] = ydata[smpl[is] .- (1:lags), :]'
    end

    X = [reshape(X, Tsmpl, nvar * lags) xdata[smpl, :]]
    y = ydata[smpl, :]

    vl, di, vr = svd(X, full = false)
    dfx = sum(di .> 100 * eps())
    snglty = size(X, 2) - dfx
    di = 1.0 ./ di[1:dfx]
    vl = vl[:, 1:dfx]
    vr = vr[:, 1:dfx]
    B = vl' * y
    B = (vr * diagm(di)) * B
    u = y - X * B
    xxi = vr * diagm(di)
    xxi = xxi * xxi'
    B = reshape(B, nvar * lags + size(xdata, 2), nvar) # rhs variables, equations
    By = B[1:(nvar * lags), :]
    By = reshape(By, nvar, lags, nvar) # variables, lags, equations
    By = permutedims(By, [3, 1, 2]) # equations, variables, lags to match impulsdt.m
    if nox
        Bx = []
    else
        Bx = copy(B[nvar * lags .+ (1:size(xdata, 2)), :]')
    end
    return (By = By, Bx = Bx, u = u, xxi = xxi, snglty = snglty)
end
