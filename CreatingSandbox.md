# Creating a Sandbox for the Redsift Platform


Redsift provides a polyglot stream prossecing platform, that follows a Directed Acyclic Graph (DAG) model. The DAG is compossed of independent processing units or **nodes**. Nodes can be implemented in a number of languages, thus the polyglot aspect. To support that functionality we use Docker to provide the necessary environment for each language, essentially a sandbox. So, its language has its onw sandbox. A sandbox can also be created when specialized packages are needed e.g. libraries for NLP processing.

## Init

The `Init` class is responsible for two things. Checking for the required environment variables and loading and parsing the **sift.json**. The required variables are:

- `SIFT_ROOT` path to the root folder of the sift. This is where the sift contents will be mounted into the container. Always set to **/run/sandbox/sift**

- `SIFT_JSON` the name of the sift.json file, usually sift.json but the SDK overrides this and supplies a rewrite of the original sift.json file. Default set to **sift.json**

- `IPC_ROOT` the root folder where nanomsg IPC sockets will be created for communication between sandbox and dagger/grip outside. This is only needed if you use io.redsift.sandbox.rpc=nanomsg. Always set to **/run/sandbox/ipc**


## Required Models

- `ComputeRequest` [schema](https://github.com/redsift/sandbox/blob/master/schemas/computeRequest.json) A node will receive a dictionary with `in`, `with` and `lookup` keys. The `value` emitted above will always come back as a byte array (Buffer in JavaScript, bytes in Python, etc.). You will then need to convert this back to the right representation you need. In general it is recommended you work with byte array where possible, since this will be guaranteed to be supported by every language sandbox.

- `ComputeResponse` [schema](https://github.com/redsift/sandbox/blob/master/schemas/computeResponse.json) A node can only return the following:
  - A dictionary with ‘name’, ‘key’, ‘value’ and an optional ‘epoch’. name is the name of the bucket, key has to be a string and value can only be one of the following:
    - JSON serialisable object (dictionary or array)
    - string
    - byte array (Buffer in JavaScript, bytes in Python, etc.)
  - An array of containing the above mentioned dictionary
  - null value (null in JavaScript, None in Python, etc.)


- JMAP related models: `Message`, `Emailer`, `Attachment` [schema](https://github.com/redsift/sandbox/blob/master/schemas/jmapMessage.json)


## Protocol

The `Protocol` class is the interface between nodes and nanomsg sockets, handling the decoding and encoding of messages. The required methods have the following signatures:

```
// decode incoming message to the node
fromEncodedMessage(byte[] bytes) -> ComputeRequest

// encode outgoing message(ComputeResponse, ComputeResponse[] OR null) from the node
toEncodedMessage(Object data, double[] diff) -> byte[]

// encode errors the node might throw
toErrorBytes(String message, String stack) -> byte[] 

// utility method to encode value of ComputeResponse as byte[] as per convention
encodeValue(ComputeResponse data) -> ComputeResponse
```

## Install

The installation script takes in as arguments a list of nodes to install. Iterates over the nodes with an `implementation` field and does the right install for the relevant language (npm install for JavaScript, pip install for Python, etc.)

## Run

The run script takes in as arguments a list of the nodes to run and then sets up nanomsg IPC sockets for communication between the node and dagger/grip. It should the methods defined in `Protocol` class above to encode and decode messages.

## Dockerfile Notes

- Required Docker labels:
  - `io.redsift.sandbox.install` label pointing to the installation script
  - `io.redsift.sandbox.run` label pointing to the run script
- The sandbox will run as user sandbox (group sandbox) with uid & gid 7438. Please ensure that you have set the right permissions for all the folders necessary during your sandbox creation. Your continuous integration script should have something similar to the following to test you have set the correct permissions in your sandbox. Here we are creating the required user, picking the location  of the *run* script from the label we defined above and trying to run it as user *7438*.

```
SV=sanbox_image_name
set -e
sudo groupadd -g 7438 sandbox
sudo adduser --system --no-create-home --shell /bin/false -u 7438 -gid 7438 sandbox
sudo chown -R sandbox:sandbox ${PWD}
RUN=$(docker inspect -f "{{index .Config.Labels \"io.redsift.sandbox.run\" }}" $SV)
echo "Calling init = $RUN"
docker run -u 7438:7438 -v $PWD/sift:/run/sandbox/sift $SV $RUN 0 1 2
```
- `WORKDIR = /run/sandbox/sift`
- `ENTRYPOINT = ["/bin/bash"]`
- Containers can be found at `https://quay.io/repository/redsift/sandbox-<LANGUAGE>?tab=tags` where LANGUAGE any of {javascript, python, java, scala, closure, julia, swift}
  
