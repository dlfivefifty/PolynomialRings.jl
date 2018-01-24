module Backends

module Gröbner
    abstract type Backend end
    struct Buchberger <: Backend end
    struct GWV <: Backend end
    _default = GWV()
    cur_default = _default
    set_default()  = (global cur_default; cur_default=_default)
    set_default(x) = (global cur_default; cur_default=x)

    using PolynomialRings
    import PolynomialRings: gröbner_basis, gröbner_transformation, monomialorder

    # fallback in case a backend only provides one, but not the other
    gröbner_basis(b::Backend, args...; kwds...)         = gröbner_transformation(b, args...; kwds...)[1]
    gröbner_transformation(::Backend, args...; kwds...) = gröbner_transformation(Buchberger(), args...; kwds...)

    # fallback in case a monomial order is not passed explicitly: choose it from G
    gröbner_basis(b::Backend, G::AbstractVector, args...; kwds...) = gröbner_basis(b, monomialorder(eltype(G)), G, args...; kwds...)
    gröbner_transformation(b::Backend, G::AbstractVector, args...; kwds...) = gröbner_transformation(b, monomialorder(eltype(G)), G, args...; kwds...)
    """
        basis, transformation = gröbner_transformation(polynomials)

    Return a Gröbner basis for the ideal generated by `polynomials`, together with a
    `transformation` that proves that each element in `basis` is in that ideal (i.e.
    `basis == transformation * polynomials`).

    This is computed using the Buchberger algorithm with a few standard
    optmizations; see [`PolynomialRings.Gröbner.buchberger`](@ref) for details.
    """
    gröbner_transformation(G::AbstractVector, args...; kwds...) = gröbner_transformation(cur_default, G, args...; kwds...)
    """
        basis = gröbner_basis(polynomials)

    Return a Gröbner basis for the ideal generated by `polynomials`.

    This is computed using the GWV algorithm; see
    [`PolynomialRings.GröbnerGWV.gwv`](@ref) for details.
    """
    gröbner_basis(G::AbstractVector, args...; kwds...) = gröbner_basis(cur_default, G, args...; kwds...)
end

end
