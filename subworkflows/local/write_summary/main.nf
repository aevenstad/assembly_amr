//
// Subworkflow for generation of summaries per sample and per run
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_STATS                       } from '../../../modules/local/shortread_summary/main'
include { STATS_FROM_FASTA                      } from '../../../modules/local/shortread_summary/main'
include { MERGE_SHORTREAD_STATS                 } from '../../../modules/local/shortread_summary/main'
include { HYBRACTER_TABLE                       } from '../../../modules/local/hybracter_summary/main'
include { TYPING_AND_RESISTANCE_TABLE           } from '../../../modules/local/typing_and_resistance_summary/main'
include { PER_CONTIG_RESISTANCE_SUMMARY         } from '../../../modules/local/typing_and_resistance_summary/main'
include { MERGE_TYPING_AND_RESISTANCE_TABLES    } from '../../../modules/local/typing_and_resistance_summary/main'
include { CREATE_RUN_TABLE                      } from '../../../modules/local/create_run_table/main'

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
    if (params.from_fasta) {
        ch_assembly_stats = (ch_quast_results)
            .map { tuple -> [tuple[0].id] + tuple[1..-1] }
        STATS_FROM_FASTA(ch_assembly_stats)
        ch_assembly_sample_table = STATS_FROM_FASTA.out.summary.map { meta, file -> file }.collect()
        MERGE_SHORTREAD_STATS(ch_assembly_sample_table)
        ch_assembly_run_summary = MERGE_SHORTREAD_STATS.out.summary
    }
    // Create shortread assembly summary
    if (!params.from_fasta && params.assembly_type == 'short') {
        ch_assembly_stats = (ch_quast_results)
            .join(ch_bbmap_results)
            .map { tuple -> [tuple[0].id] + tuple[1..-1] }
        SHORTREAD_STATS(ch_assembly_stats)
        ch_assembly_sample_table = SHORTREAD_STATS.out.summary.map { meta, file -> file }.collect()
        MERGE_SHORTREAD_STATS(ch_assembly_sample_table)
        ch_assembly_run_summary = MERGE_SHORTREAD_STATS.out.summary
    }

    // Create hybracter summary
    else if (!params.from_fasta && params.assembly_type != 'short') {
        ch_assembly_sample_table = ch_hybracter_summary.map { meta, file -> file }.collect()
        HYBRACTER_TABLE(ch_assembly_sample_table)
        ch_assembly_run_summary = HYBRACTER_TABLE.out.summary
    }

    // Create typing and resistance summary
    ch_typing_and_resistance = (ch_mlst_results)
        .join(ch_rmlst_results)
        .join(ch_kleborate_results)
        .join(ch_amrfinder_results)
        .join(ch_plasmidfinder_results)
        .map { tuple -> [tuple[0].id] + tuple[1..-1] }

    TYPING_AND_RESISTANCE_TABLE (
        ch_typing_and_resistance,
        file("${projectDir}/assets/amrfinderplus_classes.txt")
        )

    ch_typing_and_resistance_sample_summary = TYPING_AND_RESISTANCE_TABLE.out.summary.map { meta, file -> file }.collect()
    MERGE_TYPING_AND_RESISTANCE_TABLES(ch_typing_and_resistance_sample_summary)
    ch_typing_and_resistance_run_summary = MERGE_TYPING_AND_RESISTANCE_TABLES.out.summary

    // Create per contig resistance summary for hybracter assemblies
    if (!params.from_fasta && params.assembly_type != 'short') {
        ch_per_contig_resistance = (ch_amrfinder_results)
            .join(ch_plasmidfinder_results)
            .map { tuple -> [tuple[0].id] + tuple[1..-1] }
        PER_CONTIG_RESISTANCE_SUMMARY (
            ch_per_contig_resistance,
            file("${projectDir}/assets/amrfinderplus_classes.txt")
            )
    }

    // Merge assembly and resistance tables

    ch_run_summary = (ch_assembly_run_summary)
        .combine(ch_typing_and_resistance_run_summary)
    CREATE_RUN_TABLE(ch_run_summary)

}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    END OF WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
