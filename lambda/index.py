import boto3

code_build = boto3.client("codebuild")


def handler(event, _context):
    snapshot = event["Records"][0]["s3"]["object"]["key"]

    response = code_build.start_build(
        projectName="es-backup-verification",
        environmentVariablesOverride=[
            {
                "name": "SNAPSHOT_FILE",
                "value": snapshot,
                "type": "PLAINTEXT"
            }
        ]
    )

    print("Started build for snapshot %s:" % snapshot)
    print(response)
