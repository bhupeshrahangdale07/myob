/**
 * @Author : Kandisa Technologies
 * @description MYOB Setup : Setup and Configuration Component [ContactConfigCmp] & [setupPageCmp]
 * @created on        : 2024
 * @created by        : Piyush V Ganorkar
 * @last modified on  : 9-2-2024
 * @last modified by  : Piyush V Ganorkar
 */ 
public with sharing class ContactConfigController {
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

    /** @description Contact Configuration Component : Wrapper Class. */
    public class ContactObjectWrapper{
        /** @description Contact and Configuration Component : For childObjects. */
        @AuraEnabled public list<ObjectInfo> childObjects;
        /** @description Contact Configuration Component : For Objectfields. */
        @AuraEnabled public list<Picklistwrapper> Objectfields;
        /** @description Contact Configuration Component : For customSettingObjectFields. */
        @AuraEnabled public list<ObjectInfo> customSettingObjectFields;
    }

    /** @description Contact Configuration Component : Wrapper Class. */
    public class Picklistwrapper {
        /** @description Contact Configuration Component : For label. */
        @AuraEnabled public String label { get; set; }
        /** @description Contact Configuration Component : For value. */
        @AuraEnabled public String value { get; set; }
        /** @description Contact Configuration Component : For fieldType. */
        @AuraEnabled public String fieldType { get; set; }
        /** @description Contact Configuration Component : For required. */
        @AuraEnabled public boolean required { get; set; }
        /** @description Contact Configuration Component : For referencedObjectApiName. */
        @AuraEnabled public String  referencedObjectApiName{ get; set; }
        
        /**
         * @description Contact Configuration Component : Constructor for direct access.
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
     * @description Contact Configuration Component.
     * @param objectApiName - Default object from custom setting.
     * @param type - Company/Individual.
     * @return Object Data
     */
    @AuraEnabled public static ContactObjectWrapper getContactCusSettingFields(string objectApiName, string type){
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
            system.debug('$$$ getContactCusSettingFields Error: ' + e);
            HandleCustomException.LogException(e);
            throw new AuraHandledException(e.getMessage());
        }
        return contactObjectWrap;
    }

    /**
     * @description Contact and Configuration Component : For Mapping Customer (Default: Comapny - Account and Individual - Contact )
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
     * @description Contact and Configuration Component : To save ui data to custom setting.
     * @param objectFields - Default object from custom setting
     * @param objectType - Customer - Company/Individual
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
}