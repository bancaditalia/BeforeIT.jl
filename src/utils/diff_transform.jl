function _flatten_struct!(v::Vector{Float64}, obj)
    for fname in fieldnames(typeof(obj))
        # Skip fields that are not part of the differentiable state
        if fname in (:del, :lastid, :id_to_index, :ID)
            continue
        end

        field = getfield(obj, fname)

        # Append numbers and vectors of numbers
        if isa(field, Number)
            push!(v, Float64(field))
        elseif isa(field, AbstractVector{<:Number})
            append!(v, Float64.(field))
        end
    end
    return
end

function _unflatten_struct!(obj, arr::AbstractVector{Float64}, pos_ref::Ref{Int})
    for fname in fieldnames(typeof(obj))
        # Skip fields that are not part of the differentiable state
        if fname in (:del, :lastid, :id_to_index, :ID)
            continue
        end

        field_val = getfield(obj, fname)
        FieldType = typeof(field_val)

        if FieldType <: Number
            # Extract scalar value
            val = arr[pos_ref[]]

            if FieldType <: Integer
                setfield!(obj, fname, round(FieldType, val))
            else
                setfield!(obj, fname, FieldType(val))
            end

            pos_ref[] += 1

        elseif FieldType <: AbstractVector{<:Number}
            # Extract vector slice
            len = length(field_val)
            chunk = @view arr[pos_ref[]:(pos_ref[] + len - 1)]

            ElType = eltype(field_val)

            if ElType <: Integer
                field_val .= round.(ElType, chunk) # Broadcast round for integers
            else
                field_val .= ElType.(chunk)      # Broadcast conversion for floats
            end

            pos_ref[] += len
        end
    end
    return
end

function model_to_array(model)
    v = Float64[]

    # The order of these calls is critical and must be mirrored in `array_to_model`
    _flatten_struct!(v, model.w_act)
    _flatten_struct!(v, model.w_inact)
    _flatten_struct!(v, model.firms)
    _flatten_struct!(v, model.bank)
    _flatten_struct!(v, model.cb)
    _flatten_struct!(v, model.gov)
    _flatten_struct!(v, model.rotw)
    _flatten_struct!(v, model.agg)
    _flatten_struct!(v, model.prop)

    return v
end

function array_to_model(arr::AbstractVector{Float64}, original_model)
    # Create a deep copy to preserve non-state fields (prop, data) and structure
    new_model = deepcopy(original_model)
    pos = Ref(1) # Use a Ref so its value can be mutated by the helper function

    # The order MUST be identical to the one in `model_to_array`
    _unflatten_struct!(new_model.w_act, arr, pos)
    _unflatten_struct!(new_model.w_inact, arr, pos)
    _unflatten_struct!(new_model.firms, arr, pos)
    _unflatten_struct!(new_model.bank, arr, pos)
    _unflatten_struct!(new_model.cb, arr, pos)
    _unflatten_struct!(new_model.gov, arr, pos)
    _unflatten_struct!(new_model.rotw, arr, pos)
    _unflatten_struct!(new_model.agg, arr, pos)
    _unflatten_struct!(new_model.prop, arr, pos)

    return new_model
end
