
const __OBJECT_EXPR_CONTAINER__ = Dict{Symbol, Expr}()

abstract type AbstractObject end
struct Object <: AbstractObject end
__OBJECT_EXPR_CONTAINER__[:Object] = :(struct Object <: AbstractObject end)

"""
    Bit.@object struct YourObjectType{X}(ObjectTypeToInherit) [<: OptionalSupertype]
        extra_property::X
        other_extra_property_with_default::Bool = true
        const other_extra_const_property::Int
        # etc...
    end

Define an object struct which includes all fields that `YourObjectType` has,
as well as any additional ones the user may provide. The macro supports all syntaxes
that the standard Julia struct command allows for, such as `const` field
declaration or default values for some fields. Additionally, the resulting type
will always have a keyword constructor defined for it (using `@kwdef`).

Using `Bit.@object` is the recommended way to create types for BeforeIT.jl.

Structs created with `Bit.@object` by default subtype `Bit.AbstractObject`.
If you want `YourObjectType` to subtype something other than `Bit.AbstractObject`, use
the optional argument `OptionalSupertype`.

## Usage

The macro `Bit.@object` has two primary uses:

1. To include the mandatory fields for a particular object in your object struct.
   In this case you would use one of the minimal object types.
2. A convenient way to include fields from another, already existing struct,
   thereby establishing a toolkit for "type inheritance" in Julia.

The existing minimal object types are:

- `Workers`
- `Firms`
- `Bank`
- `CentralBank`
- `Government`
- `RestOfTheWorld`
- `Aggregates`
- `Data`

which describe which fields they will contribute to the new type.

## Example

```julia
# you can either constrain the type to Float64 in the definition
Bit.@object mutable struct CentralBankNew(CentralBank{Float64}) <: AbstractCentralBank
    new_field::Float64
end
# or keep it generic so that you can change it at construction time
Bit.@object mutable struct CentralBankNew2{T}(CentralBank{T}) <: AbstractCentralBank
    new_field::T
end
```

Consult the CANVAS Extension page in the documentation for a more advanced example
on how to use the macro.
"""
macro object(struct_repr) # the macro is similar to the @agent macro in Agents.jl
    expr = _object(struct_repr)
    return :(Base.@__doc__($(esc(expr))))
end

function _object(struct_repr)
    new_type, base_type_spec, abstract_type, new_fields = decompose_struct_base(struct_repr)
    base_fields = compute_base_fields(base_type_spec)
    expr_new_type = Expr(
        :struct, struct_repr.args[1], :($new_type <: $abstract_type),
        :(begin 
            $(base_fields...) 
            $(new_fields...) 
          end)
    )
    new_type_no_params = namify(new_type)
    __OBJECT_EXPR_CONTAINER__[new_type_no_params] = MacroTools.prewalk(rmlines, expr_new_type)
    return quote @kwdef $expr_new_type end
end

function decompose_struct_base(struct_repr)
    if struct_repr.args[1] == false
        if !@capture(struct_repr, struct new_type_(base_type_spec_) <: abstract_type_ new_fields__ end)
            @capture(struct_repr, struct new_type_(base_type_spec_) new_fields__ end)
        end
    else
        if !@capture(struct_repr, mutable struct new_type_(base_type_spec_) <: abstract_type_ new_fields__ end)
            @capture(struct_repr, mutable struct new_type_(base_type_spec_) new_fields__ end)
        end
    end
    abstract_type === nothing && (abstract_type = :(Bit.AbstractObject))
    return new_type, base_type_spec, abstract_type, new_fields
end

function compute_base_fields(base_type_spec)
    @capture(base_type_spec, _.base_type_name_)
    isnothing(base_type_name) && @capture(base_type_spec, _.base_type_name_{__})
    base_type_name = namify(isnothing(base_type_name) ? base_type_spec : base_type_name)
    base_agent = __OBJECT_EXPR_CONTAINER__[base_type_name]
    base_type_general = base_agent.args[2].args[1]
    old_args = base_type_general isa Symbol ? [] : base_type_general.args[2:end]
    new_args = base_type_spec isa Symbol ? [] : base_type_spec.args[2:end]
    for (old, new) in zip(old_args, new_args)
        base_agent = MacroTools.postwalk(ex -> ex == old ? new : ex, base_agent)
    end
    @capture(base_agent.args[3], base_fields__)
    return base_fields
end
