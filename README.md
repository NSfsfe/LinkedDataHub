# The Knowledge Graph management system

_LinkedDataHub_ (LDH) is open source software you can use to manage data, create visualizations and build apps on RDF Knowledge Graphs.

LDH features a completely data-driven application architecture: generic server and client components process declarative RDF/OWL, SPARQL, and XSLT instructions.
The default application structure and user interface are provided, making LDH a standalone product, yet they can be completely overridden and customized, thus also making LDH a [low-code application platform](https://en.wikipedia.org/wiki/Low-code_development_platform). Unless a custom processing is required, no imperative code such as Java or JavaScript needs to be involved at all.

## Getting started

1. [Install Docker](https://docs.docker.com/install/)
   - [Install Docker Compose](https://docs.docker.com/compose/install/), if it is not already included in the Docker installation
2. Checkout this repository into a folder
3. In the folder, create an `.env` file and fill out the missing values (you can use [`.env_sample`](https://github.com/AtomGraph/LinkedDataHub/blob/master/.env_sample) as a template). For example:
```
COMPOSE_CONVERT_WINDOWS_PATHS=1
COMPOSE_PROJECT_NAME=linkeddatahub

BASE_URI=https://localhost:4443/

OWNER_MBOX=john@doe.com
OWNER_GIVEN_NAME=John
OWNER_FAMILY_NAME=Doe
OWNER_ORG_UNIT=My unit
OWNER_ORGANIZATION=My org
OWNER_LOCALITY=Copenhagen
OWNER_STATE_OR_PROVINCE=Denmark
OWNER_COUNTRY_NAME=DK
OWNER_KEY_PASSWORD=changeit
```
4. Run this from command line:
```
docker-compose up
```
5. LinkedDataHub will start and create the following sub-folders:
   - `certs` where your WebID certificates are stored
   - `data` where the triplestore(s) will persist RDF data
   - `uploads` where LDH stores content-hashed file uploads
6. Install `certs/owner.p12` into a web browser of your choice (password is the `OWNER_KEY_PASSWORD` value)
   - Google Chrome: `Settings > Advanced > Manage Certificates > Import...`
   - Mozilla Firefox: `Options > Privacy > Security > View Certificates... > Import...`
   - Apple Safari: The file is installed directly into the operating system. Open the file and import it using the [Keychain Access](https://support.apple.com/guide/keychain-access/what-is-keychain-access-kyca1083/mac) tool.
   - Microsoft Edge: Does not support certificate management, you need to install the file into Windows. [Read more here](https://social.technet.microsoft.com/Forums/en-US/18301fff-0467-4e41-8dee-4e44823ed5bf/microsoft-edge-browser-and-ssl-certificates?forum=win10itprogeneral).
7. Open **https://localhost:4443/** in that web browser

After a successful startup, the last line of the Docker log should read:

    linkeddatahub_1    | 02-Feb-2020 02:02:20.200 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in 3420 ms

Notes:
* You will likely get a browser warning such as `Your connection is not private` in Chrome or `Warning: Potential Security Risk Ahead` in Firefox due to the self-signed server certificate. Ignore it: click `Advanced` and `Proceed` or `Accept the risk` to proceed.
* `.env_sample` and `.env` files might be invisible in MacOS Finder which hides filenames starting with a dot. You should be able to [create it using Terminal](https://stackoverflow.com/questions/5891365/mac-os-x-doesnt-allow-to-name-files-starting-with-a-dot-how-do-i-name-the-hta) however.
* You may need to run the commands as `sudo` or be in the `docker` group.

## [Documentation](https://linkeddatahub.com/linkeddatahub/docs/)

## Demo applications

*TBD*