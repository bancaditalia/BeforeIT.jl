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
Literate.markdown(joinpath(indir, "get_parameters_and_initial_conditions.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "multithreading_speedup.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "scenario_analysis_via_overload.jl"), outdir; credit = false)
Literate.markdown(joinpath(indir, "change_expectations.jl"), outdir; credit = false)


println("Documentation Build")

makedocs(
    sitename = "BeforeIT.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "Essentials" => "examples/basic_example.md",
        "Shocked simulations" => "examples/scenario_analysis_via_shock.md",
        "Shocked simulations (advanced)" => "examples/scenario_analysis_via_overload.md",
        "Experimentations (advanced)" => "examples/change_expectations.md",
        "Multithreading within the model" => "examples/multithreading_speedup.md",
        "Calibration" => "examples/get_parameters_and_initial_conditions.md",
        "API" => "api.md",
    ],
)

deploydocs(;repo = "github.com/arnauqb/BeforeIT.jl.git", devbranch = "main", target = "build", branch="gh-pages")
