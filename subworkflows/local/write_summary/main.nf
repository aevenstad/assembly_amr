include { SHORTREAD_SUMMARY } from '../shortread_summary/main'
include { LONGREAD_SUMMARY  } from '../longread_summary/main'
include { CREATE_RUN_TABLE  } from '../../../modules/local/create_run_table/main'

workflow WRITE_SUMMARY {

    take:
    ch_quast_results
    ch_bbmap_results
    ch_hybracter_summary
    ch_hybracter_per_contig_summary
    ch_plassembler_summary
    ch_mlst_results
    ch_rmlst_results
    ch_kleborate_results
    ch_amrfinder_results
    ch_plasmidfinder_results
    ch_lrefinder_results
    ch_virulencefinder_results

    main:
    if (params.assembly_type == 'short') {

        SHORTREAD_SUMMARY(
            ch_quast_results,
            ch_bbmap_results,
            ch_mlst_results,
            ch_rmlst_results,
            ch_kleborate_results,
            ch_amrfinder_results,
            ch_plasmidfinder_results,
            ch_lrefinder_results,
            ch_virulencefinder_results
        )
    }
    else {

        LONGREAD_SUMMARY(
            ch_hybracter_summary,
            ch_hybracter_per_contig_summary,
            ch_plassembler_summary,
            ch_mlst_results,
            ch_rmlst_results,
            ch_kleborate_results,
            ch_amrfinder_results,
            ch_plasmidfinder_results,
            ch_lrefinder_results
        )
    }
}

