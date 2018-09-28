module GröbnerGWV

using DataStructures: SortedDict, DefaultDict

import PolynomialRings
import PolynomialRings: gröbner_basis, gröbner_transformation, xrem!
import PolynomialRings.Backends.Gröbner: GWV

import PolynomialRings: leading_term, leading_monomial, lcm_multipliers, lcm_degree, fraction_field, basering, base_extend, base_restrict
import PolynomialRings: maybe_div, termtype, monomialtype, leading_row, leading_coefficient
import PolynomialRings.MonomialOrderings: MonomialOrder
import PolynomialRings.Monomials: total_degree, any_divisor
import PolynomialRings.Polynomials: Polynomial, monomialorder, monomialtype, PolynomialBy
import PolynomialRings.Terms: monomial, coefficient
import PolynomialRings.Modules: AbstractModuleElement, modulebasering
import PolynomialRings.Modules: withtransformations, separatetransformation
import PolynomialRings.Operators: Lead, Full, content, integral_fraction
using LinearAlgebra: Transpose
using SparseArrays: SparseVector, sparsevec

function regular_topreduce_rem(o, m, G)
    ≺(a,b) = Base.Order.lt(o, a, b)
    u1,v1 = m
    v1 = deepcopy(v1)
    i = 1
    supertopreducible = false
    while i <= length(G)
        u2, v2 = G[i]
        if iszero(v2)
            if maybe_div(u1, u2) !== nothing
                supertopreducible = true
            end
        elseif !iszero(v1)
            t = maybe_div(leading_monomial(o,v1), leading_monomial(o,v2))
            if t !== nothing
                c1 = leading_coefficient(o,v1)
                c2 = leading_coefficient(o,v2)
                m1, m2 = lcm_multipliers(c1, c2)
                if t * u2 ≺ u1
                    # new_u1 = u1 - c*(t*u2)
                    @. v1 = m1*v1 - m2*(t*v2)
                    supertopreducible = false
                    i = 1
                    continue
                elseif t * u2 == u1 && c1 == c2
                    supertopreducible = true
                end
            end
        end
        i += 1
    end

    if modulebasering(v1) <: Integer
        v1 = v1 ÷ content(v1)
    end

    return (m[1],v1), supertopreducible ? :supertopreducible : :notsupertopreducible
end

"""
    gröbner_basis = gwv(monomialorder, polynomials)

An implementation of the GWV algorithm as popularized by
> Shuhong Gao, Frank Volny, and Mingsheng Wang. "A new algorithm for computing
> Groebner bases." IACR Cryptology ePrint Archive 2010 (2010): 641.
"""
function gwv(o::MonomialOrder, polynomials::AbstractVector{P}; with_transformation=false) where P <: Polynomial
    ≺(a,b) = Base.Order.lt(o, a, b)

    if basering(P) <: Rational
        polynomials = map(f->integral_fraction(f)[1], polynomials)
    end

    if with_transformation
        polynomials = withtransformations(polynomials)
    end

    R = base_restrict(P)
    S = with_transformation ? eltype(polynomials) : R
    Signature = monomialtype(R[])
    M = Tuple{Signature, S}

    signature(m) = m[1]
    # --------------------------------------------------------------------------
    # Declare the variables where we'll accumulate the result
    # --------------------------------------------------------------------------
    G = Tuple{Signature, S}[]
    H = DefaultDict{Int, Set{monomialtype(R)}}(Set{monomialtype(R)})
    JP = SortedDict{Signature, M}(o)

    n = length(polynomials)
    for (i,p) in enumerate(polynomials)
        T = leading_monomial( sparsevec(Dict(i=>one(R)), n) )
        m = (T, p)
        JP[signature(m)] = m
    end

    loops = 0
    considered = 0
    divisors_considered = 0
    divisor_considerations = 0
    progress_logged = false
    # step 3
    while !isempty(JP)
        loops += 1
        if loops % 100 == 0
            l = length(G)
            k = length(JP)
            h = sum(length, values(H))
            @info("GWV: After $loops loops: $l elements in basis; $considered J-pairs considered; |JP|=$k, |H|=$h; $divisor_considerations considerations of divisors ($(round(divisors_considered/divisor_considerations, digits=1)) divisors on average).")
            progress_logged = true
        end

        # step 1.
        sig, m = first(JP)
        delete!(JP, sig)
        (T, v1) = m

        # step 2: criterion from thm 2.3(c)
        # there is a pair (u_2, v_2) ∈ G so that lm(u_2) divides
        # lm(T) and t lm(v_2) ≺ lm(v_1) where t = lm(T)/lm(u_2)
        if any(G) do m2
            u2,v2 = m2
            t = maybe_div(T, u2)
            if t !== nothing
                if t * leading_monomial(o, v2) ≺ leading_monomial(o, v1)
                    return true
                end
            end
            return false
        end
            continue
        end

        (_,v), status = regular_topreduce_rem(o, m, G)

        if iszero(v)
            newh = T
            push!(H[newh.i], newh.m)
            filter!(JP) do key_value
                sig, jp = key_value
                T2, v2 = jp
                divisible = maybe_div(T2, newh) !== nothing
                !divisible
            end
        else
            if status == :supertopreducible
                # pass
            elseif status == :notsupertopreducible
                # i) Add the leading terms of the principle syzygies, vT j − v j T for
                # 1 ≤ j ≤ |U |, to H,
                for (Tj, vj) in G
                    # syzygy = v*Tj - vj*T
                    lhs = leading_monomial(o,v)*Tj
                    rhs = leading_monomial(o,vj)*T
                    if lhs != rhs
                        newh = max(o, lhs, rhs)
                        push!(H[newh.i], newh.m)
                    end
                end
                # ii) Form new J-pairs of (T, v) and (T j , v j ), 1 ≤ j ≤ |U |,
                # iii) Insert into JP all such J-pairs whose signatures are not re-
                # ducible by H (storing only one J-pair for each distinct signature
                # T , the one with v-part minimal), and
                for (Tj, vj) in G
                    t1, t2 = lcm_multipliers(leading_monomial(o,v), leading_monomial(o,vj))
                    c = leading_coefficient(o,v)
                    cj = leading_coefficient(o,vj)
                    lhs = t1*T
                    rhs = t2*Tj
                    if !(c == cj && lhs == rhs)
                        if lhs ≺ rhs
                            Jsig = rhs
                            Jpair = (t2*Tj, t2*vj)
                        else
                            Jsig = lhs
                            Jpair = (t1*T, t1*v)
                        end
                        divisor_considerations += 1
                        if !any_divisor(Jsig.m) do d
                            divisors_considered += 1
                            d in H[Jsig.i]
                        end
                            if Jsig in keys(JP)
                                oldu,oldv = JP[Jsig]
                                newv = Jpair[2]
                                if newv ≺ oldv
                                    JP[Jsig] = Jpair
                                end
                            else
                                JP[Jsig] = Jpair
                            end
                        end
                    end
                end
                # iv) Append T to U and v to V .
                push!(G, (T,v))
            else
                @assert false "Didn't expect $status"
            end
        end

        considered += 1
    end

    # --------------------------------------------------------------------------
    # Interreduce the result
    # --------------------------------------------------------------------------
    result = getindex.(G, 2)
    k = length(result)
    progress_logged && @info("Done; interreducing the $k result polynomials")
    for i in 1:k
        xrem!(Full(), o, result[i], result[[1:i-1; i+1:k]])
        if modulebasering(eltype(result)) <: Integer
            result[i] ÷= content(result[i])
        end
    end
    # what we filter out is probably a Gröbner basis for the syzygies, and
    # maybe the caller wants to have it?
    filter!(!iszero, result)
    progress_logged && @info("Done. Returning a Gröbner basis of length $(length(result))")
    # --------------------------------------------------------------------------
    # Return the result
    # --------------------------------------------------------------------------
    if with_transformation
        result, transformation = separatetransformation(result)
        result = map(p->base_extend(p, P), result)
        return result, transformation
    else
        result = map(p->base_extend(p, P), result)
        return result
    end
end

gröbner_basis(::GWV, o::MonomialOrder, G::AbstractArray{<:Polynomial}; kwds...) = gwv(o, G, with_transformation=false, kwds...)
gröbner_transformation(::GWV, o::MonomialOrder, G::AbstractArray{<:Polynomial}; kwds...) = gwv(o, G, with_transformation=true, kwds...)

end
