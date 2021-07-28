# play


![image](https://user-images.githubusercontent.com/33985509/126865156-e3620833-b27a-41fa-934c-ff8d7aedb413.png)


![image](https://user-images.githubusercontent.com/33985509/126865147-68d50d07-6ca8-4c53-b3ca-4258f7a0255a.png)



## Errors

~~~

[play] $ ansible-playbook ansible/elk.yaml -i ansible/hosts.ini -f 5
[WARNING]: Unable to parse /var/lib/jenkins/workspace/play/ansible/hosts.ini as
an inventory source
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that
the implicit localhost does not match 'all'
[WARNING]: Could not match supplied host pattern, ignoring: allservers


sol :

[localhost]
52.171.37.226



TASK [elasticsearch : Create elastic search volume] ****************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": "Failed to import the required Python library (Docker SDK for Python: docker (Python >= 2.7) or docker-py (Python 2.6)) on a's Python /usr/bin/python3. Please read module documentation and install in the appropriate location. If the required library is installed, but Ansible is using the wrong Python interpreter, please consult the documentation on ansible_python_interpreter, for example via `pip install docker` or `pip install docker-py` (Python 2.6). The error was: No module named 'docker'"}

sol : pip install docker-py



Error connecting: Error while fetching server API version: ('Connection aborted.', PermissionError(13, 'Permission denied'))

sol: https://stackoverflow.com/questions/42211380/add-insecure-registry-to-docker

DOCKER_OPTS="--insecure-registry=13.65.213.184 --insecure-registry=52.171.37.226"

chmod 666 /var/run/docker.sock

sudo systemctl daemon-reload

sudo systemctl restart docker
~~~

