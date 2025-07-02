# import boto3
# import json
# from botocore.exceptions import ClientError
#
#
# def list_secrets_with_filter(region: str = "us-east-1", filter_text: str = ""):
#     """
#     Lists all secrets in AWS Secrets Manager with optional filtering.
#     """
#     try:
#         secrets_manager = boto3.client("secretsmanager", region_name=region)
#
#         print(f"Listing secrets in region: {region}")
#
#         # Get all secrets
#         paginator = secrets_manager.get_paginator('list_secrets')
#         secrets = []
#
#         for page in paginator.paginate():
#             secrets.extend(page['SecretList'])
#
#         if not secrets:
#             print("No secrets found in this region.")
#             return
#
#         print(f"\nFound {len(secrets)} secrets:")
#         print("-" * 80)
#
#         # Filter and display
#         filtered_secrets = []
#         for secret in secrets:
#             secret_name = secret['Name']
#             if not filter_text or filter_text.lower() in secret_name.lower():
#                 filtered_secrets.append(secret)
#                 print(f"Name: {secret_name}")
#                 print(f"ARN: {secret['ARN']}")
#                 print(f"Description: {secret.get('Description', 'N/A')}")
#                 print(f"Created: {secret.get('CreatedDate', 'N/A')}")
#                 print("-" * 40)
#
#         if filter_text and not filtered_secrets:
#             print(f"No secrets found matching filter: '{filter_text}'")
#
#         return filtered_secrets
#
#     except ClientError as e:
#         print(f"AWS Error: {e}")
#         return []
#     except Exception as e:
#         print(f"Error listing secrets: {e}")
#         return []
#
#
# def test_secret_access(secret_name: str, region: str = "us-east-1"):
#     """
#     Test if a specific secret can be accessed.
#     """
#     try:
#         secrets_manager = boto3.client("secretsmanager", region_name=region)
#
#         print(f"\nTesting access to secret: '{secret_name}' in region: {region}")
#
#         # Try to get the secret
#         response = secrets_manager.get_secret_value(SecretId=secret_name)
#         print("✅ Secret found and accessible!")
#
#         # Try to parse the secret
#         secret_data = json.loads(response["SecretString"])
#         print("✅ Secret data is valid JSON")
#
#         # Show the keys (but not values for security)
#         keys = list(secret_data.keys())
#         print(f"✅ Secret contains keys: {keys}")
#
#         return True
#
#     except ClientError as e:
#         error_code = e.response['Error']['Code']
#         if error_code == 'ResourceNotFoundException':
#             print("❌ Secret not found")
#         elif error_code == 'AccessDeniedException':
#             print("❌ Access denied - check your permissions")
#         elif error_code == 'InvalidRequestException':
#             print("❌ Invalid request")
#         else:
#             print(f"❌ AWS Error: {e}")
#         return False
#     except Exception as e:
#         print(f"❌ Error: {e}")
#         return False
#
#
# def check_aws_config():
#     """
#     Check AWS configuration and credentials.
#     """
#     try:
#         # Check if we can create a client
#         sts = boto3.client('sts')
#         identity = sts.get_caller_identity()
#
#         print("AWS Configuration:")
#         print(f"✅ Account ID: {identity.get('Account')}")
#         print(f"✅ User/Role ARN: {identity.get('Arn')}")
#         print(f"✅ User ID: {identity.get('UserId')}")
#
#         return True
#
#     except Exception as e:
#         print(f"❌ AWS Configuration Error: {e}")
#         return False
#
#
# if __name__ == "__main__":
#     import sys
#
#     # Check AWS config first
#     print("=" * 60)
#     print("AWS SECRETS MANAGER DIAGNOSTICS")
#     print("=" * 60)
#
#     check_aws_config()
#     print()
#
#     # Get parameters
#     if len(sys.argv) >= 2:
#         target_secret = sys.argv[1]
#         region = sys.argv[2] if len(sys.argv) > 2 else "us-east-1"
#
#         # Test the specific secret
#         test_secret_access(target_secret, region)
#         print()
#
#         # List secrets with filter
#         filter_text = target_secret.split('/')[-1] if '/' in target_secret else target_secret
#         print(f"Searching for secrets containing: '{filter_text}'")
#         list_secrets_with_filter(region, filter_text)
#
#     else:
#         print("Usage: python diagnostics.py <secret_name> [region]")
#         print("Example: python diagnostics.py facetsdemo/backend/accounts/668d34ca533be600081289ab us-east-1")
#
#         # List all secrets
#         region = "us-east-1"
#         print(f"\nListing all secrets in {region}:")
#         list_secrets_with_filter(region)


