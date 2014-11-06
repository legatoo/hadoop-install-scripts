#!/bin/bash
# Install Hadoop 2 using pdsh/pdcp where possible.
# 
# Command can be interactive or file-based.  This script sets up
# a Hadoop 2 cluster with basic configuration.  Modify data, log, and pid
# directories as desired.  Further configure your cluster with ./conf-hadoop2.sh
# after running this installation script.
#

# Basic environment variables.  Edit as necessary
HADOOP_VERSION=2.5.1
HADOOP_HOME="/opt/hadoop-${HADOOP_VERSION}"
NN_DATA_DIR=/var/data/hadoop/hdfs/nn
SNN_DATA_DIR=/var/data/hadoop/hdfs/snn
DN_DATA_DIR=/var/data/hadoop/hdfs/dn
YARN_LOG_DIR=/var/log/hadoop/yarn
HADOOP_LOG_DIR=/var/log/hadoop/hdfs
HADOOP_MAPRED_LOG_DIR=/var/log/hadoop/mapred
YARN_PID_DIR=/var/run/hadoop/yarn
HADOOP_PID_DIR=/var/run/hadoop/hdfs
HADOOP_MAPRED_PID_DIR=/var/run/hadoop/mapred
LOCK_DIR=/var/lock/subsys
HTTP_STATIC_USER=ynuser
YARN_PROXY_PORT=8081
# If using local OpenJDK, it must be installed on all nodes.
# If using jdk-6u31-linux-x64-rpm.bin, then
# set JAVA_HOME="" and place jdk-6u31-linux-x64-rpm.bin in this directory
#
#using command below to install oracle java7 se on ubuntu
#sudo add-apt-repository ppa:webupd8team/java
#sudo apt-get update
#sudo apt-get install oracle-java7-installer


JAVA_HOME=/usr/lib/jvm/java-7-oracle/

source ./hadoop-xml-conf.sh
CMD_OPTIONS=$(getopt -n "$0"  -o hif --long "help,interactive,file"  -- "$@")
HADOOP_CONF_DIR=/etc/hadoop
# Take care of bad options in the command
if [ $? -ne 0 ];
then
  exit 1
fi
eval set -- "$CMD_OPTIONS"

all_hosts="all_hosts"
nn_host="nn_host"
snn_host="snn_host"
dn_hosts="dn_hosts"
rm_host="rm_host"
nm_hosts="nm_hosts"
mr_history_host="mr_history_host"
yarn_proxy_host="yarn_proxy_host"

install()
{
	
	if [ ! -f /opt/hadoop-"$HADOOP_VERSION".tar.gz ]; then
		echo "Copying Hadoop $HADOOP_VERSION to all hosts..."
		pdcp -a hadoop-"$HADOOP_VERSION".tar.gz /opt
	fi
if [ -z "$JAVA_HOME" ]; then
	echo "Copying JDK 1.6.0_31 to all hosts..."
	pdcp -a jdk-6u31-linux-x64-rpm.bin /opt

	echo "Installing JDK 1.6.0_31 on all hosts..."
	pdsh -a chmod a+x /opt/jdk-6u31-linux-x64-rpm.bin
	pdsh -a /opt/jdk-6u31-linux-x64-rpm.bin -noregister 1>&- 2>&-
	JAVA_HOME=/usr/java/jdk1.6.0_31
fi
	echo "Setting JAVA_HOME and HADOOP_HOME environment variables on all hosts..."
#	pdsh -a "sudo echo 'export JAVA_HOME=$JAVA_HOME' >> /etc/profile"
#	pdsh -a "source /etc/profile.d/java.sh"
#	pdsh -a "sudo echo 'export HADOOP_HOME=$HADOOP_HOME' >> /etc/profile"
#	pdsh -a "sudo echo 'export HADOOP_PREFIX=$HADOOP_HOME' >> /etc/profile"
#	pdsh -a "source /etc/profile"
#	pdsh -a "source /etc/profile.d/hadoop.sh"

	# the write permission for /etc/profile.d/ is 755 (default)
	#notice here single quote is used, so $JAVA_HOME will not be expended
	pdsh -a  echo "export JAVA_HOME=$JAVA_HOME > /etc/profile.d/java.sh"

        pdsh -a  "source /etc/profile.d/java.sh"
        pdsh -a  echo "export HADOOP_HOME=$HADOOP_HOME > /etc/profile.d/hadoop.sh"
        pdsh -a  echo "export HADOOP_PREFIX=$HADOOP_HOME >> /etc/profile.d/hadoop.sh"
        pdsh -a  "source /etc/profile.d/hadoop.sh"
	pdsh -a echo "export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin >> /etc/profile"
	#pdsh -a echo "export JAVA_HOME=$JAVA_HOME >> /etc/profile"
	source /etc/profile.d/hadoop.sh
	source /etc/profile.d/java.sh
	source /etc/profile
	pdsh -a "source /etc/profile"
	pdsh -a  "echo $JAVA_HOME"

	echo "Extracting Hadoop $HADOOP_VERSION distribution on all hosts..."
	pdsh -a tar -zxf /opt/hadoop-"$HADOOP_VERSION".tar.gz -C /opt

	#in my system, ynuser the only yarn user.
#	echo "Creating system accounts and groups on all hosts..."
#	pdsh -a "sudo groupadd hadoop"
#	pdsh -a "sudo useradd -g hadoop yarn"
#	pdsh -a "sudo useradd -g hadoop hdfs"
#	pdsh -a "sudo useradd -g hadoop mapred"

	echo "Creating HDFS data directories on NameNode host, Secondary NameNode host, and DataNode hosts..."
	pdsh -w ^nn_host "sudo mkdir -p $NN_DATA_DIR && sudo chown ynuser:yarn $NN_DATA_DIR"
	pdsh -w ^snn_host "sudo mkdir -p $SNN_DATA_DIR && sudo chown ynuser:yarn $SNN_DATA_DIR"
	pdsh -w ^dn_hosts "sudo mkdir -p $DN_DATA_DIR && sudo chown ynuser:yarn $DN_DATA_DIR"

	echo "Creating log directories on all hosts..."
	pdsh -a "sudo mkdir -p $YARN_LOG_DIR && sudo chown ynuser:yarn $YARN_LOG_DIR"
	pdsh -a "sudo mkdir -p $HADOOP_LOG_DIR && sudo chown ynuser:yarn $HADOOP_LOG_DIR"
	pdsh -a "sudo mkdir -p $HADOOP_MAPRED_LOG_DIR && sudo chown ynuser:yarn $HADOOP_MAPRED_LOG_DIR"

	echo "Creating pid directories on all hosts..."
	pdsh -a "sudo mkdir -p $YARN_PID_DIR && sudo chown ynuser:yarn $YARN_PID_DIR"
	pdsh -a "sudo mkdir -p $HADOOP_PID_DIR && sudo chown ynuser:yarn $HADOOP_PID_DIR"
	pdsh -a "sudo mkdir -p $HADOOP_MAPRED_PID_DIR && sudo chown ynuser:yarn $HADOOP_MAPRED_PID_DIR"

	echo "Editing Hadoop environment scripts for log directories on all hosts..."
	pdsh -a echo "export HADOOP_LOG_DIR=$HADOOP_LOG_DIR >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
	pdsh -a echo "export YARN_LOG_DIR=$YARN_LOG_DIR >> $HADOOP_HOME/etc/hadoop/yarn-env.sh"
	pdsh -a echo "export HADOOP_MAPRED_LOG_DIR=$HADOOP_MAPRED_LOG_DIR >> $HADOOP_HOME/etc/hadoop/mapred-env.sh"

	echo "Editing Hadoop environment scripts for pid directories on all hosts..."
	pdsh -a echo "export HADOOP_PID_DIR=$HADOOP_PID_DIR >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
	pdsh -a echo "export YARN_PID_DIR=$YARN_PID_DIR >> $HADOOP_HOME/etc/hadoop/yarn-env.sh"
	pdsh -a echo "export HADOOP_MAPRED_PID_DIR=$HADOOP_MAPRED_PID_DIR >> $HADOOP_HOME/etc/hadoop/mapred-env.sh"

	echo "Creating base Hadoop XML config files..."
	create_config --file core-site.xml
	put_config --file core-site.xml --property fs.default.name --value "hdfs://$nn:9000"
	put_config --file core-site.xml --property hadoop.http.staticuser.user --value "$HTTP_STATIC_USER"

	create_config --file hdfs-site.xml
	put_config --file hdfs-site.xml --property dfs.namenode.name.dir --value "$NN_DATA_DIR"
	put_config --file hdfs-site.xml --property fs.checkpoint.dir --value "$SNN_DATA_DIR"
	put_config --file hdfs-site.xml --property fs.checkpoint.edits.dir --value "$SNN_DATA_DIR"
	put_config --file hdfs-site.xml --property dfs.datanode.data.dir --value "$DN_DATA_DIR"
	put_config --file hdfs-site.xml --property dfs.namenode.http-address --value "$nn:50070"
	put_config --file hdfs-site.xml --property dfs.namenode.secondary.http-address --value "$snn:50090"

	create_config --file mapred-site.xml
	put_config --file mapred-site.xml --property mapreduce.framework.name --value yarn
	put_config --file mapred-site.xml --property mapreduce.jobhistory.address --value "$mr_hist:10020"
	put_config --file mapred-site.xml --property mapreduce.jobhistory.webapp.address --value "$mr_hist:19888"
	put_config --file mapred-site.xml --property yarn.app.mapreduce.am.staging-dir --value /mapred

	create_config --file yarn-site.xml
	put_config --file yarn-site.xml --property yarn.nodemanager.aux-services --value mapreduce.shuffle
	put_config --file yarn-site.xml --property yarn.nodemanager.aux-services.mapreduce.shuffle.class --value org.apache.hadoop.mapred.ShuffleHandler
	put_config --file yarn-site.xml --property yarn.web-proxy.address --value "$yarn_proxy:$YARN_PROXY_PORT"
	put_config --file yarn-site.xml --property yarn.resourcemanager.scheduler.address --value "$rmgr:8030"
	put_config --file yarn-site.xml --property yarn.resourcemanager.resource-tracker.address --value "$rmgr:8031"
	put_config --file yarn-site.xml --property yarn.resourcemanager.address --value "$rmgr:8032"
	put_config --file yarn-site.xml --property yarn.resourcemanager.admin.address --value "$rmgr:8033"
	put_config --file yarn-site.xml --property yarn.resourcemanager.webapp.address --value "$rmgr:8088"

	echo "Copying base Hadoop XML config files to all hosts..."
	pdcp -a core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml $HADOOP_HOME/etc/hadoop/

	#if [ ! -f /etc/hadoop/container-executor ]; then
		#echo "Creating configuration, command, and script links on all hosts..."
		pdsh -a "sudo ln -s $HADOOP_HOME/etc/hadoop /etc/hadoop"
		#pdsh -a "sudo ln -s $HADOOP_HOME/bin/* /usr/bin"
		#pdsh -a "sudo ln -s $HADOOP_HOME/libexec/* /usr/libexec"
	#fi
#
	echo "Formatting the NameNode..."
		
	pdsh -a "sudo mkdir -p $LOCK_DIR"
	pdsh -w ^nn_host "source /etc/profile.d/java.sh"
	pdsh -w ^nn_host "source /etc/profile.d/hadoop.sh"
	pdsh -w ^nn_host "sudo $HADOOP_HOME/bin/hdfs namenode -format"

	echo "Copying startup scripts to all hosts..."
	pdcp -w ^nn_host hadoop-namenode /etc/init.d/
	pdcp -w ^snn_host hadoop-secondarynamenode /etc/init.d/
	pdcp -w ^dn_hosts hadoop-datanode /etc/init.d/
	pdcp -w ^rm_host hadoop-resourcemanager /etc/init.d/
	pdcp -w ^nm_hosts hadoop-nodemanager /etc/init.d/
	pdcp -w ^mr_history_host hadoop-historyserver /etc/init.d/
	pdcp -w ^yarn_proxy_host hadoop-proxyserver /etc/init.d/

	echo "Starting Hadoop $HADOOP_VERSION services on all hosts..."
	pdsh -w ^nn_host "sudo chmod 755 /etc/init.d/hadoop-namenode && sudo sysv-rc-conf hadoop-namenode on && sudo service hadoop-namenode start"
	pdsh -w ^snn_host "sudo chmod 755 /etc/init.d/hadoop-secondarynamenode && sudo sysv-rc-conf hadoop-secondarynamenode on && sudo service hadoop-secondarynamenode start"
	pdsh -w ^dn_hosts "sudo chmod 755 /etc/init.d/hadoop-datanode && sudo sysv-rc-conf hadoop-datanode on && sudo service hadoop-datanode start"
	pdsh -w ^rm_host "sudo chmod 755 /etc/init.d/hadoop-resourcemanager && sudo  sysv-rc-conf hadoop-resourcemanager on && sudo service hadoop-resourcemanager start"
	pdsh -w ^nm_hosts "sudo chmod 755 /etc/init.d/hadoop-nodemanager && sudo sysv-rc-conf hadoop-nodemanager on && sudo service hadoop-nodemanager start"

	pdsh -w ^yarn_proxy_host "sudo chmod 755 /etc/init.d/hadoop-proxyserver && sudo  sysv-rc-conf hadoop-proxyserver on && sudo service hadoop-proxyserver start"

	echo "Creating MapReduce Job History directories..."
	sudo hadoop fs -mkdir -p /ynuser/history/done_intermediate
	sudo hadoop fs -chown -R ynuser:yarn /ynuser
	sudo hadoop fs -chmod -R g+rwx /ynuser

	pdsh -w ^mr_history_host "sudo chmod 755 /etc/init.d/hadoop-historyserver && sudo sysv-rc-conf hadoop-historyserver on && sudo service hadoop-historyserver start"

	echo "Running YARN smoke test..."
	pdsh -a "sudo usermod -a -G yarn $(whoami)"
	sudo hadoop fs -mkdir -p /user/$(whoami)
	sudo hadoop fs -chown $(whoami):$(whoami) /user/$(whoami)
	#source /etc/profile.d/java.sh
	#source /etc/profile.d/hadoop.sh
	source /etc/hadoop/hadoop-env.sh
	source /etc/hadoop/yarn-env.sh
	hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-$HADOOP_VERSION.jar pi -Dmapreduce.clientfactory.class.name=org.apache.hadoop.mapred.YarnClientFactory -libjars $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-$HADOOP_VERSION.jar 16 10000
}

interactive()
{
	echo -n "Enter NameNode hostname: "
	read nn
	echo -n "Enter Secondary NameNode hostname: "
	read snn
	echo -n "Enter ResourceManager hostname: "
	read rmgr
	echo -n "Enter Job History Server hostname: "
	read mr_hist
	echo -n "Enter YARN Proxy hostname: "
	read yarn_proxy
	echo -n "Enter DataNode hostnames (comma separated or hostlist syntax): "
	read dns
	echo -n "Enter NodeManager hostnames (comma separated or hostlist syntax): "
	read nms
	
	echo "$nn" > "$nn_host"
	echo "$snn" > "$snn_host"
	echo "$rmgr" > "$rm_host"
	echo "$mr_hist" > "$mr_history_host"
	echo "$yarn_proxy" > "$yarn_proxy_host"
	dn_hosts_var=$(sed 's/\,/\n/g' <<< $dns)
	nm_hosts_var=$(sed 's/\,/\n/g' <<< $nms)
	echo "$dn_hosts_var" > "$dn_hosts"
	echo "$nm_hosts_var" > "$nm_hosts"
	echo "$(echo "$nn $snn $rmgr $mr_hist $yarn_proxy $dn_hosts_var $nm_hosts_var" | tr ' ' '\n' | sort -u)" > "$all_hosts"
}

file()
{
	nn=$(cat nn_host)
	snn=$(cat snn_host)
	rmgr=$(cat rm_host)
	mr_hist=$(cat mr_history_host)
	yarn_proxy=$(cat yarn_proxy_host)
	dns=$(cat dn_hosts)
	nms=$(cat nm_hosts)
	
	echo "$(echo "$nn $snn $rmgr $mr_hist $dns $nms" | tr ' ' '\n' | sort -u)" > "$all_hosts"
}

help()
{
cat << EOF
install-hadoop2.sh 
 
This script installs Hadoop 2 with basic data, log, and pid directories. 
 
USAGE:  install-hadoop2.sh [options]
 
OPTIONS:
   -i, --interactive      Prompt for fully qualified domain names (FQDN) of the NameNode,
                          Secondary NameNode, DataNodes, ResourceManager, NodeManagers,
                          MapReduce Job History Server, and YARN Proxy server.  Values
                          entered are stored in files in the same directory as this command. 
                          
   -f, --file             Use files with fully qualified domain names (FQDN), new-line
                          separated.  Place files in the same directory as this script. 
                          Services and file name are as follows:
                          NameNode = nn_host
                          Secondary NameNode = snn_host
                          DataNodes = dn_hosts
                          ResourceManager = rm_host
                          NodeManagers = nm_hosts
                          MapReduce Job History Server = mr_history_host
                          YARN Proxy Server = yarn_proxy_host
                          
   -h, --help             Show this message.
   
EXAMPLES: 
   Prompt for host names: 
     install-hadoop2.sh -i
     install-hadoop2.sh --interactive
   
   Use values from files in the same directory:
     install-hadoop2.sh -f
     install-hadoop2.sh --file
             
EOF
}

while true;
do
  case "$1" in

    -h|--help)
      help
      exit 0
      ;;
    -i|--interactive)
      interactive
      install
      shift
      ;;
    -f|--file)
      file
      install
      shift
      ;;
    --)
      shift
      break
      ;;
  esac
done

