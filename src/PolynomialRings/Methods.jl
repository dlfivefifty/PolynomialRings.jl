function ⊗ end
function to_dense_monomials end
function max_variable_index end

# -----------------------------------------------------------------------------
#
# Type information
#
# -----------------------------------------------------------------------------
function generators end
function basering end
function monomialtype end
function monomialorder end
function termtype end
function exptype end
function namestype end
function variablesymbols end
function allvariablesymbols end

base_extend(::Type{A}, ::Type{B}) where {A,B} = promote_type(A,B)

fraction_field(::Type{I}) where I <: Integer = Rational{I}
fraction_field(::Type{R}) where R <: Rational = R
fraction_field(::Type{R}) where R <: Real = R
fraction_field(::Type{Complex{N}}) where N <: Number = Complex{fraction_field(N)}

allvariablesymbols(::Type) = Set()

# -----------------------------------------------------------------------------
#
# Polynomial/term/monomial operations
#
# -----------------------------------------------------------------------------
function terms end
function leading_term end
function maybe_div end
function lcm_multipliers end
function lcm_degree end

export generators, ⊗, to_dense_monomials, max_variable_index, base_extend
