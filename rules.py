#!/usr/bin/python


import sys
import json
import fileinput
from jinja2 import Template, Environment, FileSystemLoader

#Generate rules.toml updating the backends configuration
def read_azurerm():
	azure_json_str = ""
	for line in sys.stdin:
		azure_json_str += line

	return json.loads(azure_json_str)

def get_tenant_by_name(global_tenants, tenant_name):
	for t in global_tenants:
		if t['tenant'] == tenant_name:
			return t

	#print('create tenant {0}'.format(tenant_name))
	new_tenant = {}
	new_tenant['tenant']=tenant_name
	new_tenant['backends']=[]
	
	global_tenants.append(new_tenant)
	return new_tenant


def get_backend_by_name(tenant, backend_name, hostname = None, pathprefix = None):
	for b in tenant['backends']:
		if b['name'] == backend_name:
			return b

	#print('create backend {0}'.format(backend_name))
	new_backend = {}
	new_backend['name']=backend_name
	new_backend['hostname']=hostname
	new_backend['pathprefix']=pathprefix
	new_backend['servers']=[]
	tenant['backends'].append(new_backend)
	return new_backend


def create_jsondata(azure_vm_json_data):
	global_tenants = []
	#look for every VM and add metadata to the dict
	for jd in azure_vm_json_data:
		#grab the attributes that we want from the vm
		azure_vm_tenant = jd['TENANT'].strip()
		azure_vm_backend = jd['BACKEND'].strip()
		azure_vm_ip = jd['Az_VNicPrivateIPs']

		#if we have a tenant tag and a backend tag populated
		if azure_vm_tenant and azure_vm_backend:
			#fetch or create a tenant object
			current_tenant = get_tenant_by_name(global_tenants, azure_vm_tenant)
			
			#add to new or existing tenant mapping the path to the hostname
			azure_vm_hostname = jd['HOSTNAME'].strip()
			azure_vm_pathprefix = jd['PATHPREFIX'].strip()
			current_backend = get_backend_by_name(current_tenant, azure_vm_backend, azure_vm_hostname, azure_vm_pathprefix)

			#add ip to server list
			current_backend['servers'].append(azure_vm_ip)
			
			#if everything is populated we add the current tenant and backend to the global list
			#global_tenants.append(current_tenant)

	
	return global_tenants

def render_template(global_tenants):
	file_loader = FileSystemLoader("templates")
	env = Environment(loader=file_loader)
	template = env.get_template('rules.j2')
	print(template.render(tenants=global_tenants))

if __name__== "__main__":
	azure_vm_json_data = read_azurerm()
	global_tenants = create_jsondata(azure_vm_json_data)
	#print(global_tenants)
	render_template(global_tenants)


