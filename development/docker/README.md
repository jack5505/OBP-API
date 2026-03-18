# OBP-API Docker Development Setup

This Docker Compose setup provides a complete **development environment** for OBP-API with Redis caching support.

## Services

### 🏦 **obp-api-app** 
- Main OBP-API application running as an **executable fat JAR**
- Built with Maven 3.9.6 + OpenJDK 17
- Runs with `java -jar obp-api.jar` via an embedded Http4s server
- Port: `8080`
- **Features**: Configurable via props file and environment variables

### 🔴 **obp-api-redis**
- Redis cache server
- Version: Redis 7 Alpine
- Internal port: `6379`
- External port: `6380` (configurable)
- Persistent storage with AOF

## Quick Start

1. **Prerequisites**
   - Docker and Docker Compose installed
   - Local PostgreSQL database running
   - Props file at `obp-api/src/main/resources/props/production.default.props` (included by default)

2. **Start services**
   ```bash
   cd development/docker
   docker-compose up --build
   ```

3. **Access application**
   - OBP-API: http://localhost:8080
   - Redis: `localhost:6380`

## Configuration

### Database Connection

You can configure the database connection in multiple ways:

**Option 1: Props file** (traditional):
```properties
db.driver=org.postgresql.Driver
db.url=jdbc:postgresql://host.docker.internal:5432/obp_mapped?user=obp&password=yourpassword
```

**Option 2: Environment variables** (recommended for Docker):
The setup automatically overrides database settings via environment variables, so you can configure without modifying props files.

### Redis Configuration

Redis is configured automatically using OBP-API's environment variable override system:

```yaml
# Automatically set by docker-compose.yml:
OBP_CACHE_REDIS_URL=redis      # Connect to redis service
OBP_CACHE_REDIS_PORT=6379      # Internal Docker port
OBP_DB_URL=jdbc:postgresql://host.docker.internal:5432/obp_mapped?user=obp&password=f
```

### Custom Redis Port

To customize configuration, edit `.env`:

```bash
# .env file
OBP_CACHE_REDIS_PORT=6381
OBP_DB_URL=jdbc:postgresql://host.docker.internal:5432/mydb?user=myuser&password=mypass
```

Or set environment variables:

```bash
export OBP_CACHE_REDIS_PORT=6381
export OBP_DB_URL="jdbc:postgresql://host.docker.internal:5432/mydb?user=myuser&password=mypass"
docker-compose up --build
```

## Container Names

All containers use consistent `obp-api-*` naming:

- `obp-api-app` - Main application
- `obp-api-redis` - Redis cache server
- `obp-api-network` - Docker network
- `obp-api-redis-data` - Redis data volume

## Development Features

### Props File Override

The setup mounts your local props directory for custom configuration:
```yaml
volumes:
  - ../../obp-api/src/main/resources/props:/app/props
```

The app first reads props from the classpath (bundled in the fat JAR), then the filesystem mount at `/app/props/` takes priority via `-Dprops.resource.dir=/app/props/`.

Environment variables take precedence over props files using OBP's built-in system:
- `cache.redis.url` → `OBP_CACHE_REDIS_URL`
- `cache.redis.port` → `OBP_CACHE_REDIS_PORT`
- `db.url` → `OBP_DB_URL`

### Live Development Features

**Volume Mounts for Development**:
```yaml
# Automatically mounted by docker-compose:
volumes:
  - ../../obp-api/src/main/resources/props:/app/props  # Live props updates (restart container to pick up changes)
  # Source code is compiled into the JAR during build for optimal performance
```

**Props file changes**: Update `production.default.props` on host and restart the container to pick up changes.  
**Rebuild for code changes**: Run `docker-compose up --build` to recompile and redeploy code changes.

## Useful Commands

### Service Management
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs obp-api-app
docker-compose logs obp-api-redis

# Stop services  
docker-compose down

# Rebuild and restart
docker-compose up --build
```

### Redis Operations
```bash
# Connect to Redis CLI
docker exec -it obp-api-redis redis-cli

# Check Redis keys
docker exec obp-api-redis redis-cli KEYS "*"

# Monitor Redis commands
docker exec obp-api-redis redis-cli MONITOR
```

### Container Inspection
```bash
# List containers
docker-compose ps

# Execute commands in containers
docker exec -it obp-api-app bash
docker exec -it obp-api-redis sh
```

## Troubleshooting

### Redis Connection Issues
- Check if `OBP_CACHE_REDIS_URL=redis` is set correctly
- Verify Redis container is running: `docker-compose ps`
- Test Redis connection: `docker exec obp-api-redis redis-cli ping`

### Database Connection Issues  
- Ensure local PostgreSQL is running
- Verify `host.docker.internal` resolves: `docker exec obp-api-app ping host.docker.internal`
- Check props file is mounted: `docker exec obp-api-app ls /app/props/`

### Props Loading Issues
- Check external props are detected: `docker-compose logs obp-api-app | grep "external props"`
- Verify environment variables: `docker exec obp-api-app env | grep OBP_`

## Environment Variables

The setup uses OBP-API's built-in environment override system:

| Props File Property | Environment Variable | Default | Description |
|---------------------|---------------------|---------|-------------|
| `cache.redis.url` | `OBP_CACHE_REDIS_URL` | `redis` | Redis hostname |
| `cache.redis.port` | `OBP_CACHE_REDIS_PORT` | `6379` | Redis port |
| `cache.redis.password` | `OBP_CACHE_REDIS_PASSWORD` | - | Redis password |
| `db.url` | `OBP_DB_URL` | `jdbc:postgresql://host.docker.internal:5432/obp_mapped?user=obp&password=f` | Database connection URL |

## Network Architecture

```
Host Machine
├── PostgreSQL :5432
├── Props Files (mounted) → Docker Container
└── Docker Network (obp-api-network)
    ├── obp-api-app :8080 → :8080 (Live Development Mode)
    └── obp-api-redis :6379 → :6380 (Persistent Cache)
```

**Connection Flow**:
- OBP-API ↔ Redis: Internal Docker network (`redis:6379`)
- OBP-API ↔ PostgreSQL: Host connection (`host.docker.internal:5432`) 
- Props Files: Live mounted from host (`/app/props/`)
- Redis External: Accessible via `localhost:6380`

## Development Benefits

### ⚡ **Production-grade Runtime** (`Dockerfile.dev`)
- **Single-stage build** using `mvn install` to produce a fat JAR with all dependencies
- **All modules compiled**: `obp-commons` and `obp-api` are fully built at Docker image build time
- **Self-contained JAR** (`obp-api.jar`) bundles all classes, resources, and default props
- **Props override**: Mount your local props directory at `/app/props/` for custom configuration
- **Security compliant** — selective file copying (SonarQube approved)

### 🔧 **Development vs Production**
- **Current setup**: Uses `Dockerfile.dev` which builds a fat JAR from source during `docker-compose up --build`
- **Production ready**: Can switch to `Dockerfile` for multi-stage production builds
- **Best of both**: Built-in default props with optional volume mount for custom configuration

### 📋 **Additional Notes**
- Redis data persists in `obp-api-redis-data` volume
- Props files can be live-mounted from host; restart the container to apply changes
- Environment variables override props file values automatically
- Java 17 with proper module system compatibility (`--add-opens` flags in `entrypoint.sh`)
- All containers restart automatically unless stopped manually
- `JAVA_TOOL_OPTIONS` is used (instead of `JAVA_OPTS`) so JVM flags are picked up automatically

---

🚀 **Ready for live development!** 

```bash
cd development/docker
docker-compose up --build
# Start coding - changes are reflected automatically! 🔥
```

**Pro Tips**:
- Update props files and restart the container to pick up changes
- Use `docker-compose logs obp-api -f` to watch live application logs
- Run `docker-compose up --build` to recompile the app from source
- Redis caching speeds up API responses significantly