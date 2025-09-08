using Unrolled

const AgentsTypes = Union{AbstractFirms, AbstractWorkers}

firms(model) = getfield(model, :firms)
activeworkers(model) = getfield(model, :w_act)
inactiveworkers(model) = getfield(model, :w_inact)

@generated function struct2tuple(x::T, k::Val{X}) where {T, X}
    n = fieldcount(T)
    exprs = [:(getfield(x, $(i))) for i in X:n]
    return Expr(:tuple, exprs...)
end

@generated function subfieldnames(x::T, k::Val{X}) where {T, X}
    names = fieldnames(T)
    exprs = [:($(names)[$(i)]) for i in X:length(names)]
    return Expr(:tuple, exprs...)
end

function remove!(a, i)
    @inbounds a[i], a[end] = a[end], a[i]
    pop!(a)
    return
end
function Base.delete!(structvec::AgentsTypes, id::Unsigned)
    if !(structvec.del[])
        structvec.del[] = true
        for pid in structvec.ID
            structvec.id_to_index[pid] = pid % Int
        end
    end
    i = structvec.id_to_index[id]
    removei! = a -> remove!(a, i)
    unrolled_map(removei!, struct2tuple(structvec, Val(4)))
    delete!(structvec.id_to_index, id)
    i <= length(structvec.ID) && (structvec.id_to_index[(@inbounds structvec.ID[i])] = i)
    return structvec
end
function Base.push!(structvec::AgentsTypes, t::NamedTuple)
    subfieldnames(structvec, Val(5)) != keys(t) && error("The tuple fields do not match the container fields")
    unrolled_map(push!, struct2tuple(structvec, Val(5)), t)
    nextlastid = (structvec.lastid[] += 1)
    push!(structvec.ID, nextlastid)
    id_to_index = structvec.id_to_index
    structvec.del[] && (id_to_index[nextlastid] = length(structvec.ID))
    return structvec
end
allids(structvec::AgentsTypes) = getfield(structvec, :ID)
lastid(structvec::AgentsTypes) = getfield(structvec, :lastid)[]

struct Agent{S}
    id::Int
    structvec::S
end
Base.getindex(structvec::AgentsTypes, id::Unsigned) = Agent(id, structvec)
function Base.getproperty(a::Agent, name::Symbol)
    id, structvec = getfield(a, :id), getfield(a, :structvec)
    i = get(structvec.id_to_index, id, id % Int)
    return (getfield(structvec, name)[i])
end
function Base.setproperty!(a::Agent, name::Symbol, x)
    id, structvec = getfield(a, :id), getfield(a, :structvec)
    i = get(structvec.id_to_index, id, id % Int)
    return (getfield(structvec, name)[i] = x)
end
function getfields(a::Agent)
    id, structvec = getfield(a, :id), getfield(a, :structvec)
    i = get(structvec.id_to_index, id, id % Int)
    t = struct2tuple(structvec, Val(5))
    getindexi = ar -> ar[i]
    vals = unrolled_map(getindexi, t)
    names = subfieldnames(structvec, Val(5))
    return NamedTuple{names}(vals)
end
id(a::Agent) = getfield(a, :id)

function Base.show(io::IO, ::MIME"text/plain", x::Agent{S}) where {S}
    id, structvec = getfield(x, :id), getfield(x, :structvec)
    i = get(structvec.id_to_index, id, id % Int)
    fields = NamedTuple(y => getfield(structvec, y)[i] for y in fieldnames(S)[4:end])
    return print(io, "Agent{$(nameof(S))}$fields")
end
