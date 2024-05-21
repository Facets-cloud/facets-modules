# validate_yamls.py

import os
import yaml

def validate_yaml(file_path):
    try:
        with open(file_path, 'r') as file:
            yaml.safe_load(file)
        print(f"Valid YAML file: {file_path}")
    except yaml.YAMLError as exc:
        print(f"Error in YAML file: {file_path}")
        print(exc)
        return False
    return True

def validate_all_yamls(directory):
    all_valid = True
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".yaml") or file.endswith(".yml"):
                file_path = os.path.join(root, file)
                if not validate_yaml(file_path):
                    all_valid = False
    return all_valid

if __name__ == "__main__":
    import sys
    directory = sys.argv[1] if len(sys.argv) > 1 else "."
    if not validate_all_yamls(directory):
        sys.exit(1)
    sys.exit(0)

