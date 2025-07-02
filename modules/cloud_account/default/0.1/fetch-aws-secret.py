import json
import sys
import os

import boto3


# from read_from_sm  import fetch_secrets_from_aws  # Import your existing function


def build_secret_path(secret_id: str) -> str:
    """
    Simple method to construct the full secret path from just the secret ID.

    Args:
        secret_id: The secret ID (e.g., "64996c6d7010740007bfe9ee")

    Returns:
        Full secret path (e.g., "facetsdemo/backend/accounts/64996c6d7010740007bfe9ee")
    """
    prefix = os.getenv('TF_VAR', 'facetsdemo')
    return f"{prefix}/backend/accounts/{secret_id}"


def construct_secret_path(secret_id: str) -> str:
    """
    Constructs the full secret path using environment variables and the provided secret ID.

    Args:
        secret_id: The secret ID (e.g., "64996c6d7010740007bfe9ee")

    Returns:
        Full secret path (e.g., "facetsdemo/backend/accounts/64996c6d7010740007bfe9ee")
    """
    return build_secret_path(secret_id)


def get_region() -> str:
    """
    Gets the region from environment variable or returns default.

    Returns:
        AWS region string
    """
    return os.getenv('TF_VAR_cc_region', 'us-east-1')


def get_aws_credentials(cloud_account_secrets_id: str, region: str = "us-east-1") -> dict:
    """
    Uses the existing fetch_secrets_from_aws function to get AWS credentials.

    Args:
        cloud_account_secrets_id: Secret ID like "facetsdemo/backend/accounts/668d34ca533be600081289ab"
        region: AWS region (default: us-east-1)

    Returns:
        Dict with iamRole, externalId, and region
    """
    try:
        # Use your existing perfect function
        credentials = fetch_secrets_from_aws(cloud_account_secrets_id, region)

        # Add region to the output as requested
        credentials["region"] = region

        # Validate that we got the expected fields
        required_fields = ["iamRole", "externalId"]
        missing_fields = [field for field in required_fields if not credentials.get(field)]

        if missing_fields:
            raise ValueError(f"Missing required fields in secret: {missing_fields}")

        return credentials

    except Exception as e:
        print(f"Error fetching AWS credentials: {e}")
        raise


def fetch_secrets_from_aws(secret_key: str, region: str) -> dict:
    """Fetches secrets from AWS Secrets Manager."""
    secrets_manager = boto3.client("secretsmanager", region_name=region)
    response = secrets_manager.get_secret_value(SecretId=secret_key)
    return json.loads(response["SecretString"])


def main():
    """
    Command line interface.
    Usage: python script.py <secret_id> [region]
    Example: python script.py 64996c6d7010740007bfe9ee eu-west-1

    Environment Variables:
    - TF_VAR: Prefix for secret path (default: facetsdemo)
    - TF_VAR_cc_region: Default region if not provided as argument
    """
    if len(sys.argv) < 2:
        print("Usage: python script.py <secret_id> [region]")
        sys.exit(1)

    # Get the secret ID from command line
    secret_id = sys.argv[1]

    # Determine region: prioritize command line arg, then env var, then default
    if len(sys.argv) > 2:
        region = sys.argv[2]
    else:
        region = get_region()

    # Construct the full secret path
    full_secret_path = construct_secret_path(secret_id)

    try:
        credentials = get_aws_credentials(full_secret_path, region)

        # Output the result
        print(json.dumps(credentials, indent=2))

        return credentials

    except Exception as e:
        print(f"Failed to fetch credentials: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
