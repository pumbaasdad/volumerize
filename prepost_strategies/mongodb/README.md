# Using a prepost strategy to create MongoDB backups

Volumerize can execute scripts before and after the backup process.

With this prepost strategy you can create dump of your MongoDB containers and save it with Volumerize.

## Environment Variables

Aside of the required environment variables by Volumerize, this prepost strategy will require a couple of extra variables.

| Name                      | Description                                                                        |
| ------------------------- | ---------------------------------------------------------------------------------- |
| VOLUMERIZE_MONGO_USERNAME | Username of the user who will perform the restore or dump.                         |
| VOLUMERIZE_MONGO_PASSWORD | Password of the user who will perform the restore or dump.                         |
| VOLUMERIZE_MONGO_HOST     | MongoDB IP or domain.                                                              |
| VOLUMERIZE_MONGO_PORT     | MongoDB port.                                                                      |
| VOLUMERIZE_MONGO_SOURCE   | Variable name of source where dumps are to be stored (default `VOLUMERIZE_SOURCE`) |

## Example with Docker Compose

```YAML
version: "3"

services:
  mongodb:
    image: mongo
    ports:
      - 27017:27017
    environment:
      - MONGO_INITDB_ROOT_USERNAME=root
      - MONGO_INITDB_ROOT_PASSWORD=1234
    volumes:
      - mongodb:/data/db

  volumerize:
    build: ./prepost_strategies/mongodb/
    environment:
      - VOLUMERIZE_SOURCE=/source
      - VOLUMERIZE_TARGET=file:///backup
      - MONGO_USERNAME=root
      - MONGO_PASSWORD=1234
      - MONGO_PORT=27017
      - MONGO_HOST=mongodb
    volumes:
      - volumerize-cache:/volumerize-cache
      - backup:/backup
    depends_on:
      - mongodb

volumes:
  volumerize-cache:
  mongodb:
  backup:
```

Then execute `docker-compose exec volumerize backup` to create a backup of your database and `docker-compose exec volumerize restore` to restore it from your backup.


## Multiple Databases

You can also create backups of multiple databases. This is done equivalent to multiple sources in the default image (append number to variable, starting with 1). All variables that are added with this image can be enumerated.

## Docker Secrets

The following additional variables are supported to be stored in files, the location specified in variables ending with `_FILE`. See [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/) for more info.

- `MONGO_PASSWORD`