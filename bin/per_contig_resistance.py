#!/usr/bin/env python3

import pandas as pd
import os
import sys


def get_plasmidfinder_results(plasmidfinder_output):
    if not os.path.isfile(plasmidfinder_output):
        print(f"Error: PlasmidFinder output file '{plasmidfinder_output}' does not exist.")
        sys.exit(1)

    # Read in PlasmidFinder results
    plasmidfinder_df = pd.read_csv(plasmidfinder_output, sep="\t", header=0)
    #plasmidfinder_df = plasmidfinder_df[["Plasmid", "Identity", "Contig", "Position in contig"]]

    # Subset Contig string to only before first space
    plasmidfinder_df["Contig"] = plasmidfinder_df["Contig"].str.split(" ", n=1).str[0]
    plasmidfinder_df["Plasmid_test"] = plasmidfinder_df["Plasmid"] + " (" + plasmidfinder_df["Identity"].astype(str) + "%)"
    plasmidfinder_df_subset = plasmidfinder_df[["Contig", "Plasmid_test", "Position in contig"]]
    plasmidfinder_df_subset = plasmidfinder_df_subset.rename(columns={"Plasmid_test": "Plasmids"})

    # Set value for empty cells
    plasmidfinder_df_subset["Plasmid_test"] = plasmidfinder_df_subset["Plasmids"].replace("", "-")

    # Group by Contig and join the Plasmid_test values
    plasmidfinder_df_grouped = plasmidfinder_df_subset.groupby("Contig")["Plasmids"].apply(lambda x: " | ".join(x)).reset_index()
    return plasmidfinder_df_grouped
    
    

def get_amrfinder_results(amrfinder_output, amrfinder_classes):
    if not os.path.isfile(amrfinder_output):
        print(f"Error: AMRFinder output file '{amrfinder_output}' does not exist.")
        sys.exit(1)

    # Read in AMRFinder results
    amrfinder_df = pd.read_csv(amrfinder_output, sep="\t", header=0)
    filter_condition = (amrfinder_df["% Coverage of reference"] > 90) & (amrfinder_df["% Identity to reference"] > 90)
    amrfinder_df_filtered = amrfinder_df[filter_condition]
    amrfinder_df_filtered = amrfinder_df_filtered[["Contig id", "Element symbol", "Class", "% Coverage of reference", "% Identity to reference"]]
    amrfinder_df_filtered = amrfinder_df_filtered.rename(columns={"Contig id": "Contig"})

    class_results = {}
    with open(amrfinder_classes, "r") as file:
        for line in file:
            line = line.strip()
            class_results[line] = "-"  # Default value for all classes


    # Import classes of interest
    grouped_by_contig = []
    for contig_id, group in amrfinder_df_filtered.groupby("Contig"):
        contig_results = {"Contig": contig_id}
        for line in class_results.keys():
            if line in group["Class"].values:
                class_rows = group[group["Class"] == line]
                results = []
                for _, row in class_rows.iterrows():
                    element = row["Element symbol"]
                    coverage = row["% Coverage of reference"]
                    identity = row["% Identity to reference"]
                    # Append a formatted string with the element symbol, coverage percentage, and identity percentage
                    # Format: "Element symbol (Coverage%, Identity%)"
                    results.append(f"{element} ({coverage}%, {identity}%)")
                contig_results[line] = " | ".join(results)
            else:
                contig_results[line] = "-"  # Default value if no results found
        grouped_by_contig.append(contig_results)
    
    amrfinder_grouped_df = pd.DataFrame(grouped_by_contig)
    return amrfinder_grouped_df
    


if __name__ == "__main__":
    # Set input arguments
    plasmidfinder_output = sys.argv[1]
    amrfinder_output = sys.argv[2]
    amrfinder_classes = sys.argv[3]
    output_table = sys.argv[4]

    # TESTING
    #plasmidfinder_output = "/bigdata/Jessin/Sequencing_projects/andreas/torunn/toalettstudie/resultater/2025_run3_assembly_amr_out/51575456/plasmidfinder/51575456.tsv"
    #plasmidfinder_df = get_plasmidfinder_results(plasmidfinder_output)
    #amrfinder_output = "/bigdata/Jessin/Sequencing_projects/andreas/torunn/toalettstudie/resultater/2025_run3_assembly_amr_out/51575456/amrfinderplus/51575456.tsv"
    #amrfinder_classes = "/bigdata/Jessin/Softwares/nextflow_pipeline/assembly_amr/assets/amrfinderplus_classes.txt"
    #amrfinder_df = get_amrfinder_results(amrfinder_output, amrfinder_classes)

    # Get PlasmidFinder results
    plasmidfinder_df = get_plasmidfinder_results(plasmidfinder_output)
    # Get AMRFinder results
    amrfinder_df = get_amrfinder_results(amrfinder_output, amrfinder_classes)

    # Merge the two dataframes on the 'Contig' column
    merged_df = pd.merge(plasmidfinder_df, amrfinder_df, on="Contig", how="outer")

    # Set value for empty cells
    merged_df = merged_df.fillna("-")
    # Write to file
    merged_df.to_csv(output_table, sep="\t", index=False)