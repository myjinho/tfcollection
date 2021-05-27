Purpose
-------
This solution creates single/multi node WLS cluster with OCI Database or ATP DB as INFRA DB optionally fronted 
by a load balancer. The solution will create only one stack at time and further modifications that are done will be 
done on the same stack. 

If multiple instances are desired then the user has to maintain terraform state in different locations or with different name. 
One terraform state file is generated per stack. So for multiple stacks ensure that a unique name is used for terraform state file. 
And this can be achieved by using the option -state="{unique dir or name of .tfstate file}" at the time of terraform apply.

**Public subnet Topology**
Creates following subnets under new VCN or existing VCN in different ADs.
* WLS Public subnet
* Loadbalancer Frontend Public Subnet
* Loadbalancer Backend Public Subnet

**Private Subnet Topology**
Creates following subnets under new VCN or existing VCN in different ADs.

* WLS Private Subnet
* Management Public Subnet (for bastion host, uses the same AD as WLS) 
* Loadbalancer Frontend Public Subnet
* Loadbalancer Backend Public Subnet

Organization
-------------
**inputs** - this directory consists of following:
* **env_vars_template** (for secret input variables - like user's api signing key details).
* **instance.tfvars.template** - for wls instance specific config
* **oci_db.tfvars.template** - for OCI DB specific config
* **atp_db.tfvars.template** - for ATP DB specific config

**Note:** rename the xx.tfvars.template to corresponding xx.tfvars and provide environment specific values.

* **main.tf** - is where we call the modules in order as defined in ../modules.
* **outputs.tf** - result printed on the stdout at the completion of terraform provisioning.
* **provider.tf** - oci provider is defined.
* **datasource.tf** - pre-fetch ADs, subnets etc that is then used to lookup based on user specified input.
* **variables.tf** - defines the variables that are passed to modules as input.

Pre-requisites
--------------------
The terraform OCI provider supports API Key based authentication and Instance Principal based authentication.

User has to create an OCI account in the his tenancy. Here are the authentication information required 
for invocation of Terraform scripts. 

**Tenancy OCID** - The global identifier for your account, always shown on the bottom of the web console.

**User OCID** - The identifier of the user account you will be using for Terraform

**Fingerprint** - The fingerprint of the public key added in the above user's API Keys section of the web console. 

**Private key path** - The path to the private key stored on your computer. The public key portion must be added to the user account above in the API Keys section of the web console. 


To invoke Terraform
--------------------
From solution dir (wls) execute:

### Initialize the terraform provider plugin
```bash
$ terraform init
```

### Init the environment with terraform environment vars
```bash
$ source inputs/env_vars
```

### Invoke apply passing all *.tfvars files as input
If you don't specify the -var-file then defaults in vars.tf will apply.

**WLS Non JRF:**
```bash
$ terraform apply -var-file=inputs/instance.tfvars 
```
**WLS JRF with OCI DB:**

```bash
$ terraform apply -var-file=inputs/instance.tfvars -var-file=inputs/oci_db.tfvars
```

**WLS JRF with ATP DB:**
```bash
$ terraform apply -var-file=inputs/instance.tfvars -var-file=inputs/atp_db.tfvars

```
**Creating Multiple instances from same solutions:**
```bash
$ terraform apply -var-file=inputs/instance.tfvars -state=<use unique dir or state file name for each stack>
```


### To destroy the infrasturcture

**WLS Non JRF:**
```bash
$ terraform destroy -var-file=inputs/instance.tfvars 
```

**WLS JRF with OCI DB:**
```bash
$ terraform destroy -var-file=inputs/instance.tfvars -var-file=inputs/oci_db.tfvars
```

**WLS JRF with ATP DB:**
```bash
$ terraform destroy -var-file=inputs/instance.tfvars -var-file=inputs/atp_db.tfvars
```

To invoke Terraform using Resource Manager
--------------------

The artifacts are published to idoru by nightly builds. User will have to download the terraform scripts zip to use with
Resource Manager.

* Idoru Link: http://idoru.oraclecorp.com/#/services/SOAOciNative
* Artifact Name: wlsoci-resource-manager
* Working directory: ./


What it does
-------------

**Pre-requisites for SOA with OCI Native DB 12c :** 
* User will provide compartment OCID to provision SOA 12c with all the networking. 
* User also has option to use pre existing VCN. Only mandatory requirement is that it should have internet gateway pre-configured.


* **Inputs to terraform:**
    *  User will provide the following as param to terraform:
        * Authentication information
            * Tenancy OCID 
            * User OCID
            * Path to private key 
            * FingerPrint
        * WLS Compartment name
        * Region
        * WLS parameters 
            * wls_admin_user
            * wls_admin_password
            * wls_domain_name
            * instance_shape
            * numVMInstances
            * SSH public key
        * Networking details 
            * VCN Name (if creating new VCN)
            * VCN OCID (if using existing VCN)
            * wls_subnet_cidr, lb_frontend_subnet_cidr and lb_backend_subnet_cidr (if using existing VCN)
        * Optional Load Balancer 
            * add_load_balancer
        * Optional WLS private subnet
            * assign_backend_public_ip (defaults to true, false will create private subnet for WLS)
            * mgmt_subnet_cidr (Required for private subnet only if existing VCN is used)


    ** NOTE:** User will need to ensure the subnet CIDRs are subset of the DB VCN's CIDR.
    
* **Provisioning flow** will be as follows:
    * **Create VCN (if not using existing)**
    * **Create Internet gateway(if not preconfigured), Route tables, and Security Lists**
        * *SOA Security List*
        * *Load balancer Security Lists*
    * **Create Subnets**
        * Creates one or three subnets one in each Availabity Domains. Three subnets are created if Load balancer needs to be provisioned.
    * **Create VM Instances**
        * First instance hosts the SOA 12c admin server and one managed server. 
        * Additional instance host the SOA 12c managed servers with nodemanager. 
    * **Create Load balancer (if requested)**
        * If LB is being provisioned:
            * Create Loadbalancer
            * Create Loadbalancer listener
            * Create BackendSet with more than one backends based private ip addresses of the VMs.

**Pre-requisites for supporting OCI DB as infrastructure DB:** 
* User will configure the DB subnet's seclist with a secrule to open up 1521 port for VCN CIDR or new WLS subnet CIDR.
* Also user should have created an internet gateway in the VCN.

* **Inputs to terraform:**
    * User will provide the following as param to terraform in addtion to the WLS parameters listed above:
        * WLS Subnet CIDR
        * LB Frontend Subnet CIDR
        * LB Backend Subnet CIDR
        * Mgmt Subnet CIDR if using private subnet
        * DB's VCN Compartment Name
        * Number of WLS instances
        * OCI database Params:
            * db_connect_string (Optional if rest of parameters are provided)
            * db_hostname_prefix
            * db_host_domain
            * db_shape
            * db_version
            * db_name
            * db_unique_name
            * pdb_name
            * db_node_count (defaults to 1, required for Rac DB)
            * db_user
            * db_password
        
        **NOTE:** User will need to ensure the subnet CIDRs are subset of the DB VCN's CIDR.
* **Provisioning flow** will be as follows:
    * **Create a WLS security list** resource with rules:
        * Source: WLS Subnet CIDR, Destination Port: ALL
        * Source: 0.0.0.0/0, Destination Port: *WLS SSL Console Port*
    * **Create a WLS Subnet** with user specified CIDR in the user specified VCN and the new WLS security list.
    * If LB is being provisioned:
        * Create Security list for LB frontend subnet with following rule:
            * Source: 0.0.0.0/0, Destination port: 443
        * Create LB Frontend Subnet in user specified VCN and the new LB frontend security list.
        * Use the WLS Subnet created above for LB backend subnet.
        * Create backend set.
        * Create backend endpoints
        * Create LB resource.

* **Pre-requisites for supporting ATP DB as infrastructure DB:** 
* User should download the wallet zip and provide the file path and wallet password as input to terraform.
* If using existing VCN, internet gateway has to pre-configured.

* **Inputs to terraform:**
    * User will provide the following as param to terraform in addtion to the WLS parameters listed above:
        * ATP database Params:
            * db_user ( defaults to ADMIN, as it cannot be changed in ATP)
            * db_password
            * db_name
            * atp_db_wallet_password
            * atp_db_wallet_path
            * atp_db_level
Limitations
--------
* To use existing VCN, user needs to ensure that internet gateway is preconfigured.
* It can only support WLS and OCI DB in same VCN. 

Tests
-----
https://coherence.us.oracle.com/display/CLOUD/WLS+Terraform+Testing - documents all test cases.