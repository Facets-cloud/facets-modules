import os
import sys
import json
import base64
import boto3
import requests
import traceback
from google.cloud import secretmanager, secretmanager_v1
from requests.auth import HTTPBasicAuth
from google.api_core.exceptions import GoogleAPICallError, NotFound

def get_env(var, default=None, required=False):
    value = os.getenv(var, default)
    if required and not value:
        raise ValueError(f"Environment variable {var} is required but not set.")
    return value

def get_cp_cloud():
    return get_env("TF_VAR_CP_CLOUD", required=True).lower()

def get_target_cloud():
    return get_env("CLOUD", required=True).upper()

def build_secret_id(cluster_name, account_id, cp_cloud):
    return (
        f"{cluster_name}_backend_accounts_{account_id}" if cp_cloud == "gcp"
        else f"{cluster_name}/backend/accounts/{account_id}"
    )

def fetch_secret_from_aws(secret_id):
    region = get_env("TF_VAR_AWS_DEFAULT_REGION", "us-east-1")
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_id)
    return json.loads(response["SecretString"])

def fetch_secret_from_gcp(project_id, secret_id, mode, region):
    if mode.upper() == "REGIONAL":
        parent = f"projects/{project_id}/locations/{region}/secrets/{secret_id}"
        api_endpoint = f"secretmanager.{region}.rep.googleapis.com"
        client = secretmanager_v1.SecretManagerServiceClient(
            client_options={"api_endpoint": api_endpoint}
        )
    else:
        parent = f"projects/{project_id}/secrets/{secret_id}"
        client = secretmanager.SecretManagerServiceClient()

    response = client.list_secret_versions(request={"parent": parent})
    enabled_versions = [v for v in response.versions if v.state.name == "ENABLED"]
    if not enabled_versions:
        raise RuntimeError(f"No ENABLED versions found for secret: {secret_id}")

    latest_version = enabled_versions[0]
    secret_response = client.access_secret_version(request={"name": latest_version.name})
    return json.loads(secret_response.payload.data.decode("utf-8"))

def fetch_secret(secret_id, cp_cloud):
    if cp_cloud == "aws":
        return fetch_secret_from_aws(secret_id)
    elif cp_cloud == "gcp":
        project = get_env("GCP_SECRET_MANAGER_PROJECT_ID", required=True)
        region = get_env("GCP_SECRET_MANAGER_REGION", required=True)  # null output
        mode = get_env("GCP_SECRET_MANAGER_MODE", required=True)
        return fetch_secret_from_gcp(project, secret_id, mode, region)
    else:
        raise ValueError(f"Unsupported CP cloud: {cp_cloud}")

def normalize_output(secret, target_cloud):
    if target_cloud == "AWS":
        return {
            "aws_iam_role": secret.get("iamRole"),
            "external_id": secret.get("externalId")
        }
    elif target_cloud == "GCP":
        try:
            encoded_key = secret["serviceAccountKey"]
            try:
                decoded = base64.b64decode(encoded_key)
                key_data = json.loads(decoded.decode("utf-8"))
            except (ValueError, json.JSONDecodeError):
                key_data = json.loads(encoded_key)

            return {
                "project": key_data["project_id"],
                "region": secret.get("region"),
                "credentials": encoded_key
            }
        except Exception as e:
            raise RuntimeError(f"Failed to parse GCP serviceAccountKey: {e}")
        except Exception as e:
            raise RuntimeError(f"Failed to parse GCP serviceAccountKey: {e}")
    elif target_cloud == "AZURE":
        cc_host = get_env("TF_VAR_cc_host", required=True)
        email = "aditya.prajapati@facets.cloud"
        token = "cbeaf0d6-8ea8-40d8-8841-0ad628bb7f26"

        url = f"https://{cc_host}/cc-ui/v1/accounts/{secret['accountId']}"
        headers = {"accept": "application/json"}
        auth = HTTPBasicAuth(email, token)

        response = requests.get(url, headers=headers, auth=auth)
        if response.status_code != 200:
            raise Exception(f"API call failed: {response.status_code} {response.text}")
        api_data = response.json()

        return {
            "subscription_id": api_data["subscriptionId"],
            "client_id": api_data["clientId"],
            "tenant_id": api_data["tenantId"],
            "client_secret": secret.get("clientSecret")
        }
    else:
        raise ValueError(f"Unsupported CLOUD type: {target_cloud}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python fetch_credentials.py <account_secret_suffix>")
        sys.exit(1)

    suffix = sys.argv[1]
    cp_cloud = get_cp_cloud()
    target_cloud = get_target_cloud()
    cluster_name = get_env("TF_VAR_CP_NAME", required=True)

    try:
        secret_id = build_secret_id(cluster_name, suffix, cp_cloud)
        secret_data = fetch_secret(secret_id, cp_cloud)
        secret_data["accountId"] = suffix  # for azure api call
        output = normalize_output(secret_data, target_cloud)
        print(json.dumps(output, indent=2))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()


# gcp #acetsdemo/backend/accounts/668d34ca533be600081289ab
# aws "cloudAccountSecretsId": "facetsdemo/backend/accounts/64996c6d7010740007bfe9ee"