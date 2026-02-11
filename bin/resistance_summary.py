#!/usr/bin/env python3

import pandas   as pd
import os
import sys


def get_mlst_results(mlst_results):
    if not os.path.isfile(mlst_results):
        print(f"Error: MLST results file '{mlst_results}' does not exist.")
        sys.exit(1)
    # Check if the MLST results file is empty
    if os.path.getsize(mlst_results) == 0:
        print(f"Error: MLST results file '{mlst_results}' is empty.")
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
    mlst_table = mlst_df[["Species", "ST"]]
    mlst_table = mlst_table.rename(columns={"Species": "MLST species"})
    mlst_table["MLST species"] = mlst_table["MLST species"].fillna("Unknown").astype(str).replace("-", "Unknown")
    mlst_table["ST"] = mlst_table["ST"].fillna("Unknown").astype(str).replace("-", "Unknown")
    mlst_table["MLST"] = mlst_table["ST"].apply(lambda x: "Unknown" if x == "ST-Unknown" else f"ST-{x}")
    mlst_table.drop(columns=["ST"], inplace=True)

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
    matches = []
    current_taxon = None
    current_support = None

    rmlst_table = {}
    # Extract the species and support values from the rMLST output
    with open(rmlst_results, "r") as file:
        for line in file:
            line = line.strip()
            if line.startswith("Taxon:"):
                current_taxon = line.split(sep=":")[1].strip()
            if line.startswith("Support:"):
                current_support = line.split(sep=":")[1].strip()
                if current_taxon is not None and current_support is not None:
                    try:
                        support_val = float(current_support.replace('%', '').strip())
                    except ValueError:
                        support_val = -1
                    matches.append((current_taxon, support_val))
                    current_taxon = None
                    current_support = None
    if matches:
        best_match = max(matches, key=lambda x: x[1])
        RMLST_SPECIES, RMLST_SUPPORT = best_match[0], str(best_match[1])
    else:
        RMLST_SPECIES, RMLST_SUPPORT = "NA", "NA"

    rmlst_table = {'rMLST species': RMLST_SPECIES, 'rMLST support': RMLST_SUPPORT}
    rmlst_table = pd.DataFrame([rmlst_table])
    return rmlst_table



def get_kleborate_results(kleborate_results):

    # Create empty DataFrame if kleborate is not run
    kleborate_df = pd.DataFrame([{"Kleborate species": "NA",
                                  "Kleborate species match": "NA",
                                  "OMP mutations": "NA",
                                  "Col mutations": "NA"}])

    file_name = os.path.basename(kleborate_results)
    if os.path.getsize(file_name) > 0:
        # Read in Kleborate results
        kleborate_df = pd.read_csv(kleborate_results, sep="\t", header=0)
        kleborate_df = kleborate_df[
            ["enterobacterales__species__species",
            "enterobacterales__species__species_match",
            "klebsiella_pneumo_complex__amr__Omp_mutations",
            "klebsiella_pneumo_complex__amr__Col_mutations"]
            ]
        # Rename columns
        kleborate_df = kleborate_df.rename(columns={
            "enterobacterales__species__species": "Kleborate species",
            "enterobacterales__species__species_match": "Kleborate species match",
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


def get_virulencefinder_results(virulencefinder_output):
    if virulencefinder_output == "virulencefinder_placeholder.tsv":
        virulencefinder_df = pd.DataFrame([{"VirulenceFinder" : "-"}])
        return virulencefinder_df

    virulencefinder_df = pd.read_csv(virulencefinder_output, sep = "\t", header = 0)
    virulencefinder_df = virulencefinder_df[
        ["virulence_gene", "identity", "coverage"]
    ]
    virulence_genes = []
    for _, row in virulencefinder_df.iterrows():
        virulence_gene = row["virulence_gene"]
        identity = row["identity"]
        coverage = row["coverage"]
        virulence_genes.append(f"{virulence_gene} ({identity}%, {coverage}%)")
    virulence_genes_str = " | ".join(virulence_genes)
    virulence_genes = pd.DataFrame([{" VirulenceFinder" : virulence_genes_str}])
    return virulence_genes


def get_lrefinder_results(lrefinder_output):
    if lrefinder_output == "lre-finder_placeholder.tsv":
        lrefinder_df = pd.DataFrame([{"LRE Genes": "-",
                                      "LRE Mutations" : "-"}])
        lrefinder_genes = lrefinder_df[["LRE Genes"]]
        lrefinder_mutations = lrefinder_df[["LRE Mutations"]]
        return(lrefinder_genes, lrefinder_mutations)


    with open(lrefinder_output) as f:
        lines = [line.strip() for line in f if line.strip()]

    # Add LRE-Finder genes to single row
    genes_header = next(i for i, l in enumerate(lines) if l.startswith("Genes Identified:")) + 1
    genes_data = []
    i = genes_header + 1
    while i < len(lines) and not lines[i].startswith("Identified mutations"):
        genes_data.append(lines[i].split())
        i += 1

    genes_df = pd.DataFrame(genes_data, columns=["Gene", "Template_identity", "Depth"])
    gene_lines = []
    for _, row in genes_df.iterrows():
        gene = row["Gene"]
        ident = row["Template_identity"]
        depth = row["Depth"]
        gene_lines.append(f"{gene} (ID: {ident}%, Depth: {depth})")
    gene_results = " | ".join(gene_lines)
    lrefinder_genes = pd.DataFrame([{"LRE Genes" : gene_results}])

    # Add LRE-Finder mutations to single row
    mutations_header = i + 1
    mutation_data = []
    i = mutations_header + 1
    while i < len(lines):
        mutation_data.append(lines[i].split())
        i += 1

    mutation_df = pd.DataFrame(mutation_data, columns=[
    "Position", "Wild_type_ratio", "Mutant_type_ratio", "Predicted_phenotype"
    ])
    mutation_df = mutation_df.drop([0])

    mutation_lines = []
    for _, row in mutation_df.iterrows():
        pos = row["Position"]
        wt = row["Wild_type_ratio"]
        mt = row["Mutant_type_ratio"]
        pheno = row["Predicted_phenotype"]
        mutation_lines.append(f"{pos} (WT: {wt}%, MT: {mt}%, Phenotype: {pheno})")
    mutations_results = " | ".join(mutation_lines)
    lrefinder_mutations = pd.DataFrame([{"LRE Mutations" : mutations_results}])


    return(lrefinder_genes, lrefinder_mutations)


if __name__ == "__main__":

    mlst_results = sys.argv[1]
    rmlst_results = sys.argv[2]
    kleborate_results = sys.argv[3]
    amrfinder_output = sys.argv[4]
    amrfinder_classes = sys.argv[5]
    plasmidfinder_output = sys.argv[6]
    lrefinder_output = sys.argv[7]
    virulencefinder_output = sys.argv[8]
    sample_id = sys.argv[9]
    outfile = sys.argv[10]



    sample_name = {"Sample" : sample_id}
    # Create a DataFrame with the sample name
    sample_df = pd.DataFrame([sample_name])


    mlst = get_mlst_results(mlst_results)
    rmlst = get_rmlst_results(rmlst_results)
    kleborate = get_kleborate_results(kleborate_results)
    amrfinder = get_amrfinder_results(amrfinder_output, amrfinder_classes)
    plasmidfinder = get_plasmidfinder_results(plasmidfinder_output)
    lrefinder_genes, lrefinder_mutations = get_lrefinder_results(lrefinder_output)
    virulencefinder = get_virulencefinder_results(virulencefinder_output)
    resistance_summary = pd.concat([sample_df, mlst, rmlst, kleborate, lrefinder_genes, lrefinder_mutations, virulencefinder, amrfinder, plasmidfinder], axis=1)

    # Save the final DataFrame to a TSV file
    resistance_summary.to_csv(outfile, sep="\t", index=False)
