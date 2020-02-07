module MonomialOrderings

import Base.Order: Ordering
import Base: findmin, findmax, argmin, argmax
import Base: min, max, minimum, maximum
import Base: promote_rule

import ..NamingSchemes: NamingScheme, Named, Numbered
import PolynomialRings: leading_monomial, leading_coefficient, leading_term, tail, deg
import PolynomialRings: namingscheme, to_dense_monomials, variablesymbols, num_variables

"""
    struct MonomialOrder{Rule, Names} <: Ordering end

For implementing your own monomial order, do the following:

1. Choose a symbol to represent it, say `:myorder`
2. `Base.Order.lt(::MonomialOrder{:myorder}, a, b) = ...`

A few useful functions are [`exponents`](@ref) and [`exponentsnz`](@ref). See
[`PolynomialRings.AbstractMonomials`](@ref) and
[`PolynomialRings.MonomialOrderings`](@ref) for details.

You can then create a ring that uses it by calling

    R,vars = polynomial_ring(vars...; monomialorder=:myorder)

There is no performance cost for using your own monomial order compared to a
built-in one.
"""
struct MonomialOrder{Rule, Names <: NamingScheme} <: Ordering end

const MonomialOrderIn{Scheme <: NamingScheme, Rule} = MonomialOrder{Rule, Scheme}

const NamedMonomialOrder    = MonomialOrderIn{<:Named}
const NumberedMonomialOrder = MonomialOrderIn{<:Numbered}

rulesymbol(::O)       where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Rule
rulesymbol(::Type{O}) where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Rule

namingscheme(::O)       where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Names()
namingscheme(::Type{O}) where O <: MonomialOrder{Rule, Names} where {Rule, Names} = Names()

to_dense_monomials(n::Integer, o::MonomialOrder) = MonomialOrder{rulesymbol(o), typeof(to_dense_monomials(n, namingscheme(o)))}()

min(m::MonomialOrder, x, y) = Base.Order.lt(m, x, y) ? x : y
max(m::MonomialOrder, x, y) = Base.Order.lt(m, x, y) ? y : x
min(m::MonomialOrder, a, b, c, xs...) = (op(x,y) = min(m,x,y); Base.afoldl(op, op(op(a,b),c), xs...))
max(m::MonomialOrder, a, b, c, xs...) = (op(x,y) = max(m,x,y); Base.afoldl(op, op(op(a,b),c), xs...))
function findmin(order::MonomialOrder, iter)
    p = pairs(iter)
    y = iterate(p)
    if y === nothing
        throw(ArgumentError("collection must be non-empty"))
    end
    (mi, m), s = y
    i = mi
    while true
        y = iterate(p, s)
        y === nothing && break
        m != m && break
        (i, ai), s = y
        if ai != ai || Base.Order.lt(order, ai, m)
            m = ai
            mi = i
        end
    end
    return (m, mi)
end
function findmax(order::MonomialOrder, iter)
    p = pairs(iter)
    y = iterate(p)
    if y === nothing
        throw(ArgumentError("collection must be non-empty"))
    end
    (mi, m), s = y
    i = mi
    while true
        y = iterate(p, s)
        y === nothing && break
        m != m && break
        (i, ai), s = y
        if ai != ai || Base.Order.lt(order, m, ai)
            m = ai
            mi = i
        end
    end
    return (m, mi)
end

argmin(m::MonomialOrder, iter) = findmin(m, iter)[2]
argmax(m::MonomialOrder, iter) = findmax(m, iter)[2]
minimum(m::MonomialOrder, iter) = findmin(m, iter)[1]
maximum(m::MonomialOrder, iter) = findmax(m, iter)[1]
# resolve ambiguity
minimum(m::MonomialOrder, iter::AbstractArray) = findmin(m, iter)[1]
maximum(m::MonomialOrder, iter::AbstractArray) = findmax(m, iter)[1]

degreecompatible(::MonomialOrder) = false
degreecompatible(::MonomialOrder{:degrevlex}) = true
degreecompatible(::MonomialOrder{:deglex}) = true

# -----------------------------------------------------------------------------
#
# Promotions for different variable name sets
#
# -----------------------------------------------------------------------------
function promote_rule(::Type{M1}, ::Type{M2}) where {M1 <: MonomialOrder, M2 <: MonomialOrder}
    scheme = promote_type(typeof(namingscheme(M1)), typeof(namingscheme(M2)))
    if scheme <: NamingScheme
        return MonomialOrder{:degrevlex, scheme}
    else
        return Union{}
    end
end

macro withmonomialorder(order)
    esc(quote
        ≺(a, b) =  Base.Order.lt($order, a, b)
        ⪯(a, b) = !Base.Order.lt($order, b, a)
        ≻(a, b) =  Base.Order.lt($order, b, a)
        ⪰(a, b) = !Base.Order.lt($order, a, b)
        leading_monomial(f) = $leading_monomial(f, order=$order)
        leading_term(f) = $leading_term(f, order=$order)
        leading_coefficient(f) = $leading_coefficient(f, order=$order)
        lm(f) = $leading_monomial(f, order=$order)
        lt(f) = $leading_term(f, order=$order)
        lc(f) = $leading_coefficient(f, order=$order)
        tail(f) = $tail(f, order=$order)
        deg(f) = $deg(f, $namingscheme($order))
    end)
end

function syms_from_comparison(expr, macroname)
    if expr isa Symbol
        return tuple(expr)
    elseif expr.head == :call && expr.args[1] == :>
        syms = expr.args[2:3]
        return tuple(syms...)
    elseif expr.head == :comparison
        syms = expr.args[1:2:end]
        comparisons = expr.args[2:2:end]
        all(isequal(:>), comparisons) || error("Use $macroname as follows: $macroname(x > y > z)")
        return tuple(syms...)
    else
        error("Use $macroname as follows: $macroname(x > y > z)")
    end
end

macro degrevlex(expr)
    syms = syms_from_comparison(expr, "@degrevlex")
    return MonomialOrder{:degrevlex, Named{syms}}()
end

macro deglex(expr)
    syms = syms_from_comparison(expr, "@deglex")
    return MonomialOrder{:deglex, Named{syms}}()
end

macro lex(expr)
    syms = syms_from_comparison(expr, "@lex")
    return MonomialOrder{:lex, Named{syms}}()
end

end
