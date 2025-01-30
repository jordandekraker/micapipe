
def get_flair_outputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="xfm",     
        subject="{subject}",
        session="{session}",
        suffix="from-flair_to-nativepro_mode-image_desc-affine_0GenericAffine.mat"     # TODO: check how to get acq?
    )



rule proc_flair:
    input:
        inputs["t1w"].expand(
            get_post_structural_outputs(inputs, output_dir)
        ),
    output:
        get_mpc_outputs(inputs, output_dir)
    params:
        flairScanStr=config["parameters"]["proc_flair"]["flairScanStr"],
    threads: config.get("threads", 4)
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -proc_flair \
            -threads {threads} -ses {wildcards.session} \
            -flairScanStr {params.flairScanStr}
        """

