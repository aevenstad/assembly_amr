#!/usr/bin/env python3

import pandas as pd
import os
import sys
import argparse


def merge_tables(assembly_summary, resistance_summary, output_table):
    """
    Merge tab-separated tables from assembly and resistance profiling.
    Usage:
        python merge_tables.py -a <assembly_summary> -r <resistance_summary> -o <output_table>
    """

    # Check if the input files exist
    if not os.path.isfile(assembly_summary):
        print(f"Error: Assembly summary file '{assembly_summary}' does not exist.")
        sys.exit(1)
    if not os.path.isfile(resistance_summary):
        print(f"Error: Resistance summary file '{resistance_summary}' does not exist.")
        sys.exit(1)

    # Read the assembly summary table
    assembly_df = pd.read_csv(assembly_summary, sep="\t", header=0)

    # Read the resistance summary table
    resistance_df = pd.read_csv(resistance_summary, sep="\t", header=0)

    # Merge the two dataframes on the 'assembly_accession' column
    merged_df = pd.merge(assembly_df, resistance_df, on="Sample", how="outer")

    # Write the merged dataframe to a tab-separated file
    merged_df.to_csv(output_table, sep="\t", index=False)

if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Merge assembly and resistance summary tables.")
    parser.add_argument(
        "-a", "--assembly_summary", required=True, help="Path to the assembly summary table."
    )
    parser.add_argument(
        "-r", "--resistance_summary", required=True, help="Path to the resistance summary table."
    )
    parser.add_argument(
        "-o", "--output_table", required=True, help="Path to the output merged table."
    )

    # Parse arguments
    args = parser.parse_args()

    # Call the merge function
    merge_tables(args.assembly_summary, args.resistance_summary, args.output_table)
