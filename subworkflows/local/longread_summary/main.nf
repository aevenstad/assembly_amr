/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { HYBRACTER_TABLE                } from '../../../modules/local/hybracter_summary/main'
include { LONGREAD_SUMMARY_TABLE         } from '../../../modules/local/longread_typing_and_resistance_table/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow LONGREAD_SUMMARY {

    take:
    ch_hybracter_summary
    ch_hybracter_per_contig_summary
    ch_plassembler_summary
    ch_mlst_results
    ch_rmlst_results
    ch_kleborate_results
    ch_amrfinder_results
    ch_plasmidfinder_results
    ch_lrefinder_results

    main:
    // Assembly summary
    ch_assembly_sample_tables = ch_hybracter_summary
        .map { meta, file -> file }
        .collect()

    HYBRACTER_TABLE(ch_assembly_sample_tables)
    ch_assembly_run_summary = HYBRACTER_TABLE.out.summary


    // Per-contig resistance (long-read only)
    ch_hybracter_per_contig_all    = ch_hybracter_per_contig_summary.map { meta, f -> f }.collect()
    ch_hybracter_summary_all       = ch_hybracter_summary.map { meta, f -> f }.collect()
    ch_plassembler_all             = ch_plassembler_summary.map { meta, f -> f }.collect()
    ch_mlst_all                    = ch_mlst_results.map { meta, f -> f }.collect()
    ch_rmlst_all                   = ch_rmlst_results.map { meta, f -> f }.collect()
    ch_amrfinder_all               = ch_amrfinder_results.map { meta, f -> f }.collect()
    ch_plasmidfinder_all           = ch_plasmidfinder_results.map { meta, f -> f }.collect()
    ch_kleborate_all               = ch_kleborate_results.map { meta, f -> f }.collect()


    LONGREAD_SUMMARY_TABLE(
        ch_hybracter_per_contig_all,
        ch_hybracter_summary_all,
        ch_plassembler_all,
        ch_mlst_all,
        ch_rmlst_all,
        ch_amrfinder_all,
        ch_plasmidfinder_all,
        ch_kleborate_all,
        file("${projectDir}/bin/longread_summary.Rmd")
    )

    emit:
    assembly_summary = ch_assembly_run_summary
}

