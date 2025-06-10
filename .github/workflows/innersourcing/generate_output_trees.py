import os
import json
import yaml
import boto3
import re
from boto3.session import Session
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configuration
s3_bucket_name = os.environ.get('S3_BUCKET_NAME')
dry_run = os.environ.get('DRY_RUN', 'false').lower() == 'true'

# Create a root output trees directory for local generation
output_trees_dir = 'output_trees'
os.makedirs(output_trees_dir, exist_ok=True)

def is_regex_pattern(pattern):
    """Check if a string is a valid regex pattern"""
    try:
        re.compile(pattern)
        return True
    except re.error:
        return False

def extract_properties_from_schema(schema, output_tree):
    """Recursively extract all properties from any schema structure"""
    if not isinstance(schema, dict):
        return
    
    # If we find a "properties" key, extract all property names
    if "properties" in schema:
        for prop_name, prop_value in schema["properties"].items():
            output_tree[prop_name] = {}
            # Always check for nested properties first
            if isinstance(prop_value, dict) and "properties" in prop_value:
                extract_properties_from_schema(prop_value, output_tree[prop_name])
            # If no nested properties but it's a dict with property-like keys (not just schema keywords)
            elif isinstance(prop_value, dict):
                # Check if it looks like a container with property definitions
                non_schema_keys = [k for k in prop_value.keys() if k not in ['type', 'description', 'required', 'enum', 'format', 'pattern', 'minimum', 'maximum', 'secret', 'title', 'additionalProperties', 'items']]
                if non_schema_keys:
                    # This might be a container like interfaces with reader/writer
                    for nested_prop_name in non_schema_keys:
                        nested_prop_value = prop_value[nested_prop_name]
                        output_tree[prop_name][nested_prop_name] = {}
                        # Check if this nested property also has properties to extract
                        if isinstance(nested_prop_value, dict):
                            # If it has schema keywords and properties, still recurse for properties
                            if "properties" in nested_prop_value:
                                extract_properties_from_schema(nested_prop_value, output_tree[prop_name][nested_prop_name])
                            else:
                                # Check if its keys look like property definitions
                                inner_non_schema_keys = [k for k in nested_prop_value.keys() if k not in ['type', 'description', 'required', 'enum', 'format', 'pattern', 'minimum', 'maximum', 'secret', 'title', 'additionalProperties', 'items']]
                                for inner_prop_name in inner_non_schema_keys:
                                    output_tree[prop_name][nested_prop_name][inner_prop_name] = {}
    
    # For any other dictionary values, recursively check them too (but not schema keywords)
    for key, value in schema.items():
        if key not in ["properties", "type", "description", "required", "enum", "format", "pattern", "minimum", "maximum", "title", "secret", "additionalProperties", "items"] and isinstance(value, dict):
            extract_properties_from_schema(value, output_tree)
        elif isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    extract_properties_from_schema(item, output_tree)

def find_and_process_out(schema, output_tree):
    """Find and process out section"""
    for key, value in schema.items():
        if key == "out":
            if isinstance(value, dict):
                output_tree["out"] = {}
                extract_properties_from_schema(value, output_tree["out"])
        elif isinstance(value, dict):
            find_and_process_out(value, output_tree)
        elif isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    find_and_process_out(item, output_tree)

def is_empty_output_tree(output_tree):
    """Check if the output tree is effectively empty"""
    if not isinstance(output_tree, dict):
        return True
    
    # Check if 'out' key exists
    if 'out' not in output_tree:
        return True
    
    out_section = output_tree['out']
    
    # If out is empty dict
    if not out_section:
        return True
    
    # Check if out only contains empty attributes and/or interfaces
    if isinstance(out_section, dict):
        # Check for the specific case of only having empty attributes/interfaces
        keys = set(out_section.keys())
        
        # Case 1: Only attributes and/or interfaces exist
        if keys.issubset({'attributes', 'interfaces'}):
            # Check if both are empty
            attributes_empty = out_section.get('attributes', {}) == {}
            interfaces_empty = out_section.get('interfaces', {}) == {}
            
            # If we only have attributes and/or interfaces, and they're both empty, it's empty
            if attributes_empty and interfaces_empty:
                return True
        
        # Case 2: We have other keys (direct properties) - not empty
        # Even if they're {} (which is expected for leaf properties in our format)
    
    return False

def generate_output_tree(schema_data):
    """Generate output tree from schema data"""
    output_tree = {}
    find_and_process_out(schema_data, output_tree)
    return output_tree

def upload_to_s3(file_path, s3_client, bucket_name, s3_key):
    """Upload file to S3"""
    s3_client.upload_file(file_path, bucket_name, s3_key)

def validate_yaml_file(file_path):
    """Validate YAML file and return parsed data with name"""
    try:
        with open(file_path, 'r') as file:
            data = yaml.safe_load(file)
        
        # Validate required fields
        if not isinstance(data, dict):
            return None, "Invalid YAML structure: not a dictionary"
        
        if 'name' not in data:
            return None, "Missing 'name' key"
        
        if 'out' not in data:
            return None, "Missing 'out' key"
        
        return data, None
    except yaml.YAMLError as e:
        return None, f"YAML parsing error: {e}"
    except Exception as e:
        return None, f"File reading error: {e}"

def find_output_files(base_dir):
    """Find all output.facets.yaml files recursively"""
    output_files = []
    for root, _, files in os.walk(base_dir):
        if 'output.facets.yaml' in files:
            output_files.append(os.path.join(root, 'output.facets.yaml'))
    return output_files

def main():
    """Main function to process output files"""
    print(f"Running in {'DRY RUN' if dry_run else 'UPLOAD'} mode")
    
    # Find all output files
    outputs_dir = './outputs'
    output_files = find_output_files(outputs_dir)
    print(f"Found {len(output_files)} output.facets.yaml files")
    
    # Phase 1: Validate all files and check for duplicate names
    valid_files = []
    output_names = {}
    skipped_files = []
    
    for file_path in output_files:
        data, error = validate_yaml_file(file_path)
        if error:
            skipped_files.append((file_path, error))
            print(f"SKIPPED: {file_path} - {error}")
            continue
        
        output_name = data['name']
        
        # Check for duplicate names
        if output_name in output_names:
            print(f"ERROR: Duplicate output name '{output_name}' found in:")
            print(f"  - {output_names[output_name]}")
            print(f"  - {file_path}")
            print("Failing due to duplicate names")
            exit(1)
        
        output_names[output_name] = file_path
        valid_files.append((file_path, data))
    
    print(f"Valid files: {len(valid_files)}")
    print(f"Skipped files: {len(skipped_files)}")
    
    if not valid_files:
        print("No valid files to process")
        return
    
    # Initialize S3 client if not in dry run mode
    s3_client = None
    if not dry_run:
        session = Session(
            aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY')
        )
        s3_client = session.client('s3')
    
    # Phase 2: Process files and generate/upload output trees
    with ThreadPoolExecutor() as executor:
        upload_futures = []
        processed_count = 0
        skipped_empty_count = 0
        
        for file_path, data in valid_files:
            output_name = data['name']
            print(f"Processing: {output_name}")
            
            # Generate output tree
            try:
                output_tree = generate_output_tree(data)
            except Exception as e:
                print(f"SKIPPED: {output_name} - Error generating tree: {e}")
                skipped_files.append((file_path, f"Error generating tree: {e}"))
                continue
            
            # Check if the output tree is effectively empty
            if is_empty_output_tree(output_tree):
                print(f"SKIPPED: {output_name} - Empty output tree (no meaningful properties)")
                skipped_files.append((file_path, "Empty output tree"))
                skipped_empty_count += 1
                continue
            
            # Create local file
            local_dir = os.path.join(output_trees_dir, output_name)
            os.makedirs(local_dir, exist_ok=True)
            local_file_path = os.path.join(local_dir, 'output-lookup-tree.json')
            
            with open(local_file_path, 'w') as json_file:
                json.dump(output_tree, json_file, indent=4)
            
            print(f"Generated: {local_file_path}")
            processed_count += 1
            
            # Upload to S3 if not in dry run mode
            if not dry_run:
                s3_key = f"{output_name}/output-lookup-tree.json"
                print(f"Uploading: {s3_key}")
                upload_future = executor.submit(upload_to_s3, local_file_path, s3_client, s3_bucket_name, s3_key)
                upload_futures.append(upload_future)
        
        # Wait for all uploads to complete
        if not dry_run and upload_futures:
            for future in as_completed(upload_futures):
                future.result()  # This will raise any exceptions that occurred during upload
    
    print(f"\nSummary:")
    print(f"  Total files found: {len(output_files)}")
    print(f"  Valid files processed: {processed_count}")
    print(f"  Files skipped: {len(skipped_files)}")
    print(f"    - Empty output trees: {skipped_empty_count}")
    print(f"    - Other reasons: {len(skipped_files) - skipped_empty_count}")
    if dry_run:
        print(f"  Mode: DRY RUN (no S3 uploads)")
    else:
        print(f"  S3 uploads completed: {processed_count}")

if __name__ == "__main__":
    main()
