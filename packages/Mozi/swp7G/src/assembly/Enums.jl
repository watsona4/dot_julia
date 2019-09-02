module Enums
export SectionType,MaterialType,LoadCaseType

@enum SparseSolver begin
    USE_PARDISO
end

@enum SectionType begin
    GENERAL_SECTION=0
    ISECTION=1
    HSECTION=2
    BOX=3
    PIPE=4
    CIRCLE=5
    RECTANGLE=6
end

@enum LoadCaseType begin
    STATIC
    MODAL
    BUCKLING
    TIME_HISTORY
    SPECTRUM
end

@enum MaterialType begin
    GENERAL_MATERIAL
    ISOELASTIC
    UNIAXIAL_METAL
end

@enum MassSource begin
    WEIGHT
    LOAD
end

@enum MassMatrixType begin
    CONCENTRATED
    COORDINATED
end

@enum DampType begin
    CONSTANT
    RAYLEIGH
end

@enum DynamicAlgorithm begin
    CENTRAL_DIFF
    NEWMARK_THETA
    WILSON_BETA
    MODOL_DECOMP
end

@enum ModalType begin
    EIGEN
    RITZ
end

@enum RefCSys begin
    GLOBAL
    LOCAL
end

end
