import os
import sys
import json
import base64
import traceback

import boto3
from google.cloud import secretmanager, secretmanager_v1
from google.api_core.exceptions import GoogleAPICallError, NotFound

DEPLOYMENT_CONTEXT_PATH = "/sources/deployment_context/deploymentcontext.json"


def get_env_variable(var_name, required=False):
    value = os.environ.get(var_name)
    if required and not value:
        raise ValueError(f"{var_name} environment variable is required but not set.")
    return value


def build_secret_id(cluster_name, account_id, cp_cloud):
    """
    Builds a cloud-compatible secret ID:
    - For AWS: use slash-based structure
    - For GCP: replace slashes with double underscores
    """
    if cp_cloud == "GCP":
        return f"{cluster_name}_backend_accounts_{account_id}"
    return f"{cluster_name}/backend/accounts/{account_id}"


def fetch_secret_from_aws(secret_id, region):
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_id)
    return json.loads(response["SecretString"])

def fetch_secret_from_gcp(gcp_project_id, secret_id, mode, region):
    """
    Fetches the latest ENABLED version of a secret from GCP Secret Manager.
    """
    if mode.upper() == "REGIONAL":
        parent = f"projects/{gcp_project_id}/locations/{region}/secrets/{secret_id}"
        api_endpoint = f"secretmanager.{region}.rep.googleapis.com"
        client = secretmanager_v1.SecretManagerServiceClient(
            client_options={"api_endpoint": api_endpoint}
        )
    else:
        parent = f"projects/{gcp_project_id}/secrets/{secret_id}"
        client = secretmanager.SecretManagerServiceClient()

    response = client.list_secret_versions(request={"parent": parent})
    enabled_versions = [v for v in response.versions if v.state.name == "ENABLED"]
    if not enabled_versions:
        raise RuntimeError(f"No ENABLED versions found for secret: {secret_id}")

    latest_version = enabled_versions[0]
    secret_response = client.access_secret_version(request={"name": latest_version.name})
    return json.loads(secret_response.payload.data.decode("utf-8"))


def build_output_object(secret_data, encoded_key):
    """
    Constructs the output object for both AWS and GCP secrets using decoded serviceAccountKey.
    Ensures 'project_id' and 'region' are present.
    """
    try:
        decoded = base64.b64decode(encoded_key)
        key_data = json.loads(decoded.decode("utf-8"))
        project_id = key_data.get("project_id")

        region = secret_data.get("region") or extract_cluster_region(DEPLOYMENT_CONTEXT_PATH)

        if not project_id:
            raise KeyError("'project_id' not found in service account key.")

        return {
            "project": project_id,
            "region": region,
            "serviceAccountKey": encoded_key
        }
    except Exception as e:
        raise RuntimeError(f"Failed to build output object: {e}")


def extract_cluster_region(deployment_context_path):
    with open(deployment_context_path, "r", encoding="utf-8") as f:
        context = json.load(f)
        return context.get("cluster", {}).get("region")


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: python fetch_cloud_account_secret.py <account_secret_suffix>"}))
        sys.exit(1)

    account_suffix = sys.argv[1]
    cp_cloud = get_env_variable("TF_VAR_CP_CLOUD", required=True).upper()
    cluster_name = get_env_variable("TF_VAR_CP_NAME", required=True)

    try:
        secret_id = build_secret_id(cluster_name, account_suffix, cp_cloud)

        if cp_cloud == "AWS":
            aws_region = get_env_variable("TF_VAR_AWS_DEFAULT_REGION", required=True)
            secret_data = fetch_secret_from_aws(secret_id, aws_region)

        elif cp_cloud == "GCP":
            # Use only env var project ID for fetching, don't overwrite it
            gcp_project_id = get_env_variable("GCP_SECRET_MANAGER_PROJECT_ID", required=True)
            region = get_env_variable("GCP_SECRET_MANAGER_REGION", required=True)
            mode = get_env_variable("GCP_SECRET_MANAGER_MODE", required=True)

            secret_data = fetch_secret_from_gcp(gcp_project_id, secret_id, mode, region)

        else:
            raise ValueError(f"Unsupported cloud provider: {cp_cloud}")

        encoded_key = secret_data.get("serviceAccountKey")
        if not encoded_key:
            raise KeyError("'serviceAccountKey' not found in secret.")

        output = build_output_object(secret_data, encoded_key)
        print(json.dumps(output, indent=2))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

"""
# AWS
export TF_VAR_CP_CLOUD=AWS 
export TF_VAR_CP_NAME=facetsdemo -- needed
export TF_VAR_AWS_DEFAULT_REGION=us-west-2
# GCP 
export TF_VAR_CP_CLOUD=GCP
export TF_VAR_CP_NAME=facetsdemo -- needed
export GCP_SECRET_MANAGER_PROJECT_ID=shared-vpc-host-408507 -- needed
export GCP_SECRET_MANAGER_REGION=us-south1 -- needed
export GCP_SECRET_MANAGER_MODE=REGIONAL -- needed
"""

