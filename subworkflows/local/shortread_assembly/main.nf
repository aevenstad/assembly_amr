//
// Subworkflow for assembling short reads with shovill
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include {BBMAP_ALIGN                 } from '../../../modules/nf-core/bbmap/align/main'
include {FASTQC                      } from '../../../modules/nf-core/fastqc/main'
include {FASTP                       } from '../../../modules/nf-core/fastp/main'
include {QUAST                       } from '../../../modules/nf-core/quast/main'
include {SHOVILL                     } from '../../../modules/nf-core/shovill/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SHORTREAD_ASSEMBLY {

    take:
    samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = channel.empty()
    ch_shortreads = samplesheet.map { meta, _longreads, shortreads_1, shortreads_2, _fasta ->
        tuple([id: meta], [file(shortreads_1), file(shortreads_2)])
    }

    // MODULE: FASTQC
    FASTQC (
        ch_shortreads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // MODULE: FASTP
    FASTP (
        ch_shortreads,
        false, // discard_trimmed_pass
        false, // save_trimmed_fail
        false // save merged
    )
    ch_shortread_trimmed = FASTP.out.reads
    ch_versions = ch_versions.mix(FASTP.out.versions)

    // MODULE: SHOVILL
    SHOVILL (
        ch_shortread_trimmed
    )
    ch_final_fasta = SHOVILL.out.contigs
    ch_versions = ch_versions.mix(SHOVILL.out.versions)

    // MODULE: QUAST
    QUAST (
        ch_final_fasta
    )
    ch_quast_results = QUAST.out.tsv
    ch_versions = ch_versions.mix(QUAST.out.versions)

    // MODULE: BBMAP_ALIGN
    ch_for_mapping = ch_shortread_trimmed.join(ch_final_fasta)
    BBMAP_ALIGN(ch_for_mapping)
    // Outputs BBMap results
    ch_bbmap_results = BBMAP_ALIGN.out.txt
    ch_versions = ch_versions.mix(BBMAP_ALIGN.out.versions)

    emit:
    ch_shortread_trimmed
    ch_final_fasta
    ch_quast_results
    ch_bbmap_results
    ch_versions
}
