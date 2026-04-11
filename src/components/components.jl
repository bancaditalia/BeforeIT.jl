module Components
abstract type AbstractComponent end
include("bank.jl")
include("central_bank.jl")
include("components.jl")
include("firms.jl")
include("government.jl")
include("households.jl")
include("loans.jl")
include("profits.jl")
include("rest_of_world.jl")
include("workers.jl")

const COMPONENTS = Tuple(subtypes(MyComponent))
end
