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
Literate.markdown(joinpath(indir, "scenario_analysis_via_overload.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "change_expectations.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "basic_inheritance.jl"), outdir; credit = false)


@info "Building Documentation"
makedocs(
    sitename = "BeforeIT.jl",
    format = Documenter.HTML(prettyurls = false, size_threshold=409600),
    pages = [
        "Home" => "index.md",
        "Essentials" => "examples/basic_example.md",
        "Shocked simulations" => "examples/scenario_analysis_via_shock.md",
        "Essential model extension" => "examples/basic_inheritance.md",
        "Shocked simulations (advanced)" => "examples/scenario_analysis_via_overload.md",
        "Experimentations (advanced)" => "examples/change_expectations.md",
        "Multithreading within the model" => "examples/multithreading_speedup.md",
        "Calibration and forecast" => "examples/prediction_pipeline.md",
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
