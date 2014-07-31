# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require bigtop_util
$puppet_confdir = get_setting("confdir")
$default_yumrepo = "http://bigtop01.cloudera.org:8080/view/Hadoop%200.23/job/Bigtop-23-matrix/label=centos5/lastSuccessfulBuild/artifact/output/"
$extlookup_datadir="$puppet_confdir/config"
$extlookup_precedence = ["site", "default"]
$jdk_package_name = extlookup("jdk_package_name", "jdk")

stage {"pre": before => Stage["main"]}

case $operatingsystem {
    /(OracleLinux|CentOS|Fedora|RedHat)/: {
       yumrepo { "Bigtop":
          baseurl => extlookup("bigtop_yumrepo_uri", $default_yumrepo),
          descr => "Bigtop packages",
          enabled => 1,
          gpgcheck => 0,
       }
    }
    default: {
      notify{"WARNING: running on a non-yum platform -- make sure Bigtop repo is setup": }
    }
}

package { $jdk_package_name:
  ensure => "installed",
  alias => "jdk",
}

import "cluster.pp"

  $hadoop_head_node        = extlookup("hadoop_head_node") 
  $standby_head_node = extlookup("standby_head_node", "")
  $hadoop_gateway_node     = extlookup("hadoop_gateway_node", $hadoop_head_node)

  $hadoop_ha = $standby_head_node ? {
    ""      => disabled,
    default => extlookup("hadoop_ha", "manual"),
  }

  $hadoop_namenode_host        = $hadoop_ha ? {
    "disabled" => $hadoop_head_node,
    default    => [ $hadoop_head_node, $standby_head_node ],
  }
  $hadoop_namenode_port        = extlookup("hadoop_namenode_port", "17020")
  $hadoop_namenode_thrift_port = extlookup("hadoop_namenode_thrift_port", "10090")
  $hadoop_dfs_namenode_plugins = extlookup("hadoop_dfs_namenode_plugins", "")
  $hadoop_dfs_datanode_plugins = extlookup("hadoop_dfs_datanode_plugins", "")
  # $hadoop_dfs_namenode_plugins="org.apache.hadoop.thriftfs.NamenodePlugin"
  # $hadoop_dfs_datanode_plugins="org.apache.hadoop.thriftfs.DatanodePlugin"
  $hadoop_ha_nameservice_id    = extlookup("hadoop_ha_nameservice_id", "ha-nn-uri")
  $hadoop_namenode_uri   = $hadoop_ha ? {
    "disabled" => "hdfs://$hadoop_namenode_host:$hadoop_namenode_port",
    default    => "hdfs://${hadoop_ha_nameservice_id}:8020",
  }

  notice($hadoop_namenode_host)

  $hadoop_rm_host        = $hadoop_head_node
  $hadoop_rt_port        = extlookup("hadoop_rt_port", "8025")
  $hadoop_rm_port        = extlookup("hadoop_rm_port", "8032")
  $hadoop_sc_port        = extlookup("hadoop_sc_port", "8030")
  $hadoop_rt_thrift_port = extlookup("hadoop_rt_thrift_port", "9290")

  $hadoop_hs_host        = $hadoop_head_node
  $hadoop_hs_port        = extlookup("hadoop_hs_port", "10020")
  $hadoop_hs_webapp_port = extlookup("hadoop_hs_webapp_port", "19888")

  $hadoop_ps_host        = $hadoop_head_node
  $hadoop_ps_port        = extlookup("hadoop_ps_port", "20888")

  $hadoop_jobtracker_host            = $hadoop_head_node
  $hadoop_jobtracker_port            = extlookup("hadoop_jobtracker_port", "8021")
  $hadoop_jobtracker_thrift_port     = extlookup("hadoop_jobtracker_thrift_port", "9290")
  $hadoop_mapred_jobtracker_plugins  = extlookup("hadoop_mapred_jobtracker_plugins", "")
  $hadoop_mapred_tasktracker_plugins = extlookup("hadoop_mapred_tasktracker_plugins", "")

  $hadoop_zookeeper_port             = extlookup("hadoop_zookeeper_port", "2181")
  $solrcloud_port                    = extlookup("solrcloud_port", "1978")
  $solrcloud_admin_port              = extlookup("solrcloud_admin_port", "1979")
  $hadoop_oozie_port                 = extlookup("hadoop_oozie_port", "11000")
  $hadoop_httpfs_port                = extlookup("hadoop_httpfs_port", "14000")
  $hadoop_rm_http_port               = extlookup("hadoop_rm_http_port", "8088")
  $hadoop_rm_proxy_port              = extlookup("hadoop_rm_proxy_port", "8088")
  $hadoop_history_server_port        = extlookup("hadoop_history_server_port", "19888")
  $hbase_thrift_port                 = extlookup("hbase_thrift_port", "9090")
  $spark_master_port                 = extlookup("spark_master_port", "7077")
  $spark_master_ui_port              = extlookup("spark_master_ui_port", "18080")

  $components                        = extlookup("components",    split($components, ","))

  $hadoop_ha_zookeeper_quorum        = "${hadoop_head_node}:${hadoop_zookeeper_port}"
  $solrcloud_zk                      = "${hadoop_head_node}:${hadoop_zookeeper_port}"
  $hbase_thrift_address              = "${hadoop_head_node}:${hbase_thrift_port}"
  $hadoop_oozie_url                  = "http://${hadoop_head_node}:${hadoop_oozie_port}/oozie"
  $hadoop_httpfs_url                 = "http://${hadoop_head_node}:${hadoop_httpfs_port}/webhdfs/v1"
  $sqoop_server_url                  = "http://${hadoop_head_node}:${sqoop_server_port}/sqoop"
  $solrcloud_url                     = "http://${hadoop_head_node}:${solrcloud_port}/solr/"
  $hadoop_rm_url                     = "http://${hadoop_head_node}:${hadoop_rm_http_port}"
  $hadoop_rm_proxy_url               = "http://${hadoop_head_node}:${hadoop_rm_proxy_port}"
  $hadoop_history_server_url         = "http://${hadoop_head_node}:${hadoop_history_server_port}"

  $bigtop_real_users = [ 'jenkins', 'testuser', 'hudson' ]

  $hadoop_core_proxyusers = { oozie => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,httpfs,hue,users', hosts => "*" },
                                hue => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,httpfs,hue,users', hosts => "*" },
                             httpfs => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,httpfs,hue,users', hosts => "*" } }

  $hbase_relative_rootdir        = extlookup("hadoop_hbase_rootdir", "/hbase")
  $hadoop_hbase_rootdir = "$hadoop_namenode_uri$hbase_relative_rootdir"
  $hadoop_hbase_zookeeper_quorum = $hadoop_head_node
  $hbase_heap_size               = extlookup("hbase_heap_size", "1024")
  $hbase_thrift_server           = $hadoop_head_node

  $giraph_zookeeper_quorum       = $hadoop_head_node

  $spark_master_host             = $hadoop_head_node

  $hadoop_zookeeper_ensemble = ["$hadoop_head_node:2888:3888"]

  # Set from facter if available
  $roots              = extlookup("hadoop_storage_dirs",       split($hadoop_storage_dirs, ";"))
  $namenode_data_dirs = extlookup("hadoop_namenode_data_dirs", append_each("/namenode", $roots))
  $hdfs_data_dirs     = extlookup("hadoop_hdfs_data_dirs",     append_each("/hdfs",     $roots))
  $mapred_data_dirs   = extlookup("hadoop_mapred_data_dirs",   append_each("/mapred",   $roots))
  $yarn_data_dirs     = extlookup("hadoop_yarn_data_dirs",     append_each("/yarn",     $roots))

  $hadoop_security_authentication = extlookup("hadoop_security", "simple")

  if ($hadoop_security_authentication == "kerberos") {
    $kerberos_domain     = extlookup("hadoop_kerberos_domain")
    $kerberos_realm      = extlookup("hadoop_kerberos_realm")
    $kerberos_kdc_server = extlookup("hadoop_kerberos_kdc_server")

    include kerberos::client
  }

node default {
  $hadoop_head_node = extlookup("hadoop_head_node") 
  $standby_head_node = extlookup("standby_head_node", "")
  $hadoop_gateway_node = extlookup("hadoop_gateway_node", $hadoop_head_node)

  case $::fqdn {
    $hadoop_head_node: {
      include hadoop_head_node
    }
    $standby_head_node: {
      include standby_head_node
    }
    default: {
      include hadoop_worker_node
    }
  }

  if ($hadoop_gateway_node == $::fqdn) {
    include hadoop_gateway_node
  }
}

Yumrepo<||> -> Package<||>
