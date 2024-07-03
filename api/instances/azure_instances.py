import requests
import json
import os
import sys

def get_instance_types(vcpu, region):
    def fetch_data(region, tier):
        url = "https://apiv1.cloudprice.net/api/v1/price"
        params = {
            "currency": "USD",
            "region": region,
            "tier": tier,
            "paymentType": "payasyougo"
        }
        response = requests.get(url, params=params)
        print(f"Queried URL: {response.url}")
        return response.json()
    
    def filter_and_format(data):
        instances = []
        for instance in data['listVmInformations']:
            if instance['numberOfCores'] == vcpu and instance['cpuArchitecture'] == 'x64':
                instance_info = {
                    "name": instance['name'],
                    "price": instance['linuxPrice'],
                    "tags": [],
                    "architecture": instance['cpuArchitecture'],
                    "memory": instance['memoryInMB'],
                    "perfScore": instance['perfScore'],
                    "bestPriceRegion": instance['bestPriceRegion'],
                    "canonicalname": instance['canonicalname'],
                    "paymentType": instance['paymentType'],
                    "modifiedDate": instance['modifiedDate']
                }
                instances.append(instance_info)
        instances = sorted(instances, key=lambda x: x['price'])[:4]
        if instances:
            instances[0]['tags'].append('cheapest')
        return instances

    standard_data = fetch_data(region, "standard")
    spot_data = fetch_data(region, "spot")
    
    on_demand_options = filter_and_format(standard_data)
    spot_options = filter_and_format(spot_data)
    
    return {
        f"{vcpu}Cores": {
            "onDemand": on_demand_options,
            "spot": spot_options
        }
    }

def save_instance_data(vcpu_list, regions):
    if not os.path.exists('azure'):
        os.makedirs('azure')
    
    for region in regions:
        result = {}
        for vcpu in vcpu_list:
            result.update(get_instance_types(vcpu, region))
        
        output_filename = f"azure/{region}.json"
        with open(output_filename, "w") as outfile:
            json.dump(result, outfile)
        print(f"Output written to {output_filename}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 fetch_options.py <regions>")
        print("Example: python3 fetch_options.py \"centralindia,eastus\" or \"all\"")
        sys.exit(1)
    
    input_regions = sys.argv[1]
    vcpu_list = [4, 8, 16]

    # List of all Azure regions
    all_regions = [
        "eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast", "southeastasia",
        "northeurope", "swedencentral", "uksouth", "westeurope", "centralus", "northcentralus",
        "westus", "southafricanorth", "centralindia", "eastasia", "japaneast", "jioindiawest",
        "koreacentral", "canadacentral", "francecentral", "germanywestcentral", "norwayeast",
        "switzerlandnorth", "uaenorth", "brazilsouth"
    ]
    
    if input_regions == "all":
        regions = all_regions
    else:
        regions = input_regions.split(',')

    try:
        save_instance_data(vcpu_list, regions)
    except ValueError as e:
        print(e)

