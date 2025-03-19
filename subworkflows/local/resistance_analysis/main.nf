/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { AMRFINDERPLUS_RUN      } from '../../../modules/nf-core/amrfinderplus/run/main'
include { BAKTA_BAKTA            } from '../../../modules/nf-core/bakta/bakta/main'
include { KLEBORATE              } from '../../../modules/nf-core/kleborate/main'
include { LRE_FINDER             } from '../../../modules/local/lre-finder/main'
include { MLST                   } from '../../../modules/nf-core/mlst/main'
include { PLASMIDFINDER          } from '../../../modules/nf-core/plasmidfinder/main'
include { RMLST                  } from '../../../modules/local/rmlst/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RESISTANCE_ANALYSIS {

    take:
    ch_final_fasta
    ch_reads

    main:
    ch_versions = Channel.empty()

    // MODULE: MLST
    MLST (ch_final_fasta)
    ch_versions = ch_versions.mix(MLST.out.versions)

    // MODULE: RMLST
    RMLST (ch_final_fasta)
    ch_rmlst = RMLST.out.species

    // MODULE KLEBORATE (Run Kleborate for Klebsiella)
    // Only run Kleborate fot Klebsiella assemblies identified through rMLST
    ch_species_fasta = ch_rmlst.join(ch_final_fasta)

    KLEBORATE (ch_species_fasta)
    ch_versions = ch_versions.mix(KLEBORATE.out.versions.first())

    // MODULE AMRFINDERPLUS (Run AMRFinderPlus)
    AMRFINDERPLUS_RUN (ch_species_fasta, file("../../../assets/amrfinder_organism_list.txt"))
    ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions.first())

    // MODULE: BAKTA
    if (params.bakta) {
        BAKTA_BAKTA (ch_final_fasta)
        ch_versions = ch_versions.mix(BAKTA_BAKTA.out.versions)
    }

    // MODULE: LRE_FINDER
    LRE_FINDER (ch_rmlst, ch_reads)
    ch_versions = ch_versions.mix(LRE_FINDER.out.versions)

    // MODULE: PLASMIDFINDER
    PLASMIDFINDER (ch_final_fasta)
    ch_versions = ch_versions.mix(PLASMIDFINDER.out.versions)

    emit:
    ch_versions
}