import base64
import json
import os
import sys

import boto3

DEPLOYMENT_CONTEXT_PATH = "/sources/deployment_context/deploymentcontext.json"


def get_env_variable(var_name, default=None, required=False):
    value = os.environ.get(var_name, default)
    if required and not value:
        raise ValueError(f"{var_name} environment variable is required but not set.")
    return value


def build_secret_id(cluster_name, account_id):
    return f"{cluster_name}/backend/accounts/{account_id}"


def fetch_secret_from_aws(secret_id, region):
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_id)
    return json.loads(response["SecretString"])


def decode_project_id_from_key(encoded_key):
    decoded = base64.b64decode(encoded_key)
    key_data = json.loads(decoded.decode("utf-8"))
    return key_data.get("project_id")


def extract_cluster_region(deployment_context_path):
    with open(deployment_context_path, "r", encoding="utf-8") as f:
        context = json.load(f)
        return context.get("cluster", {}).get("region")


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: python script.py <account_secret_suffix>"}))
        sys.exit(1)

    secret_id_suffix = sys.argv[1]
    cp_cloud = get_env_variable("TF_VAR_CP_CLOUD", required=True).upper()
    aws_region = get_env_variable("TF_VAR_AWS_DEFAULT_REGION", required=True)
    cluster_name = get_env_variable("TF_VAR_CP_NAME", default="facetsdemo")

    if cp_cloud != "AWS":
        print(json.dumps({"error": "Only 'AWS' is supported for TF_VAR_CP_CLOUD"}))
        sys.exit(1)

    try:
        secret_id = build_secret_id(cluster_name, secret_id_suffix)
        secret_data = fetch_secret_from_aws(secret_id, aws_region)

        encoded_key = secret_data.get("serviceAccountKey")
        if not encoded_key:
            raise KeyError("'serviceAccountKey' not found in AWS secret.")

        project_id = decode_project_id_from_key(encoded_key)
        if not project_id:
            raise KeyError("'project_id' not found in decoded service account key.")

        region_value = secret_data.get("region") or extract_cluster_region(DEPLOYMENT_CONTEXT_PATH)

        output = {
            "project": project_id,
            "region": region_value,
            "serviceAccountKey": encoded_key
        }

        print(json.dumps(output, indent=2))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
