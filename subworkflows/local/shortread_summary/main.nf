/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHORTREAD_STATS                       } from '../../../modules/local/shortread_summary/main'
include { STATS_FROM_FASTA                      } from '../../../modules/local/shortread_summary/main'
include { MERGE_SHORTREAD_STATS                 } from '../../../modules/local/shortread_summary/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SHORTREAD_SUMMARY {

    take:
    ch_quast_results
    ch_bbmap_results

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

    emit:
    run_summary = MERGE_SHORTREAD_STATS.out.summary
}

