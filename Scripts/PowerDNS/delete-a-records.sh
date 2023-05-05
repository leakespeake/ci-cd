#!/bin/bash

# PowerDNS API endpoint and API key
PDNS_URL=http://pdns01.int.leakespeake.com/api/v1/servers/localhost/zones
PDNS_API_KEY="REDACTED"

# Define the zone from which the A records will be deleted
ZONE_NAME="int.leakespeake.com."

# For loop that deletes multiple A records in a given file
for NAME in $(cat a-records.txt)
do
curl -X PATCH --data '{"rrsets": [{
  "name": "'"$NAME"'",
  "type": "A",
  "changetype": "DELETE"
}]}' -H "X-API-Key: $PDNS_API_KEY" \
"${PDNS_URL}/${ZONE_NAME}"
done
