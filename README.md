OpenNebula OpenVZ driver
========================

This set of drivers allows you to use [OpenVZ][http://wiki.openvz.org/Main_Page] as a hypervisor in [OpenNebula][http://opennebula.org]. 

Cluster Node requirements
-------------------------
1. ruby >= 1.9
* rvm is recommended to manage ruby version
* ex. rvm [tutorial for centos 6][http://blog.jeffcosta.com/2011/07/22/install-ruby-version-manager-rvm-on-centos-6/] 

2. rake, rake-remote_task
<pre>
gem install rake
gem install rake-remote_task
</pre>

3. remaining gems
<pre>
rake gems
</pre>
