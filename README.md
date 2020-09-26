
# Feki.de Volumerize 
(Fork from [blacklabelops/volumerize](https://github.com/blacklabelops/volumerize))

[![Circle CI](https://circleci.com/gh/Fekide/volumerize.svg?style=shield)](https://circleci.com/gh/Fekide/volumerize)
[![Open Issues](https://img.shields.io/github/issues/fekide/volumerize.svg)](https://github.com/fekide/volumerize/issues) [![Stars on GitHub](https://img.shields.io/github/stars/fekide/volumerize.svg)](https://github.com/fekide/volumerize/stargazers)
[![Docker Stars](https://img.shields.io/docker/stars/fekide/volumerize.svg)](https://hub.docker.com/r/fekide/volumerize/) [![Docker Pulls](https://img.shields.io/docker/pulls/fekide/volumerize.svg)](https://hub.docker.com/r/fekide/volumerize/)

[![Try in PWD](https://raw.githubusercontent.com/play-with-docker/stacks/master/assets/images/button.png)](https://labs.play-with-docker.com/?stack=https://raw.githubusercontent.com/fekide/volumerize/master/docker-compose.yml)

- [Feki.de Volumerize](#fekide-volumerize)
  - [Volume Backups Tutorials](#volume-backups-tutorials)
  - [Make It Short](#make-it-short)
  - [How It Works](#how-it-works)
  - [Backup Multiple volumes](#backup-multiple-volumes)
  - [Backup Restore](#backup-restore)
    - [Dry run](#dry-run)
  - [Periodic Backups](#periodic-backups)
  - [Docker Container Restarts](#docker-container-restarts)
      - [Additional Docker CLI API configurations](#additional-docker-cli-api-configurations)
      - [Additional Docker considerations](#additional-docker-considerations)
  - [Duplicity Parameters](#duplicity-parameters)
  - [Symmetric Backup Encryption](#symmetric-backup-encryption)
  - [Asymmetric Key-Based Backup Encryption](#asymmetric-key-based-backup-encryption)
  - [Enforcing Full Backups Periodically](#enforcing-full-backups-periodically)
  - [Automatically remove old backups](#automatically-remove-old-backups)
  - [Post scripts and pre scripts (prepost strategies)](#post-scripts-and-pre-scripts-prepost-strategies)
    - [Additional variables for prepost-scripts](#additional-variables-for-prepost-scripts)
    - [Provided PrePost-Strategies](#provided-prepost-strategies)
  - [Container Scripts](#container-scripts)
  - [Customize Jobber](#customize-jobber)
  - [Multiple Backups](#multiple-backups)
  - [Docker Secrets](#docker-secrets)
  - [All Environment Variables](#all-environment-variables)
  - [Build the Image](#build-the-image)
  - [Run the Image](#run-the-image)

Backup and restore solution for Docker volume backups. It is based on the command line tool Duplicity. Dockerized and Parameterized for easier use and configuration.

This is not a tool that can safely clone and backup data from running databases. You should always stop all containers running on your data before doing backups. You can use [pre- and postscripts](#post-scripts-and-pre-scripts-prepost-strategies) to enable maintenance mode or similar. Always make sure you're not a victim of unexpected data corruption.

Also note that the easier the tools the easier it is to lose data! Always make sure the tool works correct by checking the backup data itself, e.g. S3 bucket. Check the configuration double time and enable some check options this image offers. E.g. attaching volumes read only.

Features:

* Multiple Backends
* Cron Schedule
* Start and Stop Containers

Supported backends:

* Filesystem
* Amazon S3
* DropBox
* Google Drive
* ssh/scp
* rsync

and many more: [Duplicity Supported Backends](http://duplicity.nongnu.org/index.html)

## Volume Backups Tutorials

Docker Volume Backups on:

Backblaze B2: [Readme](https://github.com/fekide/volumerize/tree/master/backends/BackblazeB2)

Amazon S3: [Readme](https://github.com/fekide/volumerize/tree/master/backends/AmazonS3)

Dropbox: [Readme](https://github.com/fekide/volumerize/tree/master/backends/Dropbox)

Google Drive: [Readme](https://github.com/fekide/volumerize/tree/master/backends/GoogleDrive)

## Make It Short

You can make backups of your Docker application volume just by typing:

~~~~
$ docker run --rm \
    --name volumerize \
    -v yourvolume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    fekide/volumerize backup
~~~~

> Hooks up your volume with the name `yourvolume` and backups to the volume `backup_volume`

## How It Works

The container has a default startup mode. Any specific behavior is done by defining envrionment variables at container startup (`docker run`). The default container behavior is to start in daemon mode and do incremental daily backups.

Your application data must be saved inside a Docker volume. You can list your volumes with the Docker command `docker volume ls`. You have to attach the volume to the backup container using the `-v` option. Choose an arbitrary name for the folder and add the `:ro`option to make the sources read only.

Example using Jenkins:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     motionbank/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Now attach the Jenkins data to folders inside the container and tell fekide/volumerize to backup folder `/source` to folder `/backup`.

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    fekide/volumerize
~~~~

> Will start the Volumerizer. The volume jenkins_volume is now folder `/source` and backups_volume is now folder `/backup` inside the container.

You can execute commands inside the container, e.g. doing an immediate backup or even restore:

~~~~
$ docker exec volumerize backup
~~~~

> Will trigger a backup.

## Backup Multiple volumes

The container can backup one source folder, see environment variable `VOLUMERIZE_TARGET`. If you want to backup multiple volumes you will have to hook up multiple volumes under the same source folder.

Example:

* Volume: application_data
* Volume: application_database_data
* Volume: application_configuration

Now start the container hook them up under the same folder `source`.

~~~~
$ docker run -d \
    --name volumerize \
    -v application_data:/source/application_data:ro \
    -v application_database_data:/source/application_database_data:ro \
    -v application_configuration:/source/application_configuration:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    fekide/volumerize
~~~~

> Will run Volumerize on the common parent folder `/source`.

## Backup Restore

A restore is simple. First stop your Volumerize container and start a another container with the same
environment variables and the same volume but without read-only mode! This is important in order to get the same directory structure as when you did your backup!

Tip: Now add the read-only option to your backup container!

Example:

You did your backups with the following settings:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    fekide/volumerize
~~~~

Then stop the backup container and restore with the following command. The only difference is that we exclude the read-only option `:ro` from the source volume and added it to the backup volume:

~~~~
$ docker stop volumerize
$ docker run --rm \
    -v jenkins_volume:/source \
    -v backup_volume:/backup:ro \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    fekide/volumerize restore
$ docker start volumerize
~~~~

> Triggers a once time restore. The container for executing the restore command will be deleted afterwards

You can restore from a particular backup by adding a time parameter to the command `restore`. For example, using `restore -t 3D` at the end in the above command will restore a backup from 3 days ago. See [the Duplicity manual](http://duplicity.nongnu.org/duplicity.1.html#sect8) to view the accepted time formats.

To see the available backups, use the command `list` before doing a `restore`.

### Dry run

You can pass the `--dry-run` parameter to the restore command in order to test the restore functionality:

~~~~
$ docker run --rm \
    -v jenkins_volume:/source \
    -v backup_volume:/backup:ro \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    fekide/volumerize restore --dry-run
~~~~

But in order to see the differences between backup and source you need the verify command:

~~~~
$ docker run --rm \
    -v jenkins_volume:/source \
    -v backup_volume:/backup:ro \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    fekide/volumerize verify
~~~~

## Periodic Backups

The default cron setting for this container is: `0 0 4 * * *`. That's four o'clock in the morning UTC. You can set your own schedule with the environment variable `VOLUMERIZE_JOBBER_TIME`.

You can set the time zone with the environment variable `TZ`.

The syntax is different from cron because I use Jobber as a cron tool: [Jobber Time Strings](http://dshearer.github.io/jobber/doc/v1.1/#/time-strings)

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "TZ=Europe/Berlin" \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_JOBBER_TIME=0 0 3 * * *" \
    fekide/volumerize
~~~~

> Backups at three o'clock in the morning according to german local time.

## Docker Container Restarts

This image can stop and start Docker containers before and after backup. Docker containers are specified using the environment variable `VOLUMERIZE_CONTAINERS`. Just enter their names in a empty space separated list.

Example:

* Docker container application with name `application`
* Docker container application database with name `application_database`

Note: Needs the parameter `-v /var/run/docker.sock:/var/run/docker.sock` in order to be able to start and stop containers on the host.

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_CONTAINERS=application application_database" \
    fekide/volumerize
~~~~

> The startup routine will be applied to the following scripts: backup, backupFull, restore and periodBackup.

Test the routine!

~~~~
$ docker exec volumerize backup
~~~~

#### Additional Docker CLI API configurations
> If the docker host version is earlier than 1.12 then include the following docker api setting, Volumerize uses docker CLI ver 1.12 which uses Docker API version 1.24. One needs to set the compatible API version of the docker host 
ie. Docker host version 1.11 uses API 1.23

~~~~
docker version
Client:
 Version:      1.11.2
 API version:  1.23
 Go version:   go1.8
 Git commit:   5be46ee-synology
 Built:        Fri May 12 16:36:47 2017
 OS/Arch:      linux/amd64

Server:
 Version:      1.11.2
 API version:  1.23
 Go version:   go1.8
 Git commit:   5be46ee-synology
 Built:        Fri May 12 16:36:47 2017
 OS/Arch:      linux/amd64
~~~~
Then use  the following -e argument
~~~~
$ docker run -d \
    --name volumerize \
    -v /var/run/docker.sock:/var/run/docker.sock \
    ...
    ...
    -e "DOCKER_API_VERSION=1.23" \
    ...
    ...
    fekide/volumerize
~~~~
#### Additional Docker considerations
Warning: Make sure your container is running under the correct restart policy. Tools like Docker, Docker-Compose, Docker-Swarm, Kubernetes and Cattle may restart the container even when Volumerize stops it. Backups done under running instances may end in corrupted backups and even corrupted data. Always make sure that the command `docker stop` really stops an instance and there will be no restart of the underlying deployment technology. You can test this by running `docker stop` and check with `docker ps` that the container is really stopped.

## Duplicity Parameters

Under the hood fekide/volumerize uses duplicity. See here for duplicity command line options: [Duplicity CLI Options](http://duplicity.nongnu.org/duplicity.1.html#sect5)

You can pass duplicity options inside Volumerize. Duplicity options will be passed by the environment-variable `VOLUMERIZE_DUPLICITY_OPTIONS`. The options will be added to all fekide/volumerize commands and scripts. E.g. the option `--dry-run` will put the whole container in demo mode as all duplicity commands will only be simulated.

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_DUPLICITY_OPTIONS=--dry-run" \
    fekide/volumerize
~~~~

> Will only operate in dry-run simulation mode.

## Symmetric Backup Encryption

You can encrypt your backups by setting a secure passphrase inside the environment variable `PASSPHRASE`.

Creating a secure passphrase:

~~~~
$ docker run --rm fekide/volumerize openssl rand 128 -base64
~~~~

> Prints an appropriate password on the console.

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "PASSPHRASE=Jzwv1V83LHwtsbulVS7mMyijStBAs7Qr/V2MjuYtKg4KQVadRM" \
    fekide/volumerize
~~~~

> Same functionality as described above but all backups will be encrypted.

## Asymmetric Key-Based Backup Encryption

You can encrypt your backups with secure secret keys.

You need:

* A key, specified by the environment-variable `VOLUMERIZE_GPG_PRIVATE_KEY`
* A key passphrase, specified by the environment-variable `PASSPHRASE`

Creating a key? Install gpg on your comp and type:

~~~~
$ gpg2 --full-gen-key
Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048)
Requested keysize is 2048 bits   
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)
Key does not expire at all
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: YourName
Email address: yourname@youremail.com
Comment:                            
You selected this USER-ID:
    "YourName <yourname@youremail.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
$ gpg2 --export-secret-keys --armor yourname@youremail.com > MyKey.asc
~~~~

> Note: Currently, this image only supports keys without passwords. The import routine is at fault, it would always prompt for passwords.

You need to get the key id:
```shell
$ gpg -k yourname@youremail.com | head -n 2 | tail -n 1 | awk '{print $1}'
```

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -v $(pwd)/MyKey.asc:/key/MyKey.asc \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_GPG_PRIVATE_KEY=/key/MyKey.asc" \
    -e GPG_KEY_ID=<MyKeyID>
    -e "PASSPHRASE=" \
    fekide/volumerize
~~~~

> This will import a key without a password set.

Test the routine!

~~~~
$ docker exec volumerize backup
~~~~

## Enforcing Full Backups Periodically

The default behavior is that the initial backup is a full backup. Afterwards, Volumerize will perform incremental backups. You can enforce another full backup periodically by specifying the environment variable `VOLUMERIZE_FULL_IF_OLDER_THAN`.

The format is a number followed by one of the characters s, m, h, D, W, M, or Y. (indicating seconds, minutes, hours, days, weeks, months, or years)

Examples:

* After three Days: 3D
* After one month: 1M
* After 55 minutes: 55m

Volumerize Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "TZ=Europe/Berlin" \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_FULL_IF_OLDER_THAN=7D" \
    fekide/volumerize
~~~~

> Will enforce a full backup after seven days.

For the difference between a full and incremental backup, see [Duplicity's documentation](http://duplicity.nongnu.org/duplicity.1.html).

## Automatically remove old backups
> **Use with caution!**

The removal is executed as post-strategy. The following options are available:

* `REMOVE_ALL_BUT_N_FULL`: remove all backups except the latest n full backups
* `REMOVE_ALL_INC_BUT_N_FULL`: remove all incremental backups except the one from the latest n chains
* `REMOVE_OLDER_THAN`: remove all backups older than [timestamp](http://duplicity.nongnu.org/vers8/duplicity.1.html#sect8)

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "TZ=Europe/Berlin" \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "REMOVE_OLDER_THAN=30D" \
    fekide/volumerize
~~~~

## Post scripts and pre scripts (prepost strategies)


Pre-scripts must be located at `/preexecute/$duplicity_action/$your_scripts_here`.

Post-scripts must be located at `/postexecute/$duplicity_action/$your_scripts_here`.

`$duplicity_action` can be one of `backup`, `restore`, `verify`, `remove` or `replicate`.

> Note: `backup` action is the same for the scripts `backup`, `backupFull`, `backupIncremental` and `periodicBackup`.

All `.sh` files located in the `$duplicity_action` folder will be executed in alphabetical order.

When using prepost strategies, this will be the execution flow: `pre-scripts -> stop containers -> duplicity action -> start containers -> post-scripts`.

### Additional variables for prepost-scripts

The following vairables are additionally available in pre and post scripts:

-  `JOB_ID`: The id of the current job executed (only if [multiple sources](#backup-multiple-volumes) are specified)
-  `VOLUMERIZE_COMMAND`: the exact command that was executed (may be used for further filtering)

### Provided PrePost-Strategies
Some premade strategies are available at [prepost strategies](prepost_strategies). These are

- [mongodb](prepost_strategies/mongodb/README.md)
- [mysql](prepost_strategies/mysql/README.md)


## Container Scripts

This image creates at container startup some convenience scripts.
Under the hood fekide/volumerize uses duplicity. To pass script parameters, see here for duplicity command line options: [Duplicity CLI Options](http://duplicity.nongnu.org/duplicity.1.html#sect5)

| Script                         | Description                                                                              |
| ------------------------------ | ---------------------------------------------------------------------------------------- |
| `backup`                       | Creates an backup with the containers configuration                                      |
| `periodicBackup`               | Script that will be triggered by the periodic schedule, identical to `backup`            |
| `backupFull`                   | Creates a full backup with the containers configuration                                  |
| `backupIncremental`            | Creates an incremental backup with the containers configuration                          |
| `list`                         | List all available backups                                                               |
| `verify`                       | Compare the latest backup to your local files                                            |
| `restore`                      | Be Careful! Triggers an immediate force restore with the latest backup                   |
| `startContainers`              | Starts the specified Docker containers                                                   |
| `stopContainers`               | Stops the specified Docker containers                                                    |
| `remove-all-but-n-full`        | Delete all chains except n full backups                                                  |
| `remove-all-inc-of-but-n-full` | Delete all incremental backups except for the last n full backups                        |
| `remove-older-than`            | Delete older backups ([Time formats](http://duplicity.nongnu.org/duplicity.1.html#toc8)) |
| `cleanCacheLocks`              | Cleanup of old Cache locks.                                                              |

Example triggering script inside running container:

~~~~
$ docker exec volumerize backup
~~~~

> Executes script `backup` inside container with name `volumerize`

Example passing script parameter:

~~~~
$ docker exec volumerize backup --dry-run
~~~~

> `--dry-run` will simulate not execute the backup procedure.

## Customize Jobber

If you want to customize jobber more with different sinks or other commands, you should write your own job file and mount it at `/root/.jobber`. More information on how to write jobber configurations can be found [here](https://dshearer.github.io/jobber/doc/v1.4/#jobfile). For example the file generated by the automated scripts could look like this:

```yml
version: 1.4

resultSinks:
  - &stdoutSink
    type: stdout
    data:
      - stdout
      - stderr

prefs:
  runLog:
    type: file
    path: /var/log/jobber-runs
    maxFileLen: 100m
    maxHistories: 2

jobs:

  VolumerizeBackupJob1:
    cmd: /etc/volumerize/periodicBackup 1
    time: '0 0 3 * * *'
    onError: Continue
    notifyOnError: 
      - *stdoutSink
    notifyOnFailure: 
      - *stdoutSink

  VolumerizeBackupJob2:
    cmd: /etc/volumerize/periodicBackup 2
    time: '0 0 3 * * *'
    onError: Continue
    notifyOnError: 
      - *stdoutSink
    notifyOnFailure: 
      - *stdoutSink
```

## Multiple Backups

You can specify multiple backup jobs with one container with enumerated environment variables. Each environment variable must be followed by a number starting with 1. Example `VOLUMERIZE_SOURCE1`, `VOLUMERIZE_SOURCE2` or `VOLUMERIZE_SOURCE3`. If a number is skipped, only the variables before the skipped one are considered

The following environment variables can be enumerated:

* `VOLUMERIZE_SOURCE<JOB_ID>`
* `VOLUMERIZE_TARGET<JOB_ID>`
* `VOLUMERIZE_REPLICATE_TARGET<JOB_ID>`
* `VOLUMERIZE_CACHE<JOB_ID>`
* `VOLUMERIZE_INCLUDE<JOB_ID>_<INLCLUDE_ID>`
* `VOLUMERIZE_EXCLUDE<JOB_ID>_<EXCLUDE_ID>`
* `VOLUMERIZE_JOBBER_TIME<JOB_ID>`
* `JOBBER_NOTIFY_ERR<JOB_ID>`
* `JOBBER_NOTIFY_FAIL<JOB_ID>`

When using multiple backup jobs you do not necessarily need to specify a cache directory for each backup. By default `<VOLUMERIZE_CACHE>/<JOB_ID>` is used. The minimum required environment variables for each job is:

* `VOLUMERIZE_SOURCE<JOB_ID>`
* `VOLUMERIZE_TARGET<JOB_ID>`

Also the included helper scripts will change their behavior when you use enumerated environment variables. By default each script will run on all backup jobs.

Example: Executing the script `backup` will backup all jobs.

The first parameter of each script can be a job number, e.g. `1`, `2` or `3`.

Example: Executing the script `backup 1` will only trigger backup on job 1.

Full example for multiple job specifications:

~~~~
$ docker run -d \
    --name volumerize \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v jenkins_volume:/source:ro \
    -v jenkins_volume2:/source2:ro \
    -v backup_volume:/backup \
    -v backup_volume2:/backup2 \
    -v cache_volume:/volumerize-cache \
    -v cache_volume2:/volumerize-cache2 \
    -e "VOLUMERIZE_CONTAINERS=jenkins jenkins2" \
    -e "VOLUMERIZE_SOURCE1=/source" \
    -e "VOLUMERIZE_TARGET1=file:///backup" \
    -e "VOLUMERIZE_CACHE1=/volumerize-cache" \
    -e "VOLUMERIZE_SOURCE2=/source2" \
    -e "VOLUMERIZE_TARGET2=file:///backup2" \
    -e "VOLUMERIZE_CACHE2=/volumerize-cache2" \
    fekide/volumerize
~~~~

## Docker Secrets

The following variables are supported to be stored in files, the location specified in variables ending with `_FILE`. See [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/) for more info.

- `VOLUMERIZE_GPG_PRIVATE_KEY`
- `PASSPHRASE`
- `GOOGLE_DRIVE_SECRET`
- `VOLUMERIZE_TARGET`
- `VOLUMERIZE_REPLICATE`

## All Environment Variables

| Name                              | Use                                                                                                                      | Default                |
| :-------------------------------- | :----------------------------------------------------------------------------------------------------------------------- | :--------------------- |
| `DEBUG`                           | Enable shell debug output                                                                                                | `false`                |
| `VOLUMERIZE_SOURCE`               | Source directory of a job                                                                                                | required               |
| `VOLUMERIZE_CACHE`                | Cache directory for the backup job                                                                                       |                        |
| `VOLUMERIZE_TARGET`               | Target url for the backup                                                                                                | required               |
| `VOLUMERIZE_JOBBER_TIME`          | Timer for job execution                                                                                                  | `0 0 4 * * *`          |
| `VOLUMERIZE_REPLICATE`            | Replicate after a finished backup                                                                                        | `false`                |
| `VOLUMERIZE_REPLICATE_TARGET`     | Target url for a replication                                                                                             |                        |
| `VOLUMERIZE_CONTAINERS`           | Containers to stop before and start after backup (space separated)                                                       |                        |
| `VOLUMERIZE_DUPLICITY_OPTIONS`    | custom options for duplicity                                                                                             |                        |
| `VOLUMERIZE_FULL_IF_OLDER_THAN`   | Execute full backup if last full backup is older than the specified time                                                 |                        |
| `VOLUMERIZE_ASYNCHRONOUS_UPLOAD`  | (EXPERIMENTAL) upload while already creating the next volume(s)                                                          | `false`                |
| `VOLUMERIZE_INCLUDE_<INCLUDE_ID>` | Includes for the backup                                                                                                  |                        |
| `VOLUMERIZE_EXCLUDE_<INCLUDE_ID>` | Includes for the backup                                                                                                  |                        |
| `REMOVE_ALL_BUT_N_FULL`           | Remove all but n full backups after finished backup                                                                      |                        |
| `REMOVE_ALL_INC_BUT_N_FULL`       | Remove all incremental backups ecxept for the last n full backups after finished backup                                  |                        |
| `REMOVE_OLDER_THAN`               | Remove backups older than time given after finished backup job                                                           |                        |
| `VOLUMERIZE_GPG_PRIVATE_KEY`      | Private Key for GPG Encryption                                                                                           |                        |
| `PASSPHRASE`                      | Passphrase for GPG Private Key                                                                                           |                        |
| `VOLUMERIZE_GPG_PUBLIC_KEY`       | Public Key for GPG Encryption                                                                                            |                        |
| `VOLUMERIZE_DELAYED_START`        | Start Volumerize delayed by given time (`sleep` command)                                                                 | `0`                    |
| `JOBBER_NOTIFY_ERR`               | result sink for job errors                                                                                               | `\n     - *stdoutSink` |
| `JOBBER_NOTIFY_FAIL`              | result sink for job failures                                                                                             | `\n     - *stdoutSink` |
| `JOBBER_CUSTOM`                   | Specify a custom jobber file file location. You need to bind mount a file to this location or use docker configs/secrets |                        |
| `JOBBER_DISABLE`                  | Disable Jobber for the root user (It will still run but without jobs)                                                    | `false`                |
| `GOOGLE_DRIVE_ID`                 | ID for google drive                                                                                                      |                        |
| `GOOGLE_DRIVE_SECRET`             | secret for google drive                                                                                                  |                        |

## Build the Image

~~~~
$ docker build -t fekide/volumerize .
~~~~

## Run the Image

~~~~
$ docker run -it --rm fekide/volumerize bash
~~~~
