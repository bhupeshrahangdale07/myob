/**
 * @Author : Kandisa Technologies
 * @description MYOB Setup : Setup and Configuration Component [SetupConfigCmp] & [setupPageCmp] & [connectionResetCmp] & [generateInvoiceCustomerCreationForm] & [myobCustomerSync]
 * @created on        : 2024
 * @created by        : Piyush V Ganorkar
 * @last modified on  : 1-8-2024
 * @last modified by  : Piyush V Ganorkar
 */ 
@SuppressWarnings('PMD.UnusedLocalVariable') // For 'sR'(deleteMYOBIRec)
public without sharing class SetupConfigController {

    /** @description Setup and Configuration Component : Wrapper Class. */
    public class SetupConfigWrapper{
        /** @description Setup and Configuration Component : For Record id. */
        @AuraEnabled public String id {get;set;}
        /** @description Setup and Configuration Component : For Name. */
        @AuraEnabled public String name {get;set;}
        /** @description Setup and Configuration Component : For Progress Value. */
        @AuraEnabled public Decimal progressValue {get;set;}
        /** @description Setup and Configuration Component : For Total Connection Steps. */
        @AuraEnabled public Decimal totalConnectionSteps {get;set;}
        /** @description Setup and Configuration Component : For Completed Steps. */
        @AuraEnabled public Decimal completedSteps {get;set;}
        /** @description Setup and Configuration Component : For Client Id. */
        @AuraEnabled public string clientId {get;set;}
        /** @description Setup and Configuration Component : For Client Secret. */
        @AuraEnabled public string clientSecret {get;set;}
        /** @description Setup and Configuration Component : For Environment Type. */
        @AuraEnabled public string baseUrl {get;set;}
        /** @description Setup and Configuration Component : For Access Token. */
        @AuraEnabled public string accessToken {get;set;}
        /** @description Setup and Configuration Component : For Refresh Token. */
        @AuraEnabled public string refreshToken {get;set;}
        /** @description Setup and Configuration Component : For Sync Site. */
        @AuraEnabled public string syncSite {get;set;}
        /** @description Setup and Configuration Component : For Company File. */
        @AuraEnabled public string companyFile {get;set;}
    }
    
    /**
     * @description Setup and Configuration Component : For data from record in KTMYOB__MYOB_Credential__c.
     * @return Record data
     */
    @AuraEnabled public static SetupConfigWrapper getSetupConfiguration(){
        SetupConfigWrapper scwrap = new SetupConfigWrapper();
        try{
            list<KTMYOB__MYOB_Credential__c > cred = [ SELECT Id, Name, KTMYOB__Access_Token__c, KTMYOB__Base_Url__c, KTMYOB__Company_File_Id__c, KTMYOB__Client_Id__c , 
                                                       KTMYOB__Client_Secret__c, KTMYOB__Completed_Steps__c, KTMYOB__Progress_Value__c, KTMYOB__Redirect_URL__c, 
                                                       KTMYOB__Refresh_Token__c, KTMYOB__Scope__c, KTMYOB__Total_Connection_Steps__c
                                                       FROM KTMYOB__MYOB_Credential__c 
                                                       WITH SECURITY_ENFORCED
                                                       LIMIT 1 ];
            if(cred.size() > 0){
                scwrap.accessToken = Utils.processDecryption(cred[0].KTMYOB__Access_Token__c);
                scwrap.baseUrl = cred[0].KTMYOB__Base_Url__c;
                scwrap.clientId = Utils.processDecryption(cred[0].KTMYOB__Client_ID__c);
                scwrap.clientSecret = Utils.processDecryption(cred[0].KTMYOB__Client_Secret__c);
                scwrap.completedSteps =  cred[0].KTMYOB__Completed_Steps__c != null ? cred[0].KTMYOB__Completed_Steps__c : 0;
                scwrap.progressValue = cred[0].KTMYOB__Progress_Value__c != null ? cred[0].KTMYOB__Progress_Value__c : 0;
                scwrap.refreshToken = Utils.processDecryption(cred[0].KTMYOB__Refresh_Token__c);
                scwrap.syncSite =  Utils.processDecryption(cred[0].KTMYOB__Scope__c);
                scwrap.totalConnectionSteps =  cred[0].KTMYOB__Total_Connection_Steps__c != null ? cred[0].KTMYOB__Total_Connection_Steps__c : 0;
                system.debug('$$$ KTMYOB__Company_File_Id__c: '+cred[0].KTMYOB__Company_File_Id__c);
                system.debug('$$$ KTMYOB__Company_File_Id__c: '+Utils.processDecryption(cred[0].KTMYOB__Company_File_Id__c));
                scwrap.companyFile =  Utils.processDecryption(cred[0].KTMYOB__Company_File_Id__c);
            }  
        }catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        system.debug('$$$ scwrap: '+scwrap);
        return scwrap;
    }  

    /**
     * @description Setup and Configuration Component : To save fields data from ui to record in KTMYOB__MYOB_Credential__c.
     * @param setupConfig - Fields data in wrapper
     * @return Boolean
     */
    @AuraEnabled public static Boolean saveUIToSf(String setupConfig){
        Boolean updated = false;
        SetupConfigWrapper scwrap = new SetupConfigWrapper();
        try {
            if(String.isNotBlank(setupConfig)){
                scwrap = (SetupConfigWrapper)JSON.deserialize(setupConfig,SetupConfigWrapper.class);
                list<KTMYOB__MYOB_Credential__c> cred = [ SELECT Id, Name, KTMYOB__Access_Token__c, KTMYOB__Base_Url__c, KTMYOB__Company_File_Id__c, KTMYOB__Client_Id__c , 
                                                            KTMYOB__Client_Secret__c, KTMYOB__Completed_Steps__c, KTMYOB__Progress_Value__c, KTMYOB__Redirect_URL__c, 
                                                            KTMYOB__Refresh_Token__c, KTMYOB__Scope__c, KTMYOB__Total_Connection_Steps__c
                                                            FROM KTMYOB__MYOB_Credential__c 
                                                            WITH SECURITY_ENFORCED
                                                            LIMIT 1 ];
                if(cred.size() > 0 && !cred.isEmpty()){
                    if(scwrap.progressValue != null && scwrap.completedSteps != null){
                        cred[0].KTMYOB__Progress_Value__c = scwrap.progressValue;
                        cred[0].KTMYOB__Completed_Steps__c = scwrap.completedSteps;
                    }

                    if(String.isNotBlank(scwrap.companyFile) && scwrap.companyFile != 'undefined'){
                        cred[0].KTMYOB__Company_File_Id__c = Utils.processEncryption(scwrap.companyFile);
                    }
                }
                Database.SaveResult sR = Database.update(cred[0]);
                updated = sR.isSuccess();
            }
        } catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        return updated;
    }

    /**
     * @description Setup and Configuration Component : To save fields data from ui to record in KTMYOB__MYOB_Credential__c.
     */
    @AuraEnabled public static void updateCusSettingndScheduleBatch(){
        try {
                //String hour = String.valueOf(Datetime.now().hour());
                //You can add any no of Minute you want to add to schedule it for next
                String min = String.valueOf(Datetime.now().addMinutes(15).minute());
                String ss = String.valueOf(Datetime.now().second());
                
                //parse to a cron expression
            String nextFireTime = ss + ' ' + min + ' ' + '*' + ' * * ?';
                
                //Create an Instance of your Schedule Class
                //scheduleSuccessApi s = new scheduleSuccessApi(apiType,requestIdList,afterDate);
                if(!Test.isRunningTest()){
                    List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'BatchToRefreshAccessTokenInMYOB' limit 1];
                    if(cronTriggers.isEmpty()){
                        System.schedule('BatchToRefreshAccessTokenInMYOB', nextFireTime, new BatchToRefreshAccessTokenInMYOB());
                    }
                }
        } catch (Exception e) {
            HandleCustomException.LogException(e);
        }
    }

    /**
     * @description Setup and Configuration Component : To create record from ui to KTMYOB__MYOB_Credential__c with fields data for Authorization.
     * @param clientId - Client ID
     * @param clientSecret - Client Secret
     * @param environmentValue - Sandbox/Production
     * @param redirectUrl - VF Page Url
     * @param progressValue - Setup Configuration Progress
     * @param connectionStep - 1 to 4
     * @param totalConnectionStep - 4 
     * @return String [Salesforce Base Url]
     */
    @AuraEnabled public static String createAuthProvider(String clientId, String clientSecret, String companyFileValue, String baseUrl, String redirectUrl, Integer progressValue, Integer connectionStep, Integer totalConnectionStep){
        String salesforceUrl = URL.getOrgDomainUrl().toExternalForm();
        // Can use getCurrentRequestUrl()
        String result = '';
        try{
            list<KTMYOB__MYOB_Credential__c> myobCredList = [SELECT Id FROM KTMYOB__MYOB_Credential__c WITH SECURITY_ENFORCED LIMIT 1 ];
            KTMYOB__MYOB_Credential__c myobCred = new KTMYOB__MYOB_Credential__c();
            if(myobCredList.size() > 0){
                myobCred.id = myobCredList[0].id;
            }
            //myobCred.Name = 'MYOB-0001';
            myobCred.KTMYOB__Client_ID__c  = Utils.processEncryption(clientId);
            myobCred.KTMYOB__Client_Secret__c = Utils.processEncryption(clientSecret);
            myobCred.KTMYOB__Company_File_Id__c = Utils.processEncryption(companyFileValue);
            myobCred.KTMYOB__Base_Url__c = baseUrl; 
            myobCred.KTMYOB__Redirect_URL__c = redirectUrl;
            //myobCred.KTMYOB__Refresh_Token__c = '';
            //myobCred.KTMYOB__Access_Token__c = '';
            myobCred.KTMYOB__Progress_Value__c = progressValue;
            myobCred.KTMYOB__Total_Connection_Steps__c = totalConnectionStep;
            myobCred.KTMYOB__Completed_Steps__c = connectionStep;
            Database.UpsertResult upsertResult = Database.upsert(myobCred);
            if (upsertResult.isSuccess()) {
                result = salesforceUrl;
            }
        }catch(Exception e){
            HandleCustomException.LogException(e);
        }
        return result;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /** @description Contact and Configuration Component : Wrapper Class. */
    public class ContactConfigWrapper{
        /** @description Contact and Configuration Component : KTMYOB__Contact_Company_Fields_Mapping__c . */
        @AuraEnabled public List<KTMYOB__Contact_Company_Fields_Mapping__c> contactCompanyMetadata;
        /** @description Contact and Configuration Component : KTMYOB__Contact_Individual_Fields_Mapping__c . */
        @AuraEnabled public List<KTMYOB__Contact_Individual_Fields_Mapping__c> contactIndividualMetadata;
        /** @description Contact and Configuration Component : KTMYOB__MYOB_Objects_Configurations__c. */
        @AuraEnabled public KTMYOB__MYOB_Objects_Configurations__c objConfigSetting;
    }

    /**
     * @description Contact and Configuration Component : To retrive data from Custom Setting.
     * @return Custom setting fields and data.
     */
    @AuraEnabled public static ContactConfigWrapper getContactConfiguration(){
        ContactConfigWrapper ccw = new ContactConfigWrapper();
        try{
            List<KTMYOB__Contact_Company_Fields_Mapping__c> conConConfig = [ SELECT Id, Name, KTMYOB__Data_Type__c, KTMYOB__Field_API_Name__c, KTMYOB__Field_Value__c, 
                                                                             KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Read_Only__c, KTMYOB__Required__c, SetupOwnerId
                                                                             FROM KTMYOB__Contact_Company_Fields_Mapping__c 
                                                                             WHERE SetupOwnerId =: UserInfo.getOrganizationId()
                                                                             WITH SECURITY_ENFORCED ];
            List<KTMYOB__Contact_Individual_Fields_Mapping__c> conIndConfig = [ SELECT Id, Name, KTMYOB__Data_Type__c, KTMYOB__Field_API_Name__c, KTMYOB__Field_Value__c, 
                                                                                KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Read_Only__c, KTMYOB__Required__c, SetupOwnerId
                                                                                FROM KTMYOB__Contact_Individual_Fields_Mapping__c
                                                                                WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                                                WITH SECURITY_ENFORCED ];
            KTMYOB__MYOB_Objects_Configurations__c objConfig = [ SELECT Id, Name, SetupOwnerId, KTMYOB__Contact_Company_Object_Api_Name__c, KTMYOB__Contact_Individual_Object_Api_Name__c, KTMYOB__Save_Contacts_in_Different_Object__c	
                                                              FROM KTMYOB__MYOB_Objects_Configurations__c 
                                                              WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                              WITH SECURITY_ENFORCED ];                                                               
            ccw.contactCompanyMetadata = conConConfig;	
            ccw.contactIndividualMetadata = conIndConfig;
            ccw.objConfigSetting = objConfig;

        }catch(Exception e){
            HandleCustomException.LogException(e);
        }
        return ccw;
    }

    /** @description Contact and Configuration Component : Wrapper Class. */
    public class ObjectInfo {
        /** @description Contact and Configuration Component : For name. */
        @AuraEnabled public String name { get; set; }
        /** @description Contact and Configuration Component : For value. */
        @AuraEnabled public String value { get; set; }
        /** @description Contact and Configuration Component : For label. */
        @AuraEnabled public String label { get; set; }
        /** @description Contact and Configuration Component : For helpText. */
        @AuraEnabled public String helpText { get; set; }
        /** @description Contact and Configuration Component : For type. */
        @AuraEnabled public String type { get; set; }
        /** @description Contact and Configuration Component : For require. */
        @AuraEnabled public boolean require { get; set; }
        /** @description Contact and Configuration Component : For readOnly. */
        @AuraEnabled public boolean readOnly { get; set; }
        /** @description Contact and Configuration Component : For myobFieldName. */
        @AuraEnabled public string myobFieldName { get; set; }
    }

    /**
     * @description Contact and Configuration Component : To set object list.
     * @return Object info
     */
    @AuraEnabled(cacheable=true) public static List<ObjectInfo> getObjectList() {
        List<ObjectInfo> objectInfos = new List<ObjectInfo>();
        for (Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
            if(((Schema.DescribeSObjectResult)objectType.getDescribe()).isCreateable() == true){
                ObjectInfo objectInfo = new ObjectInfo();
                objectInfo.value = String.valueOf(objectType);
                objectInfo.label = ((Schema.DescribeSObjectResult)objectType.getDescribe()).getLabel();
                objectInfos.add(objectInfo);
            }
        }
        return objectInfos;
    }

    /** @description Contact and Invoice Configuration Component : Wrapper Class. */
    public class ContactObjectWrapper{
        /** @description Contact and Configuration Component : For childObjects. */
        @AuraEnabled public list<ObjectInfo> childObjects;
        /** @description Contact and Invoice Configuration Component : For Objectfields. */
        @AuraEnabled public list<Picklistwrapper> Objectfields;
        /** @description Contact and Invoice Configuration Component : For customSettingObjectFields. */
        @AuraEnabled public list<ObjectInfo> customSettingObjectFields;
    }

    /** @description Contact and Invoice Configuration Component : Wrapper Class. */
    public class Picklistwrapper {
        /** @description Contact and Invoice Configuration Component : For label. */
        @AuraEnabled public String label { get; set; }
        /** @description Contact and Invoice Configuration Component : For value. */
        @AuraEnabled public String value { get; set; }
        /** @description Contact and Invoice Configuration Component : For fieldType. */
        @AuraEnabled public String fieldType { get; set; }
        /** @description Contact and Invoice Configuration Component : For required. */
        @AuraEnabled public boolean required { get; set; }
        /** @description Contact and Invoice Configuration Component : For referencedObjectApiName. */
        @AuraEnabled public String  referencedObjectApiName{ get; set; }
        
        /**
         * @description Contact and Invoice Configuration Component : Constructor for direct access.
         * @param label
         * @param value
         * @param fieldType
         * @param required
         * @param referencedObjectApiName
         */
        public Picklistwrapper(String label, String value, String fieldType, boolean required, string referencedObjectApiName) {
            this.label = label;
            this.value = value;
            this.fieldType = fieldType;
            this.required = required;
            this.referencedObjectApiName = referencedObjectApiName;
        }
    }

    /**
     * @description From getInvoiceConfiguration, getCustomerFieldsNConfiguration() & getInvoiceFields methods.
     * @param sObjectType - From ui (any)
     * @return List<Picklistwrapper>
     */
    @AuraEnabled public static List<Picklistwrapper> getFieldMap(String sObjectType) {
        List<Picklistwrapper> options = new List<Picklistwrapper>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType targetType = schemaMap.get(sObjectType);
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        for(String fieldName : fieldMap.keySet()){
            Schema.SObjectField field = fieldMap.get(fieldName);
            String apiName = fieldMap.get(fieldName).getDescribe().getName();
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            string referencedObjectApiName='';
            if(String.isNotBlank(apiName) && field.getDescribe().isUpdateable() || String.ValueOF(fieldMap.get(fieldName).getDescribe().getType()) == 'ADDRESS'){
                String fieldType = String.valueOf(fieldMap.get(fieldName).getDescribe().getType());
                //string fieldLabel = String.ValueOF(fieldMap.get(fieldName).getDescribe().getLabel());
                if(fieldType == 'REFERENCE'){
                    Schema.SObjectType referenceObjectType = fieldMap.get(fieldName).getDescribe().getReferenceTo()[0];
            		referencedObjectApiName = referenceObjectType.getDescribe().getName();
                    if(String.ValueOF(fieldDescribe.getReferenceTo()) == '(KTMYOB__MYOB_MetaData__c)'){
                        fieldType += fieldDescribe.getReferenceTo();
                    }
                }
                options.add(new Picklistwrapper(String.ValueOF(fieldMap.get(fieldName).getDescribe().getLabel()), apiName, 
                                               fieldType, field.getDescribe().isNillable(), referencedObjectApiName));
            }
        }
        return options;
    }

    /**
     * @description Contact and Invoice Configuration Component.
     * @param objectApiName - Default object from custom setting.
     * @param type - Company/Individual.
     * @return Object Data
     */
    @AuraEnabled public static ContactObjectWrapper getContactCusMetadataFields(string objectApiName, string type){
        ContactObjectWrapper contactObjectWrap =  new ContactObjectWrapper();
        try{
            list<Picklistwrapper> objectFields = getFieldMap(objectApiName);
            system.debug('### objectFields: '+objectFields);
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            system.debug('### objDescribe: '+objDescribe);
            List<ObjectInfo> childObjectInfos = new List<ObjectInfo>();
            system.debug('### childObjectInfos 1: '+childObjectInfos);
            for (Schema.ChildRelationship cr : objDescribe.getChildRelationships()) {
                Schema.DescribeSObjectResult childObjDescribe = cr.getChildSObject().getDescribe();
                if (childObjDescribe.isCreateable()) {
                    ObjectInfo objectInfo = new ObjectInfo();
                    objectInfo.value = String.valueOf(cr.getChildSObject());
                    objectInfo.label =  String.valueOf(cr.getChildSObject().getDescribe().getLabel());
                    objectInfo.name = String.valueOf(cr.getRelationshipName());
                    childObjectInfos.add(objectInfo);
                }
            }
            system.debug('### childObjectInfos 2: '+childObjectInfos);
            List<ObjectInfo> labelValueList = new List<ObjectInfo>();
            String query = 'SELECT Name, KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Field_API_Name__c , KTMYOB__Field_Value__c, KTMYOB__Data_Type__c, KTMYOB__Required__c, KTMYOB__Read_Only__c, KTMYOB__Help_Text__c, KTMYOB__Sequence_Number__c FROM ';
            if (type == 'Company') {
                query += 'KTMYOB__Contact_Company_Fields_Mapping__c';
            } else if (type == 'Individual') {
                query += 'KTMYOB__Contact_Individual_Fields_Mapping__c';
            } else if (type == 'Invoice') {
                query += 'KTMYOB__Invoice_Fields_Mapping__c';
            } else if (type == 'LineItem') {
                query += 'KTMYOB__LineItem_Fields_Mapping__c';
            }
            query += ' ORDER BY KTMYOB__Sequence_Number__c';
            system.debug('### query: '+query);
            List<SObject> ObjectField = Database.query(query);
            for (SObject obj : ObjectField) {
                ObjectInfo objInfo = new ObjectInfo();
                objInfo.type = (String) obj.get('KTMYOB__Data_Type__c');
                objInfo.name = (String) obj.get('Name');
                objInfo.label = (String) obj.get('KTMYOB__Field_Value__c');
                objInfo.value = (String) obj.get('KTMYOB__Field_API_Name__c');
                objInfo.helpText = (String) obj.get('KTMYOB__Help_Text__c');
                Object requiredValue = obj.get('KTMYOB__Required__c');
                if (requiredValue instanceof Boolean) {
                    objInfo.require = (Boolean) requiredValue;
                } 
                Object readOnlyValue = obj.get('KTMYOB__Read_Only__c');
                if (readOnlyValue instanceof Boolean) {
                    objInfo.readOnly = (Boolean) readOnlyValue;
                } 
                labelValueList.add(objInfo);
            }
            contactObjectWrap.Objectfields = objectFields;
            contactObjectWrap.childObjects = childObjectInfos;
            contactObjectWrap.customSettingObjectFields = labelValueList;
        }catch(Exception e){
            system.debug('$$$ getContactCusMetadataFields Error: ' + e);
            HandleCustomException.LogException(e);
            throw new AuraHandledException(e.getMessage());
        }
        return contactObjectWrap;
    }

    /**
     * @description Contact and Configuration Component : For Mapping Customer (Company - Account Default and Individual - Contact )
     * @param companyObject - Fields data & Object names to save in custom setting
     * @param individualObject - Fields data & Object names to save in custom setting
     * @return Object Data
     */
    @AuraEnabled public static Boolean updateContactConfig(String companyObject, String individualObject, boolean saveContactsDifferently){
        boolean updated = false;
        try{
            KTMYOB__MYOB_Objects_Configurations__c objConfig = [ SELECT Id, Name, SetupOwnerId, KTMYOB__Contact_Company_Object_Api_Name__c, KTMYOB__Contact_Individual_Object_Api_Name__c, KTMYOB__Save_Contacts_in_Different_Object__c	
                                                              FROM KTMYOB__MYOB_Objects_Configurations__c 
                                                              WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                              WITH SECURITY_ENFORCED ]; 
            if(companyObject != ''){
                objConfig.KTMYOB__Contact_Company_Object_Api_Name__c = companyObject;
            }
            if(individualObject != ''){
                objConfig.KTMYOB__Contact_Individual_Object_Api_Name__c = individualObject;
            }
            if (!String.isEmpty(companyObject) && !String.isEmpty(individualObject)) {
                updateInvoiceFieldMapping(companyObject, individualObject);
            }
            objConfig.KTMYOB__Save_Contacts_in_Different_Object__c = saveContactsDifferently;
            Database.SaveResult sR = Database.update(objConfig);
            updated = sR.isSuccess();
            system.debug('$$$ updateContactConfig:' +sR);
            return updated;
        }catch (Exception e) {
            system.debug('$$$ updateContactConfig:' +e);
            HandleCustomException.LogException(e);
            return updated;
        }
    }

    /**
     * @description Invoice and Configuration Component : To save ui data to custom setting.
     * @param objectFields - Default object from custom setting
     * @param objectType - Invoice/LineItem/Payment/Customer
     * @return 
     */
    @AuraEnabled public static void updateInvoiceFieldMapping(String companyObject, String individualObject){
        try{
            List<sObject> objectConfigurationListToUpdate = new List<sObject>();
            List<sObject> existingSettings = KTMYOB__Invoice_Fields_Mapping__c.getAll().values();
            system.debug('$$$ Company saveObjectConfiguration: ' + existingSettings);
            
            String CompanyUIDDataType = 'REFERENCE('+ companyObject +')';
            String IndividualUIDDataType = 'REFERENCE('+ individualObject +')';

            for (sObject setting : existingSettings) {
                if (setting.get('MYOB_Field_Api_Name__c') == 'CompanyUID') {
                    setting.put('Data_Type__c', CompanyUIDDataType);
                    objectConfigurationListToUpdate.add(setting);
                } else if(setting.get('MYOB_Field_Api_Name__c') == 'IndividualUID') {
                    setting.put('Data_Type__c', IndividualUIDDataType);
                    objectConfigurationListToUpdate.add(setting);
                } 
            }
            
            if(objectConfigurationListToUpdate.size() > 0){
                List<Database.SaveResult> sR = Database.update(objectConfigurationListToUpdate);
            }
        }catch (Exception e) {
            HandleCustomException.LogException(e);
        }
    }

    /**
     * @description Invoice and Configuration Component : To save ui data to custom setting.
     * @param objectFields - Default object from custom setting
     * @param objectType - Invoice/LineItem/Payment/Customer
     * @return Boolean
     */
    @AuraEnabled public static boolean saveObjectConfiguration(List<ObjectInfo> objectFields, string objectType){
        boolean updated = false;
        try{
            system.debug('@@@ saveObjectConfiguration objectFields: ' + objectFields);
            List<sObject> objectConfigurationListToUpdate = new List<sObject>();
            List<sObject> existingSettings = new list<sObject>();
            // List<KTMYOB__Contact_Company_Fields_Mapping__c> conConConfig = [ SELECT Id, Name, KTMYOB__Data_Type__c, KTMYOB__Field_API_Name__c, KTMYOB__Field_Value__c, 
            //                                                                  KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Read_Only__c, KTMYOB__Required__c, SetupOwnerId
            //                                                                  FROM KTMYOB__Contact_Company_Fields_Mapping__c 
            //                                                                  WHERE SetupOwnerId =: UserInfo.getOrganizationId()
            //                                                                  WITH SECURITY_ENFORCED  ];
            // List<KTMYOB__Contact_Individual_Fields_Mapping__c> conIndConfig = [ SELECT Id, Name, KTMYOB__Data_Type__c, KTMYOB__Field_API_Name__c, KTMYOB__Field_Value__c, 
            //                                                                     KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Read_Only__c, KTMYOB__Required__c, SetupOwnerId
            //                                                                     FROM KTMYOB__Contact_Individual_Fields_Mapping__c 
            //                                                                     WHERE SetupOwnerId =: UserInfo.getOrganizationId()
            //                                                                     WITH SECURITY_ENFORCED ];
            // system.debug('### KTMYOB__Contact_Company_Fields_Mapping__c: ' + conConConfig);
            // system.debug('### KTMYOB__Contact_Individual_Fields_Mapping__c: ' + conIndConfig);
            if(objectType=='Company'){
                existingSettings = KTMYOB__Contact_Company_Fields_Mapping__c.getAll().values();
                system.debug('$$$ Company saveObjectConfiguration: ' + existingSettings);
            }else if(objectType == 'Individual'){
                existingSettings = KTMYOB__Contact_Individual_Fields_Mapping__c.getAll().values();
                system.debug('$$$ Individual saveObjectConfiguration: ' + existingSettings);
            }
            for(ObjectInfo fieldName : objectFields){
                for (sObject setting : existingSettings) {
                    if (setting.get('name') == fieldName.Name) {
                        setting.put('Field_API_Name__c', fieldName.value);
                        objectConfigurationListToUpdate.add(setting);
                    }
                }
            }
            if(objectConfigurationListToUpdate.size() > 0){
                List<Database.SaveResult> sR = Database.update(objectConfigurationListToUpdate);
                for (Database.SaveResult saveResult : sR) {
                    if (saveResult.isSuccess()) {
                        updated = true;
                    }
                }
            }
        }catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        return updated;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /** @description Permission Set Component : Wrapper Class. */
    public class PermissionWrapper{
        /** @description Permission Set Component : For Id. */
        @AuraEnabled public String id {get;set;}
        /** @description Permission Set Component : For Name. */
        @AuraEnabled public String name {get;set;}
        /** @description Permission Set Component : For Setup Url. */
        @AuraEnabled public String setupUrl {get;set;}
    }
    
    /**
     * @description Permission Set Component : For list of permission sets from PermissionSet.
     * @return List of Permission Sets.
     */
    @AuraEnabled public static List<PermissionWrapper> fetchPermission(){
        List<PermissionWrapper> permissionWrapList = new List<PermissionWrapper>();
        List<PermissionSet> permissionList = new List<PermissionSet>();
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        // Use getOrgDomainUrl() or getCurrentRequestUrl() instead of getSalesforceBaseUrl()
        try{
            permissionList =[ SELECT Id, Name, Label, Type, Description, CreatedDate 
                              FROM PermissionSet 
                              WHERE Name IN ('MYOB_Integration_Admin','MYOB_Integration_Operational','MYOB_Integration_Read_Only')
                              WITH SECURITY_ENFORCED];
            if(permissionList.size()>0){
                for(PermissionSet p : permissionList){
                    PermissionWrapper pw = new PermissionWrapper();
                    pw.id = p.Id;
                    pw.name = p.Name;
                    pw.setupUrl = baseUrl + '/lightning/setup/PermSets/'+p.Id+'/PermissionSetAssignment/home';
                    permissionWrapList.add(pw);
                }
            }
        } catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        return permissionWrapList;
    }
    
    /** @description Permission Set Component : Wrapper Class. */
    public class PermissionSetsWrapper{
        /** @description Permission Set Component : For User Id. */
        @AuraEnabled public String userId {get;set;}
        /** @description Permission Set Component : For Name. */
        @AuraEnabled public String name {get;set;}
        /** @description Permission Set Component : For User Name. */
        @AuraEnabled public String userName {get;set;}
        /** @description Permission Set Component : For Email. */
        @AuraEnabled public String email {get;set;}
        /** @description Permission Set Component : For isActive. */
        @AuraEnabled public Boolean isActive {get;set;}
        /** @description Permission Set Component : For Permission Set Name. */
        @AuraEnabled public String permissionSetName {get;set;}
        /** @description Permission Set Component : For Permission Set Label. */
        @AuraEnabled public String permissionSetLabel {get;set;}
        /** @description Permission Set Component : For Profile. */
        @AuraEnabled public String profile {get;set;}
    }

    /**
     * @description Permission Set Component : For list of permission sets from PermissionSet.
     * @return List of Permission Sets.
     */
    @AuraEnabled public static List<PermissionSetsWrapper> fetchPermissionSets(){
        List<PermissionSetsWrapper> permissionWrapList = new List<PermissionSetsWrapper>(); 
        try{
            List<PermissionSetAssignment> perassign =[ SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Label, 
                                                        PermissionSet.Profile.Name, AssigneeId, Assignee.Name, Assignee.IsActive, Assignee.userName,
                                                        Assignee.email
                                                       FROM PermissionSetAssignment 
                                                       WHERE PermissionSet.Name IN ('MYOB_Integration_Admin','MYOB_Integration_Operational','MYOB_Integration_Read_Only')
                                                       WITH USER_MODE ];
            Set<Id> userIdSet = new Set<Id>();
            Map<Id,user> userMap = new Map<Id,User>(); 
            for(PermissionSetAssignment obj : perassign){
                userIdSet.add(obj.AssigneeId);
                PermissionSetsWrapper wrapObj = new PermissionSetsWrapper();
                wrapObj.userId = obj.AssigneeId;
                wrapObj.name = obj.Assignee.Name;
                wrapObj.username = obj.Assignee.username;
                wrapObj.email = obj.Assignee.email;
                wrapObj.IsActive = obj.Assignee.IsActive;
                wrapObj.permissionSetName = obj.PermissionSet.Name;
                wrapObj.permissionSetLabel= obj.PermissionSet.Label;
                permissionWrapList.add(wrapObj);
            }
            if(userIdSet.size() > 0){
                userMap = new Map<Id,User>([ SELECT Id, Name, Username, Email, ProfileId, profile.Name, IsActive 
                                             FROM User 
                                             WHERE Id IN: userIdSet 
                                             WITH USER_MODE ]);
                for(PermissionSetsWrapper obj : permissionWrapList){
                    if(userMap.containsKey(obj.userId)){
                        obj.profile = userMap.get(obj.userId).profile.Name;
                    }
                }
            }
        } catch (Exception e) {
            HandleCustomException.logException(e);
        }
        return permissionWrapList;
    }

}