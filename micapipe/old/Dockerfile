# syntax=docker/dockerfile:1.4
# Base image
FROM ubuntu:bionic-20201119

USER root
ARG DEBIAN_FRONTEND="noninteractive"

# ------------------------------------------------------------------------------
# Basic system setup, locales, and neurodocker entrypoint
# ------------------------------------------------------------------------------
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        apt-utils bzip2 ca-certificates curl locales unzip && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG="en_US.UTF-8" && \
    rm -rf /var/lib/apt/lists/*

# Create neurodocker startup script
ENV ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN mkdir -p /neurodocker && \
    echo '#!/usr/bin/env bash' > "$ND_ENTRYPOINT" && \
    echo 'set -e' >> "$ND_ENTRYPOINT" && \
    echo 'export USER="${USER:=`whoami`}"' >> "$ND_ENTRYPOINT" && \
    echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT" && \
    chmod -R 777 /neurodocker

ENTRYPOINT ["/neurodocker/startup.sh"]

# ------------------------------------------------------------------------------
# Install system packages and build tools (combine apt-get update, install, clean)
# ------------------------------------------------------------------------------
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        gcc g++ lsb-core bsdtar jq libopenblas-dev tree openjdk-8-jdk libstdc++6 && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Install dcm2niix
# ------------------------------------------------------------------------------
ENV PATH="/opt/dcm2niix-v1.0.20190902/bin:$PATH"
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        cmake git make pigz zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/rordenlab/dcm2niix /tmp/dcm2niix && \
    cd /tmp/dcm2niix && \
    git fetch --tags && git checkout v1.0.20190902 && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/dcm2niix-v1.0.20190902 .. && \
    make && make install && \
    rm -rf /tmp/dcm2niix

# ------------------------------------------------------------------------------
# Install FSL
# ------------------------------------------------------------------------------
ENV FSLDIR="/opt/fsl-6.0.2" \
    PATH="/opt/fsl-6.0.2/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLTCLSH="/opt/fsl-6.0.2/bin/fsltclsh" \
    FSLWISH="/opt/fsl-6.0.2/bin/fslwish" \
    FSLLOCKDIR="" FSLMACHINELIST="" FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q"
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        bc dc file libfontconfig1 libfreetype6 libgl1-mesa-dev libgl1-mesa-dri \
        libglu1-mesa-dev libgomp1 libice6 libxcursor1 libxft2 libxinerama1 \
        libxrandr2 libxrender1 libxt6 sudo wget && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Downloading FSL ..." && \
    mkdir -p /opt/fsl-6.0.2 && \
    curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.2-centos6_64.tar.gz | \
      tar -xz -C /opt/fsl-6.0.2 --strip-components 1 && \
    sed -i '$iecho Some packages in this Docker container are non-free' $ND_ENTRYPOINT && \
    sed -i '$iecho If you are considering commercial use of this container, please consult the relevant license:' $ND_ENTRYPOINT && \
    sed -i '$iecho https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence' $ND_ENTRYPOINT && \
    sed -i '$isource $FSLDIR/etc/fslconf/fsl.sh' $ND_ENTRYPOINT

RUN bash -c 'bash /opt/fsl-6.0.2/etc/fslconf/fslpython_install.sh -f /opt/fsl-6.0.2'

# ------------------------------------------------------------------------------
# Install FreeSurfer
# ------------------------------------------------------------------------------
ENV FREESURFER_HOME="/opt/freesurfer-7.3.2" \
    PATH="/opt/freesurfer-7.3.2/bin:$PATH"
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        bc libgomp1 libxmu6 libxt6 perl tcsh && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Downloading FreeSurfer ..." && \
    mkdir -p /opt/freesurfer-7.3.2 && \
    curl -fsSL --retry 5 ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.3.2/freesurfer-linux-ubuntu18_amd64-7.3.2.tar.gz | \
      tar -xz -C /opt/freesurfer-7.3.2 --strip-components 1 \
         --exclude='freesurfer/average/mult-comp-cor' \
         --exclude='freesurfer/lib/cuda' \
         --exclude='freesurfer/lib/qt' \
         --exclude='freesurfer/subjects/V1_average' \
         --exclude='freesurfer/subjects/bert' \
         --exclude='freesurfer/subjects/cvs_avg35' \
         --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
         --exclude='freesurfer/subjects/fsaverage3' \
         --exclude='freesurfer/subjects/fsaverage4' \
         --exclude='freesurfer/subjects/fsaverage5' \
         --exclude='freesurfer/subjects/fsaverage6' \
         --exclude='freesurfer/subjects/fsaverage_sym' \
         --exclude='freesurfer/trctrain' && \
    sed -i '$isource "/opt/freesurfer-7.3.2/SetUpFreeSurfer.sh"' "$ND_ENTRYPOINT"

# ------------------------------------------------------------------------------
# Install MATLAB Compiler Runtime
# ------------------------------------------------------------------------------
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/opt/matlabmcr-2017b/v93/runtime/glnxa64:/opt/matlabmcr-2017b/v93/bin/glnxa64:/opt/matlabmcr-2017b/v93/sys/os/glnxa64:/opt/matlabmcr-2017b/v93/extern/bin/glnxa64" \
    MATLABCMD="/opt/matlabmcr-2017b/v93/toolbox/matlab"
RUN export TMPDIR="$(mktemp -d)" && \
    apt-get update -qq && apt-get install -y --no-install-recommends \
        bc libncurses5 libxext6 libxmu6 libxpm-dev libxt6 && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Downloading MATLAB Compiler Runtime ..." && \
    curl -fsSL --retry 5 -o "$TMPDIR/mcr.zip" https://ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip && \
    unzip -q "$TMPDIR/mcr.zip" -d "$TMPDIR/mcrtmp" && \
    "$TMPDIR/mcrtmp/install" -destinationFolder /opt/matlabmcr-2017b -mode silent -agreeToLicense yes && \
    rm -rf "$TMPDIR"

# ------------------------------------------------------------------------------
# Install AFNI
# ------------------------------------------------------------------------------
ENV PATH="/opt/afni-latest:$PATH" \
    AFNI_PLUGINPATH="/opt/afni-latest"
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        ed gsl-bin libglib2.0-0 libglu1-mesa-dev libglw1-mesa libgomp1 libjpeg62 \
        libxm4 netpbm tcsh xfonts-base xvfb && \
    rm -rf /var/lib/apt/lists/* && \
    curl -sSL --retry 5 -o /tmp/toinstall.deb http://launchpadlibrarian.net/160108232/libxp6_1.0.2-1ubuntu1_amd64.deb && \
    dpkg -i /tmp/toinstall.deb && rm /tmp/toinstall.deb && \
    curl -sSL --retry 5 -o /tmp/toinstall.deb http://snapshot.debian.org/archive/debian-security/20160113T213056Z/pool/updates/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb && \
    dpkg -i /tmp/toinstall.deb && rm /tmp/toinstall.deb && \
    apt-get install -f && \
    ldconfig && \
    echo "Downloading AFNI ..." && \
    mkdir -p /opt/afni-latest && \
    curl -fsSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz | \
      tar -xz -C /opt/afni-latest --strip-components 1

# ------------------------------------------------------------------------------
# Install ANTs (from an external image)
# ------------------------------------------------------------------------------
ENV ANTSPATH="/opt/ants-2.3.4" \
    PATH="/opt/ants-2.3.4:$PATH"
COPY --from=kaczmarj/ants:2.3.4 /opt/ants /opt/ants-2.3.4

# ------------------------------------------------------------------------------
# Install Connectome Workbench via Neurodebian
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      gnupg2 wget ca-certificates neurodebian-archive-keyring && \
    wget -O /etc/apt/sources.list.d/neurodebian.sources.list http://neuro.debian.net/lists/xenial-de-fzj.full && \
    apt-get update && apt-get install -y connectome-workbench=1.3.2-2~nd16.04+1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Create user 'mica'
# ------------------------------------------------------------------------------
RUN test "$(getent passwd mica)" || useradd --no-user-group --create-home --shell /bin/bash mica
USER mica

# ------------------------------------------------------------------------------
# Install Miniconda, Mamba and create micapipe environment
# ------------------------------------------------------------------------------
ENV CONDA_DIR="/opt/miniconda-22.11.1" \
    PATH="/opt/miniconda-22.11.1/bin:$PATH" \
    MAMBA_NO_SPINNER=1
RUN export PATH="/opt/miniconda-22.11.1/bin:$PATH" && \
    echo "Downloading Miniconda installer ..." && \
    curl -fsSL --retry 5 -o /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py39_22.11.1-1-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda-22.11.1 && \
    rm -f /tmp/miniconda.sh && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    sync && conda clean -y --all && sync && \
    conda install -y -n base -c conda-forge mamba && \
    mamba create -y -n micapipe python=3.9

# ------------------------------------------------------------------------------
# Install micapipe conda and pip packages
# ------------------------------------------------------------------------------
RUN conda config --system --set channel_priority strict && \
    mamba install -y -q -n micapipe -c conda-forge \
           aiohttp aiosignal asn1crypto async-timeout astropy attrs bokeh cffi \
           charset-normalizer click contourpy cryptography cycler fonttools frozenlist \
           html5lib idna importlib-resources jinja2 joblib kiwisolver lxml markupsafe \
           "matplotlib==3.4.3" multidict "nibabel==4.0.2" nilearn "numpy==1.21.5" \
           packaging "pandas==1.4.4" pillow pycparser pyhanko-certvalidator pyparsing \
           pypdf pypng python-bidi python-dateutil pytz pytz-deprecation-shim pyyaml \
           qrcode reportlab requests scikit-learn scikit-fmm scipy six svglib \
           threadpoolctl tinycss2 tornado typing-extensions tzlocal uritools urllib3 \
           "vtk==9.2.2" webencodings wslink yarl zipp "pyvirtualdisplay==3.0" && \
    sync && mamba clean -y --all && sync

RUN mamba run -n micapipe pip install --no-cache-dir \
             "argparse==1.1" "brainspace==0.1.10" "tedana==0.0.12" duecredit \
             "pyhanko==0.17.2" "mapca==0.0.3" "xhtml2pdf==0.2.9" "oscrypto==1.3.0" \
             "tzdata==2022.7" "arabic-reshaper==3.0.0" "cssselect2==0.7.0" \
             "pygeodesic==0.1.8" "seaborn==0.11.2" && \
    rm -rf ~/.cache/pip/* && sync && \
    sed -i '$isource activate micapipe' $ND_ENTRYPOINT

# ------------------------------------------------------------------------------
# Install MRtrix3 and ENIGMA
# ------------------------------------------------------------------------------
RUN mamba install -y -n micapipe -c mrtrix3 mrtrix3==3.0.1 && \
    mamba run -n micapipe pip install git+https://github.com/MICA-MNI/ENIGMA.git

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# FastSurfer setup
# ------------------------------------------------------------------------------
ENV PATH="/opt/FastSurfer:$PATH" \
    FASTSURFER_HOME=/opt/FastSurfer
RUN git clone https://github.com/Deep-MI/FastSurfer.git /opt/FastSurfer && \
    cd /opt/FastSurfer && git checkout stable

# Generate FastSurfer CPU-specific environment file and patch torchio version
RUN /opt/miniconda-22.11.1/bin/conda run -n base \
    python /opt/FastSurfer/Docker/install_env.py -m cpu -i /opt/FastSurfer/env/fastsurfer.yml -o /opt/FastSurfer/fastsurfer_cpu.yml && \
    sed -i 's/torchio==0.20.4/torchio==0.20.5/g' /opt/FastSurfer/fastsurfer_cpu.yml

RUN /opt/miniconda-22.11.1/bin/conda env create -f /opt/FastSurfer/fastsurfer_cpu.yml

# Set PYTHONPATH and download CNN checkpoints for FastSurfer
ENV PYTHONPATH="${PYTHONPATH}:/opt/FastSurfer"
RUN /opt/miniconda-22.11.1/bin/mamba run -n fastsurfer_cpu python /opt/FastSurfer/FastSurferCNN/download_checkpoints.py

# ------------------------------------------------------------------------------
# Additional installations: Xvfb, R, c3d, micapipe code copy, etc.
# ------------------------------------------------------------------------------
USER root
RUN apt-get update -qq && apt-get install -y --no-install-recommends xvfb && apt-get clean

# R installation and package setup
RUN set -uex; \
    LD_LIBRARY_PATH=/lib64/:${PATH}; \
    apt update; \
    apt install -y software-properties-common apt-transport-https; \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9; \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'; \
    apt-get update; \
    apt-get install -y r-base libblas-dev liblapack-dev gfortran g++ libgl1-mesa-glx; \
    apt-get install -y r-base-dev; \
    rm -rf /var/lib/apt/lists/*;

COPY ./R_config/* /opt/
RUN bash -c 'bash /opt/install_R_env.sh && cd /opt/afni-latest && rPkgsInstall -pkgs ALL'

# Install c3d
RUN set -uex; \
    cd /opt/ && \
    wget -O itksnap.tar.gz https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download && \
    tar -xf itksnap.tar.gz -C /opt/ && \
    rm itksnap.tar.gz
ENV PATH="/opt/c3d-1.0.0-Linux-x86_64/bin:${PATH}"

RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy micapipe source and external FIX files
COPY . /opt/micapipe/
# For the TODO: copy FIX version from an external location
COPY /data_/mica1/01_programs/fix-1.06.15 /opt/fix1.068

RUN bash -c 'cd /opt/micapipe && mv fix_settings.sh /opt/fix1.068/settings.sh && mv fsl_conf/* /opt/fsl-6.0.2/etc/flirtsch/'
RUN bash -c 'cp -r /opt/micapipe/surfaces/fsaverage5 /opt/freesurfer-7.3.2/subjects'

WORKDIR /home/mica

ENV MICAPIPE="/opt/micapipe" \
    PROC="container_micapipe-v0.2.3" \
    FIXPATH=/opt/fix1.068 \
    PATH="/opt/fix1.068/:${PATH}" \
    PATH="/opt/micapipe/:/opt/micapipe/functions:${PATH}"

ENTRYPOINT ["/neurodocker/startup.sh", "/opt/micapipe/micapipe"]
