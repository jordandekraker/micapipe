
def get_swm_outputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="surf",     
        subject="{subject}",
        session="{session}",
        hemi="L",
        suffix="space_fsnative_label_swm1.0mm.surf"   
    )



rule proc_swm:
    input:
        inputs["t1w"].expand(
            get_post_structural_outputs(inputs, output_dir)
        ),
    output:
        get_swm_outputs(inputs, output_dir)
    threads: config.get("threads", 4)
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -SWM \
            -threads {threads} -ses {wildcards.session} \
            
        """

