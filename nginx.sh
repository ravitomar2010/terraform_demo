#! /bin/bash
      set -euo pipefail

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y nginx-light jq

      NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
      IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
      METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')
      
      META_REGION_STRING=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google")
      REGION=`echo "$META_REGION_STRING" | awk -F/ '{print $4}'`

      cat <<EOF > /var/www/html/index.html
      <h3>Welcome to Ravi's World</h3><br>INSTANCE: <b>$NAME</b><br><br> INTERNALIP: <b>$IP</b><br><br> REGION: <b>$REGION</b>