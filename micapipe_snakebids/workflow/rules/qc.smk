
def get_qc_subj_outputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="QC",     
        subject="{subject}",
        session="{session}",
        suffix="module-proc_structural_qc-report.pdf"   
    )

def get_qc_outputs(inputs, output_dir):
    return f"{output_dir}/micapipe_v0.2.0/micapipe_group-QC.pdf"


rule qc_subj:
    input:
        inputs["t1w"].expand(
            get_post_structural_outputs(inputs, output_dir)
        ),
    output:
        get_qc_subj_outputs(inputs, output_dir)
    threads: config.get("threads", 4)
    params:
        tracts=process_optional_flags(
            config["parameters"]["qc_subj"]["tracts"],
            "tracts"
        ),
        tmpDir=process_optional_flags(
            config["parameters"]["qc_subj"]["tmpDir"],
            "tmpDir"
        ),
    shell:
        """
        {command} -sub sub-{wildcards.subject} -out {output_args} -bids {bids_args} -QC_subj \
            -threads {threads} -ses {wildcards.session} {params.tracts} {params.tmpDir}
        """

rule qc:
    input:
        inputs["t1w"].expand(
            get_post_structural_outputs(inputs, output_dir)
        ),
    output:
        get_qc_outputs(inputs, output_dir)
    threads: config.get("threads", 4)
    shell:
        """
        micapipe -out {output_args} -QC
        """