/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { AMRFINDERPLUS_RUN               } from '../../../modules/nf-core/amrfinderplus/run/main'
include { BAKTA as BAKTA                 } from '../../../modules/nf-core/bakta/bakta/main'
include { BAKTA as BAKTA_PLASMIDS         } from '../../../modules/nf-core/bakta/bakta/main'
include { KLEBORATE                       } from '../../../modules/nf-core/kleborate/main'
include { LRE_FINDER                      } from '../../../modules/local/lre-finder/main'
include { LRE_FINDER_LONGREAD             } from '../../../modules/local/lre-finder/main.nf'
include { MLST                            } from '../../../modules/nf-core/mlst/main'
include { PLASMIDFINDER                   } from '../../../modules/nf-core/plasmidfinder/main'
include { RMLST                           } from '../../../modules/local/rmlst/main'
//include { SPLIT_BAKTA            } from '../../../modules/local/split_bakta/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TYPING_AND_RESISTANCE {

    take:
    ch_final_fasta
    ch_reads
    ch_all_plasmids_fasta

    main:
    ch_versions = Channel.empty()

    // MODULE: MLST
    ch_mlst_rename = Channel.fromPath("bin/mlst_species_names.sh")
    ch_mlst_input = ch_final_fasta
        .combine(ch_mlst_rename)
    MLST (ch_mlst_input)
    ch_mlst_results = MLST.out.tsv
    ch_mlst_renamed = MLST.out.renamed_tsv
    ch_versions = ch_versions.mix(MLST.out.versions)

    // MODULE: RMLST
    RMLST (ch_final_fasta)
    ch_rmlst_results = RMLST.out.rmlst
    ch_rmlst = RMLST.out.species
    ch_versions = ch_versions.mix(RMLST.out.versions)

    // MODULE KLEBORATE (Run Kleborate for Klebsiella)
    // Only run Kleborate fot Klebsiella assemblies identified through rMLST
    ch_species_fasta = ch_mlst_renamed.join(ch_final_fasta)

    KLEBORATE (ch_species_fasta)
    ch_kleborate_results = KLEBORATE.out.txt
    ch_versions = ch_versions.mix(KLEBORATE.out.versions.first())

    // MODULE AMRFINDERPLUS (Run AMRFinderPlus)
    AMRFINDERPLUS_RUN (ch_species_fasta, file("${projectDir}/assets/amrfinder_organism_list.txt"))
    ch_amrfinder_results = AMRFINDERPLUS_RUN.out.report
    ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions.first())

    // MODULE: BAKTA
    if (params.bakta) {
        BAKTA (ch_final_fasta)
        ch_bakta_gff = BAKTA.out.gff
        ch_bakta_fasta = BAKTA.out.fna
        ch_bakta_results = ch_bakta_gff.join(ch_bakta_fasta)
        ch_versions = ch_versions.mix(BAKTA.out.versions)
    }
    // MODULE: BAKTA_PLASMIDS
    if (params.assembly_type != 'short' && params.bakta) {
        // Only run SPLIT BAKTA for long-read assemblies
        BAKTA_PLASMIDS (ch_all_plasmids_fasta)
    }

    // MODULE: LRE_FINDER
    // Only run LRE-Finder for Enterococcus assemblies identified through rMLST
    if (!params.from_fasta) {
        ch_species_reads = ch_rmlst.join(ch_reads)
        if (params.assembly_type == "long") {
            LRE_FINDER_LONGREAD (ch_species_reads)
            ch_lrefinder_results = LRE_FINDER_LONGREAD.out.txt
            ch_versions = ch_versions.mix(LRE_FINDER_LONGREAD.out.versions)
        } else {
            LRE_FINDER (ch_species_reads)
            ch_lrefinder_results = LRE_FINDER.out.txt
            ch_versions = ch_versions.mix(LRE_FINDER.out.versions)
        }
    }


    // MODULE: PLASMIDFINDER
    PLASMIDFINDER (ch_final_fasta)
    ch_plasmidfinder_results = PLASMIDFINDER.out.tsv
    ch_versions = ch_versions.mix(PLASMIDFINDER.out.versions)

    emit:
    ch_mlst_results
    ch_rmlst_results
    ch_kleborate_results
    ch_amrfinder_results
    ch_plasmidfinder_results
    ch_lrefinder_results
    ch_versions
}
