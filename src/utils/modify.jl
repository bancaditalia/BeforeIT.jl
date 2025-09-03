
Base.delete!(structvec::Union{AbstractFirms, AbstractWorkers}, id::Integer) = _delete!(structvec, id)
function _delete!(structvec, id)
	i = structvec.id_to_index[id]
	for fieldn in fieldnames(typeof(structvec))[3:end]
		vecfield = getfield(structvec, fieldn)
		vecfield[i], vecfield[end] = vecfield[end], vecfield[i]
		pop!(vecfield)
	end
	delete!(structvec.id_to_index, id)
	id != structvec.lastid[] && (structvec.id_to_index[structvec.lastid[]] = i)
	return structvec
end

Base.push!(structvec::Union{AbstractFirms, AbstractWorkers}, t::NamedTuple) = _push!(structvec, t)
function _push!(structvec, t)
	fieldnames(typeof(structvec))[3:end] == keys(t) || error("The tuple fields do not match the container fields")
	for fieldn in keys(t)
		vecfield = getfield(structvec, fieldn)
		tfield = getfield(t, fieldn)
		push!(vecfield, tfield)
	end
	structvec.lastid[] += 1
	len = length(getfield(structvec, first(keys(t))))
	structvec.id_to_index[structvec.lastid[]] = len
	return structvec
end

struct Worker{S}
	id::Int
	structvec::S
end
Base.getindex(structvec::AbstractWorkers, id::Integer) = Worker(id, structvec)
function Base.getproperty(w::Worker, name::Symbol)
	id, structvec = getfield(w, :id), getfield(w, :structvec)
	getfield(structvec, name)[structvec.id_to_index[id]]
end
function Base.setproperty!(w::Worker, name::Symbol, x)
	id, structvec = getfield(w, :id), getfield(w, :structvec)
	setindex!(getfield(structvec, name), x, structvec.id_to_index[id])
end

struct Firm{S}
	id::Int
	structvec::S
end
Base.getindex(structvec::AbstractFirms, id::Integer) = Firm(id, structvec)
function Base.getproperty(f::Firm, name::Symbol)
	id, structvec = getfield(f, :id), getfield(f, :structvec)
	getfield(structvec, name)[structvec.id_to_index[id]]
end
function Base.setproperty!(f::Firm, name::Symbol, x)
	id, structvec = getfield(f, :id), getfield(f, :structvec)
	setindex!(getfield(structvec, name), x, structvec.id_to_index[id])
end

function Base.show(io::IO, x::Union{Firm, Worker})
	id, structvec = getfield(x, :id), getfield(x, :structvec)
	i = structvec.id_to_index[id]
	T = typeof(x)
	fields = NamedTuple(y => getfield(structvec, y)[i] for y in fieldnames(typeof(structvec))[3:end])
	fields = merge((id=id, ), fields)
	println("$(nameof(T))$fields")
end