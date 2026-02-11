/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_STATS                       } from '../../../modules/local/shortread_summary/main'
include { STATS_FROM_FASTA                      } from '../../../modules/local/shortread_summary/main'
include { MERGE_SHORTREAD_STATS                 } from '../../../modules/local/shortread_summary/main'
include { TYPING_AND_RESISTANCE_TABLE           } from '../../../modules/local/shortread_typing_and_resistance_table/main'
include { MERGE_TYPING_AND_RESISTANCE_TABLES    } from '../../../modules/local/merge_shortread_typing_and_resistance_table/main'
include { CREATE_RUN_TABLE                      } from '../../../modules/local/create_run_table/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SHORTREAD_SUMMARY {

    take:
    ch_quast_results
    ch_bbmap_results
    ch_mlst_results
    ch_rmlst_results
    ch_kleborate_results
    ch_amrfinder_results
    ch_plasmidfinder_results
    ch_lrefinder_results
    ch_virulencefinder_results

    main:
    if (params.from_fasta) {
        ch_stats = ch_quast_results
            .map { tuple -> [tuple[0].id] + tuple[1..-1] }

        STATS_FROM_FASTA(ch_stats)

        ch_sample_tables = STATS_FROM_FASTA.out.summary
            .map { meta, file -> file }
            .collect()
    }
    else {
        ch_stats = ch_quast_results
            .join(ch_bbmap_results)
            .map { tuple -> [tuple[0].id] + tuple[1..-1] }

        SHORTREAD_STATS(ch_stats)

        ch_sample_tables = SHORTREAD_STATS.out.summary
            .map { meta, file -> file }
            .collect()
    }

    MERGE_SHORTREAD_STATS(ch_sample_tables)
    ch_assembly_run_summary = MERGE_SHORTREAD_STATS.out.summary


    // Create typing and resistance summary
    ch_typing_and_resistance = (ch_mlst_results)
        .join(ch_rmlst_results)
        .join(ch_kleborate_results)
        .join(ch_amrfinder_results)
        .join(ch_plasmidfinder_results)
        .join(ch_lrefinder_results)
        .join(ch_virulencefinder_results)
        .map { tuple -> [tuple[0].id] + tuple[1..-1] }

    TYPING_AND_RESISTANCE_TABLE (
        ch_typing_and_resistance,
        file("${projectDir}/assets/amrfinderplus_classes.txt")
        )


    ch_typing_and_resistance_sample_summary = TYPING_AND_RESISTANCE_TABLE.out.summary.map { meta, file -> file }.collect()
    MERGE_TYPING_AND_RESISTANCE_TABLES(ch_typing_and_resistance_sample_summary)
    ch_typing_and_resistance_run_summary = MERGE_TYPING_AND_RESISTANCE_TABLES.out.summary


    ch_run_summary = (ch_assembly_run_summary)
        .combine(ch_typing_and_resistance_run_summary)
    CREATE_RUN_TABLE(ch_run_summary)

    emit:
    run_summary = MERGE_SHORTREAD_STATS.out.summary
}

