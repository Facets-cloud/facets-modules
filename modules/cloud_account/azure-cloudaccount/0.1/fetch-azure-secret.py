import json
import sys
import os
import boto3
import requests
from requests.auth import HTTPBasicAuth


def build_secret_path(secret_id: str) -> str:
    prefix = os.getenv('TF_VAR_CP_NAME', 'facetsdemo')
    return f"{prefix}/backend/accounts/{secret_id}"


def construct_secret_path(secret_id: str) -> str:
    return build_secret_path(secret_id)


def get_region() -> str:
    return os.getenv('TF_VAR_cc_region', 'us-east-1')


def fetch_secrets_from_aws(secret_key: str, region: str) -> dict:
    secrets_manager = boto3.client("secretsmanager", region_name=region)
    response = secrets_manager.get_secret_value(SecretId=secret_key)
    return json.loads(response["SecretString"])


def get_aws_credentials(cloud_account_secrets_id: str) -> dict:
    """
    Fetch AWS credentials from Secrets Manager.

    Args:
        cloud_account_secrets_id: Full secret path

    Returns:
        Dict with iamRole and externalId only
    """
    try:
        region = get_region()
        credentials = fetch_secrets_from_aws(cloud_account_secrets_id, region)

        required_fields = ["iamRole", "externalId"]
        missing_fields = [field for field in required_fields if not credentials.get(field)]
        if missing_fields:
            raise ValueError(f"Missing required fields in secret: {missing_fields}")

        return {
            "iamRole": credentials["iamRole"],
            "externalId": credentials["externalId"]
        }

    except Exception as e:
        print(f"Error fetching AWS credentials: {e}")
        raise


def get_azure_credentials(secret_id: str) -> dict:
    """
    Fetch Azure credentials:
    - subscriptionId, clientId, tenantId from API
    - clientSecret from AWS Secrets Manager
    """
    # Hardcoded credentials for API
    cc_host = os.getenv("TF_VAR_cc_host")
    email = "aditya.prajapati@facets.cloud"
    token = "cbeaf0d6-8ea8-40d8-8841-0ad628bb7f26"

    url = f"https://{cc_host}/cc-ui/v1/accounts/{secret_id}"
    headers = {"accept": "application/json"}
    auth = HTTPBasicAuth(email, token)

    response = requests.get(url, headers=headers, auth=auth)
    if response.status_code != 200:
        raise Exception(f"API call failed: {response.status_code} {response.text}")
    api_data = response.json()

    # Fetch clientSecret from AWS
    region = get_region()
    full_secret_path = construct_secret_path(secret_id)
    secret_data = fetch_secrets_from_aws(full_secret_path, region)
    if "clientSecret" not in secret_data:
        raise ValueError("Missing 'clientSecret' in AWS secret")

    return {
        "subscription_id": api_data["subscriptionId"],
        "client_id": api_data["clientId"],
        "tenant_id": api_data["tenantId"],
        "client_secret": secret_data["clientSecret"]
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python fetch_credentials.py <secret_id>")
        sys.exit(1)

    secret_id = sys.argv[1]
    cloud = os.getenv("CLOUD", "AWS").upper()

    try:
        if cloud == "AZURE":
            result = get_azure_credentials(secret_id)
        else:
            full_secret_path = construct_secret_path(secret_id)
            result = get_aws_credentials(full_secret_path)

        print(json.dumps(result, indent=2))

    except Exception as e:
        print(f"Failed to fetch credentials: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()