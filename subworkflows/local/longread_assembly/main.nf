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
include { KRAKEN2_KRAKEN2        } from '../../../modules/nf-core/kraken2/kraken2/main'
include { NANOSTAT_RAW           } from '../../../modules/local/nanostat/main'
include { NANOSTAT_TRIMMED       } from '../../../modules/local/nanostat/main'
include { PLASMID_FASTA          } from '../../../modules/local/plasmid_fasta/main'
include { SETMINCHROMSIZE        } from '../../../modules/local/setminchromsize/main'

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
    ch_long_input = samplesheet.map { meta, nanopore, _illumina_R1, _illumina_R2, _fasta ->
            tuple([id: meta], nanopore)
    }

    ch_hybrid_input = samplesheet.map { meta, nanopore, illumina_R1, illumina_R2, _fasta ->
            tuple([id: meta], nanopore, illumina_R1, illumina_R2)
    }

    //
    // MODULE: NANOSTAT_RAW
    //
    NANOSTAT_RAW (
        ch_long_input
    )
    ch_versions = ch_versions.mix(NANOSTAT_RAW.out.versions)

    //
    // MODULE: KRAKEN2
    //
    KRAKEN2_KRAKEN2 (
        ch_long_input,
        false,
        true
    )
    ch_kraken_report = KRAKEN2_KRAKEN2.out.report
    //ch_kraken2_classified_reads = KRAKEN2_KRAKEN2.out.classified_reads_fastq
    ch_kraken2_genus = KRAKEN2_KRAKEN2.out.genus
    ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions)



    //
    // MODULE: MINCHROMSIZE
    //
    SETMINCHROMSIZE (
        ch_kraken2_genus,
        file("${projectDir}/assets/genome_size.csv")
    )
    ch_minchromsize = SETMINCHROMSIZE.out.txt

    // Prepare channel for assembly
    //
    //ch_classified_np = ch_kraken2_classified_reads.map { meta, classified ->
    //    tuple(meta, classified)
    //}
    //ch_samplesheet_hybrid =
    //    ch_samplesheet
    //        .map { meta, nanopore, illumina_R1, illumina_R2, fasta ->
    //            tuple(meta, nanopore, illumina_R1, illumina_R2)
    //        }
    //        .join(ch_classified_np)   // join by meta.id
    //        .map { meta, _original_np, illumina_R1, illumina_R2, classified_np ->
    //            tuple(meta, classified_np, illumina_R1, illumina_R2)
    //        }
    //ch_samplesheet_long =
    //    ch_samplesheet
    //        .map { meta, nanopore, illumina_R1, illumina_R2, fasta ->
    //            tuple(meta, nanopore)
    //        }
    //        .join(ch_classified_np)   // join by meta.id
    //        .map { meta, _original_np, classified_np ->
    //            tuple(meta, classified_np)
    //        }

    //
    // MODULE: HYBRACTER
    //
    //  Create input channels
    ch_hybrid_assembly = ch_hybrid_input.join(ch_minchromsize)
    ch_long_assembly = ch_long_input.join(ch_minchromsize)

    if (params.assembly_type == 'hybrid'){
        HYBRACTER_HYBRID (ch_hybrid_assembly)
        ch_hybracter_final_out = HYBRACTER_HYBRID.out.final_output
        ch_trimmed = HYBRACTER_HYBRID.out.processing
        ch_versions = ch_versions.mix(HYBRACTER_HYBRID.out.versions)
    } else if (params.assembly_type == 'long') {
        HYBRACTER_LONG (ch_long_assembly)
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
    ch_circular_plasmid_fasta = PLASMID_FASTA.out.circular.flatMap { meta, files ->
        files.collect { file -> tuple(meta, file) }
    }

    ch_linear_plasmid_fasta = PLASMID_FASTA.out.linear.flatMap { meta, files ->
        files.collect { file -> tuple(meta, file) }
    }

    ch_all_plasmid_fasta = ch_circular_plasmid_fasta.concat(ch_linear_plasmid_fasta)
    ch_all_plasmid_fasta.view()
    //
    // MODULE: NANOSTAT_TRIMMED
    //
    NANOSTAT_TRIMMED (
        ch_trimmed_longreads
    )

    emit:
    ch_final_fasta
    ch_trimmed_longreads
    ch_trimmed_shortreads
    ch_hybracter_summary
    ch_all_plasmid_fasta
    ch_versions
}
