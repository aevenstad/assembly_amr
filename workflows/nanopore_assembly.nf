/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MLST                   } from '../modules/nf-core/mlst/main'
include { RMLST                  } from '../modules/local/rmlst/main'
include { KLEBORATE              } from '../modules/nf-core/kleborate/main'
include { AMRFINDERPLUS_RUN      } from '../modules/nf-core/amrfinderplus/run/main'
include { BAKTA_BAKTA            } from '../modules/nf-core/bakta/bakta/main'
include { HYBRACTER              } from '../modules/local/hybracter/main'
include { NANOSTAT_RAW           } from '../modules/local/nanostat/main'
include { NANOSTAT_TRIMMED       } from '../modules/local/nanostat/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_nanopore_assembly_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NANOPORE_ASSEMBLY_ANNOTATION {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_longreads = ch_samplesheet.map { meta, longreads, shortreads_1, shortreads_2 -> 
        tuple(meta, longreads) 
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
    HYBRACTER (
        ch_samplesheet
    )
    ch_final_fasta = HYBRACTER.out.final_output.map { meta, dir -> 
        tuple(meta, file("${dir}/complete/*_final.fasta"))
    }
    ch_trimmed_longreads = HYBRACTER.out.processing.map { meta, dir -> 
        def files = file("${dir}/qc/*filt_trim.fastq.gz")
        println "Files in directory ${dir}: $files"
        tuple(meta, files)
    }
    ch_multiqc_files = ch_multiqc_files.mix(HYBRACTER.out.fastp_json)
    ch_versions = ch_versions.mix(HYBRACTER.out.versions)


    //
    // MODULE: NANOSTAT_TRIMMED
    //
    NANOSTAT_TRIMMED (
        ch_trimmed_longreads
    )
    ch_multiqc_files = ch_multiqc_files.mix(NANOSTAT_TRIMMED.out.nanostat_trimmed)

    //
    // MODULE: Run MLST (Multi Locus Sequence Typing)
    //
    MLST (
        ch_final_fasta
    )
    ch_mlst = MLST.out.tsv
    ch_versions = ch_versions.mix(MLST.out.versions.first())

    //
    // MODULE RMLST (Run MLST)
    //
    RMLST (
        ch_final_fasta
    )
    ch_rmlst = RMLST.out.species // Outputs rMLST results

    //
    // MODULE KLEBORATE (Run Kleborate for Klebsiella)
    // Only run Kleborate fot Klebsiella assemblies identified through rMLST
    //
    KLEBORATE (
        ch_rmlst,
        ch_final_fasta
    )
    ch_kleborate = KLEBORATE.out.txt // Outputs Kleborate results
    ch_versions = ch_versions.mix(KLEBORATE.out.versions.first())

    //
    // MODULE AMRFINDERPLUS (Run AMRFinderPlus)
    //
    AMRFINDERPLUS_RUN (
        ch_final_fasta,
        ch_rmlst
    )
    ch_amrfinderplus = AMRFINDERPLUS_RUN.out // Outputs AMRFinderPlus results
    ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions.first())


    //
    // MODULE: BAKTA
    //
    BAKTA_BAKTA (
        ch_final_fasta
    )

    ch_versions = ch_versions.mix(BAKTA_BAKTA.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(BAKTA_BAKTA.out.txt)




    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'nanopore_assembly_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
