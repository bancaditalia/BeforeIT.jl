using MacroTools

macro sum_over(generator)
    # Parse: expr for var in Query(world, component)
    @capture(generator, expr_ for var_ in query_call_) ||
        error("Syntax: @sum_over(expr for var in Query(world, ComponentType))")

    @capture(query_call, query_type_(world_, component_type_)) ||
        error("Expected Query(world, ComponentType)")
    e = gensym(:e)
    vals = gensym(:vals)
    i = gensym(:i)

    # Replace var with vals[i] in expr
    new_expr = MacroTools.postwalk(expr) do x
        x === var ? :($vals[$i]) : x
    end

    return quote
        let total = 0.0
            for ($e, $vals) in $query_type($world, $component_type)
                for $i in eachindex($e)
                    total += $new_expr
                end
            end
            total
        end
    end |> esc
end

sinlge(q::Ark.Query) = Iterators.flatten(zip(tup...) for tup in q) |> only
