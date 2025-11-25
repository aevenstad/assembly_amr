/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_ASSEMBLY            } from '../subworkflows/local/shortread_assembly/main'
include { LONGREAD_ASSEMBLY             } from '../subworkflows/local/longread_assembly/main'
include { TYPING_AND_RESISTANCE         } from '../subworkflows/local/typing_and_resistance/main'
include { QUAST                         } from '../modules/nf-core/quast/main'
include { WRITE_SUMMARY                 } from '../subworkflows/local/write_summary/main'
include { paramsSummaryMap              } from 'plugin/nf-schema'
include { paramsSummaryMultiqc          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText        } from '../subworkflows/local/utils_nfcore_nanopore_assembly_pipeline'
// include { handleInput                   } from '../utils/input_handler'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ASSEMBLY_AMR {

    take:
    samplesheet // channel: samplesheet read in from --input

    main:
    ch_versions = Channel.empty()
    ch_hybracter_summary = Channel.empty()
    ch_quast_results = Channel.empty()
    ch_bbmap_results = Channel.empty()


    // Run the appropriate assembly workflow based on input type
    // TODO: Use function to handle different input types
    if (params.from_fasta) {
        // Skip assembly workflows and use the provided FASTA files
        ch_trimmed = Channel.empty()
        ch_final_fasta = samplesheet.map { meta, _nanopore, _illumina_R1, _illumina_R2, fasta ->
                tuple([id: meta], [file(fasta)])
        }
        // Get assembly stats from quast
        QUAST(ch_final_fasta)
            ch_quast_results = QUAST.out.tsv
            ch_versions = ch_versions.mix(QUAST.out.versions)
    } else if (params.assembly_type == 'short') {
        // Run short-read assembly workflow
        SHORTREAD_ASSEMBLY(samplesheet)
        ch_versions = ch_versions.mix(SHORTREAD_ASSEMBLY.out.ch_versions)
        ch_trimmed_shortreads = SHORTREAD_ASSEMBLY.out.ch_shortread_trimmed
        ch_final_fasta = SHORTREAD_ASSEMBLY.out.ch_final_fasta
        ch_quast_results = SHORTREAD_ASSEMBLY.out.ch_quast_results
        ch_bbmap_results = SHORTREAD_ASSEMBLY.out.ch_bbmap_results
    } else if (params.assembly_type == 'hybrid' || params.assembly_type == 'long') {
        // Run long-read or hybrid assembly workflow
        LONGREAD_ASSEMBLY(samplesheet)
        ch_versions = ch_versions.mix(LONGREAD_ASSEMBLY.out.ch_versions)
        ch_trimmed_longreads = LONGREAD_ASSEMBLY.out.ch_trimmed_longreads
        ch_trimmed_shortreads = LONGREAD_ASSEMBLY.out.ch_trimmed_shortreads
        ch_final_fasta = LONGREAD_ASSEMBLY.out.ch_final_fasta
        ch_hybracter_summary = LONGREAD_ASSEMBLY.out.ch_hybracter_summary
        ch_plasmid_fasta = LONGREAD_ASSEMBLY.out.ch_all_plasmid_fasta
    } else {
        error "Invalid assembly type: ${params.assembly_type}"
    }

    // Set channel for trimmed reads (used by LRE-Finder)
    if (params.from_fasta) {
        ch_trimmed = Channel.empty()
    } else if (params.assembly_type == 'long') {
        ch_trimmed = ch_trimmed_longreads
    } else {
        ch_trimmed = ch_trimmed_shortreads
    }


    // Run the resistance analysis workflow
    TYPING_AND_RESISTANCE(ch_final_fasta, ch_trimmed, ch_plasmid_fasta)
        ch_versions = ch_versions.mix(TYPING_AND_RESISTANCE.out.ch_versions)
        ch_mlst_results = TYPING_AND_RESISTANCE.out.ch_mlst_results
        ch_rmlst_results = TYPING_AND_RESISTANCE.out.ch_rmlst_results
        ch_kleborate_results = TYPING_AND_RESISTANCE.out.ch_kleborate_results
        ch_amrfinder_results = TYPING_AND_RESISTANCE.out.ch_amrfinder_results
        ch_plasmidfinder_results = TYPING_AND_RESISTANCE.out.ch_plasmidfinder_results
        ch_lrefinder_results = TYPING_AND_RESISTANCE.out.ch_lrefinder_results


    WRITE_SUMMARY(
        ch_quast_results,
        ch_bbmap_results,
        ch_hybracter_summary,
        ch_mlst_results,
        ch_rmlst_results,
        ch_kleborate_results,
        ch_amrfinder_results,
        ch_plasmidfinder_results
    )


    // Collate and save software versions
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'assembly_amr'  + '_'  + 'versions.yml',
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
