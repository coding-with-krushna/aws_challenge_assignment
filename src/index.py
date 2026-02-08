import boto3
import os
import json

# Clients initialized outside handler for performance (execution environment reuse)
ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    method = event.get('httpMethod')
    
    # --- GET /v1/vpc (List all created VPCs) ---
    if method == 'GET':
        # Scan returns all items in the table
        response = table.scan()
        items = response.get('Items', [])
        
        return {
            "statusCode": 200,
            "body": json.dumps({"vpcs": items})
        }

    # --- POST /v1/vpc (Create New Infrastructure) ---
    if method == 'POST':
        try:
            body = json.loads(event.get('body', '{}'))

            # 1. Validation
            if 'cidr_vpc' not in body or 'subnets' not in body:
                return {
                    "statusCode": 400,
                    "body": json.dumps({"error": "Missing 'cidr_vpc' or 'subnets' list."})
                }

            cidr_vpc = body['cidr_vpc']
            subnet_cidrs = body['subnets']

            # 2. Create VPC in AWS
            vpc = ec2.create_vpc(CidrBlock=cidr_vpc)
            vpc_id = vpc['Vpc']['VpcId']
            
            # 3. Create Subnets
            created_subnets = []
            for cidr in subnet_cidrs:
                s = ec2.create_subnet(VpcId=vpc_id, CidrBlock=cidr)
                created_subnets.append(s['Subnet']['SubnetId'])
            
            # 4. Record the infrastructure in DynamoDB
            table.put_item(Item={
                'vpc_id': vpc_id, # This matches your DynamoDB Hash Key
                'subnets': created_subnets,
                'cidr_block': cidr_vpc,
                'status': 'created'
            })

            return {
                "statusCode": 201,
                "body": json.dumps({
                    "message": "Success",
                    "vpc_id": vpc_id, 
                    "subnets": created_subnets
                })
            }
        except Exception as e:
            return {
                "statusCode": 500,
                "body": json.dumps({"error": str(e)})
            }

    # Default response if method is not GET or POST
    return {
        "statusCode": 405,
        "body": json.dumps({"error": f"Method {method} not allowed"})
    }   