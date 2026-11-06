# Deploy Checkon backend to Railway (dev)

This setup runs the five NestJS services and one PostgreSQL instance in a
Railway project. PostgreSQL contains separate `catalog_db`, `auth_db`, and
`customer_db` databases. The analytics service reads through catalog-service
and does not use a database. Only the API Gateway should have public networking.

Railway usage may incur charges. Check the current plan and resource pricing
before deploying.

## 1. Create a Railway project and connect the repository

1. Create a Railway account and an empty project.
2. Connect the GitHub repository containing Checkon.
3. Add a PostgreSQL service and name it `postgres`.
4. Create five services from the same repository. For each service, set its
   **Root Directory** to the path below. The Dockerfile in that directory will
   build the service.

| Service name | Root directory |
| --- | --- |
| `api-gateway` | `/backend/api-gateway` |
| `auth-service` | `/backend/auth-service` |
| `customer-service` | `/backend/customer-service` |
| `catalog-service` | `/backend/catalog-service` |
| `analytics-service` | `/backend/analytics-service` |

These are isolated monorepo directories; Railway's monorepo guide describes
setting a root directory per service:
<https://docs.railway.com/deployments/monorepo>.

## 2. Create the application databases

The Railway PostgreSQL service starts with one database. Create the other
application databases in that same instance while keeping each service's data
in a separate database:

1. Install the Railway CLI and PostgreSQL client (`psql`) locally.
2. From the repository directory, link the CLI to the new Railway project and
   its development environment:

   ```sh
   railway link
   ```

3. Open an SSH-tunneled PostgreSQL session (no public database proxy is needed):

   ```sh
   railway connect postgres --ssh
   ```

4. In the `psql` prompt, create the three databases:

   ```sql
   CREATE DATABASE catalog_db;
   CREATE DATABASE auth_db;
   CREATE DATABASE customer_db;
   ```

   Keep the default database too. Do not expose PostgreSQL through public
   networking. Railway documents private database connections at
   <https://docs.railway.com/cli/connect>.

## 3. Set service variables

In each service's **Variables** tab, add the variables in its section below.
Use Railway reference variables as shown; the PostgreSQL service must be named
`postgres`, and service names must match the table above. Railway's reference
syntax is documented at <https://docs.railway.com/variables>.

### `catalog-service`

```text
PORT=3001
DB_HOST=${{postgres.PGHOST}}
DB_PORT=${{postgres.PGPORT}}
DB_USER=${{postgres.PGUSER}}
DB_PASSWORD=${{postgres.PGPASSWORD}}
DB_NAME=catalog_db
```

### `customer-service`

```text
PORT=3004
DB_HOST=${{postgres.PGHOST}}
DB_PORT=${{postgres.PGPORT}}
DB_USER=${{postgres.PGUSER}}
DB_PASSWORD=${{postgres.PGPASSWORD}}
DB_NAME=customer_db
```

### `auth-service`

```text
PORT=3003
DB_HOST=${{postgres.PGHOST}}
DB_PORT=${{postgres.PGPORT}}
DB_USER=${{postgres.PGUSER}}
DB_PASSWORD=${{postgres.PGPASSWORD}}
DB_NAME=auth_db
JWT_SECRET=<same-long-random-secret-as-api-gateway>
JWT_REFRESH_SECRET=<different-long-random-secret>
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=7d
APP_BASE_URL=https://${{api-gateway.RAILWAY_PUBLIC_DOMAIN}}
CUSTOMER_SERVICE_URL=http://customer-service.railway.internal:3004
```

### `analytics-service`

```text
PORT=3002
CATALOG_SERVICE_URL=http://catalog-service.railway.internal:3001
```

### `api-gateway`

```text
PORT=3000
CATALOG_SERVICE_URL=http://catalog-service.railway.internal:3001
ANALYTICS_SERVICE_URL=http://analytics-service.railway.internal:3002
AUTH_SERVICE_URL=http://auth-service.railway.internal:3003
CUSTOMER_SERVICE_URL=http://customer-service.railway.internal:3004
JWT_SECRET=<same-long-random-secret-as-auth-service>
```

Generate both JWT secrets independently and set them in Railway's Variables UI;
never commit them to the repository. The access-token `JWT_SECRET` must match
between gateway and auth-service. Private service URLs should remain private.

## 4. Deploy and expose the gateway

Deploy each service and wait until all five are running. In Railway's
**Networking** settings, generate a public domain for `api-gateway` and set
its target port to `3000`. Do not generate public domains for the other
services or PostgreSQL.

The application currently uses TypeORM `synchronize: true`, which is suitable
for this development deployment but should be replaced with migrations before
production.

Check the public gateway URL:

```sh
curl -i https://<gateway-domain>/api/catalog/products/to-buy
```

An unauthenticated `401` is expected and confirms the gateway is reachable.
For dev registration, `auth-service` uses `DevMailerAdapter`; the six-digit OTP
is logged in that service's Railway deployment logs as `[DEV OTP]`.

## 5. Point an iPhone dev build to Railway

Use the gateway's HTTPS URL as the Flutter compile-time API base URL:

```sh
cd frontend
/opt/homebrew/share/flutter/bin/flutter build ipa \
  --dart-define=GATEWAY_URL=https://<gateway-domain>
```

The build can then be distributed privately for device testing, for example
through TestFlight Internal Testing. An iPhone cannot use `localhost` to reach
the Railway backend.
