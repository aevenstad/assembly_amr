#!/bin/bash
mlst_out=$1

# mlst species scheme map
mlst_species_map="/usr/local/db/scheme_species_map.tab"
if [ -f $mlst_species_map ]; then
    echo "MLST species map file: $mlst_species_map"
else
    echo "MLST species map not found!"
    exit 1
fi

# Get species name from mlst
mlst_species=$(awk '{print $2}' ${mlst_out})

# Set new names based on the mlst species map
# For E.coli and certain Klebsiella species, set specific names to be used for the amrfinder --organism option

# Escherichia coli
if [[ $mlst_species == "escherichia" ]]; then
    new_name="Escherichia coli"
    sed "s/$mlst_species/$new_name/g" $mlst_out >${mlst_out%.tsv}_renamed.tsv

# Klebsiella pneumoniae
elif [[ $mlst_species == "klebsiella" ]]; then
    new_name="Klebsiella pneumoniae"
    sed "s/$mlst_species/$new_name/g" $mlst_out >${mlst_out%.tsv}_renamed.tsv

# Klebsiella aerogenes is missing from the mlst species list, added manually
elif [[ $mlst_species == "kaerogenes" ]]; then
    new_name="Klebsiella aerogenes"
    sed "s/$mlst_species/$new_name/g" $mlst_out >${mlst_out%.tsv}_renamed.tsv

# Rename if name present in scheme
elif grep -q "$mlst_species" "$mlst_species_map"; then
    new_name=$(grep "$mlst_species" "$mlst_species_map" |
        cut -f2,3 |
        sed 's/\t/ /g' |
        # Some names have a trailing space in mlst species list
        sed 's/  / /g')
    sed "s/$mlst_species/$new_name/g" "$mlst_out" >"${mlst_out%.tsv}_renamed.tsv"

# Handle unknown species
elif [[ $mlst_species == "-" ]]; then
    echo -e "\t - Unknown MLST scheme - could not identify species"
    sed "s/-/Unknown/" $mlst_out >${mlst_out%.tsv}_renamed.tsv

# Keep original name if not found in species map
else
    cat "$mlst_out" >"${mlst_out%.tsv}_renamed.tsv"
fi
