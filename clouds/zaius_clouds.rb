POOL_NAME     = 'zaius'
require File.dirname(__FILE__)+'/cloud_aspects'

#
# EBS-backed hadoop cluster in the cloud.
# See the ../README.textile file for usage, etc
# If you use the west coast availability zone, to avoid 'ami not found' errors, first run
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com

pool POOL_NAME do
  #
  # Combined chef server, nfs server and hadoop master. Run this if you're just
  # starting out.
  #
  cloud :chefmaster do
    using :ec2
    settings = settings_for_node(POOL_NAME, :chefmaster)
    instances            1..1
    user                        'ubuntu'
    is_spot_priced              settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_nfs_server               settings
    is_chef_server              settings
    #
    is_hadoop_node              settings
    mounts_ebs_volumes          settings
    has_recipe settings, 'hadoop_cluster:format_namenode_once'
    has_role   settings, "hadoop_master"
    has_role   settings, "hadoop_worker"
    has_recipe settings, 'hadoop_cluster:std_hdfs_dirs'
    has_recipe settings, "pig::install_from_release"
    has_big_package             settings
    #
    user_data                   (settings[:user_data].merge(settings[:user_data][:attributes])).to_json
  end

  #
  # Hadoop master, to be used with a standalone chef server and (optional) nfs server.
  #
  cloud :master do
    using :ec2
    settings = settings_for_node(POOL_NAME, :master)
    instances                   1..1
    user                        'ubuntu'
    is_spot_priced              settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_nfs_client               settings
    is_chef_client              settings
    #
    is_hadoop_node              settings
    has_recipe settings, 'hadoop_cluster:format_namenode_once'
    has_role   settings, "hadoop_master"
    has_role   settings, "hadoop_worker"
    has_recipe settings, 'hadoop_cluster:std_hdfs_dirs'
    has_recipe settings, "pig::install_from_package"
    has_big_package             settings
    #
    user_data                   settings[:user_data].to_json
    # puts JSON.pretty_generate(settings)
  end

  cloud :slave do
    using :ec2
    settings = settings_for_node(POOL_NAME, :slave)
    instances                   3..3
    user                        'ubuntu'
    is_spot_priced              settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    #
    is_hadoop_node              settings
    has_role   settings, "hadoop_worker"
    has_recipe settings, "pig::install_from_package"
    #
    has_big_package             settings
    user_data                   settings[:user_data].to_json
    puts JSON.pretty_generate(settings)
  end
end
