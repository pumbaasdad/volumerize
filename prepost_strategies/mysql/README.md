# Using a prepost strategy to create mySQL backups

Volumerize can execute scripts before and after the backup process.

With this prepost strategy you can create a .sql backup of your MySQL containers and save it with Volumerize.

## Environment Variables

Aside of the required environment variables by Volumerize, this prepost strategy will require a couple of extra variables.

| Name                        | Description                                                                        |
| --------------------------- | ---------------------------------------------------------------------------------- |
| `VOLUMERIZE_MYSQL_USERNAME` | Username of the user who will perform the restore or dump.                         |
| `VOLUMERIZE_MYSQL_PASSWORD` | Password of the user who will perform the restore or dump.                         |
| `VOLUMERIZE_MYSQL_HOST`     | IP or domain of the host machine.                                                  |
| `VOLUMERIZE_MYSQL_DATABASE` | Database to backup/restore.                                                        |
| `VOLUMERIZE_MYSQL_SOURCE`   | Variable name of source where dumps are to be stored (default `VOLUMERIZE_SOURCE`) |
| `VOLUMERIZE_MYSQL_OPTIMIZE` | Optimize database before dumping (default `false`)                                 |

## Example with Docker Compose

```YAML
version: "3"

services:
  mariadb:
    image: mariadb
    ports:
      - 3306:3306
    environment:
      - MYSQL_ROOT_PASSWORD=1234
      - MYSQL_DATABASE=somedatabase
    volumes:
      - mariadb:/var/lib/mysql

  volumerize:
    build: .
    environment:
      - VOLUMERIZE_SOURCE=/source
      - VOLUMERIZE_TARGET=file:///backup
      - MYSQL_USERNAME=root
      - MYSQL_PASSWORD=1234
      - MYSQL_HOST=mariadb
    volumes:
      - volumerize-cache:/volumerize-cache
      - backup:/backup
    depends_on:
      - mariadb

volumes:
  volumerize-cache:
  mariadb:
  backup:
```

Then execute `docker compose exec volumerize backup` to create a backup of your database and `docker compose exec volumerize restore` to restore it from your backup.

## Multiple Databases

You can also create backups of multiple databases. This is done equivalent to multiple sources in the default image (append number to variable, starting with 1). All variables that are added with this image can be enumerated.

## Docker Secrets

The following additional variables are supported to be stored in files, the location specified in variables ending with `_FILE`. See [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/) for more info.

- `VOLUMERIZE_MYSQL_PASSWORD`
