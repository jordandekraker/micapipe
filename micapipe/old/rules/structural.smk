def get_structural_outputs(inputs, output_dir):
    return bids(
            root=f'{output_dir}/micapipe_v0.2.0',
            datatype='anat',
            space='nativepro',
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
        micapipe -sub sub-{wildcards.subject} -out {output_args} -bids {bids_args} \
                -proc_structural -T1wStr {params.T1wStr} -mf {params.MF} -UNI {params.UNI}\
             -ses {wildcards.session} -threads {threads}
        """


# # Rule for cortical surface reconstruction
# rule proc_surf:
#     input:
#         inputs['t1w'].expand(
#             bids(
#                 root=f'{output_dir}/micapipe_v0.2.0',
#                 datatype='anat',
#                 space='nativepro',
#                 suffix='T1w.nii.gz',
#                 **inputs['t1w'].wildcards
#             )
#         ),
#     output:
#         inputs['t1w'].expand(
#             bids(
#                 root=f'{output_dir}/micapipe_v0.2.0',
#                 datatype='surf',
#                 hemi="{hemi}",
#                 space='nativepro',
#                 surf="{surf}",
#                 label="{label}",
#                 suffix='.surf.gii',
#                 **inputs['t1w'].wildcards
#             ),
#             hemi=['L', 'R'],
#             surf=['fsaverage5', 'fsLR32k', 'fsLR5k', 'fsnative'],
#             label=['midthickness', 'pial', 'white']
#         )
#     params:
#         fs_licence=config["parameters"].get("fs_licence", None),
#         surf_dir=config["parameters"]["proc_surface"].get("surf_dir", None),
#         freesurfer=config["parameters"]["proc_surface"].get("freesurfer", None),
#         T1wStr=config["parameters"]["proc_structural"].get("T1wSTr", None),
#         t1=config["parameters"]["proc_surface"].get("T1", None),
#         t1w_str=f"-T1wStr {T1wStr}" if T1wStr else "",
#         freesurfer_str=f"-freesurfer {freesurfer}" if freesurfer else "",
#         surf_dir_str=f"-surf_dir {surf_dir}" if surf_dir else "",
#         t1_str=f"-T1 {t1}" if t1 else "",
#     threads: config.get("threads", 4),
#     shell:
#         """
#         micapipe -sub sub-{wildcards.subject} -out {output_args} -bids {bids_args} -proc_surf \
#             -threads {threads} -fs_licence {params.fs_licence} {params.t1w_str} {params.freesurfer_str} \
#             {params.surf_dir_str} {params.t1_str} -ses {wildcards.session}
#         """

# # Rule for post structural processing
# rule post_structural:
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
#     output:
#         post_structural=bids(
#                 root=f'{output_dir}/micapipe_v0.2.0',
#                 datatype='anat',
#                 space='fsnative',
#                 suffix='T1w.nii.gz',
#                 **inputs['t1w'].wildcards
#             )
#     params:
#         atlas_raw=config["parameters"]["post_structural"].get("atlas", "default"),
#         atlas=",".join(atlas) if isinstance(atlas, list) else atlas
#     threads: config.get("threads", 4),
#     shell:
#         """
#         micapipe -sub sub-{wildcards.subject} -out {output_args} -bids {bids_args} -post_structural \
#             -threads {threads} -atlas {params.atlas} -ses {wildcards.session}
#         """

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
#         micapipe -sub sub-{wildcards.subject} -out {output_args} -bids {bids_args} -GD \
#             -threads {threads} -ses {wildcards.session}
#         """
