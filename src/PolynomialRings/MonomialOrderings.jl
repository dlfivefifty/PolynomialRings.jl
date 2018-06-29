module MonomialOrderings

import Base: min, max, minimum, maximum
import Base.Order: Ordering, lt
import PolynomialRings: namestype, to_dense_monomials

import PolynomialRings.Monomials: AbstractMonomial, VectorMonomial, total_degree, index_union, rev_index_union

"""
    struct MonomialOrder{Rule, Names} <: Ordering end

For implementing your own monomial order, do the following:

1. Choose a symbol to represent it, say `:myorder`;
2. `import Base.Order: lt`;
3. `lt(::MonomialOrder{:myorder}, a::M, b::M) where M <: AbstractMonomial = ...`

A few useful functions are `enumeratenz`, `index_union`, and `rev_index_union`.
See `PolynomialRings.Monomials` and `PolynomialRings.MonomialOrderings` for
details.

You can then create a ring that uses it by calling

    R,vars = polynomial_ring(vars...; monomialorder=:myorder)

There is no performance cost for using your own monomial order compared to a
built-in one.
"""
struct MonomialOrder{Rule, Names} <: Ordering end

rulesymbol(::O)       where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Rule
rulesymbol(::Type{O}) where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Rule

namestype(::O)       where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Names
namestype(::Type{O}) where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Names

to_dense_monomials(n::Integer, o::MonomialOrder) = MonomialOrder{rulesymbol(o), to_dense_monomials(n, namestype(o))}()

function lt(::MonomialOrder{:degrevlex}, a::M,b::M) where M <: AbstractMonomial

    if total_degree(a) == total_degree(b)
        for i in rev_index_union(a,b)
            if a[i] != b[i]
                return a[i] > b[i]
            end
        end
        return false
    else
        return total_degree(a) < total_degree(b)
    end
end

function lt(::MonomialOrder{:deglex}, a::M,b::M) where M <: AbstractMonomial

    if total_degree(a) == total_degree(b)
        for i in index_union(a,b)
            if a[i] != b[i]
                return a[i] < b[i]
            end
        end
        return false
    else
        return total_degree(a) < total_degree(b)
    end
end

function lt(::MonomialOrder{:lex}, a::M,b::M) where M <: AbstractMonomial
    for i in index_union(a,b)
        if a[i] != b[i]
            return a[i] < b[i]
        end
    end
    return false
end

# This method is mostly for supporting leading monomials of elements of a free
# f.g. module which is a tuple (index, monomial). That's in use in Gröbner,
# and maybe this implementation detail should move there.
function lt(m::MonomialOrder, a::T, b::T) where T <: Tuple
    for i = 1:nfields(T)
        if fieldtype(T,i) <: AbstractMonomial
            if lt(m, a[i], b[i])
                return true
            elseif lt(m, b[i], a[i])
                return false
            end
        else
            if isless(a[i], b[i])
                return true
            elseif isless(b[i], a[i])
                return false
            end
        end
    end
    return false
end

min(m::MonomialOrder, x, y) = lt(m, x, y) ? x : y
max(m::MonomialOrder, x, y) = lt(m, x, y) ? y : x
min(m::MonomialOrder, a, b, c, xs...) = (op(x,y) = min(m,x,y); Base.afoldl(op, op(op(a,b),c), xs...))
max(m::MonomialOrder, a, b, c, xs...) = (op(x,y) = max(m,x,y); Base.afoldl(op, op(op(a,b),c), xs...))
minimum(m::MonomialOrder, iter) = (op(x,y) = min(m,x,y); reduce(op, iter))
maximum(m::MonomialOrder, iter) = (op(x,y) = max(m,x,y); reduce(op, iter))

degreecompatible(::MonomialOrder) = false
degreecompatible(::MonomialOrder{:degrevlex}) = true
degreecompatible(::MonomialOrder{:deglex}) = true

end
