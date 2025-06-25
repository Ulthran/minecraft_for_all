import uuid
import boto3

def handler(event, context):
    """Add a unique identifier to the user after signup confirmation."""
    user_pool_id = event['userPoolId']
    username = event['userName']

    cognito_client = boto3.client('cognito-idp')

    cognito_client.admin_update_user_attributes(
        UserPoolId=user_pool_id,
        Username=username,
        UserAttributes=[
            {
                'Name': 'custom:uuid',
                'Value': str(uuid.uuid4())
            }
        ]
    )

    return event
