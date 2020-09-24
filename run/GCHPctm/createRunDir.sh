#!/bin/bash

# createRunDir.sh: Create GCHP run directory
#
# Optional argument: run directory name
#
# If optional run directory name argument is not passed then the user
# will be prompted to enter a name interactively, or choose to use the
# default name gchp_{simulation}.
#
# Usage: ./createRunDir.sh [rundirname]
#
# Initial version: E. Lundgren,10/5/2018

srcrundir=$(pwd -P)
cd ${srcrundir}
cd ../..
gcdir=$(pwd)
cd ../../../..
gchpdir=$(pwd)
cd ${srcrundir}

# Load file with utility functions to setup configuration files
. ${gcdir}/run/shared/setupConfigFiles.sh

# Initialize RDI_VARS
RDI_VARS=""

# Define separator lines
thickline="\n===========================================================\n"
thinline="\n-----------------------------------------------------------\n"

printf "${thickline}GCHP RUN DIRECTORY CREATION${thickline}"

#-----------------------------------------------------------------
# Export data root path in ~/.geoschem/config if file exists
#-----------------------------------------------------------------
if [[ -f ${HOME}/.geoschem/config ]]; then
    source ${HOME}/.geoschem/config
    if [[ ! -d ${GC_DATA_ROOT} ]]; then
	printf "\nWarning: Default root data directory does not exist!"
        printf "\nSet new path below or manually edit ${HOME}/.geoschem/config.\n"
    fi
else
    printf "${thinline}Define path to ExtData."
    printf "\nThis will be stored in ${HOME}/.geoschem/config for future automatic use.${thinline}"
    mkdir -p ${HOME}/.geoschem
fi

#-----------------------------------------------------------------
# One-time configuration of data root path in ~/.geoschem/config
#-----------------------------------------------------------------
if [[ -z "${GC_DATA_ROOT}" ]]; then
    printf "${thinline}Enter path for ExtData:${thinline}"
    valid_path=0
    while [ "$valid_path" -eq 0 ]; do
	read extdata
	if [[ ${extdata} = "q" ]]; then
	    printf "\nExiting.\n"
	    exit 1
	elif [[ ! -d ${extdata} ]]; then
            printf "\nERROR: ${extdata} does not exist. Enter a new path or hit q to quit.\n"
	else
	    valid_path=1
	    echo "export GC_DATA_ROOT=${extdata}" >> ${HOME}/.geoschem/config
            source ${HOME}/.geoschem/config
	fi
    done
fi

RDI_VARS+="RDI_DATA_ROOT=$GC_DATA_ROOT\n"

#-----------------------------------------------------------------
# Ask user to select simulation type
#-----------------------------------------------------------------
printf "${thinline}Choose simulation type:${thinline}"
printf "   1. Full chemistry\n"
printf "   2. TransportTracers\n"

valid_sim=0
while [ "${valid_sim}" -eq 0 ]; do
    read sim_num
    valid_sim=1
    if [[ ${sim_num} = "1" ]]; then
	sim_name=fullchem
    elif [[ ${sim_num} = "2" ]]; then
	sim_name=TransportTracers
    else
        valid_sim=0
	printf "Invalid simulation option. Try again.\n"
    fi
done

RDI_VARS+="RDI_SIM_NAME=$sim_name\n"

#-----------------------------------------------------------------
# Ask user to specify full-chemistry simulation options
#-----------------------------------------------------------------
sim_extra_option=none

# Ask user to specify full chemistry simulation options
if [[ ${sim_name} = "fullchem" ]]; then
    
    printf "${thinline}Choose additional simulation option:${thinline}"
    printf "  1. Standard\n"
    printf "  2. Benchmark\n"
    printf "  3. Complex SOA\n"
    printf "  4. Marine POA\n"
    printf "  5. Acid uptake on dust\n"
    printf "  6. TOMAS\n"
    printf "  7. APM\n"
    printf "  8. RRTMG\n"
    valid_sim_option=0
    while [ "${valid_sim_option}" -eq 0 ]; do
	read sim_option
	valid_sim_option=1
	if [[ ${sim_option} = "1" ]]; then
	    sim_extra_option=none
	elif [[ ${sim_option} = "2" ]]; then
	    sim_extra_option="benchmark"
	elif [[ ${sim_option} = "3" ]]; then
	    printf "${thinline}Choose complex SOA option:${thinline}"
	    printf "  1. Complex SOA\n"
	    printf "  2. Complex SOA with semivolatile POA\n"
	    valid_soa=0
	    while [ "${valid_soa}" -eq 0 ]; do
		read soa_option
		valid_soa=1
		if [[ ${soa_option} = "1" ]]; then
		    sim_extra_option="complexSOA"
		elif [[ ${soa_option} = "2" ]]; then
		    sim_extra_option="complexSOA_SVPOA"
		else
		    valid_soa=0
		    printf "Invalid complex SOA option.Try again.\n"
		fi
	    done
	elif [[ ${sim_option} = "4" ]]; then
	   sim_extra_option="marinePOA"
	elif [[ ${sim_option} = "5" ]]; then
	   sim_extra_option="aciduptake"
	elif [[ ${sim_option} = "6" ]]; then
	    printf "${thinline}Choose TOMAS option:${thinline}"
	    printf "  1. TOMAS with 15 bins\n"
	    printf "  1. TOASS with 40 bins\n"
	    valid_tomas=0
	    while [ "${valid_tomas}" -eq 0 ]; do
		read tomas_option
		valid_tomas=1
		if [[ ${tomas_option} = "1" ]]; then
		    sim_extra_option="TOMAS15"
		elif [[ ${tomas_option} = "2" ]]; then
		    sim_extra_option="TOMAS40"
		else
		    valid_tomas=0
		    printf "Invalid TOMAS option. Try again.\n"
		fi
	    done
	elif [[ ${sim_option} = "7" ]]; then
	    sim_extra_option="APM"
	elif [[ ${sim_option} = "8" ]]; then
	    sim_extra_option="RRTMG"
	else
	    valid_sim_option=0
	    printf "Invalid simulation option. Try again.\n"
	fi
    done

# Currently no transport tracer extra options
elif [[ ${sim_name} = "TransportTracers" ]]; then
   sim_extra_option=none

fi 

#-----------------------------------------------------------------
# Ask user to select meteorology source
#-----------------------------------------------------------------
printf "${thinline}Choose meteorology source:${thinline}"
printf "  1. MERRA2 (Recommended)\n"
printf "  2. GEOS-FP \n"
valid_met=0
while [ "${valid_met}" -eq 0 ]; do
    read met_num
    valid_met=1
    if [[ ${met_num} = "1" ]]; then
      RDI_VARS+="$(cat ${srcrundir}/settings/merra2_settings.txt)\n"
      RDI_VARS+='RDI_MET_DIR=$RDI_DATA_ROOT/GEOS_0.5x0.625/MERRA2\n'
    elif [[ ${met_num} = "2" ]]; then
      RDI_VARS+="$(cat ${srcrundir}/settings/geosfp_settings.txt)\n"
      RDI_VARS+='RDI_MET_DIR=$RDI_DATA_ROOT/GEOS_0.25x0.3125/GEOS_FP\n'
    else
	valid_met=0
	printf "Invalid meteorology option. Try again.\n"
    fi
done



#-----------------------------------------------------------------
# Ask user to define path where directoy will be created
#-----------------------------------------------------------------
printf "${thinline}Enter path where the run directory will be created:${thinline}"
valid_path=0
while [ "$valid_path" -eq 0 ]; do
    read rundir_path
    if [[ ${rundir_path} = "q" ]]; then
	printf "\nExiting.\n"
	exit 1
    elif [[ ! -d ${rundir_path} ]]; then
        printf "\nERROR: ${rundir_path} does not exist. Enter a new path or hit q to quit.\n"
    else
	valid_path=1
    fi
done

#-----------------------------------------------------------------
# Ask user to define run directoy name if not passed as argument
#-----------------------------------------------------------------
if [ -z "$1" ]; then
    printf "${thinline}Enter run directory name, or press return to use default:${thinline}"
    read rundir_name
    if [[ -z "${rundir_name}" ]]; then
	if [[ "${sim_extra_option}" = "none" ]]; then
	    rundir_name=gchp_${sim_name}
	else
	    rundir_name=gchp_${sim_name}_${sim_extra_option}
	fi
	printf "  -- Using default directory name ${rundir_name}\n"
    fi
else
    rundir_name=$1
fi

#-----------------------------------------------------------------
# Ask user for a new run directory name if specified one exists
#-----------------------------------------------------------------
rundir=${rundir_path}/${rundir_name}
valid_rundir=0
while [ "${valid_rundir}" -eq 0 ]; do
    if [[ -d ${rundir} ]]; then
	printf "\nWARNING: ${rundir} already exists.\n"
        printf "Enter a different run directory name, or q to quit:\n"
	read new_rundir
	if [[ ${new_rundir} = "q" ]]; then
	    printf "Exiting.\n"
	    exit 1
	else
	    rundir=${rundir_path}/${new_rundir}
	fi
    else
        valid_rundir=1
    fi
done

#-----------------------------------------------------------------
# Create run directory
#-----------------------------------------------------------------
mkdir -p ${rundir}

# Copy run directory files and subdirectories
cp ${gcdir}/run/shared/cleanRunDir.sh ${rundir}
cp ./archiveRun.sh                    ${rundir}
cp ./README                           ${rundir}
cp ./setEnvironment.sh                ${rundir}
cp ./gitignore                        ${rundir}/.gitignore
if [[ ${sim_name} = "fullchem" ]]; then
    cp -r ${gcdir}/run/shared/metrics_fullchem.py  ${rundir}
    chmod 744 ${rundir}/metrics_fullchem.py
fi
cp -r ./runScriptSamples              ${rundir}

# Set permissions
chmod 744 ${rundir}/setEnvironment.sh
chmod 744 ${rundir}/cleanRunDir.sh
chmod 744 ${rundir}/archiveRun.sh
chmod 744 ${rundir}/runScriptSamples/*
chmod 644 ${rundir}/runScriptSamples/README

# Copy species database; append APM or TOMAS species if needed
cp -r ${gcdir}/run/shared/species_database.yml   ${rundir}
if [[ ${sim_extra_option} =~ "TOMAS" ]]; then
    cat ${gcdir}/run/shared/species_database_tomas.yml >> ${rundir}/species_database.yml
elif [[ ${sim_extra_option} =~ "APM" ]]; then
    cat ${gcdir}/run/shared/species_database_apm.yml >> ${rundir}/species_database.yml
fi

# If benchmark simulation, put run script in directory
if [[ ${sim_extra_option} = "benchmark" ]]; then
    cp ./runScriptSamples/gchp.benchmark.run ${rundir}
    chmod 744 ${rundir}/gchp.benchmark.run
fi

# Create symbolic links to data directories, restart files, and code
ln -s ${gchpdir}                                ${rundir}/CodeDir
ln -s ${GFTL}                                   ${rundir}/gFTL
restarts=${GC_DATA_ROOT}/SPC_RESTARTS
for N in 24 48 90 180 360
do
    ln -s ${restarts}/initial_GEOSChem_rst.c${N}_${sim_name}.nc  ${rundir}
done

# Put RDI_RESTART_FILE='initial_GEOSChem_rst.c${CS_RES}'_fullchem.nc in RDI vars
RDI_VARS+="RDI_RESTART_FILE='initial_GEOSChem_rst.c"'${CS_RES}'"'_${sim_name}.nc\n"

# Determine settings
if [[ ${sim_extra_option} = "benchmark" ]]; then
   RDI_VARS+="$(cat ${srcrundir}/settings/benchmark_settings.txt)\n"
elif [[ ${sim_name} == "TransportTracers" ]]; then
   RDI_VARS+="$(cat ${srcrundir}/settings/transporttracer_settings.txt)\n"
else
   RDI_VARS+="$(cat ${srcrundir}/settings/fullchem_settings.txt)\n"
fi

#--------------------------------------------------------------------
# Navigate to run directory and set up input files
#--------------------------------------------------------------------
cd ${rundir}

echo -e "$RDI_VARS" > rdi_vars.txt

# Call init_rd.sh
${srcrundir}/init_rd.sh rdi_vars.txt

# Call function to setup configuration files with settings common between
# GEOS-Chem Classic and GCHP.
if [[ ${sim_name} = "fullchem" ]]; then
    set_common_settings ${sim_extra_option}
fi

# Call runConfig.sh so that all config files are consistent with its
# default settings. Suppress informational prints.
chmod +x runConfig.sh
./runConfig.sh --silent

#--------------------------------------------------------------------
# Navigate back to source code directory
#--------------------------------------------------------------------
cd ${srcrundir}

#----------------------------------------------------------------------
# Archive repository version in run directory file rundir.version
#----------------------------------------------------------------------
version_log=${rundir}/rundir.version
echo "This run directory was created with ${srcrundir}/createRunDir.sh." > ${version_log}
echo " " >> ${version_log}
echo "GEOS-Chem repository version information:" >> ${version_log}
cd ${gcdir}
remote_url=$(git config --get remote.origin.url)
code_branch=$(git rev-parse --abbrev-ref HEAD)
last_commit=$(git log -n 1 --pretty=format:"%s")
commit_date=$(git log -n 1 --pretty=format:"%cd")
commit_user=$(git log -n 1 --pretty=format:"%cn")
commit_hash=$(git log -n 1 --pretty=format:"%h")
cd ${srcrundir}
printf "\n  Remote URL: ${remote_url}" >> ${version_log}
printf "\n  Branch: ${code_branch}"    >> ${version_log}
printf "\n  Commit: ${last_commit}"    >> ${version_log}
printf "\n  Date: ${commit_date}"      >> ${version_log}
printf "\n  User: ${commit_user}"      >> ${version_log}
printf "\n  Hash: ${commit_hash}"      >> ${version_log}

#-----------------------------------------------------------------
# Ask user whether to track run directory changes with git
#-----------------------------------------------------------------
printf "${thinline}Do you want to track run directory changes with git? (y/n)${thinline}"
valid_response=0
while [ "$valid_response" -eq 0 ]; do
    read enable_git
    if [[ ${enable_git} = "y" ]]; then
	cd ${rundir}
	printf "\n\nChanges to the following run directory files are tracked by git:\n\n" >> ${version_log}
	printf "\n"
	git init
	git add *.rc *.sh *.yml *.run input.geos input.nml
        if [[ ${sim_name} = "fullchem" ]]; then
            git add *.py
        fi
	git add runScriptSamples/* README .gitignore
	printf " " >> ${version_log}
	git commit -m "Initial run directory" >> ${version_log}
	cd ${srcrundir}
	valid_response=1
    elif [[ ${enable_git} = "n" ]]; then
	valid_response=1
    else
	printf "Input not recognized. Try again.\n"
    fi
done

#-----------------------------------------------------------------
# Done!
#-----------------------------------------------------------------
printf "\nCreated ${rundir}\n"

exit 0
