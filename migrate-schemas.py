import requests
import yaml
import os
import json
import glob
from pprint import pprint

class SchemaMigrator:
    def __init__(self, schema_metadata_url, local_filename, index_filename, intents_index_filename):
        self.schema_metadata_url = schema_metadata_url
        self.local_filename = local_filename
        self.index_filename = index_filename
        self.intents_index_filename = intents_index_filename

    def download_schema_metadata(self):
        try:
            response = requests.get(self.schema_metadata_url)
            response.raise_for_status()  # Check if the request was successful
            with open(self.local_filename, "wb") as file:
                file.write(response.content)
            print(f"File downloaded successfully and saved as {self.local_filename}")
        except requests.exceptions.RequestException as e:
            print(f"An error occurred: {e}")

    def read_intent_and_flavors(self):
        subdirectories = []
        directories = glob.glob("modules/**", recursive=True)
        for directory in directories:
            if os.path.isdir(directory):
                subdirs = [
                    d
                    for d in os.listdir(directory)
                    if os.path.isdir(os.path.join(directory, d))
                ]
                if not subdirs and "monitoring" not in directory:
                    schema = directory.split("/")
                    subdirectories.append({
                                    "intent": schema[1],
                                    "flavor_name": schema[2],
                                    "version": schema[3],
                                })
        return subdirectories

    def load_schema_metadata(self):
        with open(self.local_filename, "r") as file:
            data = json.load(file)
        return data

    def extract_schema_intents(self, schema_metadata):
        schema_intents = []
        for item in schema_metadata:
            intent = item["displayName"].lower()
            for flavor in item.get("flavors", []):
                clouds = flavor.get("clouds", [])
                for name in flavor.get("name", []):
                    if "versions" in flavor:
                        for version in flavor["versions"]:
                            schema_intents.append(
                                {
                                    "intent": intent,
                                    "flavor_name": name,
                                    "version": version.get("number"),
                                    "cloud": clouds,
                                    "sample": flavor.get("flavorSampleUrl", "")
                                }
                            )
                    else:
                        schema_intents.append(
                            {
                                "intent": intent,
                                "flavor_name": name,
                                "version": None,
                                "cloud": clouds,
                                "sample": flavor.get("flavorSampleUrl", "")
                            }
                        )
        return schema_intents

    def compare_and_filter_lists(self, list_with_clouds, list_without_clouds):
        filtered_list = []
        set_without_clouds = {json.dumps({k: v for k, v in item.items() if k not in ["cloud", "sample"]}) for item in list_without_clouds}
        
        for item in list_with_clouds:
            item_without_cloud_and_sample = {k: v for k, v in item.items() if k not in ["cloud", "sample"]}
            if json.dumps(item_without_cloud_and_sample) not in set_without_clouds:
                filtered_list.append(item)
        
        return filtered_list

    def update_index_file(self, unique_schema_intents):
        try:
            with open(self.index_filename, "r") as file:
                index_data = json.load(file)
        except FileNotFoundError:
            index_data = []

        for value in unique_schema_intents:
            intent = value.get('intent')
            flavor = value.get('flavor_name')
            version = value.get('version')
            clouds = value.get('cloud')
            git_url = "https://github.com/Facets-cloud/facets-modules"
            relative_path = f"./modules/{intent}/{flavor}/{version}/"

            new_entry = {
                "intent": intent,
                "flavor": flavor,
                "version": version,
                "gitUrl": git_url,
                "relativePath": relative_path,
                "clouds": clouds
            }

            index_data.append(new_entry)

        with open(self.index_filename, "w") as file:
            json.dump(index_data, file, indent=2)
        print(f"Index file {self.index_filename} updated successfully.")

    def update_intents_index_file(self, unique_schema_intents):
        try:
            with open(self.intents_index_filename, "r") as file:
                intents_index_data = json.load(file)
        except FileNotFoundError:
            intents_index_data = []

        for value in unique_schema_intents:
            intent = value.get('intent')
            git_url = "https://github.com/Facets-cloud/facets-modules"
            relative_path = f"./intents/{intent}/"

            new_entry = {
                "gitUrl": git_url,
                "relativePath": relative_path
            }

            if new_entry not in intents_index_data:
                intents_index_data.append(new_entry)

        with open(self.intents_index_filename, "w") as file:
            json.dump(intents_index_data, file, indent=2)
        print(f"Intents index file {self.intents_index_filename} updated successfully.")

    def create_yaml_files(self, unique_schema_intents):
        for value in unique_schema_intents:
            intent = value.get('intent')
            flavor = value.get('flavor_name')
            version = value.get('version') 
            clouds = value.get('cloud')
            sample_url = value.get('sample')

            # Download the JSON content from the sample URL
            try:
                print(f"Downloading sample: {sample_url}")
                response = requests.get(sample_url)
                response.raise_for_status()
                sample_json = response.json()
            except requests.exceptions.RequestException as e:
                print(f"An error occurred while downloading the sample JSON: {e}")

            modules_template_yaml = {
                'intent': intent,
                'flavor': flavor,
                'version': version,
                'description': f'Adds {intent} - {flavor} flavor',
                'clouds': clouds,
                'sample': sample_json,
            }

            modules_directory = f'modules/{intent}/{flavor}/{version}'
            modules_filename = f'modules/{intent}/{flavor}/{version}/facets.yaml'
            os.makedirs(modules_directory, exist_ok=True)
            print(f"Migrated filename {modules_filename} to facets modules")
            with open(modules_filename, 'w') as yaml_file:
                yaml.dump(modules_template_yaml, yaml_file, default_flow_style=False, sort_keys=False)

            intent_template_yaml = {
                'name': intent,
                'type': flavor,
                'displayName': ' '.join(intent.split('_')) 
            }   

            intent_directory = f'intents/{intent}/'
            intent_filename = f'intents/{intent}/facets.yaml'
            if not os.path.exists(intent_directory):
                os.makedirs(intent_directory)
                print(f"Migrated filename {intent_filename} to facets modules")
                with open(intent_filename, 'w') as yaml_file:
                    yaml.dump(intent_template_yaml, yaml_file, default_flow_style=False, sort_keys=False)
            else:
                print(f"Directory {intent_directory} already exists. Skipping creation of YAML.")

    def migrate_schemas(self):
        # Download and save the schema metadata
        self.download_schema_metadata()

        # Read through all the directories inside modules
        intent_and_flavors = self.read_intent_and_flavors()
        # pprint(intent_and_flavors)

        # Load the downloaded file into memory and read the data inside it
        schema_metadata = self.load_schema_metadata()

        # Extract intent and flavor names from the schema metadata
        schema_intents = self.extract_schema_intents(schema_metadata)

        # Compare and filter lists
        unique_schema_intents = self.compare_and_filter_lists(schema_intents, intent_and_flavors)

        # Create YAML files for the unique schema intents
        self.create_yaml_files(unique_schema_intents)

        # Update the index file with new modules
        self.update_index_file(unique_schema_intents)

        # Update the intents index file with new intents
        self.update_intents_index_file(unique_schema_intents)

if __name__ == "__main__":
    # URL of the schema metadata
    schema_metadata_url = (
        "https://facets-cloud.github.io/facets-schemas/schema-metadata.json"
    )
    # Local filename to save the downloaded file
    local_filename = "schema-metadata.json"
    # Index filename to update
    index_filename = "index.json"
    # Intents index filename to update
    intents_index_filename = "intents.index.json"

    migrator = SchemaMigrator(schema_metadata_url, local_filename, index_filename, intents_index_filename)
    migrator.migrate_schemas()
    os.remove(local_filename)