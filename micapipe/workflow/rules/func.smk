def get_func_outputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="func",
        space="func",
        desc="se",
        suffix="preproc.nii.gz",
        **inputs["t1w"].wildcards
    )

rule proc_func:
    input:
        inputs['t1w'].expand(
            get_structural_outputs(inputs, output_dir)
        ),
        inputs['t1w'].expand(
            get_surf_outputs(inputs, output_dir)
        ),
        inputs['t1w'].expand(
            get_post_structural_outputs(inputs, output_dir)
        )
    output:
        processed_func=get_func_outputs(inputs, output_dir)
    threads: config.get("threads", 4)
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -proc_func \
            -threads {threads} -ses {wildcards.session}
        """