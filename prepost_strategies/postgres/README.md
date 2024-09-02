# Using a prepost strategy to create PostgreSQL backups

Volumerize can execute scripts before and after the backup process.

With this prepost strategy you can create dump of your PostgreSQL containers and backup & restore it with Volumerize.

## Environment Variables

Aside of the required environment variables by Volumerize, this prepost strategy will require a couple of extra variables.

| Name                         | Description                                                                        |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| VOLUMERIZE_POSTGRES_USERNAME | Username of the user who will perform the restore or dump.                         |
| VOLUMERIZE_POSTGRES_PASSWORD | Password of the user who will perform the restore or dump.                         |
| VOLUMERIZE_POSTGRES_HOST     | PostgreSQL IP or domain.                                                           |
| VOLUMERIZE_POSTGRES_DATABASE | PostgreSQL database.                                                               |
| VOLUMERIZE_POSTGRES_PORT     | PostgreSQL port. (default: 5432)                                                   |
| VOLUMERIZE_POSTGRES_SOURCE   | Variable name of source where dumps are to be stored (default `VOLUMERIZE_SOURCE`) |

## Example with Docker Compose

```YAML
services:
  postgres:
    image: postgres
    ports:
      - 5432:5432
    environment:
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=1234
      - POSTGRES_DATABASE=postgres
    volumes:
      - postgresdb:/var/lib/postgresql/data

  volumerize:
    build: .
    environment:
      - VOLUMERIZE_SOURCE=/source
      - VOLUMERIZE_TARGET=file:///backup
      - VOLUMERIZE_POSTGRES_USERNAME=postgres
      - VOLUMERIZE_POSTGRES_PASSWORD=1234
      - VOLUMERIZE_POSTGRES_PORT=5432
      - VOLUMERIZE_POSTGRES_HOST=postgres
      - VOLUMERIZE_POSTGRES_DATABASE=postgres
    volumes:
      - volumerize-cache:/volumerize-cache
      - backup:/backup
    depends_on:
      - postgres

volumes:
  volumerize-cache:
  postgresdb:
  backup:
```

Then execute `docker compose exec volumerize backup` to create a backup of your database and `docker compose exec volumerize restore` to restore it from your backup.


## Multiple Databases

You can also create backups of multiple databases. This is done equivalent to multiple sources in the default image (append number to variable, starting with 1). All variables that are added with this image can be enumerated.

## Docker Secrets

The following additional variables are supported to be stored in files, the location specified in variables ending with `_FILE`. See [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/) for more info.

- `VOLUMERIZE_POSTGRES_PASSWORD`
