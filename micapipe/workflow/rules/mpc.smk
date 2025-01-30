
def get_mpc_outputs(inputs, output_dir):
    return bids(
        root=f"{output_dir}/micapipe_v0.2.0",
        datatype="xfm",     
        subject="{subject}",
        session="{session}",
        suffix="from-T1map_to-fsnative_0GenericAffine.mat"     # TODO: check how to get acq?
    )



rule proc_mpc:
    # A) Inputs
    input:
        inputs["t1w"].expand(
            get_post_structural_outputs(inputs, output_dir)
        ),
    output:
        processed_mpc = get_mpc_outputs(inputs, output_dir)
    params:
        microstructural_img = process_optional_flags(
            config["parameters"]["proc_mpc"]["microstructural_img"],
            "microstructural_img"
        ),
        microstructural_reg = process_optional_flags(
            config["parameters"]["proc_mpc"]["microstructural_reg"],
            "microstructural_reg"
        ),
        mpc_acq = process_optional_flags(
            config["parameters"]["proc_mpc"]["mpc_acq"],
            "mpc_acq"
        ),

        # Boolean flags that only appear if set to TRUE
        regSynth = process_flags(
            config["parameters"]["proc_mpc"]["regSynth"], "regSynth"
        ),
        reg_nonlinear = process_flags(
            config["parameters"]["proc_mpc"]["reg_nonlinear"], "reg_nonlinear"
        ),
    threads: config.get("threads", 4)
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -MPC \
            -threads {threads} -ses {wildcards.session} \
            {params.microstructural_img} {params.microstructural_reg} \
            {params.mpc_acq} {params.regSynth} {params.reg_nonlinear}
        """

