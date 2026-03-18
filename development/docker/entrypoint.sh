#!/bin/bash
set -e

exec java \
  --add-opens=java.base/java.util.jar=ALL-UNNAMED \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
  -Xms512m -Xmx2g \
  -Drun.mode=production \
  -Dprops.resource.dir=/app/props/ \
  -jar /app/obp-api/target/obp-api.jar