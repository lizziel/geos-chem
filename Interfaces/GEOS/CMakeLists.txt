esma_set_this(OVERRIDE GEOSCHEMchem_GridComp)

set(srcs
    GEOSCHEMchem_GridCompMod.F90
    )
set_source_files_properties (${src} PROPERTIES COMPILE_FLAGS "${FOPT2} ${GEOS_Fortran_Release_FPE_Flags} ${ALIGNCOM}")

esma_add_library (${this}
   SRCS ${srcs}
   DEPENDENCIES MAPL MAPL_cfio_r4 Chem_Base Chem_Shared GCHP
   GeosCore GeosRad GeosUtil Hg History Isorropia NcdfUtil ObsPack
   KPPFirstPass_Standard KPP_Standard KPPFirstPass_Tropchem KPP_Tropchem KPPFirstPass_SOA_SVPOA KPP_SOA_SVPOA
   )

target_include_directories (${this} PUBLIC ${INC_ESMF} ${INC_NETCDF})
target_link_libraries(${this} PUBLIC HCOI_MAPL_ESMF)

target_compile_definitions(${this} PRIVATE ESMF_ DEVEL NO_BPCH UCX
   EXTERNAL_GRID EXTERNAL_FORCING GEOS_FP USE_REAL8 USE_TEND NC_DIAG DISCOVER MODEL_GEOS)

if (CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
   target_compile_definitions(${this} PRIVATE LINUX_IFORT)
endif ()

if (CMAKE_Fortran_COMPILER_ID MATCHES "PGI")
   target_compile_definitions(${this} PRIVATE LINUX_PGI)
endif ()

if (CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
   target_compile_definitions(${this} PRIVATE LINUX_GFORTRAN)
endif ()


set_target_properties (${this} PROPERTIES Fortran_MODULE_DIRECTORY ${include_${this}})

new_esma_generate_automatic_code (
   ${this} GEOSCHEMchem_Registry.rc
   "GEOSCHEMCHEM_InternalSpec___.h;GEOSCHEMCHEM_DeclarePointer___.h;GEOSCHEMCHEM_GetPointer___.h"
   GEOSCHEMCHEM_History___.rc
   ${include_GEOSCHEMchem_GridComp} ${esma_etc}
   "-v;-F"
   )

file (GLOB resource_files "*.rc")

install(
   FILES ${resource_files}
   DESTINATION etc
   )
