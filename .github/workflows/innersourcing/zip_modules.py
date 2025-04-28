import os
import zipfile
import yaml
import boto3
from boto3.session import Session
from concurrent.futures import ThreadPoolExecutor, as_completed

# Specify your AWS S3 bucket from environment variable
s3_bucket_name = os.environ.get('S3_BUCKET_NAME')  # Bucket name sourced from environment variables

# Create a root zips directory
zip_root_dir = 'zips'
os.makedirs(zip_root_dir, exist_ok=True)

def upload_to_s3(file_path, s3_client, bucket_name, s3_key):
    s3_client.upload_file(file_path, bucket_name, s3_key)

# Create a boto3 S3 client using environment variables for credentials
session = Session(
    aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY')
)
s3_client = session.client('s3')

# Function to find all facets.yaml files recursively
def find_facets_yaml_files(base_dir):
    facets_paths = []
    for root, _, files in os.walk(base_dir):
        if 'facets.yaml' in files:
            # Check if there are any .tf or .tf.json files in the directory
            terraform_files = [file for file in files if file.endswith('.tf') or file.endswith('.tf.json')]
            if terraform_files:
                facets_paths.append(root)
    return facets_paths

# Find all facets.yaml files in the modules directory
modules_dir = './modules'
facets_paths = find_facets_yaml_files(modules_dir)

# Initialize a ThreadPoolExecutor for concurrent uploads
with ThreadPoolExecutor() as executor:
    # This will hold all future upload tasks
    upload_futures = []
    
    # Process each directory containing facets.yaml
    for relative_path in facets_paths:
        # Construct the path to facets.yaml
        facets_yaml_path = os.path.join(relative_path, 'facets.yaml')
        
        # Load facets.yaml file
        with open(facets_yaml_path) as yaml_file:
            facets_data = yaml.safe_load(yaml_file)
        
        # Extract intent, flavor, and version
        intent = facets_data.get('intent')
        flavor = facets_data.get('flavor')
        version = facets_data.get('version')
        
        # Check if all required fields are present
        if intent and flavor and version:
            print(f"Zipping intent {intent} flavor {flavor} version {version}")
            
            # Create the target zip file path
            zip_dir_path = os.path.join(str(zip_root_dir), str(intent), str(flavor), str(version))
            os.makedirs(zip_dir_path, exist_ok=True)
            
            # Create zip file name
            zip_file_name = os.path.join(zip_dir_path, 'module.zip')
            
            # Create the zip file
            with zipfile.ZipFile(zip_file_name, 'w') as zipf:
                # Walk through the directory and add files
                for root, _, files in os.walk(relative_path):
                    for file in files:
                        file_path = os.path.join(root, file)
                        # Write the file into the zip, preserving the original structure
                        zipf.write(file_path, os.path.relpath(file_path, os.path.dirname(relative_path)))
            
            # Prepare to upload the zip file to S3
            s3_key = os.path.relpath(zip_file_name, zip_root_dir)  # Path within the S3 bucket
            print(f"Uploading {s3_key}")
            
            # Fire a thread to upload the zip file to S3
            upload_future = executor.submit(upload_to_s3, zip_file_name, s3_client, s3_bucket_name, s3_key)
            upload_futures.append(upload_future)
    
    # Wait for all upload tasks to complete
    for future in as_completed(upload_futures):
        future.result()  # This will raise any exceptions that occurred during the upload
