# micapipe_snakebids

**micapipe_snakebids** is an extension of [Snakebids](https://github.com/khanlab/snakebids) integrated within [micapipe](https://github.com/MIClabUNIGE/micapipe). It enables users to parse and process a BIDS dataset through a customizable workflow, leveraging both **Snakebids** and **micapipe** features.

## Features

- **Seamless BIDS Parsing**: Uses Snakebids functionality to automatically detect and parse available modalities in a BIDS dataset.
- **micapipe Integration**: Leverages micapipe’s neuroimaging processing modules (structural, DWI, fMRI, etc.) in a unified Snakemake workflow.
- **Customizable Configurations**: A YAML-based configuration (`snakebids.yml`) controls your input/output paths, enabled micapipe modules, and parameter settings.
- **Scalable & Portable**: Built on top of Snakemake for parallel execution, reproducibility, and straightforward deployment on different systems (local or HPC).
- **Command Line Interface**: Provides a `run.py` script for command-line invocation, allowing flexible configuration and execution of the pipeline.

## Setup within micapipe

Since **micapipe_snakebids** is part of the larger [micapipe](https://github.com/MIClabUNIGE/micapipe) project, you do not need to install it separately. Simply ensure that both micapipe and its dependencies (including [Snakebids](https://github.com/khanlab/snakebids)) are available in your environment. If Snakemake and Snakebids are not yet installed, you can install them with:

```bash
pip install snakemake snakebids
```

For additional details, refer to the main micapipe documentation regarding environment setup and dependencies.

## Usage

1. **Configure the Pipeline**  
   Edit the `config/snakebids.yml` file to specify:

   - Input/Output directories
   - micapipe modules to enable or disable (e.g., structural, dwi, func)
   - Relevant analysis parameters

2. **Run the Pipeline**  
   Use the `run.py` script to parse your BIDS dataset and execute the Snakebids workflow:

   ```bash
   python run.py \
     --bids-dir /path/to/bids_dataset \
     --output-dir /path/to/outputs \
     [other options...]
   ```

## Contributing

Contributions to **micapipe_snakebids** are welcome! If you encounter bugs or have feature suggestions, please open an issue or submit a pull request within the main micapipe repository. We recommend the following workflow:

1. **Fork** or clone the micapipe repository.
2. Make a new branch for your changes.
3. Modify the code/tests as needed.
4. Submit a pull request once your work is ready for review.

## License

This project is distributed under the [MIT License](https://opensource.org/licenses/MIT). Please see the [LICENSE](LICENSE) file in the micapipe repository for more details.

## Acknowledgments

- **Snakebids**: This workflow is built upon [Snakebids](https://github.com/khanlab/snakebids), which extends [Snakemake](https://snakemake.github.io).
- **micapipe**: The processing modules come from the [micapipe project](https://github.com/MIClabUNIGE/micapipe).
- **BIDS**: We adhere to the [BIDS specification](https://bids.neuroimaging.io) for organizing and describing the data.
- **Snakemake**: The workflow engine that orchestrates the pipeline.
