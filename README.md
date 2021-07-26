# play


![image](https://user-images.githubusercontent.com/33985509/126865156-e3620833-b27a-41fa-934c-ff8d7aedb413.png)


![image](https://user-images.githubusercontent.com/33985509/126865147-68d50d07-6ca8-4c53-b3ca-4258f7a0255a.png)




------------------------------------------------------------------------------------------------------------------------------------------------------------

create instance in azure ubuntu 18

### Docker
~~~

sudo apt update
sudo apt upgrade
sudo apt-get install curl apt-transport-https ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce
~~~

### ansible

~~~
apt-get install python-pip python-dev
apt install python3-pip
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt-get install ansible -y

~~~

### Specific version

~~~
sudo add-apt-repository --update ppa:ansible/ansible-2.9.7
sudo apt install ansible

or 

sudo apt-get install python-pip python-dev
sudo -H pip install ansible==2.9.7
~~~


### jenkins

~~~
sudo apt update	
sudo apt install openjdk-8-jdk -y
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl status jenkins

~~~


![image](https://user-images.githubusercontent.com/33985509/127038871-eb1d3376-c800-439b-8659-aadc9424b365.png)
