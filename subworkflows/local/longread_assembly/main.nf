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

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow LONGREAD_ASSEMBLY {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_longreads = ch_samplesheet.map { meta, longreads, _shortreads_1, _shortreads_2 -> 
        def metadata = [ id: meta ]    
        tuple(metadata, longreads) 
    }


    //
    // MODULE: NANOSTAT_RAW
    //
    NANOSTAT_RAW (
        ch_longreads
    )
    ch_versions = ch_versions.mix(NANOSTAT_RAW.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(NANOSTAT_RAW.out.nanostat_raw)


    //
    // MODULE: HYBRACTER
    //

    if (params.assembly_type == 'hybrid'){
        HYBRACTER_HYBRID (ch_samplesheet)
        ch_final_fasta = HYBRACTER_HYBRID.out.final_output
        ch_trimmed = HYBRACTER_HYBRID.out.processing
        ch_multiqc_files = ch_multiqc_files.mix(HYBRACTER_HYBRID.out.fastp_json)
        ch_versions = ch_versions.mix(HYBRACTER_HYBRID.out.versions)
    } else if (params.assembly_type == 'long') {
        HYBRACTER_LONG (ch_longreads)
        ch_final_fasta = HYBRACTER_LONG.out.final_output
        ch_trimmed = HYBRACTER_LONG.out.processing
        ch_multiqc_files = ch_multiqc_files.mix(HYBRACTER_LONG.out.fastp_json)
        ch_versions = ch_versions.mix(HYBRACTER_LONG.out.versions)
    }
    
    ch_final_fasta = ch_final_fasta.map { meta, dir -> 
        tuple(meta, file("${dir}/*_final.fasta"))
    }
    ch_trimmed_longreads = ch_trimmed.map { meta, dir -> 
        def files = file("${dir}/qc/*filt_trim.fastq.gz")
        println "Files in directory ${dir}: $files"
        tuple(meta, files)
    }
    ch_trimmed_shortreads = ch_trimmed.map { meta, dir -> 
        def files = file("${dir}/qc/fastp/*.fastq.gz")
        println "Files in directory ${dir}: $files"
        tuple(meta, files)
    }

    //
    // MODULE: NANOSTAT_TRIMMED
    //
    NANOSTAT_TRIMMED (
        ch_trimmed_longreads
    )
    ch_multiqc_files = ch_multiqc_files.mix(NANOSTAT_TRIMMED.out.nanostat_trimmed)

    emit:
    ch_final_fasta
    ch_multiqc_files
    ch_versions
    ch_trimmed_longreads
    ch_trimmed_shortreads
}