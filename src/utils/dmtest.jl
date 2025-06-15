
#DMTEST: Retrieves the Diebold-Mariano test statistic (1995) for the 
# equality of forecast accuracy of two forecasts under general assumptions.
#
#   DM = dmtest(e1, e2, ...) calculates the D-M test statistic on the base 
#   of the loss differential which is defined as the difference of the 
#   squared forecast errors
#
#   In particular, with the DM statistic one can test the null hypothesis: 
#   H0: E(d) = 0. The Diebold-Mariano test assumes that the loss 
#   differential process 'd' is stationary and defines the statistic as:
#   DM = mean(d) / sqrt[ (1/T) * VAR(d) ]  ~ N(0,1),
#   where VAR(d) is an estimate of the unconditional variance of 'd'.
#
#   This function also corrects for the autocorrelation that multi-period 
#   forecast errors usually exhibit. Note that an efficient h-period 
#   forecast will have forecast errors following MA(h-1) processes. 
#   Diebold-Mariano use a Newey-West type estimator for sample variance of
#   the loss differential to account for this concern.
#
#   'e1' is a 'T1-by-1' vector of the forecast errors from the first model
#   'e2' is a 'T2-by-1' vector of the forecast errors from the second model
#
#   It should hold that T1 = T2 = T.
#
#   DM = DMTEST(e1, e2, 'h') allows you to specify an additional parameter 
#   value 'h' to account for the autocorrelation in the loss differential 
#   for multi-period ahead forecasts.   
#       'h'         the forecast horizon, initially set equal to 1
#
#   DM = DMTEST(...) returns a constant:
#       'DM'      the Diebold-Mariano (1995) test statistic
#
#  Modified code from Semin Ibisevic (2011)
#  Steven Hoekstra
#  $Date: 13/08/2024 $
#
# -------------------------------------------------------------------------
# References
# K. Bouman. Quantitative methods in international finance and 
# macroeconomics. Econometric Institute, 2011. Lecture FEM21004-11.
# 
# Diebold, F.X. and R.S. Mariano (1995), "Comparing predictive accuracy", 
# Journal of Business & Economic Statistics, 13, 253-263.
# -------------------------------------------------------------------------
function dmtest_modified(e1::Vector{Float64}, e2::Vector{Float64}, h::Int=1)    
    # Check input arguments
    length(e1) != length(e2) && error("Vectors should be of equal length")

    # Initialization
    n = length(e1)

    # Define the loss differential
    d = abs.(e1).^2 .- abs.(e2).^2

    # Calculate the variance of the loss differential, taking into account autocorrelation
    if h > 1
        gamma = [cov(d[1:end-i], d[1+i:end]) for i in 0:h-1] / n
        varD = gamma[1] + 2 * sum(gamma[2:h])
    else
        varD = var(d)
    end

    # Deal with a negative long-run variance estimate by replacing it with the corresponding short-run variance estimate
    if varD < 0
        h = 1
        varD = var(d)
    end

    # k is calculated to adjust the statistic as per Harvey, Leybourne, and Newbold (1997)
    k = sqrt((n + 1 - 2 * h + (h * (h - 1)) / n) / n)

    # Retrieve the Diebold-Mariano statistic DM ~ N(0,1)
    DM = (mean(d) / sqrt(varD / n)) * k

    # Calculate p-value
    p_value = 2 * cdf(Normal(0, 1), -abs(DM))

    return DM, p_value
end