#BIAS_TTEST: One-sample t-test for forecast bias with Newey-West (HAC) standard errors.
#
#   Tests H₀: E[eₜ] = 0, i.e. whether the mean forecast error is significantly
#   different from zero. Uses the same Newey-West variance estimator as the
#   Diebold-Mariano test to account for autocorrelation in multi-step-ahead
#   forecast errors.
#
#   'errors' is a 'T-by-1' vector of forecast errors (forecast - actual)
#   'h'      is the forecast horizon (default 1), used as the truncation lag
#            for the Newey-West estimator (MA(h-1) autocorrelation structure)
#
#   Returns:
#       't_stat'   the t-statistic
#       'p_value'  two-sided p-value from N(0,1)
#
function bias_ttest(errors::Vector{Float64}, h::Int = 1)
    n = length(errors)
    d = errors

    # Newey-West variance estimate (same structure as DM test)
    if h > 1
        gamma = [cov(d[1:(end - i)], d[(1 + i):end]) for i in 0:(h - 1)] / n
        varD = gamma[1] + 2 * sum(gamma[2:h])
    else
        varD = var(d)
    end

    # Deal with a negative long-run variance estimate by replacing with short-run
    if varD < 0
        varD = var(d)
    end

    t_stat = mean(d) / sqrt(varD / n)
    p_value = 2 * cdf(Normal(0, 1), -abs(t_stat))

    return t_stat, p_value
end
