import requests
import os
import sys
from requests.auth import HTTPBasicAuth

# Configuration
url = "https://root.console.facets.cloud/cc-ui/v1/modules/bootstrap"

def post(url, username, password, payload):
    """Makes a POST API call and returns the response data or prints an error if the response is non-200."""
    try:
        response = requests.post(url, auth=HTTPBasicAuth(username, password), json=payload)

        # Check if the response status code is not 200
        if response.status_code != 200:
            print(f"Error: Received status code {response.status_code}.")
            print("Response message:", response.text)  # Print the error message from the response
            return None

        print("POST request successful. Status code:", response.status_code)
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error during API call: {e}")
        return None

def check_for_errors(data):
    """Checks for errors in the data and prints the full response body if errors exist."""
    error_found = False
    error_messages = []

    for key, value in data.items():
        if isinstance(value, list) and value:
            error_found = True
            print(f"Errors found in {key}:")
            for error in value:
                print(f"  - {error}")
                error_messages.append(f"• {error}")

    if error_found:
        # Print a summary for Slack
        print("\n--- SLACK_MESSAGE_START ---")
        print(f"Bootstrap validation failed with {sum(len(v) for v in data.values() if isinstance(v, list))} errors:")
        for msg in error_messages[:10]:  # Limit to first 10 errors to avoid message length issues
            print(msg)
        if sum(len(v) for v in data.values() if isinstance(v, list)) > 10:
            print(f"... and {sum(len(v) for v in data.values() if isinstance(v, list)) - 10} more errors")
        print("--- SLACK_MESSAGE_END ---")
    else:
        print("No errors found.")

    return error_found

if __name__ == "__main__":
    # Take username and password from environment variables
    USERNAME = os.getenv('ROOT_USER')  # Get the username from environment variable
    PASSWORD = os.getenv('ROOT_TOKEN')  # Get the password from environment variable

    # Validate environment variables
    if not USERNAME or not PASSWORD:
        print("Error: ROOT_USER and ROOT_TOKEN environment variables must be set")
        sys.exit(1)

    print(f"Starting bootstrap validation for user: {USERNAME}")

    # Define the payload you want to send with the POST request
    payload = {
        # Add your key-value pairs here as needed for the API
    }

    data = post(url, USERNAME, PASSWORD, payload)
    if data:
        has_errors = check_for_errors(data)
        if has_errors:
            print("Bootstrap validation failed - errors found")
            sys.exit(1)
        else:
            print("Bootstrap validation passed - no errors found")
            sys.exit(0)
    else:
        print("Bootstrap validation failed - unable to get response")
        sys.exit(1)
