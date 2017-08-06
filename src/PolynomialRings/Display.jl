module Display

import PolynomialRings.Polynomials: Polynomial, terms, basering
import PolynomialRings.NamedPolynomials: NamedPolynomial, names
import PolynomialRings.Terms: Term, coefficient, monomial
import PolynomialRings.Monomials: AbstractMonomial, TupleMonomial, num_variables
import PolynomialRings.MonomialOrderings: MonomialOrder
import PolynomialRings: monomialtype, monomialorder

import Base: show

# -----------------------------------------------------------------------------
#
# Display of polynomials
#
# -----------------------------------------------------------------------------

function show(io::IO, p::P) where P <: Polynomial
    DummyNames = :x
    show(io, NamedPolynomial{P, DummyNames}(p))
end

_varname(n::NTuple{N, Symbol}, ix::Integer) where N = repr(n[ix])[2:end]
_varname(s::Symbol, ix::Integer) = (var = repr(s)[2:end]; "$var$ix")

function show(io::IO, np::NP) where NP <: NamedPolynomial{P, Names} where P<:Polynomial where Names
    p = np.p
    frst = true
    if length(terms(p)) == 0
        print(io, zero(basering(P)))
    end
    for t in terms(p)
        if !frst
            print(io, " + ")
        else
            frst = false
        end
        print(io, coefficient(t))
        for (ix, i) in enumerate(monomial(t))
            varname = _varname(Names, ix)
            if i == 1
                print(io, " $varname")
            elseif i > 1
                print(io, " $varname^$i")
            end
        end
    end
end

# -----------------------------------------------------------------------------
#
# Display of types
#
# -----------------------------------------------------------------------------

function show(io::IO, ::MO) where MO <: MonomialOrder{Name} where Name
    print(io, Name)
end

function show(io::IO, ::Type{NP}) where NP <: NamedPolynomial{P,Names} where P <: Polynomial where Names
    show_names = names(NP) isa Symbol ? "$(names(NP))_i" : join(names(NP), ",", " and ")
    print(io, "(Polynomial over $(basering(NP)) in $show_names)")
end

function show(io::IO, ::Type{NP}) where NP <: NamedPolynomial{P,Names} where P <: Term where Names
    show_names = names(NP) isa Symbol ? "$(names(NP))_i" : join(names(NP), ",", " and ")
    print(io, "(Term over $(basering(NP)) in $show_names)")
end

function show(io::IO, ::Type{NP}) where NP <: NamedPolynomial{P,Names} where P <: AbstractMonomial where Names
    show_names = names(NP) isa Symbol ? "$(names(NP))_i" : join(names(NP), ",", " and ")
    print(io, "(Monomial in $show_names)")
end

function show(io::IO, ::Type{Polynomial{A,Order}}) where {A,Order}
    P = Polynomial{A,Order}
    n = monomialtype(P) <: TupleMonomial ?  num_variables(monomialtype(P)) : "∞"
    print(io, "(Polynomial over ",basering(P), " in ", n," variables (", monomialorder(P), "))")
end

end
