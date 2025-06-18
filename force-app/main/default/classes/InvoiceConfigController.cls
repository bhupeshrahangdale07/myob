/**
 * @Author : Kandisa Technologies
 * @description MYOB Setup : Setup and Configuration Component [SetupConfigCmp] & [setupPageCmp] & [connectionResetCmp] & [generateInvoiceCustomerCreationForm] & [myobCustomerSync]
 * @created on        : 2024
 * @created by        : Piyush V Ganorkar
 * @last modified on  : 8-8-2024
 * @last modified by  : Piyush V Ganorkar
 */ 
@SuppressWarnings('PMD.UnusedLocalVariable') // For 'sR'(deleteMYOBIRec)
public without sharing class InvoiceConfigController {

    /** @description Invoice and Configuration Component : Wrapper Class. */
    public class InvoiceConfigWrapper{
        /** @description Invoice and Configuration Component : KTMYOB__Invoice_Fields_Mapping__c . */
        @AuraEnabled public List<KTMYOB__Invoice_Fields_Mapping__c> invoiceFieldMappingSetting;
        /** @description Invoice and Configuration Component : KTMYOB__LineItem_Fields_Mapping__c . */
        @AuraEnabled public List<KTMYOB__LineItem_Fields_Mapping__c> lineitemFieldMappingSetting;
        /** @description Invoice and Configuration Component : KTMYOB__MYOB_Objects_Configurations__c. */
        @AuraEnabled public KTMYOB__MYOB_Objects_Configurations__c objConfigSetting;
        /** @description Invoice and Configuration Component : For invoiceLabelSetting. */
        @AuraEnabled public String invoiceLabelSetting { get; set; }
        /** @description Invoice and Configuration Component : For lineitemLabelSetting. */
        @AuraEnabled public String lineitemLabelSetting { get; set; }
    }

    /**
     * @description Invoice and Configuration Component : To retrive data from Custom Setting.
     * @return Custom setting fields and data.
     */
    @AuraEnabled public static InvoiceConfigWrapper getInvoiceConfiguration(){
        InvoiceConfigWrapper icw = new InvoiceConfigWrapper();
        try{
            List<KTMYOB__Invoice_Fields_Mapping__c> conConConfig = [ SELECT Id, Name, KTMYOB__Data_Type__c, KTMYOB__Field_API_Name__c, KTMYOB__Field_Value__c, 
                                                                             KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Read_Only__c, KTMYOB__Required__c, SetupOwnerId
                                                                             FROM KTMYOB__Invoice_Fields_Mapping__c 
                                                                             WHERE SetupOwnerId =: UserInfo.getOrganizationId()
                                                                             WITH SECURITY_ENFORCED ];
            List<KTMYOB__LineItem_Fields_Mapping__c> conIndConfig = [ SELECT Id, Name, KTMYOB__Data_Type__c, KTMYOB__Field_API_Name__c, KTMYOB__Field_Value__c, 
                                                                                KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Read_Only__c, KTMYOB__Required__c, SetupOwnerId
                                                                                FROM KTMYOB__LineItem_Fields_Mapping__c
                                                                                WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                                                WITH SECURITY_ENFORCED ];
            KTMYOB__MYOB_Objects_Configurations__c objConfig = [ SELECT Id, Name, SetupOwnerId, KTMYOB__Invoice_Object_Api_Name__c, KTMYOB__LineItem_Object_Api_Name__c, KTMYOB__Save_Contacts_in_Different_Object__c	
                                                                 FROM KTMYOB__MYOB_Objects_Configurations__c 
                                                                 WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                                 WITH SECURITY_ENFORCED ];
            String invoiceLabel = '';                                                           
            String lineitemLabel = '';                                                             
            if (!String.isEmpty(objConfig.KTMYOB__Invoice_Object_Api_Name__c)) {
                DescribeSObjectResult invoiceDescribe = Schema.getGlobalDescribe().get(objConfig.KTMYOB__Invoice_Object_Api_Name__c).getDescribe();
                invoiceLabel = invoiceDescribe.getLabel();
                System.debug('Invoice Object Label: ' + invoiceLabel);
            }
        
            if (!String.isEmpty(objConfig.KTMYOB__LineItem_Object_Api_Name__c)) {
                DescribeSObjectResult lineitemDescribe = Schema.getGlobalDescribe().get(objConfig.KTMYOB__LineItem_Object_Api_Name__c).getDescribe();
                lineitemLabel = lineitemDescribe.getLabel();
                System.debug('Line Item Object Label: ' + lineitemLabel);
            }
            icw.invoiceFieldMappingSetting = conConConfig;	
            icw.lineitemFieldMappingSetting = conIndConfig;
            icw.objConfigSetting = objConfig;
            icw.invoiceLabelSetting = invoiceLabel;
            icw.lineitemLabelSetting = lineitemLabel;


        }catch(Exception e){
            HandleCustomException.LogException(e);
        }
        return icw;
    }
    
    /** @description Configuration Component : Wrapper Class. */
    public class ObjectInfo {
        /** @description Configuration Component : For name. */
        @AuraEnabled public String name { get; set; }
        /** @description Configuration Component : For value. */
        @AuraEnabled public String value { get; set; }
        /** @description Configuration Component : For label. */
        @AuraEnabled public String label { get; set; }
        /** @description Configuration Component : For helpText. */
        @AuraEnabled public String helpText { get; set; }
        /** @description Configuration Component : For type. */
        @AuraEnabled public String type { get; set; }
        /** @description Configuration Component : For require. */
        @AuraEnabled public boolean require { get; set; }
        /** @description Configuration Component : For readOnly. */
        @AuraEnabled public boolean readOnly { get; set; }
        /** @description Configuration Component : For myobFieldName. */
        @AuraEnabled public string myobFieldName { get; set; }
    }

    /**
     * @description Configuration Component : To set object list.
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

    /** @description Invoice Configuration Component : Wrapper Class. */
    public class InvoiceObjectWrapper{
        /** @description Configuration Component : For childObjects. */
        @AuraEnabled public list<ObjectInfo> childObjects;
        /** @description Invoice Configuration Component : For Objectfields. */
        @AuraEnabled public list<Picklistwrapper> Objectfields;
        /** @description Invoice Configuration Component : For customSettingObjectFields. */
        @AuraEnabled public list<ObjectInfo> customSettingObjectFields;
    }

    /** @description Invoice Configuration Component : Wrapper Class. */
    public class Picklistwrapper {
        /** @description Invoice Configuration Component : For label. */
        @AuraEnabled public String label { get; set; }
        /** @description Invoice Configuration Component : For value. */
        @AuraEnabled public String value { get; set; }
        /** @description Invoice Configuration Component : For fieldType. */
        @AuraEnabled public String fieldType { get; set; }
        /** @description Invoice Configuration Component : For required. */
        @AuraEnabled public boolean required { get; set; }
        /** @description Invoice Configuration Component : For referencedObjectApiName. */
        @AuraEnabled public String  referencedObjectApiName{ get; set; }
        
        /**
         * @description Invoice Configuration Component : Constructor for direct access.
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
    @AuraEnabled public static List<Picklistwrapper> getFieldMap(String sObjectType, String type) {
        List<Picklistwrapper> options = new List<Picklistwrapper>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType targetType = schemaMap.get(sObjectType);
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        String contactComapnyObjectApiName = '';
        String contactIndividualObjectApiName = '';
        KTMYOB__MYOB_Objects_Configurations__c objConfig = [ SELECT Id, Name, SetupOwnerId, KTMYOB__Contact_Company_Object_Api_Name__c, KTMYOB__Contact_Individual_Object_Api_Name__c, KTMYOB__Save_Contacts_in_Different_Object__c	
                                                            FROM KTMYOB__MYOB_Objects_Configurations__c 
                                                            WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                            WITH SECURITY_ENFORCED ];
        for(String fieldName : fieldMap.keySet()){
            Schema.SObjectField field = fieldMap.get(fieldName);
            String apiName = fieldMap.get(fieldName).getDescribe().getName();
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            string referencedObjectApiName='';
            if(String.isNotBlank(apiName) && field.getDescribe().isUpdateable() || String.ValueOF(fieldMap.get(fieldName).getDescribe().getType()) == 'ADDRESS'){
                String fieldType = String.valueOf(fieldMap.get(fieldName).getDescribe().getType());
                if(fieldType == 'REFERENCE'){
                    Schema.SObjectType referenceObjectType = fieldMap.get(fieldName).getDescribe().getReferenceTo()[0];
            		referencedObjectApiName = referenceObjectType.getDescribe().getName();
                    if(type == 'Invoice'){
                        if(!String.isEmpty(objConfig.KTMYOB__Contact_Company_Object_Api_Name__c)) { 
                            contactComapnyObjectApiName = objConfig.KTMYOB__Contact_Company_Object_Api_Name__c;
                            String objectSearch = '('+contactComapnyObjectApiName+')';
                            if(String.ValueOF(fieldDescribe.getReferenceTo()) == objectSearch){
                                system.debug('$$$ fieldDescribe1 : ' + String.ValueOF(fieldDescribe.getReferenceTo()));
                                fieldType += fieldDescribe.getReferenceTo();
                            }
                        }
                        if (objConfig.KTMYOB__Save_Contacts_in_Different_Object__c == true && !String.isEmpty(objConfig.KTMYOB__Contact_Individual_Object_Api_Name__c)) {
                            contactIndividualObjectApiName = objConfig.KTMYOB__Contact_Individual_Object_Api_Name__c;
                            String objectSearch = '('+contactIndividualObjectApiName+')';
                            if(String.ValueOF(fieldDescribe.getReferenceTo()) == objectSearch){
                                system.debug('$$$ fieldDescribe2 : ' + String.ValueOF(fieldDescribe.getReferenceTo()));
                                fieldType += fieldDescribe.getReferenceTo();
                            }
                        }
                    }else{
                        if(String.ValueOF(fieldDescribe.getReferenceTo()) == '(KTQB__QB_MetaData__c)'){
                            fieldType += fieldDescribe.getReferenceTo();
                        }
                    }
                }
                options.add(new Picklistwrapper(String.ValueOF(fieldMap.get(fieldName).getDescribe().getLabel()), apiName, 
                                               fieldType, field.getDescribe().isNillable(), referencedObjectApiName));
            }
        }
        return options;
    }

    /**
     * @description Invoice Configuration Component.
     * @param objectApiName - Default object from custom setting.
     * @param type - Invoice/LineItem.
     * @return Object Data
     */
    @AuraEnabled public static InvoiceObjectWrapper getInvoiceCusSettingFields(String objectApiName, String type){
        InvoiceObjectWrapper invoiceObjectWrap =  new InvoiceObjectWrapper();
        try{
            list<Picklistwrapper> objectFields = getFieldMap(objectApiName, type);
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
            if (type == 'Invoice') {
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
            invoiceObjectWrap.Objectfields = objectFields;
            invoiceObjectWrap.childObjects = childObjectInfos;
            invoiceObjectWrap.customSettingObjectFields = labelValueList;
        }catch(Exception e){
            system.debug('$$$ getInvoiceCusSettingFields Error: ' + e);
            HandleCustomException.LogException(e);
            throw new AuraHandledException(e.getMessage());
        }
        return invoiceObjectWrap;
    }

    /**
     * @description Invoice Configuration Component : For Mapping Invoice (Default: Invoice - MYOB Invoice and LineItem - MYOB Invoice Line Item )
     * @param invoiceObject - Fields data & Object names to save in custom setting
     * @param lineitemObject - Fields data & Object names to save in custom setting
     * @return Object Data
     */
    @AuraEnabled public static Boolean updateContactConfig(string invoiceObject, string lineitemObject){
        boolean updated = false;
        try{
            KTMYOB__MYOB_Objects_Configurations__c objConfig = [ SELECT Id, Name, SetupOwnerId, KTMYOB__Invoice_Object_Api_Name__c, KTMYOB__LineItem_Object_Api_Name__c	
                                                              FROM KTMYOB__MYOB_Objects_Configurations__c 
                                                              WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                              WITH SECURITY_ENFORCED ]; 
            if(invoiceObject != ''){
                objConfig.KTMYOB__Invoice_Object_Api_Name__c = invoiceObject;
            }
            if(lineitemObject != ''){
                objConfig.KTMYOB__LineItem_Object_Api_Name__c = lineitemObject;
            }
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
     * @return Boolean
     */
    @AuraEnabled public static boolean saveObjectConfiguration(List<ObjectInfo> objectFields, string objectType){
        boolean updated = false;
        try{
            system.debug('@@@ saveObjectConfiguration objectFields: ' + objectFields);
            List<sObject> objectConfigurationListToUpdate = new List<sObject>();
            List<sObject> existingSettings = new list<sObject>();
            if(objectType=='Invoice'){
                existingSettings = KTMYOB__Invoice_Fields_Mapping__c.getAll().values();
                system.debug('$$$ Invoice saveObjectConfiguration: ' + existingSettings);
            }else if(objectType == 'LineItem'){
                existingSettings = KTMYOB__LineItem_Fields_Mapping__c.getAll().values();
                system.debug('$$$ LineItem saveObjectConfiguration: ' + existingSettings);
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