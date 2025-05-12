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

# Helper functions for LaTeX table creation and stars notation
function stars(p_value)
    if p_value < 0.01
        return "***"
    elseif p_value < 0.05
        return "**"
    elseif p_value < 0.1
        return "*"
    else
        return ""
    end
end

nanmean(x) = mean(filter(!isnan,x))
nanmean(x,y) = mapslices(nanmean,x; dims = y)

# Load calibration data (with figaro input-output tables)
year_ = 2010
number_years = 10
number_quarters = 4 * number_years
quarters_num = []
year_m = year_
max_year = 2019

for month in 4:3:((number_years + 1) * 12 + 1)
    year_m = year_ + (month ÷ 12)
    mont_m = month % 12
    date = DateTime(year_m, mont_m, 1) - Day(1)
    push!(quarters_num, Bit.date2num(date))
end

horizon = 12
number_variables = 8
presample = 4
number_seeds = 100

data = matread(("data/" * country * "/calibration/data/1996.mat"))["data"]
ea = matread(("data/" * country * "/calibration/ea/1996.mat"))["ea"]