from index import handler

event = {
    "Records": [
        {
            "eventVersion": "2.1",
            "eventSource": "aws:s3",
            "awsRegion": "eu-west-2",
            "eventTime": "blah",
            "eventName": "foo",
            "userIdentity": {
                "principalId": "123"
            },
            "requestParameters": {
                "sourceIPAddress": "some.ip"
            },
            "responseElements": {
                "x-amz-request-id": "123",
                "x-amz-id-2": "Amazon S3 host that processed the request"
            },
            "s3": {
                "s3SchemaVersion": "1.0",
                "configurationId": "ID found in the bucket notification configuration",
                "bucket": {
                    "name": "my-little-snapshots",
                    "ownerIdentity": {
                        "principalId": "Amazon-customer-ID-of-the-bucket-owner"
                    },
                    "arn": "bucket-ARN"
                },
                "object": {
                    "key": "snap-NsfmfvVCQnK2PDH0R0AuWw",
                    "size": 10,
                    "eTag": "object eTag",
                    "versionId": "object version if bucket is versioning-enabled, otherwise null",
                    "sequencer": "a string representation of a hexadecimal value used to determine event sequence"
                }
            }
        }
    ]
}

handler(event)
