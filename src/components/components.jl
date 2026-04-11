module Components

import Ark

# Registry
const ALL = Type[]
macro component(ex)
    # Handle both @component struct Name ... end and @component Name begin ... end
    return if ex isa Expr && ex.head == :struct
        # Extract type name from struct definition
        type_expr = ex.args[2]

        name = if type_expr isa Symbol
            type_expr
        elseif type_expr.head == :(<:)
            # struct Name <: Super
            name_part = type_expr.args[1]
            if name_part isa Expr && name_part.head == :curly
                name_part.args[1]  # Name{T} -> Name
            else
                name_part
            end
        elseif type_expr.head == :curly
            # struct Name{T}
            type_expr.args[1]
        else
            error("Cannot extract name from: $type_expr")
        end

        quote
            $(esc(ex))  # Define the struct in caller's scope
            push!($(esc(ALL)), $(esc(name)))  # Register the type
            $(esc(name))  # Return the type
        end
    else
        error("@component expects a struct definition")
    end
end
abstract type AbstractComponent end
include("bank.jl")
include("central_bank.jl")
include("firms.jl")
include("government.jl")
include("households.jl")
include("loans.jl")
include("profits.jl")
include("rest_of_world.jl")
include("workers.jl")


# Convert to Tuple for Ark
const COMPONENTS = Tuple(ALL)

end
