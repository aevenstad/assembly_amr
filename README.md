# Assembly & AMR
***The pipeline is currently under development!***
## Author
* Andreas Evenstad (https://github.com/aevenstad/)

## Table of contents
- [Introduction](#introduction)
- [Requirements](#requirements)
  - [Dependencies](#dependencies)
  - [Databases](#databases)
- [Quickstart](#quickstart)
  - [Download the pipeline](#download-the-pipeline)
  - [Get dependencies](#get-dependencies)
  - [Download databases](#download-databases)
  - [Arguments](#arguments)
  - [Run the pipeline](#run-the-pipeline)
    - [Hybrid input](#hybrid-input)
    - [Long-read input](#long-read-input)
    - [Short-read input](#short-read-input)


## Introduction
This is a Nextflow pipeline written using the nf-core template, and is made for analyzing whole-genome sequencing data from bacterial isolates.
It`s main function is to asses antimicrobial resistance in the provided isolates and the main steps of the pipeline is:
* Genome assembly:
  - `hybrid` or `long` mode with hybracter (0.11.0)
  - Short read mode with shovill (1.1.0) (using spades assembler)
* Multi locus sequence typing:
    - MLST (2.23.0)
    - rMLST (https://gist.github.com/kjolley/703fa2f00c3b2abeef9242fa193ea901#file-species_api_upload-py)
* Resistance analysis:
    - AMRFinderPlus (4.0.3)
    - Kleborate (3.1.2) (for Klebsiella)
    - PlasmidFinder (2.1.6)
    - LRE-Finder (1.0.0) (for enterobactales)
* Annotation:
    - Bakta (1.10.4)

## Requirements
### Dependencies
This pipeline is developed with singularity for tool dependencies. Most of the containers used is accessible from public registries like `quay` and `biocontainers`
but for the tools not available in the registries local builds are currently used.

### Databases
In order for the pipeline to run these databases must be available on the system:
* AMRFinderPlus database (release 2024-10-22.1 or later)
* PlasmidFinder database
* Bakta database (optionally for annotation)


## Quickstart

### Download the pipeline
Clone the repository:
```
git clone https://github.com/aevenstad/assembly_amr.git
```

### Get dependencies
You can optionally install dependencies before running the pipeline using the helper scripts in `bin/`.  
It’s recommended to set the container directory using the Nextflow variable `$NXF_SINGULARITY_CACHEDIR`:
```
NXF_SINGULARITY_CACHEDIR=/path/to/containers/

# to pull containers from public registries, run:
bash bin/pull_containers.sh $NXF_SINGULARITY_CACHEDIR

# for dependencies without publicly available container images, use:
bash bin/build_containers.sh $NXF_SINGULARITY_CACHEDIR
```
This will build the required containers using custom definition files in `singularity/`.

### Download databases
AMRFinderPlus database:
```
singularity exec <amrfinderplus_image> amrfinder_update -d <database_dir>
```

PlasmidFinder database:
```
# go to preferred database directory
cd <database_dir>
# clone the latest version of the database:
git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git
cd plasmidfinder_db
PLASMID_DB=$(pwd)
# install the database:
singularity exec <plasmidfinder_image> python3 INSTALL.py kma_index
```

Bakta database:
```
cd <database_dir>
singularity exec <bakta_image> bakta_db download --output ./ --type [light|full]
```

### Arguments
```
-profile                [string] Name of profile from `nextflow.conf` (Currently only <singularity> supported)
--input                 [string] Path to input samplesheet
--outdir                [string] Path to output directory
--assembly_type         [string] Type of assembly to perform  (accepted: hybrid, long, short)
--amrfinder_db          [string] Path to the AMRFinderPlus database
--plasmidfinder_db      [string] Path to the PlasmidFinder database
--bakta                 [boolean] Run annotation with bakta [default: false]
--bakta_db              [string] Path to the bakta database
```

### Run the pipeline

```
nextflow run /path/to/assembly_amr/main.nf \
-profile singularity \
--input samplesheet.csv \
--outdir <outdir> \
--assembly_type [hybrid|long|short] \
--amrfinder_db <amrfinder_db> \
--plasmidfinder_db <plasmidfinder_db>
```

#### Hybrid input
If you have both Nanopore and Illumina reads from the same isolate and want to run a hybrid assembly, input must be provided in a comma-separated file e.g. `samplesheet.csv`:
```
sample,nanopore,illumina_R1,illumina_R2
isolate1,/path/to/nanopore/data/isolate1.fastq.gz,/path/to/illumina/data/isolate1_R1.fastq.gz,/path/to/illumina/data/isolate1_R2.fastq.gz
isolate2,/path/to/nanopore/data/isolate2.fastq.gz,/path/to/illumina/data/isolate2_R1.fastq.gz,/path/to/illumina/data/isolate2_R2.fastq.gz
```

#### Long-read input
For long read only assembly with Nanopore reads:
`samplesheet.csv`:
```
sample,nanopore
isolate1,/path/to/nanopore/data/isolate1.fastq.gz
isolate2,/path/to/nanopore/data/isolate2.fastq.gz
```
#### Short-read input
For short read only assembly with Illumina reads:
`samplesheet.csv`:
```
sample,illumina_R1,illumina_R2
isolate1,/path/to/illumina/data/isolate1_R1.fastq.gz,/path/to/illumina/data/isolate1_R2.fastq.gz
isolate2,/path/to/illumina/data/isolate2_R1.fastq.gz,/path/to/illumina/data/isolate2_R2.fastq.gz
```



