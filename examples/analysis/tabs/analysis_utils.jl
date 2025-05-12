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
