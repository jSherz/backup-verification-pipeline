import os
import boto3
import json
import requests
import time

s3 = boto3.client("s3")

bucket = os.environ["SNAPSHOT_BUCKET"]
es_url = os.environ["ES_URL"]
es_repo = os.environ["ES_REPO"]

snapshot_file = os.environ["SNAPSHOT_FILE"]
snapshot_uuid = snapshot_file[:-4].split("-")[1]

print("Notified for snapshot with UUID %s" % snapshot_uuid)

# Downloading snapshot index
latest_index = s3.get_object(
    Bucket=bucket,
    Key="index.latest"
)

latest_index_num = int(latest_index["Body"].read().hex(), 16)
index_path = "index-%d" % latest_index_num

print("Using snapshot index %s" % index_path)

index_file = s3.get_object(
    Bucket=bucket,
    Key=index_path
)

metadata = json.loads(index_file["Body"].read())

# Look for the name of the snapshot we"ve been notified about
matches = list(filter(lambda s: s["uuid"] == snapshot_uuid, metadata["snapshots"]))

if len(matches) == 0:
    raise Exception("Failed to find snapshot with UUID %s" % snapshot_uuid)

snapshot = matches[0]

print("Restoring snapshot %s" % snapshot["name"])

# Check which indices we"ll be checking data for
snapshot_info = requests.get("%s/_snapshot/%s/%s" % (es_url, es_repo, snapshot["name"])).json()

indices = snapshot_info["snapshots"][0]["indices"]

print("Snapshot contains indices %s" % ", ".join(indices))

# Restore
requests.post(
    "%s/_snapshot/%s/%s/_restore?wait_for_completion=false" % (es_url, es_repo, snapshot["name"])).json()


# Poll for status
def check_all_complete():
    print("Checking if all shards are recovered...")

    for index in indices:
        recovery_data = requests.get("%s/%s/_recovery" % (es_url, index)).json()

        if index in recovery_data and all(map(lambda shard: shard["stage"] == "DONE", recovery_data[index]["shards"])):
            print("Index %s is complete" % index)
        else:
            print("Still waiting for index %s" % index)
            return False
    return True


while not check_all_complete():
    time.sleep(3)

for index in indices:
    count_query = requests.get("%s/%s/_count" % (es_url, index)).json()

    print("Index %s has %d documents" % (index, count_query["count"]))

    if count_query["count"] <= 100000:
        # page engineers
        # cry
        # ???
        print("AAAAH %s IS MISSING DOCS :O :O :O" % index)
