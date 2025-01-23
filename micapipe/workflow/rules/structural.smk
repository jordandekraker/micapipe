def get_structural_outputs(inputs, output_dir):
    return bids(
            root=f'{output_dir}/micapipe_v0.2.0',
            datatype='anat',
            space='nativepro',
            suffix='T1w.nii.gz',
            **inputs['t1w'].wildcards
        )

def get_surf_outputs(inputs, output_dir):
    return bids(
            root=f'{output_dir}/micapipe_v0.2.0',
            datatype='surf',
            hemi='L',
            space='nativepro',
            # surf='fsaverage5',
            # label='midthickness',
            suffix='surf-fsaverage5_label-midthickness.surf.gii',
            **inputs['t1w'].wildcards
        )

def get_post_structural_outputs(inputs, output_dir):
    return bids(
            root=f'{output_dir}/micapipe_v0.2.0',
            datatype='anat',
            space='fsnative',
            suffix='T1w.nii.gz',
            **inputs['t1w'].wildcards
        )

rule proc_structural:
    input:
        inputs['t1w'].expand()
    output:
        structural_output=get_structural_outputs(inputs, output_dir)
    params:
        T1wStr=config["parameters"]["proc_structural"].get("T1wStr", "DEFAULT"),
        UNI=config["parameters"]["proc_structural"].get("UNI", "FALSE"),
        MF=config["parameters"]["proc_structural"].get("MF", 3),
    threads: config.get("threads", 4),
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} \
                -proc_structural -T1wStr {params.T1wStr} -mf {params.MF} -UNI {params.UNI}\
             -ses {wildcards.session} -threads {threads}
        """


# Rule for cortical surface reconstruction
rule proc_surf:
    input:
        inputs['t1w'].expand(
            get_structural_outputs(inputs, output_dir)
        ),
    output:
        surf_output=get_surf_outputs(inputs, output_dir)
    params:
        fs_licence=config["parameters"].get("fs_licence", None),
        surf_dir=config["parameters"]["proc_surface"].get("surf_dir", "FALSE"),
        freesurfer=config["parameters"]["proc_surface"].get("freesurfer", "FALSE"),
        T1wStr=config["parameters"]["proc_structural"].get("T1wStr", "DEFAULT"),
        t1=config["parameters"]["proc_surface"].get("T1", "DEFAULT"),

    threads: config.get("threads", 4),
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -proc_surf \
            -threads {threads} -fs_licence {params.fs_licence} -T1wStr {params.T1wStr} -freesurfer {params.freesurfer} \
            -surf_dir {params.surf_dir} -T1 {params.t1} -ses {wildcards.session}
        """

# Rule for post structural processing
rule post_structural:
    input:
        structural_output=inputs['t1w'].expand(
            get_structural_outputs(inputs, output_dir)
        ),
        surf_output=inputs['t1w'].expand(
            get_surf_outputs(inputs, output_dir)
        ),
    output:
        post_structural=get_post_structural_outputs(inputs, output_dir)
    params:
        atlas_raw=config["parameters"]["post_structural"].get("atlas", "DEFAULT"),
        atlas=",".join(atlas) if isinstance(atlas, list) else atlas
    threads: config.get("threads", 4),
    shell:
        """
        micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -post_structural \
            -threads {threads} -atlas {params.atlas} -ses {wildcards.session}
        """

# # Rule for geodesic distance
# rule proc_geodesic_distance:
#     input:
#         structural_output=inputs['t1w'].expand(
#             bids(
#                 root=f'{output_dir}/micapipe_v0.2.0',
#                 datatype='anat',
#                 space='nativepro',
#                 suffix='T1w.nii.gz',
#                 **inputs['t1w'].wildcards
#             )
#         ),
#         surf_output=inputs['t1w'].expand(
#             bids(
#                 root=f'{output_dir}/micapipe_v0.2.0',
#                 datatype='surf',
#                 hemi=['L', 'R'],
#                 space='nativepro',
#                 surf=['fsaverage5', 'fsLR32k', 'fsLR5k', 'fsnative'],
#                 label=['midthickness', 'pial', 'white'],
#                 suffix='.surf.gii',
#                 **inputs['t1w'].wildcards
#             )
#         ),
#         post_structural_output=inputs['t1w'].expand(
#             bids(
#                 root=f'{output_dir}/micapipe_v0.2.0',
#                 datatype='anat',
#                 space='fsnative',
#                 suffix='T1w.nii.gz',
#                 **inputs['t1w'].wildcards
#             )
#         ),
#     output:
#         geodesic_distance=bids(
#             root=f'{output_dir}/micapipe_v0.2.0',
#             datatype='dist',
#             atlas='{parcellation}',
#             suffix='GD.shape.gii',
#             **inputs['t1w'].wildcards
#         )
#     threads: config.get("threads", 4),
#     shell:
#         """
#         micapipe -sub sub-{wildcards.subject} -out {output_dir} -bids {bids_dir} -GD \
#             -threads {threads} -ses {wildcards.session}
#         """
