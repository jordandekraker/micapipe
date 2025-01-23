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
        processed_dwi=get_dwi_outputs
    # params:
    threads: config.get("threads", 4),
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -proc_dwi \
            -threads {threads} -ses {wildcards.session}
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
