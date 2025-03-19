/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_ASSEMBLY          } from '../subworkflows/local/shortread_assembly/main'
include { LONGREAD_ASSEMBLY           } from '../subworkflows/local/longread_assembly/main'
include { RESISTANCE_ANALYSIS         } from '../subworkflows/local/resistance_analysis/main'
include { paramsSummaryMap            } from 'plugin/nf-schema'
include { paramsSummaryMultiqc        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML      } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText      } from '../subworkflows/local/utils_nfcore_nanopore_assembly_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow KRES_AMR {

    take:
    samplesheet             // channel: samplesheet read in from --input

    main:
    ch_versions = Channel.empty()

    // Run the appropriate assembly workflow based on the assembly type
    if (params.assembly_type == 'short') {
        SHORTREAD_ASSEMBLY(samplesheet)
        ch_versions = ch_versions.mix(SHORTREAD_ASSEMBLY.out.ch_versions)
        ch_trimmed_shortreads = SHORTREAD_ASSEMBLY.out.ch_shortread_trimmed
        ch_final_fasta = SHORTREAD_ASSEMBLY.out.ch_final_fasta
    } else {
        LONGREAD_ASSEMBLY(samplesheet)
        ch_versions = ch_versions.mix(LONGREAD_ASSEMBLY.out.ch_versions)
        ch_trimmed_longreads = LONGREAD_ASSEMBLY.out.ch_trimmed_longreads
        ch_trimmed_shortreads = LONGREAD_ASSEMBLY.out.ch_trimmed_shortreads
        ch_final_fasta = LONGREAD_ASSEMBLY.out.ch_final_fasta
    }


    if (params.assembly_type == 'long') {
        ch_trimmed = ch_trimmed_longreads
    } else {
        ch_trimmed = ch_trimmed_shortreads
    }

    // Run the resistance analysis workflow
    RESISTANCE_ANALYSIS(ch_final_fasta, ch_trimmed)
        ch_versions = ch_versions.mix(RESISTANCE_ANALYSIS.out.ch_versions)


    // Collate and save software versions
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'nanopore_assembly_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
