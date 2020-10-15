# Using a prepost strategy to create PostgreSQL backups

Volumerize can execute scripts before and after the backup process.

With this prepost strategy you can create dump of your PostgreSQL containers and backup & restore it with Volumerize.

## Environment Variables

Aside of the required environment variables by Volumerize, this prepost strategy will require a couple of extra variables.

| Name                         | Description                                                                        |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| VOLUMERIZE_POSTRGES_USERNAME | Username of the user who will perform the restore or dump.                         |
| VOLUMERIZE_POSTRGES_PASSWORD | Password of the user who will perform the restore or dump.                         |
| VOLUMERIZE_POSTRGES_HOST     | PostgreSQL IP or domain.                                                           |
| VOLUMERIZE_POSTRGES_PORT     | PostgreSQL port. (default: 5432)                                                                   |
| VOLUMERIZE_POSTRGES_SOURCE   | Variable name of source where dumps are to be stored (default `VOLUMERIZE_SOURCE`) |

## Example with Docker Compose

```YAML
version: "3"

services:
  postgres:
    image: postgres
    ports:
      - 5432:5432
    environment:
      - POSTRGES_USERNAME=postgres
      - POSTRGES_PASSWORD=1234
      - POSTRGES_DATABASE=postgres
    volumes:
      - postgresdb:/var/lib/postgresql/data

  volumerize:
    build: .
    environment:
      - VOLUMERIZE_SOURCE=/source
      - VOLUMERIZE_TARGET=file:///backup
      - VOLUMERIZE_POSTRGES_USERNAME=postgres
      - VOLUMERIZE_POSTRGES_PASSWORD=1234
      - VOLUMERIZE_POSTRGES_PORT=5432
      - VOLUMERIZE_POSTRGES_HOST=postgres
      - VOLUMERIZE_POSTRGES_DATABASE=postgres
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

Then execute `docker-compose exec volumerize backup` to create a backup of your database and `docker-compose exec volumerize restore` to restore it from your backup.


## Multiple Databases

You can also create backups of multiple databases. This is done equivalent to multiple sources in the default image (append number to variable, starting with 1). All variables that are added with this image can be enumerated.

## Docker Secrets

The following additional variables are supported to be stored in files, the location specified in variables ending with `_FILE`. See [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/) for more info.

- `VOLUMERIZE_POSTRGES_PASSWORD`