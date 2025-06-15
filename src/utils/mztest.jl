
"""
    mztest(y::Vector{Float64}, x::Vector{Float64})

Conducts the Mincer-Zarnowitz test for forecast accuracy. 

# Arguments
- `y::Vector{Float64}`: A vector of actual values.
- `x::Vector{Float64}`: A vector of forecasted values.

# Returns
- `c::Float64`: Intercept of the regression model.
- `beta::Float64`: Slope of the regression model.
- `p_value::Float64`: p-value for the joint hypothesis test that the intercept is 0 and the slope is 1.

The MZ test, or the Mincer-Zarnowitz test, is a method used in econometrics to assess the accuracy of forecast models. 
It involves regressing the actual values on the forecasted values and checking the coefficients. 
Specifically, if the forecasts are unbiased and efficient, the intercept should be zero and the slope 
should be one in the regression of actual values on forecasted values. 
The test involves the following steps:

1. Estimate the Regression Model: Regress the actual values (y) on the forecasted values (x):

y_t = \alpha + \beta x_t + \epsilon_t

where y_t are the actual values, x_t are the forecasted values, \alpha is the intercept, \beta is the slope, and \epsilon_t is the error term.
2.  Test the Hypotheses:
•   Unbiasedness: Test the null hypothesis H_0: \alpha = 0.
•   Efficiency: Test the null hypothesis H_0: \beta = 1.

If the forecasts are unbiased and efficient, the intercept (\alpha) should be zero and the slope (\beta) should be one. 
The joint test can be conducted using an F-test.
"""
function mztest(y::Vector{Float64}, x::Vector{Float64})
    # Fit a linear model

    X = hcat(ones(length(x)), x)
    n, k = size(X)

    β = inv(X'X) * X'y

    # Calculate residuals
    residuals = y - X * β

    # Estimate variance of the residuals
    σ² = sum(residuals.^2) / (n - k)

    # Calculate standard errors of the coefficients
    var_β = σ² * inv(X'X)

    # Perform the Wald test for the hypothesis that both coefficients are equal to their respective values in the null hypothesis
    H0 = [0, 1]

    coef_diff = β.- H0
    test_statistic =  coef_diff' * inv(var_β) * coef_diff
    df = length(H0)  # Degrees of freedom
    p_value = 1 - cdf(Chisq(df), test_statistic)

    return β[1], β[2], p_value
end