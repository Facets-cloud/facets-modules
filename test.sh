#!/bin/bash

# Array of directories to check
dirs=("./modules" "./modules/kubernetes_cluster/aws_eks/0.3" "modules/kubernetes_cluster/aws_eks/0.3/aws-terraform-eks")

# Array to store directories containing facets.yaml
facets_dirs=()

for dir in "${dirs[@]}"; do
    current_dir="$dir"
    while [[ "$current_dir" != "/" && "$current_dir" != "." ]]; do
        if [[ -f "$current_dir/facets.yaml" ]] && ls $current_dir/*.tf &> /dev/null; then
            # Check if the directory is already in the facets_dirs array
            if ! [[ " ${facets_dirs[@]} " =~ " ${current_dir} " ]]; then
                # Add the directory to the facets_dirs array
                facets_dirs+=("$current_dir")
            fi
            break
        else
            # Move up to the parent directory
            current_dir=$(dirname "$current_dir")
        fi
    done
    if [[ "$current_dir" == "/" || "$current_dir" == "." ]]; then
        echo "No facets.yaml along with terraform files found in $dir or any of its parent directories"
    fi
done

# Perform the curl command for each directory in facets_dirs
for dir in "${facets_dirs[@]}"; do
    curl -s https://facets-cloud.github.io/facets-schemas/scripts/module_register.sh | bash -s -- -c "$URL" -u "$USERNAME" -t "$TOKEN" -p "$dir" -r "${GITHUB_REF}"
done