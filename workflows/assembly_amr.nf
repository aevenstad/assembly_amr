/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_ASSEMBLY          } from '../subworkflows/local/shortread_assembly/main'
include { LONGREAD_ASSEMBLY           } from '../subworkflows/local/longread_assembly/main'
include { RESISTANCE_ANALYSIS         } from '../subworkflows/local/resistance_analysis/main'
include { SHORTREAD_SUMMARY           } from '../modules/local/shortread_summary/main'
include { HYBRACTER_SUMMARY           } from '../modules/local/hybracter_summary/main'
include { paramsSummaryMap            } from 'plugin/nf-schema'
include { paramsSummaryMultiqc        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML      } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText      } from '../subworkflows/local/utils_nfcore_nanopore_assembly_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ASSEMBLY_AMR {

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
        ch_quast_results = SHORTREAD_ASSEMBLY.out.ch_quast_results
        ch_bbmap_results = SHORTREAD_ASSEMBLY.out.ch_bbmap_results
       
    } else {
        LONGREAD_ASSEMBLY(samplesheet)
        ch_versions = ch_versions.mix(LONGREAD_ASSEMBLY.out.ch_versions)
        ch_trimmed_longreads = LONGREAD_ASSEMBLY.out.ch_trimmed_longreads
        ch_trimmed_shortreads = LONGREAD_ASSEMBLY.out.ch_trimmed_shortreads
        ch_final_fasta = LONGREAD_ASSEMBLY.out.ch_final_fasta
        ch_hybracter_summary = LONGREAD_ASSEMBLY.out.ch_hybracter_summary
    }


    if (params.assembly_type == 'long') {
        ch_trimmed = ch_trimmed_longreads
    } else {
        ch_trimmed = ch_trimmed_shortreads
    }

    // Run the resistance analysis workflow
    RESISTANCE_ANALYSIS(ch_final_fasta, ch_trimmed)
        ch_versions = ch_versions.mix(RESISTANCE_ANALYSIS.out.ch_versions)
        ch_mlst_results = RESISTANCE_ANALYSIS.out.ch_mlst_results
        ch_rmlst_results = RESISTANCE_ANALYSIS.out.ch_rmlst_results
        ch_kleborate_results = RESISTANCE_ANALYSIS.out.ch_kleborate_results
        ch_amrfinder_results = RESISTANCE_ANALYSIS.out.ch_amrfinder_results
        ch_plasmidfinder_results = RESISTANCE_ANALYSIS.out.ch_plasmidfinder_results



    if (params.assembly_type == 'short') {
        ch_summary_input = ch_quast_results
            .join(ch_bbmap_results)
            .join(ch_mlst_results)
            .join(ch_rmlst_results)
            .join(ch_kleborate_results)
            .join(ch_amrfinder_results)
            .join(ch_plasmidfinder_results)
            .map { tuple -> [tuple[0].id] + tuple[1..-1] }


        // Run the summary module
        SHORTREAD_SUMMARY(ch_summary_input)
    
    }
    // else do nothing
    else {
        ch_summary_input = ch_hybracter_summary.map { meta, file -> file }.collect()
        HYBRACTER_SUMMARY(ch_summary_input)
    }



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
