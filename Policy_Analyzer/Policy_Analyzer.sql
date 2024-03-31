create or replace PACKAGE       Policy_Analyzer AS
   TYPE POLICY_RECORD IS RECORD (Policy_Id     NUMBER, 
                                 Subject_Type  VARCHAR2(50), 
                                 SUBJECT       VARCHAR2(100), 
                                 VERB          VARCHAR2(50), 
                                 RESOURCE_TYPE VARCHAR2(100), 
                                 SCOPE         VARCHAR2(1000), 
                                 CONDITION     VARCHAR2(1000));
   TYPE POLICY_TABLE IS TABLE OF POLICY_RECORD INDEX BY BINARY_INTEGER;                  
   FUNCTION extractPolicies(i_compartmentID VARCHAR2) RETURN POLICY_TABLE;
   PROCEDURE getPoliciesbyParameters(i_sbjct_nm VARCHAR2, 
                                    i_sbjct_typ_cd VARCHAR2, 
                                    i_resrc_typ VARCHAR2,
                                    i_compartmentID VARCHAR2,
                                    i_separator VARCHAR2);
END Policy_Analyzer;
/
create or replace PACKAGE BODY       Policy_Analyzer AS
-- Extracts policies applied under tenancy/compartment by subject/resource types
   TYPE COMPARTMENT_REC IS RECORD (Cmprtmnt_Id VARCHAR2(100));
   TYPE COMPARTMENT_TBL IS TABLE OF COMPARTMENT_REC
      INDEX BY BINARY_INTEGER;
   TYPE POLICY_STATEMENT IS RECORD (Stmnt       VARCHAR2(1000));
   TYPE POLICY_STATEMENT_TBL IS TABLE OF POLICY_STATEMENT 
      INDEX BY BINARY_INTEGER;
   m_compartments     COMPARTMENT_TBL; --Compartments loaded in memory
   m_compatmentindx   NUMBER := 1; --Compartment Index
PROCEDURE listCompartments(i_compartmentID VARCHAR2) IS 
-- Lists the compartments under the tenancy or compartment 
   v_compartment_list DBMS_CLOUD_OCI_ID_IDENTITY_LIST_COMPARTMENTS_RESPONSE_T;
   v_compartments     COMPARTMENT_TBL;
   v_hierarchy_indx   NUMBER := 0;
BEGIN  
   IF INSTR(lower(i_compartmentID),'tenancy') > 1 THEN
      v_hierarchy_indx := 1; --Tenancy gets complete compartment hierarchy
   END IF;
   IF m_compatmentindx = 1 THEN
      --Input compartment is added on top of the compartment list
      m_compartments(m_compatmentindx).cmprtmnt_id := i_compartmentID;
      m_compatmentindx := m_compatmentindx + 1; 
   END IF;
   v_compartment_list := DBMS_CLOUD_OCI_ID_IDENTITY.list_compartments(
                        compartment_id => i_compartmentID, 
                        compartment_id_in_subtree => v_hierarchy_indx,
                        region => 'us-ashburn-1',
                        credential_name => 'OCI$RESOURCE_PRINCIPAL'); 
   FOR i in 1..v_compartment_list.response_body.count LOOP
      --Loading compartments in memory
      m_compartments(m_compatmentindx).cmprtmnt_id := 
         v_compartment_list.response_body(i).id;
      m_compatmentindx := m_compatmentindx + 1;
      IF v_hierarchy_indx <> 1 THEN
         --Recursive call to append nested compartments when tenancy OCID is not the input
         listCompartments(v_compartment_list.response_body(i).id);
      END IF;
   END LOOP;   
END listCompartments;
FUNCTION listPolicies(i_compartmentID VARCHAR2) 
RETURN dbms_cloud_oci_id_identity_list_policies_response_t IS
--Get all policies associated with the compartment
   v_Policy_list_response dbms_cloud_oci_id_identity_list_policies_response_t;
BEGIN     
   v_policy_list_response := DBMS_CLOUD_OCI_ID_IDENTITY.list_policies(
                        compartment_id => i_compartmentID, 
                        region => 'us-ashburn-1',
                        credential_name => 'OCI$RESOURCE_PRINCIPAL'); 
  RETURN v_Policy_list_response;
END listPolicies;
FUNCTION getPolicyComponents
            (i_compartmentID VARCHAR2, i_Policies POLICY_STATEMENT_TBL) 
-- Extracting the components of the policies
   RETURN POLICY_TABLE IS
   v_structured_policy POLICY_TABLE;
   v_compartment       dbms_cloud_oci_id_identity_get_compartment_response_t;
   v_statement         VARCHAR2(1000);
   v_count             NUMBER := 0;
   v_policy_components VARCHAR2(100);
   v_allow_position    NUMBER;
   v_to_position       NUMBER;
   v_in_position       NUMBER;
   v_where_position    NUMBER;
   v_subject           VARCHAR2(100);
   v_privilege         VARCHAR2(100);
BEGIN    
   FOR i in 1..i_Policies.count LOOP
      IF INSTR(lower(i_Policies(i).Stmnt),'define ') <> 1 THEN
         v_count := v_count + 1;
         v_statement := i_Policies(i).Stmnt;
         v_structured_policy(v_count).Policy_Id := v_count;
         v_allow_position := instr(lower(v_statement),'allow ')+6;
         v_to_position := instr(lower(v_statement),' to ')+4;
         v_in_position := instr(lower(v_statement),' in ')+4;
         v_where_position := instr(lower(v_statement),' where ')+7;
         v_subject 
            := trim(Substr(v_statement,
                           v_allow_position, 
                           v_to_position - v_allow_position - 4));
         v_structured_policy(v_count).subject      
            := trim(substr(v_subject,instr(v_subject,' ')));
         IF v_structured_policy(v_count).subject <> 'any-user' THEN
            v_structured_policy(v_count).subject_type
               := trim(substr(v_subject,1,instr(v_subject,' ')));
         ELSE 
            v_structured_policy(v_count).subject_type := 'global';
         END iF;
         v_privilege 
            := trim(Substr(v_statement,
                           v_to_position, 
                           v_in_position - v_to_position - 4));
         v_structured_policy(v_count).verb 
            := trim(substr(v_privilege,1,instr(v_privilege,' ')));
         v_structured_policy(v_count).resource_type 
            := trim(substr(v_privilege,instr(v_privilege,' ')));
         IF v_where_position = 7 THEN
            v_structured_policy(v_count).scope := trim(substr(v_statement, v_in_position));
         ELSE
            v_structured_policy(v_count).scope
               := trim(substr(v_statement, 
                              v_in_position, 
                              v_where_position - v_in_position - 7));
            v_structured_policy(v_count).condition 
               := trim(substr(v_statement, v_where_position)); 
         END IF;  
         IF INSTR(lower(v_structured_policy(v_count).scope), 'compartment id') > 0 THEN
            IF INSTR(lower(v_structured_policy(v_count).scope), 'ocid1.tenancy') = 0 THEN
               v_compartment 
                  := DBMS_CLOUD_OCI_ID_IDENTITY.GET_compartment(
                        compartment_id => substr(v_structured_policy(v_count).scope,
                                                 15,
                                                 length(v_structured_policy(v_count).scope)
                                                    - 15),                                              
                        region => 'us-ashburn-1',
                        endpoint => 'https://identity.us-ashburn-1.oci.oraclecloud.com',
                        credential_name => 'OCI$RESOURCE_PRINCIPAL'); 
               v_structured_policy(v_count).scope := 'compartment '||v_compartment.response_body.name;
            ELSE 
               v_structured_policy(v_count).scope :=  'tenancy';
            END IF;
         END IF;
      END IF;
   END LOOP;   
   RETURN v_structured_policy;
END getPolicyComponents;
PROCEDURE getPolicies(i_compartmentID VARCHAR2,
                      o_allpolicies OUT 
                         POLICY_STATEMENT_TBL) IS
--Gather all the policies associated within the compartment hierarchy
   v_compartments        COMPARTMENT_TBL;
   v_policies            dbms_cloud_oci_id_identity_list_policies_response_t;
   v_allpolicies         POLICY_STATEMENT_TBL;
   v_cummulativecount    NUMBER := 0;
   No_Policies           EXCEPTION;
   Compartment_Not_Found EXCEPTION;
   PRAGMA EXCEPTION_INIT(Compartment_Not_Found, -20404);
BEGIN 
   listCompartments(i_compartmentID);
   dbms_output.put_line('------------------------------------------------------------------------------------------------------');
   dbms_output.put_line('****************************************COMPARTMENTS HIERARCHY****************************************');
   dbms_output.put_line('------------------------------------------------------------------------------------------------------');
   FOR i in 1..m_compartments.count LOOP
      dbms_output.put_line('Compartment OCID: '||m_compartments(i).Cmprtmnt_Id);
      --Get policies for each of the compartments
      v_policies := listPolicies(m_compartments(i).Cmprtmnt_Id);
      FOR j in 1..v_policies.response_body.count LOOP
         FOR k in 1..v_policies.response_body(j).statements.count LOOP
         --Load policy statements from all the policies gathered
         v_cummulativecount := v_cummulativecount + 1;
         o_allpolicies(v_cummulativecount).stmnt := v_policies.response_body(j).statements(k);
         END LOOP;
      END LOOP;
   END LOOP;
   m_compartments.delete; --Clear memory after policy extraction
   m_compatmentindx := 1;  
   IF v_cummulativecount = 0 THEN
      RAISE No_Policies;
   END IF;
EXCEPTION
WHEN No_Policies THEN
   RAISE_APPLICATION_ERROR (-20003,' No Policies Found');
WHEN Compartment_Not_Found THEN
   RAISE_APPLICATION_ERROR (-20002,' Tenancy or Compartment Not Found');
END getPolicies;
FUNCTION extractPolicies(i_compartmentID VARCHAR2) RETURN POLICY_TABLE IS
--Public method to extract policies for the user requested compartment hierarchy 
   v_PolicyStatements   POLICY_STATEMENT_TBL;
   o_Policies           POLICY_TABLE;
BEGIN
   --Get Policies by compartment ID
   getPolicies(i_compartmentID, v_PolicyStatements);
   --Break down policy statements
   o_Policies := getPolicyComponents(i_compartmentID, v_PolicyStatements); 
   RETURN o_Policies;
EXCEPTION
WHEN OTHERS THEN
   RAISE;
END extractPolicies;
PROCEDURE getPoliciesbyParameters(i_sbjct_nm VARCHAR2, 
                                 i_sbjct_typ_cd VARCHAR2, 
                                 i_resrc_typ VARCHAR2,
                                 i_compartmentID VARCHAR2,
                                 i_separator VARCHAR2) IS          
--Filter Policies by subject, subject type, resource type for the requested compartment
   v_Policies POLICY_TABLE;
   o_Policies POLICY_TABLE;
   v_count    NUMBER :=0;
BEGIN
   m_compartments.delete; --Clear memory after policy extraction
   m_compatmentindx := 1; 
   v_Policies := extractPolicies(i_compartmentID);
   --Filter by the input parameters
   FOR i in 1..v_Policies.count LOOP
     IF ((lower(v_Policies(i).Subject_Type) = i_sbjct_typ_cd and 
        lower(v_Policies(i).Subject) = lower(nvl(i_sbjct_nm, 
                                                 v_Policies(i).Subject))) or 
        lower(v_Policies(i).Subject_Type) = 'any-user') or
        (lower(v_Policies(i).resource_type) = lower(i_resrc_typ) or 
        lower(v_Policies(i).resource_type) = 'all-resources') THEN
        v_count := v_count + 1;
        o_Policies(v_count) := v_Policies(i);
     END IF;
   END LOOP;
   dbms_output.put_line('------------------------------------------------------------------------------------------------------');
   dbms_output.put_line('Policy_Number,Subject_Type,Subject,Verb,Resource_Type,Scope,Condition');
   dbms_output.put_line('------------------------------------------------------------------------------------------------------');
   FOR i in 1..o_Policies.count LOOP
      dbms_output.put_line(o_Policies(i).Policy_Id||i_separator||
                           o_Policies(i).Subject_Type||i_separator||
                           o_Policies(i).Subject||i_separator||
                           o_Policies(i).Verb||i_separator||
                           o_Policies(i).Resource_Type||i_separator||
                           o_Policies(i).Scope||i_separator||
                           o_Policies(i).Condition);
   END LOOP;
EXCEPTION
WHEN OTHERS THEN
   dbms_output.put_line('Error Message:'||SQLERRM);
END getPoliciesbyParameters;
END Policy_Analyzer;
/
