#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt install openjdk-11-jdk -y
cd /opt
sudo wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.107/bin/apache-tomcat-9.0.107.tar.gz
sudo tar -xvzf apache-tomcat-9.0.107.tar.gz
sudo mv apache-tomcat-9.0.107 tomcat9
sudo su 
sudo chmod +x /opt/tomcat9/bin/*.sh
sudo sed -i '/<\/tomcat-users>/i \
  <role rolename="manager-gui"/>\n  <user username="admin" password="admin123" roles="manager-gui"/>' /opt/tomcat9/conf/tomcat-users.xml
sudo sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' /opt/tomcat9/webapps/manager/META-INF/context.xml  
sudo ufw allow from any to any port 8080 proto tcp
sudo apt install unzip curl -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo usermod -aG tomcat $USER
sudo ./aws/install
cd /opt/tomcat9/webapps
rm -rf ROOT
aws s3 cp s3://${bucket_name}/artifact/vprofile-v2.war /tmp/vprofile-v2.war
cp /tmp/vprofile-v2.war /opt/tomcat9/webapps/ROOT.war
cd /opt/tomcat9/bin/
./startup.sh
