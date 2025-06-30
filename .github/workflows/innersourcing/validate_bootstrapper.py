import requests
import os
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
    for key, value in data.items():
        if isinstance(value, list) and value:
            print("Errors found in bootstrap modules:")
            print(data)  # Print the full response body
            error_found = True
            break  # Break the loop after printing the response

    if not error_found:
        print("No errors found.")

if __name__ == "__main__":
    # Take username and password from environment variables
    USERNAME = os.getenv('ROOT_USER')  # Get the username from environment variable
    PASSWORD = os.getenv('ROOT_TOKEN')  # Get the password from environment variable
    
    # Define the payload you want to send with the POST request
    payload = {
        # Add your key-value pairs here as needed for the API
    }
    
    data = post(url, USERNAME, PASSWORD, payload)
    print("Response data:", data)  # Print the response data for debugging
    if data:
        print("Reached check_for_errors")
        check_for_errors(data)
