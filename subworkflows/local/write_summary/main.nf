//
// Subworkflow for generation of summaries per sample and per run
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_STATS                       } from '../../../modules/local/shortread_summary/main'
include { MERGE_SHORTREAD_STATS                 } from '../../../modules/local/shortread_summary/main'
include { HYBRACTER_TABLE                       } from '../../../modules/local/hybracter_summary/main'
include { TYPING_AND_RESISTANCE_TABLE           } from '../../../modules/local/typing_and_resistance_summary/main'
include { MERGE_TYPING_AND_RESISTANCE_TABLES    } from '../../../modules/local/typing_and_resistance_summary/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow WRITE_SUMMARY {
    
    take:
    ch_quast_results
    ch_bbmap_results
    ch_hybracter_summary
    ch_mlst_results
    ch_rmlst_results
    ch_kleborate_results
    ch_amrfinder_results
    ch_plasmidfinder_results

    main:
    // Create shortread assembly summary
    if (params.assembly_type == 'short') {
    ch_assembly = (ch_quast_results)
        .join(ch_bbmap_results)
        .map { tuple -> [tuple[0].id] + tuple[1..-1] }
    SHORTREAD_STATS(ch_assembly)
    ch_assembly_summary = SHORTREAD_STATS.out.summary.map { meta, file -> file }.collect()
    MERGE_SHORTREAD_STATS(ch_assembly_summary)
    }
    
    // Create hybracter summary
    else {
        ch_assembly_summary = ch_hybracter_summary.map { meta, file -> file }.collect()
        HYBRACTER_TABLE(ch_assembly_summary)
    }

    // Create typing and resistance summary
    ch_typing_and_resistance = (ch_mlst_results)
        .join(ch_rmlst_results)
        .join(ch_kleborate_results)
        .join(ch_amrfinder_results)
        .join(ch_plasmidfinder_results)
        .map { tuple -> [tuple[0].id] + tuple[1..-1] }
    TYPING_AND_RESISTANCE_TABLE(ch_typing_and_resistance)
    ch_typing_and_resistance_summary = TYPING_AND_RESISTANCE_TABLE.out.summary.map { meta, file -> file }.collect()
    MERGE_TYPING_AND_RESISTANCE_TABLES(ch_typing_and_resistance_summary)
}

