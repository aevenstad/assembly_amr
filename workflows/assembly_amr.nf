/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_ASSEMBLY            } from '../subworkflows/local/shortread_assembly/main'
include { LONGREAD_ASSEMBLY             } from '../subworkflows/local/longread_assembly/main'
include { RESISTANCE_ANALYSIS           } from '../subworkflows/local/resistance_analysis/main'
include { QUAST                         } from '../modules/nf-core/quast/main'
include { WRITE_SUMMARY                 } from '../subworkflows/local/write_summary/main'
include { WRITE_PDF_REPORT              } from '../modules/local/pdf_report/main'
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
    RESISTANCE_ANALYSIS(ch_final_fasta, ch_trimmed)
        ch_versions = ch_versions.mix(RESISTANCE_ANALYSIS.out.ch_versions)
        ch_mlst_results = RESISTANCE_ANALYSIS.out.ch_mlst_results
        ch_rmlst_results = RESISTANCE_ANALYSIS.out.ch_rmlst_results
        ch_kleborate_results = RESISTANCE_ANALYSIS.out.ch_kleborate_results
        ch_amrfinder_results = RESISTANCE_ANALYSIS.out.ch_amrfinder_results
        ch_plasmidfinder_results = RESISTANCE_ANALYSIS.out.ch_plasmidfinder_results
        ch_lrefinder_results = RESISTANCE_ANALYSIS.out.ch_lrefinder_results


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


    // Write PDF report
    ch_genome_size = Channel.fromPath("${projectDir}/assets/genome_size.csv")
    ch_kleborate_columns = Channel.fromPath("${projectDir}/assets/kleborate_columns.txt")
    ch_test_rmd = Channel.fromPath("${projectDir}/bin/test.Rmd")
    
    ch_pdf_input = ch_quast_results
        .join(ch_bbmap_results)
        .join(ch_mlst_results)
        .join(ch_rmlst_results)
        .join(ch_kleborate_results)
        .join(ch_amrfinder_results)
        .join(ch_plasmidfinder_results)
        .join(ch_lrefinder_results)
        .combine(ch_genome_size)
        .combine(ch_kleborate_columns)
        .combine(ch_test_rmd)
        .combine(ch_collated_versions)
        .map { tuple -> [tuple[0].id] + tuple[1..-1] }


    WRITE_PDF_REPORT(ch_pdf_input)



    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
