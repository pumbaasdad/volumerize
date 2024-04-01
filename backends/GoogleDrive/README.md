# Using Volumerize With Google Drive

Volumerize can backup Docker volumes on Google Drive.

Note: If you previously created Google Drive credentials using PyDrive and your key has not expired, those keys can still be used via the `GOOGLE_DRIVE_ID` and `GOOGLE_DRIVE_SECRET` environment variables.  However, since Google has removed the ability for out of band OAuth authentication, this is no longer the recommended approach.

You have to perform the following steps:

Login to [Google developers console](https://console.developers.google.com) and create a service account.

Create a new JSON key for the service account, and save the key to a location that can be mounted to the Volumerize container.

Share a folder in your google drive with the e-mail address of the service account.

First we start our example container with some data to backup:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     pumbaasdad/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Setup Volumerize to use Google Drive for backups of the volume `jenkins_volume`.

See [A Note on GDrive Backend](https://duplicity.gitlab.io/stable/duplicity.1.html#a-note-on-gdrive-backend) for a description of the `gdrive://` path structure.

This example assumes that the service account key is stored in the `volumerize_credentials` volume.

Start the container in demon mode:

~~~~
$ docker run -d \
    --name volumerize \
    -v volumerize_cache:/volumerize-cache \
    -v volumerize_credentials:/credentials \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdrive://service-account@project-projectid.iam.gserviceaccount.com?myDriveFolderID=folderId" \
    -e "GOOGLE_SERVICE_JSON_FILE=/credentials/google_service_account.json" \
    pumbaasdad/volumerize
~~~~

> `volumerize_cache` is the local data cache.

You can start an initial full backup:

~~~~
$ docker exec volumerize backupFull
~~~~

# Restore from Google Drive

Restore is easy, just pass the same environment variables and start the restore script:

> Note: Remove the read-only option `:ro` on the source volume.

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v volumerize_credentials:/credentials \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdrive://service-account@project-projectid.iam.gserviceaccount.com?myDriveFolderID=folderId" \
    -e "GOOGLE_SERVICE_JSON_FILE=/credentials/google_service_account.json" \
    pumbaasdad/volumerize restore
~~~~

> Will perform a test restore inside a separate volume `jenkins_test_restore`

Check the contents of the volume:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    pumbaasdad/alpine ls -R /source
~~~~

> Lists files inside the source volume

Verify against the Google Drive content:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v volumerize_credentials:/credentials \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdrive://service-account@project-projectid.iam.gserviceaccount.com?myDriveFolderID=folderId" \
    -e "GOOGLE_SERVICE_JSON_FILE=/credentials/google_service_account.json" \
    pumbaasdad/volumerize verify
~~~~

> Will perform a single verification of the volume contents against the Google Drive archive.

# Start and Stop Docker Containers

Volumerize can stop containers before backup and start them after backup.

First start a test container with the name `jenkins`

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     pumbaasdad/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Now add the containers name inside the environment variable `VOLUMERIZE_CONTAINERS` and start Volumerize in demon mode:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v volumerize_cache:/volumerize-cache \
    -v volumerize_credentials:/credentials \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdrive://service-account@project-projectid.iam.gserviceaccount.com?myDriveFolderID=folderId" \
    -e "GOOGLE_SERVICE_JSON_FILE=/credentials/google_service_account.json" \
    -e "VOLUMERIZE_CONTAINERS=jenkins" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    pumbaasdad/volumerize
~~~~

> Needs access to the docker host over the directive `-v /var/run/docker.sock:/var/run/docker.sock`

You can test the backup routine:

~~~~
$ docker exec volumerize backup
~~~~

> Triggers the backup inside the volume, the name `jenkins` should appear on the console.

> Note: Make sure your container is not running with docker auto restart!
