This is script-based Hadoop YARN installation for Ubuntu cluster. Original scripts are  from Book: Apache Hadoop Yarn chapter5.

Before you use these scripts:
1. install pdsh & psd-less ssh connection between nodes 
2. install java(Oracle) on ubuntu
3. according to your hadoop version, change the HADOOP_VERSION in install-hadoop2.sh
4. install libxml-utils for parsing/generating XMLs
5. on all nodes, set your account sudoer without typing password(in /etc/sudoers  NOPASSWD:ALL)
6. permit write permission on /etc/init.d and /etc/profile.d/ etc.
7. .....can't remember all of them. will post all inofrmation in my blog later


Feel free to contact via email.

Cheers,
Steven
