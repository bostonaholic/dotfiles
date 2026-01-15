# Architecture Diagrams

Architecture diagrams visualize system components, their relationships,
and infrastructure layout.

## Basic Syntax

```mermaid
architecture-beta
    group api(cloud)[API Layer]

    service db(database)[Database] in api
    service server(server)[Server] in api
    service cache(disk)[Cache] in api

    db:L -- R:server
    server:L -- R:cache
```

## Groups

Groups organize related services:

```mermaid
architecture-beta
    group public(cloud)[Public Zone]
    group private(cloud)[Private Zone]

    service lb(server)[Load Balancer] in public
    service app(server)[App Server] in private
    service db(database)[Database] in private

    lb:R -- L:app
    app:B -- T:db
```

### Group Syntax

```text
group {id}({icon})[{title}]
group {id}({icon})[{title}] in {parent_id}
```

### Nested Groups

```mermaid
architecture-beta
    group cloud(cloud)[Cloud Infrastructure]
        group compute(server)[Compute] in cloud
        group storage(disk)[Storage] in cloud

    service web(server)[Web] in compute
    service api(server)[API] in compute
    service db(database)[DB] in storage

    web:R -- L:api
    api:B -- T:db
```

## Services

Services represent individual components:

```mermaid
architecture-beta
    service web(server)[Web Server]
    service db(database)[Database]
    service cache(disk)[Cache]

    web:R -- L:db
    web:B -- T:cache
```

### Service Syntax

```text
service {id}({icon})[{title}]
service {id}({icon})[{title}] in {group_id}
```

## Built-in Icons

- `cloud` - Cloud symbol
- `database` - Database cylinder
- `disk` - Disk/storage
- `internet` - Globe/internet
- `server` - Server box

```mermaid
architecture-beta
    service a(cloud)[Cloud]
    service b(database)[Database]
    service c(disk)[Disk]
    service d(internet)[Internet]
    service e(server)[Server]
```

## Custom Icons (Iconify)

Access 200,000+ icons from iconify.design:

```mermaid
architecture-beta
    service aws(logos:aws)[AWS]
    service gcp(logos:google-cloud)[GCP]
    service k8s(logos:kubernetes)[K8s]
    service docker(logos:docker-icon)[Docker]
```

Format: `{collection}:{icon-name}`

Common collections:

- `logos` - Brand/technology logos
- `mdi` - Material Design Icons
- `fa6-solid` - Font Awesome solid
- `fa6-brands` - Font Awesome brands

## Junctions

Junctions act as connection points for multiple edges:

```mermaid
architecture-beta
    service users(internet)[Users]
    junction junc
    service api1(server)[API 1]
    service api2(server)[API 2]
    service api3(server)[API 3]

    users:R -- L:junc
    junc:R -- L:api1
    junc:R -- L:api2
    junc:R -- L:api3
```

### Junction Syntax

```text
junction {id}
junction {id} in {group_id}
```

## Edges (Connections)

### Edge Syntax

```text
{serviceId}:{direction} {arrow} {direction}:{serviceId}
```

Directions:

- `T` - Top
- `B` - Bottom
- `L` - Left
- `R` - Right

### Arrow Types

```mermaid
architecture-beta
    service a(server)[A]
    service b(server)[B]
    service c(server)[C]
    service d(server)[D]

    a:R -- L:b
    b:R --> L:c
    c:R <-- L:d
```

- `--` - Bidirectional line
- `-->` - Arrow pointing right
- `<--` - Arrow pointing left
- `<-->` - Bidirectional arrows

### Group-to-Group Edges

Use `{group}` modifier:

```mermaid
architecture-beta
    group frontend(cloud)[Frontend]
    group backend(cloud)[Backend]

    service web(server)[Web] in frontend
    service api(server)[API] in backend

    web{group}:B --> T:api{group}
```

## Complete Examples

### Web Application Architecture

```mermaid
architecture-beta
    group client(internet)[Client Layer]
    group web(cloud)[Web Layer]
    group app(server)[Application Layer]
    group data(database)[Data Layer]

    service browser(internet)[Browser] in client
    service cdn(cloud)[CDN] in web
    service lb(server)[Load Balancer] in web
    service api1(server)[API Server 1] in app
    service api2(server)[API Server 2] in app
    service db(database)[PostgreSQL] in data
    service cache(disk)[Redis Cache] in data

    browser:B --> T:cdn
    cdn:B --> T:lb
    lb:B --> T:api1
    lb:B --> T:api2
    api1:B --> T:db
    api2:B --> T:db
    api1:R -- L:cache
    api2:R -- L:cache
```

### Microservices Architecture

```mermaid
architecture-beta
    group gateway(cloud)[API Gateway]
    group services(server)[Services]
    group messaging(disk)[Messaging]
    group storage(database)[Storage]

    service gw(server)[Gateway] in gateway
    service auth(server)[Auth] in services
    service users(server)[Users] in services
    service orders(server)[Orders] in services
    service queue(disk)[Message Queue] in messaging
    service userdb(database)[User DB] in storage
    service orderdb(database)[Order DB] in storage

    gw:B --> T:auth
    gw:B --> T:users
    gw:B --> T:orders
    auth:R -- L:queue
    users:R -- L:queue
    orders:R -- L:queue
    users:B --> T:userdb
    orders:B --> T:orderdb
```

### Cloud Infrastructure

```mermaid
architecture-beta
    group vpc(cloud)[VPC]
        group public(cloud)[Public Subnet] in vpc
        group private(cloud)[Private Subnet] in vpc

    service internet(internet)[Internet]
    service igw(cloud)[Internet Gateway] in public
    service alb(server)[ALB] in public
    service nat(server)[NAT Gateway] in public

    service app1(server)[App Server 1] in private
    service app2(server)[App Server 2] in private
    service rds(database)[RDS] in private

    internet:B --> T:igw
    igw:B --> T:alb
    alb:B --> T:app1
    alb:B --> T:app2
    app1:R -- L:nat
    app2:R -- L:nat
    app1:B --> T:rds
    app2:B --> T:rds
```

### Data Pipeline

```mermaid
architecture-beta
    group ingest(cloud)[Ingestion]
    group process(server)[Processing]
    group store(database)[Storage]
    group serve(server)[Serving]

    service api(server)[API] in ingest
    service stream(disk)[Kafka] in ingest
    service spark(server)[Spark] in process
    service lake(database)[Data Lake] in store
    service warehouse(database)[Warehouse] in store
    service bi(server)[BI Tool] in serve
    service ml(server)[ML Service] in serve

    api:R --> L:stream
    stream:B --> T:spark
    spark:B --> T:lake
    lake:R --> L:warehouse
    warehouse:B --> T:bi
    lake:B --> T:ml
```

## Best Practices

1. Use groups to organize related components
2. Choose appropriate icons for service types
3. Use consistent edge directions (usually top-to-bottom or left-to-right)
4. Label services with clear, concise names
5. Use junctions to simplify complex connections
6. Keep diagrams focused on one aspect of architecture
7. Use nested groups for complex systems
8. Add directional arrows to show data flow

## Limitations

- Beta feature (syntax may change)
- Limited built-in icons (use Iconify for more)
- No automatic layout optimization
- Cannot style individual components
- No annotations or notes
- Limited text on edges
