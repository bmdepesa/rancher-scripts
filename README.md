# rancher-scripts
Some general purpose, some specific to Rancher

## Setup
* Clone project
* Set the scripts to be executable: `chmod -R +x rancher-scripts/`
* (Optional) add the `rancher-scripts/` directory to your PATH

### runOnHosts.sh

Run a local script on multiple remote hosts. Use `-q` flag to hide output from remote host.

For example:
Using a script `install_docker.sh`

```bash
#!/bin/bash
curl https://releases.rancher.com/install-docker/17.03.sh | sh
```

With a file containing hosts:
* ./runOnHosts.sh -f \<file containing hosts\> -s \<script to run\>
* `./runOnHosts.sh -f hosts.txt -s install_docker.sh`

With a string of hosts:
* ./runOnHosts.sh -h \<string containing hosts\> -s \<script to run\>
* `./runOnHosts.sh -h "138.140.2.8 138.141.2.6" -s install_docker.sh`

With a script that takes arguments:
* ./runOnHosts.sh -h \<string containing hosts\> -s "\<script to run\> arg0 arg1"
* ./runOnHosts.sh -h "138.10.2.8" -s "installRancherAIO.sh v2.0.8"

### installRancherAIO.sh

Installs Docker, and then Rancher with the specified Rancher server version.

Takes the tag of the Rancher version as an argument.

### installRancherNoDocker.sh

Installs Rancher with the specified Rancher server version.

Takes the tag of the Rancher version as an argument.

### installDocker.sh

Installs Docker on the host.
