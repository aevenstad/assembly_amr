// Subworkflow for assembling Nanopore reads with hybracter in hybrid or long mode (if short reads are provided)
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { HYBRACTER              } from '../../../modules/local/hybracter/main'
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
    ch_versions = channel.empty()
    ch_longreads = samplesheet.map { meta, nanopore, _illumina_R1, _illumina_R2, _fasta ->
            tuple([id: meta], nanopore)
    }

    ch_long_hybracter = samplesheet.map { meta, nanopore, _illumina_R1, _illumina_R2, _fasta ->
            tuple([id: meta], nanopore, [], [])
    }

    ch_hybrid_hybracter = samplesheet.map { meta, nanopore, illumina_R1, illumina_R2, _fasta ->
            tuple([id: meta], nanopore, illumina_R1, illumina_R2)
    }

    // MODULE: NANOSTAT_RAW
    NANOSTAT_RAW (
        ch_longreads
    )
    ch_versions = ch_versions.mix(NANOSTAT_RAW.out.versions)

    // MODULE: KRAKEN2
    KRAKEN2_KRAKEN2 (
        ch_longreads,
        false,
        true
    )
    ch_kraken2_genus    = KRAKEN2_KRAKEN2.out.genus
    ch_versions         = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions)



    // MODULE: MINCHROMSIZE
    SETMINCHROMSIZE (
        ch_kraken2_genus,
        file("${projectDir}/assets/genome_size.csv")
    )
    ch_minchromsize = SETMINCHROMSIZE.out.txt

    // MODULE: HYBRACTER
    ch_hybrid_assembly = ch_hybrid_hybracter.join(ch_minchromsize)
    ch_long_assembly = ch_long_hybracter.join(ch_minchromsize)

    if (params.assembly_type == 'hybrid'){
        HYBRACTER (
            ch_hybrid_assembly
        )
    } else if (params.assembly_type == 'long') {
        HYBRACTER (
            ch_long_assembly
        )
    }

    ch_hybracter_final_out      = HYBRACTER.out.final_output
    ch_hybracter_processing     = HYBRACTER.out.processing
    ch_versions                 = ch_versions.mix(HYBRACTER.out.versions)

    // Set up channels from hybracter outputs
    ch_hybracter_outputs = ch_hybracter_final_out.multiMap { meta, dir ->
        final_fasta        : tuple(meta, file("${dir}/*_final.fasta"))
        chromosome         : tuple(meta, file("${dir}/complete/*_chromosome.fasta"))
        summary            : tuple(meta, file("${dir}/*_hybracter_summary.tsv"))
        per_contig_stats   : tuple(meta, file("${dir}/complete/*_per_contig_stats.tsv"))
        plasmid_fasta      : tuple(meta, file("${dir}/complete/*_plasmid.fasta"))
    }

    ch_final_fasta             = ch_hybracter_outputs.final_fasta
    ch_chromosome              = ch_hybracter_outputs.chromosome
    ch_hybracter_summary       = ch_hybracter_outputs.summary
    ch_plasmid_fasta           = ch_hybracter_outputs.plasmid_fasta
    ch_per_contig_summary      = ch_hybracter_outputs.per_contig_stats
    ch_split_plasmids          = ch_plasmid_fasta.join(ch_per_contig_summary)

    ch_hybracter_processing_outputs = ch_hybracter_processing.multiMap { meta, dir ->
        longreads        : tuple(meta, file("${dir}/qc/*filt_trim.fastq.gz"))
        shortreads       : tuple(meta, file("${dir}/qc/fastp/*.fastq.gz"))
        plassembler      : tuple(meta, file("${dir}/plassembler/*/*plassembler_summary.tsv"))
    }

    ch_trimmed_longreads    = ch_hybracter_processing_outputs.longreads
    ch_trimmed_shortreads   = ch_hybracter_processing_outputs.shortreads
    ch_plassembler_summary  = ch_hybracter_processing_outputs.plassembler


    // MODULE: PLASMID_FASTA
    PLASMID_FASTA (
        ch_split_plasmids
    )
    ch_circular_plasmids = PLASMID_FASTA.out.circular
    ch_linear_plasmids = PLASMID_FASTA.out.linear
    ch_all_fasta = channel.empty()
        .mix(ch_chromosome)
        .mix(ch_circular_plasmids)
        .mix(ch_linear_plasmids)


    // Set kleborate input channel as a list of chromosome fasta + plasmids
    ch_kleborate_longread = ch_all_fasta
        .groupTuple()
        .map { meta, fasta_list ->
            def flat_fastas = fasta_list.collect { it instanceof List ? it : [it] }.flatten()
            tuple(meta, flat_fastas)
        }

    // MODULE: NANOSTAT_TRIMMED
    NANOSTAT_TRIMMED (
        ch_trimmed_longreads
    )

    emit:
    ch_final_fasta
    ch_versions
    ch_trimmed_longreads
    ch_trimmed_shortreads
    ch_hybracter_summary
    ch_per_contig_summary
    ch_plassembler_summary
    ch_kleborate_longread
}
