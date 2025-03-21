import boto3
import json
import logging

def lambda_handler(event, context):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    ecs_client = boto3.client('ecs')
    logger.info(f"Event received: {json.dumps(event)}")
    
    lifecycle_info = event.get('tf', {})
    action = lifecycle_info.get('action', event.get('action'))
    prev_input = lifecycle_info.get('prev_input', {})
    target_group_arn = event['target_group_arn']
    ecs_service_arn = event['ecs_service_arn']
    port = event['port']
    container_name = event['container_name']
    
    cluster_name = ecs_service_arn.split('/')[1]
    service_name = ecs_service_arn.split('/')[2]
    
    response = ecs_client.describe_services(
        cluster=cluster_name,
        services=[service_name]
    )
    
    service = response['services'][0]
    load_balancers = service.get('loadBalancers', [])
    
    # If container_name is empty, fetch the task definition and pick the first container's name
    if not container_name:
        task_definition_arn = service['taskDefinition']
        task_definition = ecs_client.describe_task_definition(
            taskDefinition=task_definition_arn
        )
        container_name = task_definition['taskDefinition']['containerDefinitions'][0]['name']

    new_load_balancer = {
        'targetGroupArn': target_group_arn,
        'containerName': container_name,
        'containerPort': port
    }
    
    target_group_exists = False
    for lb in load_balancers:
        if lb['targetGroupArn'] == target_group_arn:
            target_group_exists = True
            break

    if (action == 'create' or action == 'update') and not target_group_exists:
        if not target_group_exists:
            load_balancers.append(new_load_balancer)
            logger.info(f"Updating service to add load balancer: {json.dumps(new_load_balancer)}")
            ecs_client.update_service(
                cluster=cluster_name,
                service=service_name,
                loadBalancers=load_balancers
            )
        return {
            'statusCode': 200,
            'body': json.dumps('Target group attached successfully')
        }
    elif action == 'delete' or (action == 'update' and target_group_exists):
        if target_group_exists:
            load_balancers = [lb for lb in load_balancers if lb['targetGroupArn'] != target_group_arn]
            logger.info(f"Updating service to remove load balancer: {json.dumps(new_load_balancer)}")
            ecs_client.update_service(
                cluster=cluster_name,
                service=service_name,
                loadBalancers=load_balancers
            )
        return {
            'statusCode': 200,
            'body': json.dumps('Target group detached successfully')
        }
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid action specified')
        }
