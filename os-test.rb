# nova commands can be executed by cd ~/devstack
# . openrc admin
# eg. nova list
# cinder volume-list
# docs of cinder http://docs.openstack.org/grizzly/openstack-block-storage/admin/content/cinder-install.html
#
require "rubygems"
require "openstack"
require "pp"
os = OpenStack::Connection.create({:username => "admin", :api_key=>"stack", :auth_method=>"password", :auth_url => "http://192.168.1.5:5000/v2.0/", :authtenant_name =>"admin", :service_type=>"compute"})
servers = os.servers
pp servers
pp os.get_floating_ips
vs = OpenStack::Connection.create({:username => "admin", :api_key=>"stack", :auth_method=>"password", :auth_url => "http://192.168.1.5:5000/v2.0/", :authtenant_name =>"admin", :service_type=>"volume"})
#volume = vs.create_volume({:display_name=>"nick volume", :size=>1, :display_description=>"test nick volume"})
pp vs.volumes
#pp vs.list_volumes
vs.delete_volume("6a02276a-0d8a-4f57-8a84-73f22b3c5731")
