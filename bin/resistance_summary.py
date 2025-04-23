#!/usr/bin/env python3

import pandas   as pd
import os
import sys


def get_mlst_results(mlst_results, translation_table):
    if not os.path.isfile(mlst_results):
        print(f"Error: MLST results file '{mlst_results}' does not exist.")
        sys.exit(1)
    if not os.path.isfile(translation_table):
        print(f"Error: Translation table file '{translation_table}' does not exist.")
        sys.exit(1)
    # Check if the MLST results file is empty
    if os.path.getsize(mlst_results) == 0:
        print(f"Error: MLST results file '{mlst_results}' is empty.")
        sys.exit(1)
    # Check if the translation table file is empty
    if os.path.getsize(translation_table) == 0:
        print(f"Error: Translation table file '{translation_table}' is empty.")
        sys.exit(1)    


    colnames = ["Sample",
                "Species",
                "ST",
                "locus_1",
                "locus_2",
                "locus_3",
                "locus_4",
                "locus_5",
                "locus_6",
                "locus_7"]
    
    mlst_df = pd.read_csv(mlst_results, sep="\t", names=colnames, header=None)
    species_df = pd.read_csv(translation_table, sep="\t", header=0)
    mlst_df = mlst_df.merge(species_df, left_on="Species", right_on="short_name", how="inner")

    mlst_table = mlst_df[["full_name", "ST"]]
    mlst_table = mlst_table.rename(columns={"full_name": "MLST species"})
    return mlst_table



def get_rmlst_results(rmlst_results):
    if not os.path.isfile(rmlst_results):
        print(f"Error: rMLST output file '{rmlst_results}' does not exist.")
        sys.exit(1)
    # Check if the rMLST results file is empty
    if os.path.getsize(rmlst_results) == 0:
        print(f"Error: rMLST results file '{rmlst_results}' is empty.")
        sys.exit(1)

    # Initialize variables with default values
    RMLST_SPECIES = "NA"
    RMLST_SUPPORT = "NA"
    
    rmlst_table = {}
    # Extract the species and support values from the rMLST output
    with open(rmlst_results, "r") as file:
        for line in file:
            line = line.strip()
            if line.startswith("Taxon:"):
                RMLST_SPECIES = line.split(sep=":")[1].strip()
            if line.startswith("Support:"):
                RMLST_SUPPORT = line.split(sep=":")[1].strip()
    
    rmlst_table = {'rMLST species': RMLST_SPECIES, 'rMLST support': RMLST_SUPPORT}
    rmlst_table = pd.DataFrame([rmlst_table])
    return rmlst_table



def get_kleborate_results(kleborate_results):

    # Create empty DataFrame if kleborate is not run
    kleborate_df = pd.DataFrame([{"Kleborate species": "NA",
                                  "Kleborate species match": "NA",
                                  "Kleborate QC": "NA",
                                  "OMP mutations": "NA",
                                  "Col mutations": "NA"}])

    if not os.path.isfile(kleborate_results):
        print(f"Error: Kleborate results file '{kleborate_results}' does not exist.")
        sys.exit(1)

    file_name = os.path.basename(kleborate_results)
    if not file_name.startswith("kleborate_skipped"):
        # Read in Kleborate results
        kleborate_df = pd.read_csv(kleborate_results, sep="\t", header=0)
        kleborate_df = kleborate_df[
            ["enterobacterales__species__species", 
            "enterobacterales__species__species_match", 
            "general__contig_stats__QC_warnings", 
            "klebsiella_pneumo_complex__amr__Omp_mutations",
            "klebsiella_pneumo_complex__amr__Col_mutations"]
            ]
        # Rename columns
        kleborate_df = kleborate_df.rename(columns={
            "enterobacterales__species__species": "Kleborate species",
            "enterobacterales__species__species_match": "Kleborate species match",
            "general__contig_stats__QC_warnings": "Kleborate QC",
            "klebsiella_pneumo_complex__amr__Omp_mutations": "OMP mutations",
            "klebsiella_pneumo_complex__amr__Col_mutations": "Col mutations"})
    return kleborate_df


def get_amrfinder_results(amrfinder_output, amrfinder_classes):
    if not os.path.isfile(amrfinder_output):
        print(f"Error: AMRFinder output file '{amrfinder_output}' does not exist.")
        sys.exit(1)

    # Read in AMRFinder results
    amrfinder_df = pd.read_csv(amrfinder_output, sep="\t", header=0)
    filter_condition = (amrfinder_df["% Coverage of reference"] > 90) & (amrfinder_df["% Identity to reference"] > 90)
    amrfinder_df_filtered = amrfinder_df[filter_condition]
    amrfinder_df_filtered = amrfinder_df_filtered[["Element symbol", "Class", "% Coverage of reference", "% Identity to reference"]]

    class_results = {}
    with open(amrfinder_classes, "r") as file:
        for line in file:
            line = line.strip()
            class_results[line] = "NA"  # Default value for all classes


    # Import classes of interest
    for line in class_results.keys():
        if line in amrfinder_df_filtered["Class"].values:
            class_rows = amrfinder_df_filtered[amrfinder_df_filtered["Class"] == line]
            
            results = []
            for _, row in class_rows.iterrows():
                element = row["Element symbol"]
                coverage = row["% Coverage of reference"]
                identity = row["% Identity to reference"]
                # Append a formatted string with the element symbol, coverage percentage, and identity percentage
                # Format: "Element symbol (Coverage%, Identity%)"
                results.append(f"{element} ({coverage}%, {identity}%)")
            class_results[line] = " | ".join(results)
    column_order = list(class_results.keys())
    results_df = pd.DataFrame([class_results], columns=column_order)
    return results_df


def get_plasmidfinder_results(plasmidfinder_output):
    if not os.path.isfile(plasmidfinder_output):
        print(f"Error: PlasmidFinder output file '{plasmidfinder_output}' does not exist.")
        sys.exit(1)

    # Read in PlasmidFinder results
    plasmidfinder_df = pd.read_csv(plasmidfinder_output, sep="\t", header=0)
    plasmidfinder_df = plasmidfinder_df[
        ["Plasmid", "Identity"]
    ]
    plasmids = []
    for _, row in plasmidfinder_df.iterrows():
        plasmid = row["Plasmid"]
        identity = row["Identity"]
        # Append a formatted string with the plasmid name and identity percentage
        # Format: "Plasmid name (Identity%)"
        plasmids.append(f"{plasmid} ({identity}%)")
    # Join the plasmids into a single string
    plasmids_str = " | ".join(plasmids)
    # Create a DataFrame with the plasmids
    plasmids = pd.DataFrame([{"Plasmids": plasmids_str}])
    return plasmids



if __name__ == "__main__":
    
    mlst_results = sys.argv[1]
    translation_table = sys.argv[2]
    rmlst_results = sys.argv[3]
    kleborate_results = sys.argv[4]
    amrfinder_output = sys.argv[5]
    amrfinder_classes = sys.argv[6]
    plasmidfinder_output = sys.argv[7]
    sample_id = sys.argv[8]
    outfile = sys.argv[9]
    
    # TESTING
    #mlst_results = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/test/illumina_full_test/SHORT_FULL_TEST/xxx/mlst/_mlst.tsv"
    #translation_table = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/assets/mlst_species_translations.tsv"
    #rmlst_results = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/test/illumina_full_test/SHORT_FULL_TEST/xxx/rmlst/_rmlst.txt"
    #kleborate_results = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/test/illumina_full_test/SHORT_FULL_TEST/xxx/kleborate/kleborate_skipped.txt"
    #amrfinder_output = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/test/illumina_full_test/SHORT_FULL_TEST/xxx/amrfinderplus/.tsv"
    #amrfinder_classes = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/assets/amrfinderplus_classes.txt"
    #plasmidfinder_output = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/test/illumina_full_test/SHORT_FULL_TEST/xxx/plasmidfinder/results.tsv"
    #sample_id = "xxx"
    #outfile = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/test/illumina_full_test/SHORT_FULL_TEST/xxx/testout.tsv"



    sample_name = {"Sample": sample_id}
    # Create a DataFrame with the sample name
    sample_df = pd.DataFrame([sample_name])


    mlst = get_mlst_results(mlst_results, translation_table)
    rmlst = get_rmlst_results(rmlst_results)
    kleborate = get_kleborate_results(kleborate_results)
    amrfinder = get_amrfinder_results(amrfinder_output, amrfinder_classes)
    plasmidfinder = get_plasmidfinder_results(plasmidfinder_output)
    resistance_summary = pd.concat([sample_df, mlst, rmlst, kleborate, amrfinder, plasmidfinder], axis=1)

    # Save the final DataFrame to a TSV file
    resistance_summary.to_csv(outfile, sep="\t", index=False)
