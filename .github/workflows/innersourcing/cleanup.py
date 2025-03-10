import requests
import os
import json
from validate_bootstrapper import post
from requests.auth import HTTPBasicAuth

def read_json_file(file_path):
    try:
        with open(file_path, "r", encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error reading JSON file at {file_path}: {e}", flush=True)
        return None

def get(url, username, password, params):
    """Makes a GET API call and returns the response data or prints an error if the response is non-200."""
    try:
        response = requests.get(url, auth=HTTPBasicAuth(username, password), params=params)

        # Check if the response status code is not 200
        if response.status_code != 200:
            print(f"Error: Received status code {response.status_code}.")
            print("Response message:", response.text)  # Print the error message from the response
            return None

        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error during API call: {e}")
        return None

def delete(url, username, password):
    """Makes a DELETE API call and returns the response data or prints an error if the response is non-200."""
    try:
        response = requests.delete(url, auth=HTTPBasicAuth(username, password))

        # Check if the response status code is not 200
        if response.status_code != 200:
            print(f"Error: Received status code {response.status_code}.")
            print("Response message:", response.text)  # Print the error message from the response

    except requests.exceptions.RequestException as e:
        print(f"Error during API call: {e}")

if __name__ == '__main__':
    # Load control planes and secrets
    control_planes = read_json_file('control_planes.json')
    secrets = read_json_file('secrets.json')
    feature_branch_name = os.getenv('GITHUB_REF_NAME')
    print(f'Cleaning Facets preview modules for branch {feature_branch_name}')

    for key, value in control_planes.items():
        cp_url = value.get('URL', "")
        username = value.get('Username', "")
        token = secrets.get(value.get('TokenRef', ""), '')
        # Assuming the first URL is used for API calls
        print(f"Executing bootstrap modules in {key} cp")
        post(cp_url + '/cc-ui/v1/modules/bootstrap', username, token, {})
        modules = get(cp_url + '/cc-ui/v1/modules/all', username, token, {'allowPreviewModules': 'true'})

        for module in modules:
            ref     = module.get('gitRef', '')
            version = module.get('version', '')
            intent = module.get('intent', '')
            flavor = module.get('flavor', '')
            stage = module.get('stage', '')
            if ref == feature_branch_name and stage == "PREVIEW":
                module_id = module.get('id', '')
                delete(cp_url + f'/cc-ui/v1/modules/{module_id}', username, token)
                print(f"Deleted module with ID: {module_id} Intent: {intent} Flavor: {flavor} Version: {version} from control plane {cp_url}")