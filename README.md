# OCI PL SQL SDK Utilities & Tools

This repository contains PL SQL scripts to work with the resources in OCI. This helps developers and administrators on OCI who are familiar with PL-SQL to operate effectively in OCI.
   - Policy Analyzer: Helps extracting policies comprehensively across the compartments within the tenancy and to filter them by subjects for analyzing how the permissions are setup and how they affect the resources or subjects

## Installation

No direct installation steps are needed. 

## Documentation

**Policy Analyzer**

This needs to be run on an existing Database instance running on OCI. The authentication is done using resource principal. Alternatively, OCI user credentials could be used as well.

Initial steps to be followed to setup permissions for the Database to access the policies associated with the tenancy or the compartment

Dynamic Group <br />
    - Create a dynamic group for the respective Databse instance(s) <br />
         &nbsp;&nbsp;&nbsp; - In the Oracle Cloud Infrastructure console click Identity and Security and click Dynamic Groups <br />
         &nbsp;&nbsp;&nbsp; - Click Create Dynamic Group and enter a Name, a Description, and a rule or use the Rule Builder to add a rule; Click Create. <br />
    - Matching rule: <br />
         &nbsp;&nbsp;&nbsp; - Resources that meet the rule criteria are members of the dynamic group <br />
         &nbsp;&nbsp;&nbsp; - Example to allow a specific Database instance to access a resource: _resource.id = '<your_Database_instance_OCID>'_ <br />

Resource Principal <br />
    - Enable Resource Principal for the OCI database instance <br />
         &nbsp;&nbsp;&nbsp; - Example of an execution statement: _EXEC DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => 'adb_user');_ <br />
            
Policies - <br />
    - Define permissions for the Database instance (Dynamic Group) to access policies <br />
    - Policy Statement: _Allow dynamic-group <Dynamic to <manage/use/read> policies in tenancy_ <br />

Packages <br />
    - Run @Policy_Analyzer.sql - Compiles Policy_Analyzer package specification and body <br />

Execution <br />
    - Extract policies in the scope of the tenancy or compartment <br />
    - Policies could further be filtered by the subject, subject type or resource type <br />
    - Output will be list of policies with the policy components separated by the defined or the default separator <br />
    - Pass the appropriate parameters <br />
           &nbsp;&nbsp;&nbsp; - Compartment ID: Compartment or Tenancy OCID <br />
           &nbsp;&nbsp;&nbsp; - Subject Name: Default - All <br />
           &nbsp;&nbsp;&nbsp; - Subject Type: group, dynamic-group, service, etc | Default - All <br />
           &nbsp;&nbsp;&nbsp; - Resource Type: object-family, database-family, etc | Default - All <br />
           &nbsp;&nbsp;&nbsp; - Field Separator: ",","|", etc | Default - "," <br />
    - Sample Execution <br />
        &nbsp;&nbsp;&nbsp; _SET SERVEROUT ON; <br />
        &nbsp;&nbsp;&nbsp; Spool (Output Path).csv; <br />
        &nbsp;&nbsp;&nbsp; -- Required Parameter <br />
            &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; -- i_compartmentID: compartment or tenancy OCID <br />
        &nbsp;&nbsp;&nbsp; -- Optional Parameters for filters <br />
            &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; -- i_sbjct_nm: Subject Name | Default - All <br />
            &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; -- i_sbjct_typ_cd: Subject Type - group, dynamic-group, service, etc | Default - All <br />
            &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; -- i_resrc_typ: Resource Type - object-family, database-family, etc | Default - All <br />
            &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; -- i_separator: Field Separator - ",","|", etc | Default - "," <br />
        &nbsp;&nbsp;&nbsp; EXEC Policy_Analyzer.getPoliciesbyParameters(i_compartmentID => '<ocid1.tenancy.oc1..xxxxxx>', i_sbjct_nm => NULL, i_sbjct_typ_cd => 'service', i_resrc_typ => NULL, i_separator => ','); <br />
        &nbsp;&nbsp;&nbsp; Spool Off;_ <br />
    - Sample Output <br />
        ------------------------------------------------------------------------------------------------------ <br />
        ****************************************COMPARTMENTS HIERARCHY**************************************** <br />
        ------------------------------------------------------------------------------------------------------ <br />
        Compartment OCID: ocid1.tenancy.oc1..aaaaaaaa6llsor5h4mbc6dohmct5gj437bvq6nmefdeobpiqqgk4vfmxdmlq <br />
        Compartment OCID: ocid1.compartment.oc1..aaaaaaaapx234d667dpdbqglkfmak6fbcoayvhd6tmcb6bcnn56w735ctxzq <br />
        Compartment OCID: ocid1.compartment.oc1..aaaaaaaavhvolmjws4dpzczvhiznrctowbuuf3twprwasn7d3xxei4ugvnpq <br />
        Compartment OCID: ocid1.compartment.oc1..aaaaaaaazacvk3zjbjtl36hhyoxh4dvmfz2zsgtk4j4pzpod65rl4yl5ci7q <br />
        ------------------------------------------------------------------------------------------------------ <br />
        Policy_Number,Subject_Type,Subject,Verb,Resource_Type,Scope,Condition <br />
        ------------------------------------------------------------------------------------------------------ <br />
        3,service,cloudguard,manage,cloudevents-rules,tenancy,target.rule.type='managed' <br />
        4,service,cloudguard,read,vaults,tenancy, <br />
        5,service,cloudguard,read,keys,tenancy, <br />
        6,service,cloudguard,read,compartments,tenancy, <br />
        7,service,cloudguard,read,tenancies,tenancy, <br />
        8,service,cloudguard,read,audit-events,tenancy, <br />
        9,service,cloudguard,read,compute-management-family,tenancy, <br />
        10,service,cloudguard,read,instance-family,tenancy, <br />
        11,service,cloudguard,read,virtual-network-family,tenancy, <br />
        12,service,cloudguard,read,volume-family,tenancy, <br />
        13,service,cloudguard,read,database-family,tenancy, <br />
        14,service,cloudguard,read,object-family,tenancy, <br />
        15,service,cloudguard,read,load-balancers,tenancy, <br />
        16,service,cloudguard,read,users,tenancy, <br />
        17,service,cloudguard,read,groups,tenancy, <br />
        18,service,cloudguard,read,policies,tenancy, <br />
        19,service,cloudguard,read,dynamic-groups,tenancy, <br />
        20,service,cloudguard,read,authentication-policies,tenancy, <br />
        21,service,cloudguard,use,network-security-groups,tenancy, <br />
        22,service,cloudguard,read,data-safe-family,tenancy, <br />
        23,service,cloudguard,read,autonomous-database-family,tenancy, <br />
        24,service,cloudguard,read,log-groups,tenancy, <br />
        27,service,objectstorage-us-ashburn-1,manage,object-family,tenancy, <br />
        28,service,dpd,read,secret-family,tenancy,any {target.secret.id = 'ocid1.vaultsecret.oc1.iad.amaaaaaam44ozeiaj6phbbiazugq7p363d7e7srbauiemw2hryfmbtckxmnq'} <br />
        39,service,datascience,use,virtual-network-family,compartment DataScienceLab, <br />
        42,service,operations-insights,read,secret-family,tenancy,any { target.vault.id = 'ocid1.vault.oc1.iad.ejsw6q7caacle.abuwcljrio7eakbc7nf6jpfwlhbwsugffvrawpfs6nqjroliyytlktzdihtq' } <br />
        43,GROUP,Administrators,manage,all-resources,TENANCY, <br />

## Help

For support, bug reporting and feedback about the provided Dockerfiles, please open an issue on GITHub

## Contributing

*If your project has specific contribution requirements, update the CONTRIBUTING.md file to ensure those requirements are clearly explained*

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md)

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

*The correct copyright notice format for both documentation and software is*
    "Copyright (c) [year,] year Oracle and/or its affiliates."
*You must include the year the content was first released (on any platform) and the most recent year in which it was revised*

Copyright (c) 2023 Oracle and/or its affiliates.

*Replace this statement if your project is not licensed under the UPL*

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
