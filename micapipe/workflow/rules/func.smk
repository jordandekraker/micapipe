def get_func_outputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="func/desc-se_task-{task}_acq-{acq}_bold/volumetric",
        space="func",
        desc="se",
        suffix="preproc.nii.gz",
        subject="{subject}",
        session="{session}"
    )

def get_func_inputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="func",
        suffix="bold.nii.gz",
        **inputs["func"].wildcards
    )

rule proc_func:
    input:
        inputs['func'].expand(
            get_func_inputs(inputs, output_dir)
        ),
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