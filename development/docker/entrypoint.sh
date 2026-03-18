#!/bin/bash
set -e

export MAVEN_OPTS="-Xss128m \
 --add-opens=java.base/java.util.jar=ALL-UNNAMED \
 --add-opens=java.base/java.lang=ALL-UNNAMED \
 --add-opens=java.base/java.lang.reflect=ALL-UNNAMED"

# Build the fat JAR (skip tests for speed)
mvn package -pl obp-api -am -DskipTests

# Run the fat JAR
exec java \
  --add-opens=java.base/java.util.jar=ALL-UNNAMED \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
  -Dprops.resource.dir=/app/props/ \
  -Drun.mode=production \
  -jar obp-api/target/obp-api.jar
