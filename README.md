# OCI PL SQL SDK Utilities & Tools

This repository contains PL SQL scripts to work with the resources in OCI. This helps developers and administrators on OCI who are familiar with PL-SQL to operate effectively in OCI.
   - Policy Analyzer: Helps extracting policies comprehensively across the compartments within the tenancy and to filter them by subjects for analyzing how the permissions are setup and how they affect the resources or subjects

## Installation

No direct installation steps are needed. 

## Documentation

**Policy Analyzer**

This needs to be run on an existing Database instance running on OCI. The authentication is done using resource principal. Alternatively, OCI user credentials could be used as well.

Initial steps to be followed to setup permissions for the Database to access the policies associated with the tenancy or the compartment

Dynamic Group 
    - Create a dynamic group for the respective Databse instance(s)
        - In the Oracle Cloud Infrastructure console click Identity and Security and click Dynamic Groups
        - Click Create Dynamic Group and enter a Name, a Description, and a rule or use the Rule Builder to add a rule.
        - Click Create.
    - Matching rule:
        - Resources that meet the rule criteria are members of the dynamic group
        - Example to allow a specific Database instance to access a resource:
            - _resource.id = '<your_Database_instance_OCID>'_

Resource Principal
    - Enable Resource Principal for the OCI database instance
        - Example of an execution statement:
            - _EXEC DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => 'adb_user');_
            
Policies - 
    - Define permissions for the Database instance (Dynamic Group) to access policies
    - Policy Statement: 
        _Allow dynamic-group <Dynamic to <manage/use/read> policies in tenancy_

Packages
    - Run @Policy_Analyzer.sql 
        - Compiles Policy_Analyzer package specification and body

Execution
    - Extract policies in the scope of the tenancy or compartment 
    - Policies could further be filtered by the subject, subject type or resource type
    - Output will be list of policies with the policy components separated by the defined or the default separator
    - Pass the appropriate parameters 
            - Compartment ID: Compartment or Tenancy OCID
            - Subject Name: Default - All
            - Subject Type: group, dynamic-group, service, etc | Default - All
            - Resource Type: object-family, database-family, etc | Default - All
            - Field Separator: ",","|", etc | Default - ","
    - Sample Execution
        _SET SERVEROUT ON;
        Spool <Output Path>.csv;
        -- Required Parameter
            -- i_compartmentID: compartment or tenancy OCID
        -- Optional Parameters for filters
            -- i_sbjct_nm: Subject Name | Default - All
            -- i_sbjct_typ_cd: Subject Type - group, dynamic-group, service, etc | Default - All
            -- i_resrc_typ: Resource Type - object-family, database-family, etc | Default - All
            -- i_separator: Field Separator - ",","|", etc | Default - ","
        EXEC Policy_Analyzer.getPoliciesbyParameters(i_sbjct_nm => <subject_name>, i_sbjct_typ_cd => '<group>', i_resrc_typ => <resource_type>, i_compartmentID => '<ocid1.tenancy.oc1..xxxx>', i_separator => '<,>');
        Spool Off;_
    - Sample Output  
        ------------------------------------------------------------------------------------------------------
        ****************************************COMPARTMENTS HIERARCHY****************************************
        ------------------------------------------------------------------------------------------------------
        Compartment OCID: ocid1.tenancy.oc1..aaaaaaaa6llsor5h4mbc6dohmct5gj437bvq6nmefdeobpiqqgk4vfmxdmlq
        Compartment OCID: ocid1.compartment.oc1..aaaaaaaapx234d667dpdbqglkfmak6fbcoayvhd6tmcb6bcnn56w735ctxzq
        Compartment OCID: ocid1.compartment.oc1..aaaaaaaavhvolmjws4dpzczvhiznrctowbuuf3twprwasn7d3xxei4ugvnpq
        Compartment OCID: ocid1.compartment.oc1..aaaaaaaazacvk3zjbjtl36hhyoxh4dvmfz2zsgtk4j4pzpod65rl4yl5ci7q
        ------------------------------------------------------------------------------------------------------
        Policy_Number,Subject_Type,Subject,Verb,Resource_Type,Scope,Condition
        ------------------------------------------------------------------------------------------------------
        3,service,cloudguard,manage,cloudevents-rules,tenancy,target.rule.type='managed'
        4,service,cloudguard,read,vaults,tenancy,
        5,service,cloudguard,read,keys,tenancy,
        6,service,cloudguard,read,compartments,tenancy,
        7,service,cloudguard,read,tenancies,tenancy,
        8,service,cloudguard,read,audit-events,tenancy,
        9,service,cloudguard,read,compute-management-family,tenancy,
        10,service,cloudguard,read,instance-family,tenancy,
        11,service,cloudguard,read,virtual-network-family,tenancy,
        12,service,cloudguard,read,volume-family,tenancy,
        13,service,cloudguard,read,database-family,tenancy,
        14,service,cloudguard,read,object-family,tenancy,
        15,service,cloudguard,read,load-balancers,tenancy,
        16,service,cloudguard,read,users,tenancy,
        17,service,cloudguard,read,groups,tenancy,
        18,service,cloudguard,read,policies,tenancy,
        19,service,cloudguard,read,dynamic-groups,tenancy,
        20,service,cloudguard,read,authentication-policies,tenancy,
        21,service,cloudguard,use,network-security-groups,tenancy,
        22,service,cloudguard,read,data-safe-family,tenancy,
        23,service,cloudguard,read,autonomous-database-family,tenancy,
        24,service,cloudguard,read,log-groups,tenancy,
        27,service,objectstorage-us-ashburn-1,manage,object-family,tenancy,
        28,service,dpd,read,secret-family,tenancy,any {target.secret.id = 'ocid1.vaultsecret.oc1.iad.amaaaaaam44ozeiaj6phbbiazugq7p363d7e7srbauiemw2hryfmbtckxmnq'}
        39,service,datascience,use,virtual-network-family,compartment DataScienceLab,
        42,service,operations-insights,read,secret-family,tenancy,any { target.vault.id = 'ocid1.vault.oc1.iad.ejsw6q7caacle.abuwcljrio7eakbc7nf6jpfwlhbwsugffvrawpfs6nqjroliyytlktzdihtq' }
        43,GROUP,Administrators,manage,all-resources,TENANCY,

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
