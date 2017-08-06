module PolynomialRings

include("PolynomialRings/Methods.jl")
include("PolynomialRings/Util.jl")

include("PolynomialRings/Monomials.jl")
include("PolynomialRings/MonomialOrderings.jl")
include("PolynomialRings/Terms.jl")
include("PolynomialRings/Polynomials.jl")
include("PolynomialRings/Operators.jl")
include("PolynomialRings/NamedPolynomials.jl")
include("PolynomialRings/Constructors.jl")
include("PolynomialRings/Conversions.jl")
include("PolynomialRings/Expansions.jl")
include("PolynomialRings/Arrays.jl")
include("PolynomialRings/Display.jl")
include("PolynomialRings/Modules.jl")
include("PolynomialRings/Groebner.jl")

import .Monomials: TupleMonomial, VectorMonomial
import .Terms: Term
import .Polynomials: Polynomial, generators
import .NamedPolynomials: NamedPolynomial
import .Constructors: polynomial_ring, formal_coefficients, @ring
import .Expansions: expansion, @expansion, coefficient, @coefficient, constant_coefficient, @constant_coefficient
import .Groebner: red, groebner_basis

export TupleMonomial, Term, Polynomial, NamedPolynomial, generators, ⊗, polynomial_ring, formal_coefficients
export deg, red, groebner_basis, expansion, @expansion, coefficient, @coefficient, constant_coefficient, @constant_coefficient, @ring

# TODO: needs a better place
import .NamedPolynomials: polynomialtype
construct_monomial(::Type{P}, e::T) where P<:Polynomial where T<:Tuple = P([termtype(P)(monomialtype(P)(e, sum(e)),one(basering(P)))])
construct_monomial(::Type{P}, e::T) where P<:Polynomial where T<:AbstractArray = P([termtype(P)(monomialtype(P)(ntuple(i->e[i], length(e)), sum(e)),one(basering(P)))])
construct_monomial(::Type{NP}, e::T) where NP<:NamedPolynomial where T = NP(construct_monomial(polynomialtype(NP), e))
export construct_monomial

end # module
