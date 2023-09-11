# Anchore Engine to Enterprise Helm Chart Value File Converter

This script converts the values file of Anchore Engine to the values file format suitable for the Anchore Enterprise Helm chart.

## Prerequisites

- Docker: Make sure you have Docker installed on your machine.

## Usage

1. **The Docker Image**:
    To build the docker image yourself, from the `scripts` directory, build the Docker image using the following command:

    ```bash
    docker build -t script-container .
    ```

    Alternatively, a docker image is available at `docker.io/anchore/enterprise-helm-migrator:latest`

2. **Run the Docker Container**:

    Run the Docker container with the following command. Change the name of the file as needed:

    ```bash
    export VALUES_FILE_NAME=my-values-file.yaml
    docker run -v ${PWD}:/tmp -v ${PWD}/${VALUES_FILE_NAME}:/app/${VALUES_FILE_NAME} docker.io/anchore/enterprise-helm-migrator:latest -e /app/${VALUES_FILE_NAME} -d /tmp/output
    ```

    This command mounts a local volume to store the output files and mounts the input file to be converted, and passes it using the `-e` flag.

3. **Retrieve Output**:

    After running the Docker container, the converted Helm chart values file will be available in the `${PWD}/output` directory on your local machine.

## Important Note

Please ensure that you have reviewed and understood the content of the input file before running the conversion. The script provided is specifically tailored to convert Anchore Engine values files to the format expected by the Anchore Enterprise Helm chart.

## Disclaimer

This script is provided as-is and is intended to help reduce the friction of converting from anchore-engine to enterprise. It is your responsibility to ensure that any modifications or usage of the script align with your requirements and best practices.

For any issues or suggestions related to the script or Docker image, feel free to create an issue or pull request in this repository.
