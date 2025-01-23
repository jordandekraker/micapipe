def get_dwi_outputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="dwi",
        **inputs["t1w"].wildcards
    )

# rule for diffusion processing
rule proc_dwi:
    input:
        # DWI processing requires structural output as dependency
        inputs['t1w'].expand(
            get_structural_outputs(inputs, output_dir)
        ),
    output:
        processed_dwi=get_dwi_outputs(inputs, output_dir)
    params:
        dwi_main=process_multi_inputs(config["parameters"]["proc_dwi"]["dwi_main"]),
        dwi_rpe=process_multi_inputs(config["parameters"]["proc_dwi"]["dwi_rpe"]),
        dwi_processed=config["parameters"]["proc_dwi"]["dwi_processed"],
        rpe_all=config["parameters"]["proc_dwi"]["rpe_all"],
        regAffine=config["parameters"]["proc_dwi"]["regAffine"],
        b0thr=config["parameters"]["proc_dwi"]["b0thr"],
        # the following are just flags
        dwi_acq=process_2_flags(config["parameters"]["proc_dwi"]["dwi_acq"], "dwi_acq", config["parameters"]["proc_dwi"]["dwi_str"]),
        no_bvalue_scaling=process_flags(config["parameters"]["proc_dwi"]["no_bvalue_scaling"], "no_bvalue_scaling"),
        regSynth=process_flags(config["parameters"]["proc_dwi"]["regSynth"], "regSynth"),
        dwi_upsample=process_flags(config["parameters"]["proc_dwi"]["dwi_upsample"], "dwi_upsample"),
    threads: config.get("threads", 4),
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -proc_dwi \
            -threads {threads} -ses {wildcards.session} -dwi_main {params.dwi_main} -dwi_rpe {params.dwi_rpe} \
            -dwi_processed {params.dwi_processed} -rpe_all {params.rpe_all} -regAffine {params.regAffine} \
            -b0thr {params.b0thr} {params.dwi_acq} {params.no_bvalue_scaling} {params.regSynth} {params.dwi_upsample}
        """

# rule sc:
#     input:
#         dwi_output=lambda w: f"{output_dir}/sub-{w.subject}/ses-{w.session}/dwi/processed_dwi.mif",
#         post_structural=lambda w: f"{output_dir}/sub-{w.subject}/ses-{w.session}/anat/post_structural.nii.gz"
#     output:
#         sc_output=f"{output_dir}/sub-{{subject}}/ses-{{session}}/connectome/sc.csv"
#     params:
#         tmpDir="tmp",
#         sub=lambda w: w.subject,
#         ses=lambda w: w.session
#     threads: config.get("threads", 4),
#     shell:
#         """
#         bash {script_dir}/03_SC.sh \
#             {bids_dir} {params.sub} {output_dir} {params.ses} \
#             -threads {threads} -tmpDir {params.tmpDir}
#         """
