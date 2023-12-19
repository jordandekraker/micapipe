#!/bin/bash
#
# Microstructural imaging processing:
#
# Preprocessing workflow for qT1.
# Generates microstructural profiles and mpc matrices on specified parcellations
#
# This workflow makes use of freesurfer and custom python scripts
#
# Atlas an templates are avaliable from:
#
# https://github.com/MICA-MNI/micapipe/tree/master/parcellations
#
#   ARGUMENTS order:
#   $1 : BIDS directory
#   $2 : participant
#   $3 : Out Directory
#
BIDS=$1
id=$2
out=$3
SES=$4
nocleanup=$5
threads=$6
tmpDir=$7
input_im=$8
mpc_reg=$9
mpc_str=${10}
synth_reg=${11}
reg_nonlinear=${12}
PROC=${13}
export OMP_NUM_THREADS=$threads
here=$(pwd)

#------------------------------------------------------------------------------#
# qsub configuration
if [ "$PROC" = "qsub-MICA" ] || [ "$PROC" = "qsub-all.q" ] || [ "$PROC" = "LOCAL-MICA" ]; then
    MICAPIPE=/host/yeatman/local_raid/rcruces/git_here/micapipe
    source "${MICAPIPE}/functions/init.sh" "$threads"
fi

# source utilities
source "$MICAPIPE"/functions/utilities.sh

# Assigns variables names
bids_variables "$BIDS" "$id" "$out" "$SES"

# Check dependencies Status: POST_STRUCTURAL
micapipe_check_dependency "post_structural" "${dir_QC}/${idBIDS}_module-post_structural.json"

# Setting Surface Directory from post_structural
post_struct_json="${proc_struct}/${idBIDS}_post_structural.json"
recon=$(grep SurfRecon "${post_struct_json}" | awk -F '"' '{print $4}')
set_surface_directory "${recon}"

# Variables naming for multiple acquisitions
if [[ "${mpc_str}" == DEFAULT ]]; then
  mpc_str="qMRI"
  mpc_p="acq-qMRI"
else
  mpc_p="acq-${mpc_str}"
fi

# End if module has been processed
module_json="${dir_QC}/${idBIDS}_module-MPC-SWM_${mpc_str}.json"
micapipe_check_json_status "${module_json}" "MPC-SWM"

# Check microstructural image input flag and set parameters accordingly
if [[ "$input_im" == "DEFAULT" ]]; then microImage="$bids_T1map"; else microImage="${input_im}"; fi
Note "Microstructural image =" "$microImage"

# Check microstructural image to registrer
if [[ "$mpc_reg" == "DEFAULT" ]]; then regImage="${bids_inv1}"; else regImage="${mpc_reg}"; fi
Note "Microstructural image for registration =" "$regImage"

# Exit if microImage or Registration image do not exists
if [ ! -f "${microImage}" ]; then Error "Image for MPC-SWM was not found or the path is wrong!!!"; exit; fi
if [ ! -f "${regImage}" ]; then Error "Image for MPC-SWM registration was not found or the path is wrong!!!"; exit; fi

#------------------------------------------------------------------------------#
Title "Microstructural Profiles Covariance - SWM\n\t\tmicapipe $Version, $PROC"
micapipe_software
bids_print.variables-post
Note "Saving temporal dir : " "${nocleanup}"
Note "Parallel processing : " "${threads} threads"
Note "tmp dir   : " "${tmpDir}"
Note "recon     : " "${recon}"
Note "synth_reg : " ${synth_reg}
Note "reg_nonlinear : " ${reg_nonlinear}

#	Timer
aloita=$(date +%s)
Nsteps=0
N=0

# Create script specific temp directory
#tmp="${tmpDir}/${RANDOM}_micapipe_${mpc_str}-MPC_${id}"
tmp="${tmpDir}/${RANDOM}_micapipe_mpc-swm_${idBIDS}"
Do_cmd mkdir -p "$tmp"

# TRAP in case the script fails
trap 'cleanup $tmp $nocleanup $here' SIGINT SIGTERM

# Freesurface SUBJECTs directory
export SUBJECTS_DIR="$dir_surf"
outDir="${subject_dir}/mpc-swm/${mpc_p}"
Note "acqMRI:" "${mpc_str}"

# json file
#qt1_json="${dir_maps}/${idBIDS}_space-nativepro_map-${mpc_str}.json"

#------------------------------------------------------------------------------#
# Registration between both images
T1_in_fs=${tmp}/orig.nii.gz
qT1_fsnative=${proc_struct}/${idBIDS}_space-fsnative_${mpc_str}.nii.gz

# Affine transformations
str_qMRI2fs_xfm="${dir_warp}/${idBIDS}_from-${mpc_str}_to-fsnative"
mat_qMRI2fs_xfm="${str_qMRI2fs_xfm}0GenericAffine.mat"

# SyN_transformations
SyN_qMRI2fs_warp="${str_qMRI2fs_xfm}1Warp.nii.gz"
SyN_qMRI2fs_Invwarp="${str_qMRI2fs_xfm}1InverseWarp.nii.gz"

# Apply transformations
if [[ ${reg_nonlinear}  == "TRUE" ]]; then
    # SyN from T1_nativepro to t1-nativepro
    export reg="s"
    transformsInv="-t [${mat_qMRI2fs_xfm},1] -t ${SyN_qMRI2fs_Invwarp}" # T1_fsnative to qMRI
    transforms="-t ${SyN_qMRI2fs_warp} -t ${mat_qMRI2fs_xfm}"  # qMRI to T1_fsnative T1_fsnative to qMRI
else
    export reg="a"
    transformsInv="-t [${mat_qMRI2fs_xfm},1]"  # T1_fsnative to qMRI
    transforms="-t ${mat_qMRI2fs_xfm}"   # qMRI to T1_fsnative
fi

synthseg_native() {
  mri_img=$1
  mri_str=$2
  mri_synth="${tmp}/${mri_str}_synthsegGM.nii.gz"
  Do_cmd mri_synthseg --i "${mri_img}" --o "${tmp}/${mri_str}_synthseg.nii.gz" --robust --threads "$threads" --cpu
  Do_cmd fslmaths "${tmp}/${mri_str}_synthseg.nii.gz" -uthr 42 -thr 42 -bin -mul -39 -add "${tmp}/${mri_str}_synthseg.nii.gz" "${mri_synth}"
}

# Calculate the restristations
if [[ ! -f "$qT1_fsnative" ]] || [[ ! -f "$mat_qMRI2fs_xfm" ]]; then ((N++))
    img_fixed="${T1_in_fs}"
    img_moving="${regImage}"

    # copy orig.nii.gz from fsurfer to tmp
    Do_cmd mrconvert "$T1surf" "$T1_in_fs"
    # Registration with synthseg
    if [[ "${synth_reg}" == "TRUE" ]]; then
      Info "Running label based affine registrations"
      synthseg_native "${T1_in_fs}" "T1w"
      synthseg_native "${regImage}" "qT1"
      img_fixed="${tmp}/T1w_synthsegGM.nii.gz"
      img_moving="${tmp}/qT1_synthsegGM.nii.gz"
    fi

    # Registrations from t1-fsnative to qMRI
    Do_cmd antsRegistrationSyN.sh -d 3 -f "$img_fixed" -m "$img_moving" -o "$str_qMRI2fs_xfm" -t "${reg}" -n "$threads" -p d -i ["${img_fixed}","${img_moving}",0]

    # Check if transfo ations file exist
    if [ ! -f "${mat_qMRI2fs_xfm}" ]; then Error "Registration between ${mpc_str} and T1nativepro FAILED. Check you inputs!"; cleanup "$tmp" "$nocleanup" "$here"; exit; fi

    # Apply transformations: from qMRI to T1-fsnative
    Do_cmd antsApplyTransforms -d 3 -i "$microImage" -r "$T1_in_fs" "${transforms}" -o "$qT1_fsnative" -v -u int
    if [[ -f ${qT1_fsnative} ]]; then ((Nsteps++)); fi
else
    Info "Subject ${id} has a ${mpc_str} on Surface space"; ((Nsteps++)); ((N++))
fi

# Convert the ANTs transformation file for wb_command
wb_affine="${tmp}/${idBIDS}_from-fsnative_to_qMRI_wb.mat"
Do_cmd c3d_affine_tool -itk "${mat_qMRI2fs_xfm}" -o "${wb_affine} -inv"

#------------------------------------------------------------------------------#
# Check if the directory exists and change the permissions
[[ ! -d "$outDir" ]] && mkdir -p "$outDir" && chmod -R 770 "$outDir"
# Create the MPC-SWM module json file
json_mpc "$microImage" "${outDir}/${idBIDS}_MPC-SWM_${mpc_str}.json"

# Laplacian surface generation
num_surfs=15
thickness=0.2

Nwm=$(ls "${dir_conte69}/${idBIDS}_hemi-"*_surf-fsnative_label-swm*.surf.gii 2>/dev/null | wc -l)
if [[ "$Nwm" -lt 15 ]]; then ((N++))
    # Import the surface segmentation to NIFTI
    T1fs_seg="${tmp}/aparc+aseg.nii.gz"
    Do_cmd mri_convert "${dir_subjsurf}/mri/aparc+aseg.mgz" "${T1fs_seg}"

    # Move the segmentation to T1_nativepro space
    mat_fsnative_affine="${dir_warp}/${idBIDS}_from-fsnative_to_nativepro_T1w_"
    T1_fsnative_affine="${mat_fsnative_affine}0GenericAffine.mat"
    T1nativepro_seg="${tmp}/aparc+aseg_space-nativepro.nii.gz"
    Do_cmd antsApplyTransforms -d 3 -i "${T1fs_seg}" -r "${T1nativepro}" -t ${T1_fsnative_affine} -o "${T1nativepro_seg}" -n GenericLabel -v -u int

    # Generate the laplacian field
    WM_laplace=${tmp}/wm-laplace.nii.gz
    Do_cmd python "$MICAPIPE"/functions/laplace_solver.py ${T1nativepro_seg} ${WM_laplace}

    deepths=($(seq "$thickness" "$thickness" "$((num_surfs * thickness))"))

    # Create the surfaces by depths
    for HEMI in L R; do
      # Prepare the white matter surface
      Do_cmd cp "${dir_conte69}/${idBIDS}_hemi-${HEMI}_space-nativepro_surf-fsnative_label-white.surf.gii ${tmp}/${HEMI}_wm.surf.gii"
      # Run SWM
      Do_cmd python "${MICAPIPE}"/functions/surface_generator.py "${tmp}/${HEMI}_wm.surf.gii" "${WM_laplace}" "${dir_conte69}/${idBIDS}_hemi-${HEMI}_surf-fsnative_label-swm" "${deepths}"

      # find all laplacian surfaces and list by creation time
      x=$(ls -t ${dir_conte69}/${idBIDS}_hemi-${HEMI}_surf-fsnative_label-swm*)
      for n in $(seq 1 1 "$num_surfs") ; do
          which_surf=$(sed -n "$n"p <<< "$x")
          surf_gii="${tmp}/${hemi}.${n}by${num_surf}_space-fsnative.surf.gii"
          surf_tmp="${tmp}/${hemi}.${n}by${num_surf}_no_offset.surf.gii"
          out_surf="${tmp}/${hemi}.${n}by${num_surf}_space-qMRI.surf.gii"
          out_feat="${outDir}/${idBIDS}_hemi-${HEMI}_surf-fsnative_label-MPC-${n}.func.gii"
          # Register surface to qMRI space
          Do_cmd mris_convert "$which_surf" "${surf_gii}"
          # Apply transformation to register surface to nativepro
          Do_cmd wb_command -surface-apply-affine "${surf_tmp}" "${wb_affine}" "${out_surf}"
          # Apply Non-linear Warpfield to register surface to nativepro
          if [[ ${reg_nonlinear}  == "TRUE" ]]; then Do_cmd wb_command -surface-apply-warpfield "${out_surf}" "${SyN_qMRI2fs_Invwarp}" "${out_surf}"; fi
          # Sample intensity and resample to other surfaces
          map_to-surfaces "${microImage}" "${out_surf}" "${out_feat}" "${HEMI}" "MPC-${n}" "${outDir}"
          # remove tmp surfaces
          rm "${surf_tmp}" "${which_surf}"
       done
    done
    Nwm=$(ls "${dir_conte69}/${idBIDS}_hemi-"*_surf-fsnative_label-swm*.surf.gii 2>/dev/null | wc -l)
    if [[ "$Nwm" -ge 15 ]]; then ((Nsteps++)); fi
else
    Info "Subject ${idBIDS} has SWM surfaces"; ((Nsteps++)); ((N++))
fi

#------------------------------------------------------------------------------#
### qT1 registration to nativepro ###
# Register nativepro and qt1
# T1_fsnative_affine="${dir_warp}/${idBIDS}_from-fsnative_to_nativepro_T1w_0GenericAffine.mat"
#
# qmriNP="${dir_maps}/${idBIDS}_space-nativepro_map-${mpc_str}.nii.gz"
# if [[ ! -f "$qmriNP" ]]; then
#   Info "${mpc_str} registration to nativepro"
#     Do_cmd antsApplyTransforms -d 3 -i "$microImage" -r "$T1nativepro_brain" -t "${T1_fsnative_affine}" "${transforms}" -o "$qmriNP" -v -u float
#     ((Nsteps++)); ((N++))
# else
#     Info "Subject ${id} ${mpc_str} is registered to nativepro"; ((Nsteps++)); ((N++))
# fi

# Write json file
#json_nativepro_qt1 "$qmriNP" \
#    "antsApplyTransforms -d 3 -i ${microImage} -r ${T1nativepro_brain} -t ${T1_fsnative_affine} ${transforms} -o ${qmriNP} -v -u float" \
#    "$qt1_json"

#------------------------------------------------------------------------------#
# # Map to surface: midthickness, white
# Nmorph=$(ls "${dir_maps}/"*"${mpc_str}"*gii 2>/dev/null | wc -l)
# if [[ "$Nmorph" -lt 16 ]]; then ((N++))
#     Info "Mapping ${mpc_str} to fsLR-32k, fsLR-5k and fsaverage5"
#     for HEMI in L R; do
#         for label in midthickness white; do
#             surf_fsnative="${dir_conte69}/${idBIDS}_hemi-${HEMI}_space-nativepro_surf-fsnative_label-${label}.surf.gii"
#             # MAPPING metric to surfaces
#             map_to-surfaces "${qmriNP}" "${surf_fsnative}" "${dir_maps}/${idBIDS}_hemi-${HEMI}_surf-fsnative_label-${label}_${mpc_str}.func.gii" "${HEMI}" "${label}_${mpc_str}" "${dir_maps}"
#         done
#     done
#     Nmorph=$(ls "${dir_maps}/"*${mpc_str}*gii 2>/dev/null | wc -l)
#     if [[ "$Nmorph" -eq 16 ]]; then ((Nsteps++)); fi
# else
#     Info "Subject ${idBIDS} has ${mpc_str} mapped to surfaces"; ((Nsteps++)); ((N++))
# fi

# Map to surface: swm depths
maps=(${dir_maps}/*nii*)
for map in ${maps[*]}; do
  map_id=$(echo ${map/.nii.gz/} | awk -F 'map-' '{print $2}')
  # Map to surface: swm
      for HEMI in L R; do
          for i in $(ls "${dir_conte69}/${idBIDS}_hemi-L"_surf-fsnative_label-swm*mm.surf.gii); do
              label=$(echo ${i/.surf.gii/} | awk -F 'label-' '{print $2}')
              Info "Mapping ${map_id} SWM-${label} to fsLR-32k, fsLR-5k and fsaverage5"
              surf_fsnative="${dir_conte69}/${idBIDS}_hemi-${HEMI}_surf-fsnative_label-${label}.surf.gii"
              # MAPPING metric to surfaces
              map_to-surfaces "${map}" "${surf_fsnative}" "${dir_maps}/${idBIDS}_hemi-${HEMI}_surf-fsnative_label-${label}_${map_id}.func.gii" "${HEMI}" "${label}_${map_id}" "${dir_maps}"
          done
      done
done

#------------------------------------------------------------------------------#
# Create MPC connectomes and Intensity profiles per parcellations
parcellations=($(find "$dir_volum" -name "*atlas*" ! -name "*cerebellum*" ! -name "*subcortical*"))
for seg in "${parcellations[@]}"; do
    parc=$(echo "${seg/.nii.gz/}" | awk -F 'atlas-' '{print $2}')
    parc_annot="${parc}_mics.annot"
    MPC_int="${outDir}/${idBIDS}_atlas-${parc}_desc-intensity_profiles.shape.gii"
    if [[ ! -f "$MPC_int" ]]; then ((N++))
        Info "Running MPC on $parc"
        Do_cmd python "$MICAPIPE"/functions/surf2mpc_swm.py "$out" "$id" "$SES" "$num_surfs" "$parc_annot" "$dir_subjsurf" "${mpc_p}"
        if [[ -f "$MPC_int" ]]; then ((Nsteps++)); fi
    else Info "Subject ${id} has MPC connectome and intensity profile on ${parc}"; ((Nsteps++)); ((N++)); fi
done

#------------------------------------------------------------------------------#
# Create vertex-wise MPC connectome and directory cleanup
if [[ ! -f "${MPC_fsLR5k}" ]]; then ((N++))
  Info "Running MPC vertex-wise on fsLR-5k"
  Do_cmd python "$MICAPIPE"/functions/build_mpc-vertex_swm.py "$out" "$id" "$SES" "${mpc_p}"
  ((Nsteps++))
else Info "Subject ${id} has MPC vertex-wise on fsLR-5k"; ((Nsteps++)); ((N++)); fi
rm "${dir_warp}/${idBIDS}"*_Warped.nii.gz

#------------------------------------------------------------------------------#
# QC notification of completition
lopuu=$(date +%s)
eri=$(echo "$lopuu - $aloita" | bc)
eri=$(echo print "$eri"/60 | perl)

# Notification of completition
micapipe_completition_status "MPC-SWM"
micapipe_procStatus "${id}" "${SES/ses-/}" "MPC-SWM_${mpc_str}" "${out}/micapipe_processed_sub.csv"
Do_cmd micapipe_procStatus_json "${id}" "${SES/ses-/}" "MPC-SWM_${mpc_str}" "${module_json}"
cleanup "$tmp" "$nocleanup" "$here"
