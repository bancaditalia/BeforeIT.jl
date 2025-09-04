using Unrolled

const AgentsTypes = Union{AbstractFirms, AbstractWorkers}

@generated function struct2tuple(x::T) where {T}
    n = fieldcount(T)
    exprs = [:(getfield(x, $(i))) for i in 1:n]
    return Expr(:tuple, exprs...)
end
@generated function struct2namedtuple(x::T) where {T}
    names = fieldnames(T)
    vals = [:(getfield(x, $(i))) for i in 1:length(names)]
    nt_type = Expr(:curly, :NamedTuple, Expr(:tuple, QuoteNode.(names)...))
    return Expr(:call, nt_type, Expr(:tuple, vals...))
end

function remove!(a, i)
    @inbounds a[i], a[end] = a[end], a[i]
    pop!(a)
    return
end

function Base.delete!(structvec::AgentsTypes, id::Unsigned)
    i = structvec.id_to_index[id]
    removei! = a -> remove!(a, i)
    unrolled_map(removei!, struct2tuple(structvec)[3:end])
    delete!(structvec.id_to_index, id)
    i <= length(structvec.ID) && (structvec.id_to_index[(@inbounds structvec.ID[i])] = i)
    return structvec
end

function Base.push!(structvec::T, t::NamedTuple) where {T <: AgentsTypes}
    fieldnames(T)[4:end] != keys(t) && error("The tuple fields do not match the container fields")
    unrolled_map(push!, struct2tuple(structvec)[4:end], t)
    nextlastid = (structvec.lastid[] += 1)
    push!(structvec.ID, nextlastid)
    structvec.id_to_index[nextlastid] = length(structvec.ID)
    return structvec
end

allids(structvec::AgentsTypes) = getfield(structvec, :ID)
lastid(structvec::AgentsTypes) = getfield(structvec, :lastid)[]

struct Agent{S}
    id::UInt
    structvec::S
end
Base.getindex(structvec::AgentsTypes, id::Unsigned) = Agent(id, structvec)
function Base.getproperty(a::Agent, name::Symbol)
    id, structvec = getfield(a, :id), getfield(a, :structvec)
    i = structvec.id_to_index[id]
    return (@inbounds getfield(structvec, name)[i])
end
function Base.setproperty!(a::Agent, name::Symbol, x)
    id, structvec = getfield(a, :id), getfield(a, :structvec)
    i = structvec.id_to_index[id]
    return (@inbounds getfield(structvec, name)[i] = x)
end
function getfields(a::Agent)
    nt = struct2namedtuple(getfield(a, :structvec)[4:end]
    return Base.tail(Base.tail(Base.tail(nt)))
end
id(a::Agent) = getfield(a, :id)

function Base.show(io::IO, x::Agent{S}) where {S}
    id, structvec = getfield(x, :id), getfield(x, :structvec)
    i = structvec.id_to_index[id]
    fields = NamedTuple(y => getfield(structvec, y)[i] for y in fieldnames(S)[3:end])
    fields = merge((id = id,), fields)
    return println("Agent{$(nameof(S))}$fields")
end
