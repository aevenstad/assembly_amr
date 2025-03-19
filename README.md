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
  - [Arguments](#arguments)
  - [Hybrid assembly](#hybrid-assembly)
  - [Long read assembly](#long-read-assembly)
  - [Short read assembly](#short-read-assembly)


## Introduction
This is a Nextflow pipeline written using the nf-core template, and is made for analyzing whole-genome sequencing data from bacterial isolates.
It`s main function is to asses antimicrobial resistance in the provided isolates and the main steps of the pipeline is:
* Genome assembly:
  - Hybrid mode with Hybracter (using Nanopore and Illumina data)
  - Long read mode with Hybracter (using only Nanopore data)
  - Short read mode with Shovill (using only Illumina data)
* Multi locus sequence typing:
    - MLST
    - rMLST
* Resistance analysis:
    - AMRFinder
    - Kleborate (for Klebsiella)
    - PlasmidFinder
    - LRE-Finder (for enterobactales)
* Annotation:
    - Bakta (optionally)

## Requirements
### Dependencies
This pipeline is developed with singularity for tool dependencies. Most of the containers used is accessible from public registries like `quay` and `biocontainers`
but for the tools not available in the registries local builds are currently used.

### Databases
In order for the pipeline to run these databases must be available on the system:
* AMRFinderPlus database (release 2024-10-22.1 or later)
* PlasmidFinder database
* LRE-Finder database
* Bakta database (optionally for annotation)


## Quickstart

### Download the pipeline
Clone the repository:
```
git clone https://github.com/aevenstad/assembly_amr.git
```
### Arguments
```
-profile                [string] Name of profile from `nextflow.conf` (Currently only <singularity> supported)
--input                 [string] Path to input samplesheet
--outdir                [string] Path to output directory
--assembly_type         [string] Type of assembly to perform  (accepted: hybrid, long, short)
--amrfinder_db          [string] Path to the AMRFinderPlus database
--plasmidfinder_db      [string] Path to the PlasmidFinder database
--lrefinder_db          [string] Path to the LRE-Finder database
--bakta                 [boolean] Run annotation with bakta [default: false]
--bakta_db              [string] Path to the bakta database
```

### Hybrid assembly
If you have both Nanopore and Illumina reads from the same isolate and want to run a hybrid assembly, input must be provided in a comma-separated file e.g. `samplesheet.csv`:
```
sample,nanopore,illumina_R1,illumina_R2
isolate1,/path/to/nanopore/data/isolate1.fastq.gz,/path/to/illumina/data/isolate1_R1.fastq.gz,/path/to/illumina/data/isolate1_R2.fastq.gz
isolate2,/path/to/nanopore/data/isolate2.fastq.gz,/path/to/illumina/data/isolate2_R1.fastq.gz,/path/to/illumina/data/isolate2_R2.fastq.gz
```

Run the pipeline with:
```
nextflow run /path/to/assembly_amr/main.nf -profile singularity --input samplesheet.csv --outdir <outdir> --assembly_type hybrid 
```

### Long read assembly
For long read only assembly with Nanopore reads:
`samplesheet.csv`:
```
sample,nanopore
isolate1,/path/to/nanopore/data/isolate1.fastq.gz
isolate2,/path/to/nanopore/data/isolate2.fastq.gz
```

Run the pipeline with:
```
nextflow run /path/to/assembly_amr/main.nf -profile singularity --input samplesheet.csv --outdir <outdir> --assembly_type long 
```

### Short read assembly
For short read only assembly with Illumina reads:
`samplesheet.csv`:
```
sample,illumina_R1,illumina_R2
isolate1,/path/to/illumina/data/isolate1_R1.fastq.gz,/path/to/illumina/data/isolate1_R2.fastq.gz
isolate2,/path/to/illumina/data/isolate2_R1.fastq.gz,/path/to/illumina/data/isolate2_R2.fastq.gz
```

Run the pipeline with:
```
nextflow run /path/to/assembly_amr/main.nf -profile singularity --input samplesheet.csv --outdir <outdir> --assembly_type short 
```

