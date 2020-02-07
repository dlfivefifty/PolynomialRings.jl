module TupleMonomials

import Base: exp, rand

import Random: AbstractRNG, SamplerType

import ...AbstractMonomials: AbstractMonomial, num_variables, maybe_div
import PolynomialRings: exptype

# -----------------------------------------------------------------------------
#
# TupleMonomial
#
# -----------------------------------------------------------------------------

"""
    TupleMonomial{N, I, Order} <: AbstractMonomial where I <: Integer where Order

An implementation of AbstractMonomial that stores exponents as a tuple
of integers. This is a dense representation.
"""
struct TupleMonomial{N, I <: Integer, Order} <: AbstractMonomial{Order}
    e   :: NTuple{N, I}
    deg :: I
end


num_variables(::Type{TupleMonomial{N,I,Order}}) where {N,I,Order} = N
exptype(::Type{TupleMonomial{N,I,Order}}) where I <: Integer where {N,Order} = I
expstype(::Type{TupleMonomial{N,I,Order}}) where I <: Integer where {N,Order} = NTuple{N,I}

exp(::Type{M}, exps::NTuple, deg=sum(exps)) where M <: TupleMonomial = M(exps, deg)
exp(::Type{M}, exps, deg=sum(exps)) where M <: TupleMonomial = M(ntuple(i -> get(exps, i, 0), num_variables(M)), deg)

@inline exponent(m::TupleMonomial, i::Integer) = m.e[i]

# -----------------------------------------------------------------------------
#
# TupleMonomial: overloads for speedup
#
# -----------------------------------------------------------------------------
total_degree(a::TupleMonomial) = a.deg

==(a::M, b::M) where M <: TupleMonomial = a.e == b.e

function rand(rng::AbstractRNG, ::SamplerType{M}) where M <: TupleMonomial
    maxexp = 2 ^ (leading_zeros(zero(exptype(M))) ÷ 2)
    exps = ntuple(i -> rand(rng, 1:maxexp), num_variables(M))
    return exp(M, exps)
end


end
