//
// Subworkflow for assembling Nanopore reads with hybracter in hybrid or long mode (if short reads are provided)
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { HYBRACTER_HYBRID       } from '../../../modules/local/hybracter/main'
include { HYBRACTER_LONG         } from '../../../modules/local/hybracter/main'
include { NANOSTAT_RAW           } from '../../../modules/local/nanostat/main'
include { NANOSTAT_TRIMMED       } from '../../../modules/local/nanostat/main'
include { PLASMID_FASTA          } from '../../../modules/local/plasmid_fasta/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow LONGREAD_ASSEMBLY {

    take:
    samplesheet // channel: samplesheet read in from --input

    main:
    ch_versions = Channel.empty()
    ch_longreads = samplesheet.map { meta, nanopore, _illumina_R1, _illumina_R2, _fasta ->
            tuple([id: meta], nanopore)
    }

    //
    // MODULE: NANOSTAT_RAW
    //
    NANOSTAT_RAW (
        ch_longreads
    )
    ch_versions = ch_versions.mix(NANOSTAT_RAW.out.versions)

    //
    // MODULE: HYBRACTER
    //

    if (params.assembly_type == 'hybrid'){
        ch_samplesheet = samplesheet.map { meta, nanopore, illumina_R1, illumina_R2, _fasta ->
            tuple([id: meta], nanopore, illumina_R1, illumina_R2)
        }
        HYBRACTER_HYBRID (ch_samplesheet)
        ch_hybracter_final_out = HYBRACTER_HYBRID.out.final_output
        ch_trimmed = HYBRACTER_HYBRID.out.processing
        ch_versions = ch_versions.mix(HYBRACTER_HYBRID.out.versions)
    } else if (params.assembly_type == 'long') {
        HYBRACTER_LONG (ch_longreads)
        ch_hybracter_final_out = HYBRACTER_LONG.out.final_output
        ch_trimmed = HYBRACTER_LONG.out.processing
        ch_versions = ch_versions.mix(HYBRACTER_LONG.out.versions)
    }
    
    ch_final_fasta = ch_hybracter_final_out.map { meta, dir -> 
        tuple(meta, file("${dir}/*_final.fasta"))
    }
    ch_trimmed_longreads = ch_trimmed.map { meta, dir -> 
        def files = file("${dir}/qc/*filt_trim.fastq.gz")
        tuple(meta, files)
    }
    ch_trimmed_shortreads = ch_trimmed.map { meta, dir -> 
        def files = file("${dir}/qc/fastp/*.fastq.gz")
        tuple(meta, files)
    }
    ch_hybracter_summary = ch_hybracter_final_out.map { meta, dir -> 
        def files = file("${dir}/*_hybracter_summary.tsv")
        tuple(meta, files)
    }
    ch_plasmid_fasta = ch_hybracter_final_out.map { meta, dir -> 
        def files = file("${dir}/complete/*_plasmid.fasta")
        tuple(meta, files)
    }
    ch_plasmid_stats = ch_hybracter_final_out.map { meta, dir -> 
        def files = file("${dir}/complete/*_per_contig_stats.tsv")
        tuple(meta, files)
    }
    ch_split_plasmids = ch_plasmid_fasta.join(ch_plasmid_stats)

    // 
    // MODULE: PLASMID_FASTA
    //
    PLASMID_FASTA (
        ch_split_plasmids
    )

    //
    // MODULE: NANOSTAT_TRIMMED
    //
    NANOSTAT_TRIMMED (
        ch_trimmed_longreads
    )

    emit:
    ch_final_fasta
    ch_versions
    ch_trimmed_longreads
    ch_trimmed_shortreads
    ch_hybracter_summary
}
