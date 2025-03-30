#!/bin/bash
#
# This script runs micapipe on the same subject on:
# SINGLE session 3T
# multi-session 3T
# multi-session 7T

# input arguments
version=0.2.3
container=singularity
container_img=/data_/mica1/01_programs/micapipe-v0.2.0/micapipe_v0.2.3.sif

# Local variables
bids=/data/mica3/BIDS_CI/rawdata
fs_lic=/data_/mica3/BIDS_CI/license_fc.txt
tmp=/tmp

# Create a timestamp (e.g., 20250328_150305)
timestamp=$(date +%Y%m%d_%H%M%S)
outdir_base="/data/mica1/03_projects/enning/BIDS_CI/${container}_${version}"

# -------------------------------------------------------------------------------
function run_test(){
    recon=$1

    # Conditional statement for freesurfer/fastsurfer run
    if [[ "$recon" == "freesurfer" ]]; then
        out="${outdir_base}_freesurfer_${timestamp}"
        recon="-freesurfer"
    else
        out="${outdir_base}_${timestamp}"
        recon=""
    fi

    # Create output directory; -p avoids error if directory exists
    mkdir -p ${out} || { echo "Failed to create ${out}"; exit 1; }
    chmod 777 ${out} || echo "Warning: could not set permissions for ${out}"

    # Create command string
    if [[ "$container" == "docker" ]]; then
      command="docker run -ti --rm -v ${bids}:/bids -v ${out}:/out -v ${tmp}:/tmp -v ${fs_lic}:/opt/licence.txt ${container_img}"
    elif [[ "$container" == "singularity" ]]; then
      command="singularity run --writable-tmpfs --containall -B ${bids}:/bids -B ${out}:/out -B ${tmp}:/tmp -B ${fs_lic}:/opt/licence.txt ${container_img}"
    fi

    # Session 01 and 02: run for each session (example with one session)
    for i in 01; do
      ses=ses-${i}
      sub=sub-mri3T
      ${command} \
      -bids /bids -out /out -fs_licence /opt/licence.txt -threads 15 -sub ${sub} -ses ${ses} \
      -proc_structural -proc_surf -post_structural -proc_dwi -GD -proc_func -MPC -MPC_SWM -SC -SWM -QC_subj -proc_flair \
      -atlas economo,aparc \
      -dwi_rpe /bids/${sub}/${ses}/dwi/${sub}_${ses}_acq-b0_dir-PA_epi.nii.gz -dwi_upsample \
      -func_pe /bids/${sub}/${ses}/fmap/${sub}_${ses}_acq-fmri_dir-AP_epi.nii.gz \
      -func_rpe /bids/${sub}/${ses}/fmap/${sub}_${ses}_acq-fmri_dir-PA_epi.nii.gz \
      -mpc_acq T1map -regSynth -tracts 100000 \
      -microstructural_img /bids/${sub}/${ses}/anat/${sub}_${ses}_acq-T1_T1map.nii.gz \
      -microstructural_reg /bids/${sub}/${ses}/anat/${sub}_${ses}_acq-inv1_T1map.nii.gz ${recon}
    done
}

# Run tests
run_test "fastsurfer"
run_test "freesurfer"
