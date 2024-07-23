import requests
import json
import os
import sys
import threading
instances_length = 4

def response(url, params):
    response = requests.get(url, params=params)
    print(f"Queried URL: {response.url}")
    return response.json()

def get_aws_instance_types(vcpu, region):
    def fetch_data(region, vcpu, payment_type):
        url = "https://cloudprice.net/api/v2/aws/ec2/instances"
        params = {
            "currency": "USD",
            "region": region,
            "tenancy": "Shared",
            "timeoption": "hour",
            "operatingSystem": "Linux",
            "bringYourOwnLicense": "false",
            "paymentType": payment_type,
            "sortField": "InstanceType",
            "sortOrder": "true",
            "columns": "InstanceType,InstanceFamily,ProcessorVCPUCount,MemorySizeInMB,ProcessorArchitecture,HasGPU,PricePerHour,__AlternativeInstances,__SavingsOptions,BestOnDemandHourPriceDiff",
            "_ProcessorVCPUCount_max": vcpu
        }
        return response(url, params)
    
    def filter_and_format(data, vcpu):
        instances = []
        for instance in data['Data']['Items']:
            if instance['ProcessorVCPUCount'] == vcpu and 'x86_64' in instance['ProcessorArchitecture']:
                instance_info = {
                    "InstanceType": instance['InstanceType'],
                    "PricePerHour": instance['PricePerHour'],
                    "tags": [],
                    "Architecture": instance['ProcessorArchitecture'],
                    "Memory": instance['MemorySizeInMB'],
                    "BestOnDemandHourPriceRegion": instance['BestOnDemandHourPriceRegion'],
                    "CanonicalName": instance['InstanceType'],
                    "PaymentType": "OnDemand",
                    "ModifiedDate": data['Data']['UpdatedAt']
                }
                instances.append(instance_info)
        instances = sorted(instances, key=lambda x: x['PricePerHour'])[:instances_length]
        if instances:
            instances[0]['tags'].append('cheapest')
        return instances

    ondemand_data = fetch_data(region, vcpu, "OnDemand")
    spot_data = fetch_data(region, vcpu, "Spot")

    on_demand_options = filter_and_format(ondemand_data, vcpu)
    spot_options = filter_and_format(spot_data, vcpu)

    return {
        f"{vcpu}Cores": {
            "onDemand": on_demand_options,
            "spot": spot_options
        }
    }

def save_instance_data(vcpu_list, region):
    result = {}
    for vcpu in vcpu_list:
        result.update(get_aws_instance_types(vcpu, region))

    output_filename = f"aws/{region}.json"
    with open(output_filename, "w") as outfile:
        json.dump(result, outfile, indent=4, sort_keys=True)
    print(f"Output written to {output_filename}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 fetch_options.py <regions>")
        print("Example: python3 fetch_options.py \"us-east-1,us-west-2\" or \"all\"")
        sys.exit(1)
    
    input_regions = sys.argv[1]
    vcpu_list = [4, 8, 16]

    # List of all AWS regions (sample list; please use the actual list of regions you need)
    all_regions = response("https://cloudprice.net/api/v2/aws/ec2/regions", {}).get("Data", {})
    
    if input_regions == "all":
        regions = all_regions
    else:
        regions = input_regions.split(',')

    threads = []
    try:
        if not os.path.exists('aws'):
            os.makedirs('aws')
        for region in regions:
            thread = threading.Thread(target=save_instance_data, args=(vcpu_list, region))
            threads.append(thread)
            thread.start()
        for thread in threads:
            thread.join()
    except ValueError as e:
        print(e)

