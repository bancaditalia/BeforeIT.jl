cd(@__DIR__)
println("Loading packages...")
using BeforeIT
using Documenter
using Literate

println("Converting Examples...")
cd(@__DIR__)
indir = joinpath(@__DIR__, "..", "examples")
outdir = joinpath(@__DIR__, "src", "examples")

indir = joinpath("..", "examples")
outdir = joinpath("src", "examples")
rm(outdir; force = true, recursive = true) # cleans up previous examples
mkpath(outdir)

# toskip = ("../examples/demo.ipynb")
# for file in readdir(indir)
#     # file ∈ toskip && continue
#     occursin(file, ".ipynb") && continue
#     occursin(file, "compare_model_vs_real.jl") && continue
#     Literate.markdown(joinpath(indir, file), outdir; credit = false)
# end

Literate.markdown(joinpath(indir, "basic_example.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "scenario_analysis_via_shock.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "prediction_pipeline.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "multithreading_speedup.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "basic_inheritance.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "single_agents.jl"), outdir; credit = false)
# Literate.markdown(joinpath(indir, "analysis/tabs/create_tables.jl"), outdir; credit = false)

@info "Building Documentation"
makedocs(
    sitename = "BeforeIT.jl",
    format = Documenter.HTML(prettyurls = false, size_threshold = 409600),
    pages = [
        "Home" => "index.md",
        "Basics" => "examples/basic_example.md",
        "Shocked simulations" => "examples/scenario_analysis_via_shock.md",
        "Extending the model" => "examples/basic_inheritance.md",
        "Working with Single Agents" => "examples/single_agents.md",
        "Multithreading within the model" => "examples/multithreading_speedup.md",
        "Calibration" => "examples/prediction_pipeline.md",
        # "Prediction Comparison" => "examples/create_tables.md",
        "API" => "api.md",
    ],
)

@info "Deploying Documentation"
CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing
if CI
    deploydocs(
        repo = "github.com/bancaditalia/BeforeIT.jl.git",
        target = "build",
        push_preview = true,
        devbranch = "main",
    )
end
println("Finished building and deploying docs.")
