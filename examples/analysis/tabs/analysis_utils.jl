using Statistics, Distributions

function latexTableContent(input_data::Matrix{String}, tableRowLabels::Vector{String}, dataFormat::String, tableColumnAlignment, tableBorders::Bool, booktabs::Bool, makeCompleteLatexDocument::Bool)
    nrows, ncols = size(input_data)
    latex = []

    if makeCompleteLatexDocument
        push!(latex, "\\documentclass{article}")
        push!(latex, "\\begin{document}")
    end

    #push!(latex, "\\begin{table}")
    #push!(latex, "\\begin{tabular}{" * tableColumnAlignment * "}")

    if booktabs
        push!(latex, "\\toprule")
    end

    for row in 1:nrows
        row_content = [tableRowLabels[row]]
        for col in 1:ncols
            push!(row_content, input_data[row, col])
        end
        if row < nrows
            push!(latex, join(row_content, " & "), " \\\\ ")
        else
            push!(latex, join(row_content, " & "))
        end
    end

    if booktabs
        push!(latex, "\\bottomrule")
    end

    #push!(latex, "\\end{tabular}")
    #push!(latex, "\\end{table}")

    if makeCompleteLatexDocument
        push!(latex, "\\end{document}")
    end

    return latex
end

function mztest(y::Vector{Float64}, x::Vector{Float64})
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

	1.	Estimate the Regression Model: Regress the actual values (y) on the forecasted values (x):

    y_t = \alpha + \beta x_t + \epsilon_t

    where y_t are the actual values, x_t are the forecasted values, \alpha is the intercept, \beta is the slope, and \epsilon_t is the error term.
	2.	Test the Hypotheses:
	•	Unbiasedness: Test the null hypothesis H_0: \alpha = 0.
	•	Efficiency: Test the null hypothesis H_0: \beta = 1.

    If the forecasts are unbiased and efficient, the intercept (\alpha) should be zero and the slope (\beta) should be one. 
    The joint test can be conducted using an F-test.
    """

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

function dmtest_modified(e1::Vector{Float64}, e2::Vector{Float64}, h::Int=1)
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
    
        # Check input arguments
        if length(e1) != length(e2)
            error("Vectors should be of equal length")
        end
    
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