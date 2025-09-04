
using Unrolled

@generated function struct2tuple(x::T) where T
    n = fieldcount(T)
    exprs = [:(getfield(x, $(i))) for i in 1:n]
    return Expr(:tuple, exprs...)
end

function remove!(a, i)
    @inbounds a[i], a[end] = a[end], a[i]
    pop!(a)
    return
end

Base.delete!(structvec::Union{AbstractFirms, AbstractWorkers}, id::Integer) = _delete!(structvec, id)
function _delete!(structvec::T, id) where {T}
    i = structvec.id_to_index[id]
    removei! = a -> remove!(a, i)
    unrolled_map(removei!, struct2tuple(structvec)[3:end])
    delete!(structvec.id_to_index, id)
    i <= length(structvec.index_to_id) && (@inbounds structvec.id_to_index[structvec.index_to_id[i]] = i)
    return structvec
end

Base.push!(structvec::Union{AbstractFirms, AbstractWorkers}, t::NamedTuple) = _push!(structvec, t)
function _push!(structvec, t)
    length(t) != nfields(structvec) - 3 && error("The tuple fields do not match the container fields")
    unrolled_map(push!, struct2tuple(structvec)[4:end], t)
    nextlastid = (structvec.lastid[] += 1)
    len = length(getfield(structvec, first(keys(t))))
    structvec.id_to_index[nextlastid] = len
    push!(structvec.index_to_id, nextlastid)
    return structvec
end

allids(structvec::Union{AbstractFirms, AbstractWorkers}) = structvec.index_to_id

abstract type AbstractWorker <: AbstractObject end
struct Worker{S} <: AbstractWorker
    id::Int
    structvec::S
end
Base.getindex(structvec::AbstractWorkers, id::Integer) = Worker(id, structvec)
function Base.getproperty(w::Worker, name::Symbol)
    id, structvec = getfield(w, :id), getfield(w, :structvec)
    i = structvec.id_to_index[id]
    return (@inbounds getfield(structvec, name)[i])
end
function Base.setproperty!(w::Worker, name::Symbol, x)
    id, structvec = getfield(w, :id), getfield(w, :structvec)
    i = structvec.id_to_index[id]
    return (@inbounds getfield(structvec, name)[i] = x)
end

abstract type AbstractFirm <: AbstractObject end
struct Firm{S} <: AbstractFirm
    id::Int
    structvec::S
end
Base.getindex(structvec::AbstractFirms, id::Integer) = Firm(id, structvec)
function Base.getproperty(f::Firm, name::Symbol)
    id, structvec = getfield(f, :id), getfield(f, :structvec)
    return getfield(structvec, name)[structvec.id_to_index[id]]
end
function Base.setproperty!(f::Firm, name::Symbol, x)
    id, structvec = getfield(f, :id), getfield(f, :structvec)
    return setindex!(getfield(structvec, name), x, structvec.id_to_index[id])
end

function Base.show(io::IO, x::Union{Firm, Worker})
    id, structvec = getfield(x, :id), getfield(x, :structvec)
    i = structvec.id_to_index[id]
    T = typeof(x)
    fields = NamedTuple(y => getfield(structvec, y)[i] for y in fieldnames(typeof(structvec))[3:end])
    fields = merge((id = id,), fields)
    return println("$(nameof(T))$fields")
end
