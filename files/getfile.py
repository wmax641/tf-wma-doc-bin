#!/usr/bin/env python3

import json
import boto3
from botocore.config import Config
import os
import re


_PRESIGNED_URL_EXPIRY = 1337

# Tries to get s3 object key from dynamodb table, if exists
# Exceptions: KeyError
def get_object_key_from_dynamodb(key_id: str) -> str:
    table_name = os.environ["DYNAMODB_TABLE"]

    dynamodb = boto3.client("dynamodb")
    r = dynamodb.get_item(TableName="wma-doc-bin", Key={"id":{"S":key_id}}) 

    if "Item" not in r:
        raise KeyError

    return(r["Item"]["key"]["S"])

# For a given s3 object key, look up the s3 object and try to generate an s3 presigned URL
# Exceptions: all uncaught
def generate_presigned_url(object_key: str) -> str:

    bucket_name = os.environ["S3_BUCKET"]

    s3 = boto3.client('s3', 
                      region_name="ap-southeast-2",)
                      #config=boto3.session.Config(signature_version='s3v4',))
   
    url = s3.generate_presigned_url('get_object', 
                                    Params = {'Bucket':bucket_name, 'Key':object_key}, 
                                    ExpiresIn =_PRESIGNED_URL_EXPIRY)
    return (url)

# Helper function to easily return a HTTP error
def generate_error_html_response(status_code: int, msg: str) -> str:
    return {"statusCode" : status_code, 
            "headers":{"Content-Type": "text/plain"},
            "body" : f"{status_code} - {msg}"
    }

def lambda_handler(event, context):

    # (try to) Log request
    try:
        ip = event['requestContext']['identity']['sourceIp'] 
        ua = event['requestContext']['identity']['userAgent'][:128]
        print(f"{ip}, {ua}")
    except Excetion as e:
        print(f"Error reading requestor IP/UA: [{type(e).__name__}] exception - {str(e)}")

    # Check if environment variables set
    try:
        environment_check()
    except KeyError as e:
        return(generate_error_html_response(500, "Server Error, contact system administrator"))

    # Get input key_id from URL param, attempt to clean it up (remove leading "/" and bad characters)
    try:
        #path = event["requestContext"]["path"]
        param_id = event["queryStringParameters"]["id"]

        # Error on any weird characters that are not alphanumeric or "/"
        if any(not c.isalnum() for c in param_id):
            print("Error - Found illegal character in id parameter")
            raise KeyError

        # Error if input is too long or too short
        if len(param_id) < 64 or len(param_id) > 70:
            print("Error - Input too small or large")
            raise KeyError

    except Exception as e:
        print(f"Error reading url path: [{type(e).__name__}] exception - {str(e)}")
        return(generate_error_html_response(400, "Bad request, please check URL"))


    # Try to get the s3 object key/path that matches the input
    try:
        object_key = get_object_key_from_dynamodb(param_id)
    except KeyError:
        print(f"Error get_object_key_from_dynamodb({param_id}): Key lookup not found")
        return(generate_error_html_response(404, "File not found"))
    except Exception as e:
        print(f"Error looking up dynamodb: [{type(e).__name__}] exception - {str(e)}")
        return(generate_error_html_response(500, "Server Error, contact system administrator"))


    # Try to get s3 presigned URl for a particular {object_key}
    try:
        presigned_url = generate_presigned_url(object_key)
    except Exception as e:
        print(f"Error generating presigned s3 URL: [{type(e).__name__}] exception - {str(e)}")
        return(generate_error_html_response(500, "Server Error, contact system administrator"))

    # Return a redirect to the presigned URL
    print(f"Finished request for:")
    print(f"param_id={param_id}, object_key={object_key}")
    return {
        "statusCode" : 301,
        'headers':{"Location": f"{presigned_url}"},
    }

# Initial environment variable checks to ensure they're set
# Raises KeyError if a required key is missing
def environment_check():

    env_output = ""

    # Each of the required environment variables to check
    for key in ["S3_BUCKET", "DYNAMODB_TABLE"]:
        if key not in os.environ:
            print(f"Required env variable '{key}' not set. Exiting...")
            raise KeyError
        else:
            env_output += f"{key}={os.environ[key]}, "

    print(env_output)

# For local testing
if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("usage: python3 list.py <key_id>")
        sys.exit(1)

    # Check if environment variables set
    environment_check()

    object_key = get_object_key_from_dynamodb(sys.argv[1])
    print(object_key)

    url = generate_presigned_url(object_key)
    print(url)
