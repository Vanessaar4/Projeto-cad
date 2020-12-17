# Docker Compose 

Repository with the necessary settings to enable [Percona Server for MongoDB](https://www.percona.com/doc/percona-server-for-mongodb/LATEST/index.html) encryption at rest integrated with [Vault Hashicorp](https://www.vaultproject.io/docs/).

## Prerequisites

- Docker Engine 18.06.0+

  - **Linux:** Follow all the steps present in the [official documentation](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce)
  
- Docker Compose 1.22.0+
  -  Follow all the steps present in the [official documentation](https://docs.docker.com/compose/install/)

## Building and Deploying the containers

```sh
docker-compose up -d
 ```

It will build the containers and run the platform as specified in the file `docker-compose.yml`, opening a log screen with the logs of all the services started. 

## Stopping the execution

If you are still in the log screen press `Ctrl + C` just one time for graceful stop, two times to force stop

To stop all containers created by docker-compose, you need to go to the folder where docker-compose.yml is and run:
```sh
docker-compose down
 ```

To stop just one container:

```ssh
docker stop my_container
 ```

## Configuring Percona Server for MongoDB

1. Once the Vault Hashicorp is started, execute the following command to access the token that will be used in Percona Server for MongoDB settings:
    ```ssh
    docker exec -ti cad-vault sh -c 'cat ~/infra_tokens'
     ```

2. Copy the token to the `config/mongodb/psmdb-tokenFile` file and set the file permission to `600`;

3. Restart the Percona MongoDB service:

    ```ssh
    docker-compose restart psmdb
     ```
## Other useful commands

Restarts Docker. Useful in critical situations:

```sh
sudo service docker restart
 ``` 

Check all containers and its status:

```sh
docker container ls
 ```

Enter in the shell or bash of a particular container:

```sh
docker exec -it container_id /bin/bash
 ```

Stop all containers:

```sh
docker stop $(docker ps -a -q)
 ```

Delete all containers:

```sh
docker rm -f $(docker ps -a -q)
 ``` 
 
Delete all volumes:

```sh
docker volume rm $(docker volume ls -q)
```

Delete all container images:

```sh
docker rmi -f $(sudo docker images -q)
```
