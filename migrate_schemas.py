import requests
import yaml
import os
import json
import glob
from pprint import pprint

class SchemaMigrator:
    def __init__(self, schema_metadata_url, local_filename):
        self.schema_metadata_url = schema_metadata_url
        self.local_filename = local_filename

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
                                }
                            )
                    else:
                        schema_intents.append(
                            {
                                "intent": intent,
                                "flavor_name": name,
                                "version": None,
                                "cloud": clouds,
                            }
                        )
        return schema_intents

    def compare_and_filter_lists(self, list_with_clouds, list_without_clouds):
        filtered_list = []
        set_without_clouds = {json.dumps({k: v for k, v in item.items() if k != "cloud"}) for item in list_without_clouds}
        
        for item in list_with_clouds:
            item_without_cloud = {k: v for k, v in item.items() if k != "cloud"}
            if json.dumps(item_without_cloud) not in set_without_clouds:
                filtered_list.append(item)
        
        return filtered_list

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
        # pprint(schema_intents)

        # Compare and filter lists
        unique_schema_intents = self.compare_and_filter_lists(schema_intents, intent_and_flavors)
        # pprint(unique_schema_intents)

        for value in unique_schema_intents:
            intent = value.get('intent')
            flavor = value.get('flavor_name')
            version = value.get('version') 
            clouds = value.get('cloud')

            template_yaml = {
                'intent': intent,
                'flavor': flavor,
                'version': version,
                'description': f'Adds {intent} {flavor}',
                'clouds': clouds,
                'spec': {}
            }

            directory = f'modules/{intent}/{flavor}/{version}'
            filename = f'modules/{intent}/{flavor}/{version}/facets.yaml'
            os.makedirs(directory, exist_ok=True)
            print(f"Migrated filename {filename} to facets modules")
            with open(filename, 'w') as yaml_file:
                yaml.dump(template_yaml, yaml_file, default_flow_style=False)

if __name__ == "__main__":
    # URL of the schema metadata
    schema_metadata_url = (
        "https://facets-cloud.github.io/facets-schemas/schema-metadata.json"
    )
    # Local filename to save the downloaded file
    local_filename = "schema-metadata.json"

    migrator = SchemaMigrator(schema_metadata_url, local_filename)
    migrator.migrate_schemas()
    os.remove(local_filename)