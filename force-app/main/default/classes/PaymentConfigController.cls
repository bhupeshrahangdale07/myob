/**
 * @Author : Kandisa Technologies
 * @description MYOB Setup : Setup and Configuration Component [PaymentConfigurationCmp] & [setupPageCmp]
 * @created on        : 2-9-2024
 * @created by        : Piyush V Ganorkar
 * @last modified on  : 3-9-2024
 * @last modified by  : Piyush V Ganorkar
 */ 
public without sharing class PaymentConfigController {

    /** @description Payment and Configuration Component : Wrapper Class. */
    public class PaymentConfigWrapper{
        /** @description Payment and Configuration Component : KTMYOB__Payment_Fields_Mapping__c . */
        @AuraEnabled public List<KTMYOB__Payment_Fields_Mapping__c> PaymentFieldMappingSetting;
        /** @description Payment and Configuration Component : KTMYOB__MYOB_Objects_Configurations__c. */
        @AuraEnabled public KTMYOB__MYOB_Objects_Configurations__c objConfigSetting;
        /** @description Payment and Configuration Component : For paymentLabelSetting. */
        @AuraEnabled public String paymentLabelSetting { get; set; }
    }

    /**
     * @description Payment and Configuration Component : To retrive data from Custom Setting.
     * @return Custom setting fields and data.
     */
    @AuraEnabled public static PaymentConfigWrapper getPaymentConfiguration(){
        PaymentConfigWrapper icw = new PaymentConfigWrapper();
        try{
            List<KTMYOB__Payment_Fields_Mapping__c> payConfig = [ SELECT Id, Name, KTMYOB__Data_Type__c, KTMYOB__Field_API_Name__c, KTMYOB__Field_Value__c, 
                                                                             KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Read_Only__c, KTMYOB__Required__c, SetupOwnerId
                                                                             FROM KTMYOB__Payment_Fields_Mapping__c 
                                                                             WHERE SetupOwnerId =: UserInfo.getOrganizationId()
                                                                             WITH SECURITY_ENFORCED ];
            KTMYOB__MYOB_Objects_Configurations__c objConfig = [ SELECT Id, Name, SetupOwnerId, KTMYOB__Payment_Object_Api_Name__c	
                                                                 FROM KTMYOB__MYOB_Objects_Configurations__c 
                                                                 WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                                 WITH SECURITY_ENFORCED ];
            String paymentLabel = '';                                                                                                                      
            if (!String.isEmpty(objConfig.KTMYOB__Payment_Object_Api_Name__c)) {
                DescribeSObjectResult paymentDescribe = Schema.getGlobalDescribe().get(objConfig.KTMYOB__Payment_Object_Api_Name__c).getDescribe();
                paymentLabel = paymentDescribe.getLabel();
                System.debug('Payment Object Label: ' + paymentLabel);
            }
        
            icw.PaymentFieldMappingSetting = payConfig;	
            icw.objConfigSetting = objConfig;
            icw.paymentLabelSetting = paymentLabel;


        }catch(Exception e){
            HandleCustomException.LogException(e);
        }
        return icw;
    }
    
    /** @description Payment Configuration Component : Wrapper Class. */
    public class ObjectInfo {
        /** @description Payment Configuration Component : For name. */
        @AuraEnabled public String name { get; set; }
        /** @description Payment Configuration Component : For value. */
        @AuraEnabled public String value { get; set; }
        /** @description Payment Configuration Component : For label. */
        @AuraEnabled public String label { get; set; }
        /** @description Payment Configuration Component : For helpText. */
        @AuraEnabled public String helpText { get; set; }
        /** @description Payment Configuration Component : For type. */
        @AuraEnabled public String type { get; set; }
        /** @description Payment Configuration Component : For require. */
        @AuraEnabled public boolean require { get; set; }
        /** @description Payment Configuration Component : For readOnly. */
        @AuraEnabled public boolean readOnly { get; set; }
        /** @description Payment Configuration Component : For myobFieldName. */
        @AuraEnabled public string myobFieldName { get; set; }
    }

    /**
     * @description Payment Configuration Component : To set object list.
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

    /** @description Payment Configuration Component : Wrapper Class. */
    public class PaymentObjectWrapper{
        /** @description Payment Configuration Component : For Objectfields. */
        @AuraEnabled public list<Picklistwrapper> Objectfields;
        /** @description Payment Configuration Component : For customSettingObjectFields. */
        @AuraEnabled public list<ObjectInfo> customSettingObjectFields;
    }

    /** @description Payment Configuration Component : Wrapper Class. */
    public class Picklistwrapper {
        /** @description Payment Configuration Component : For label. */
        @AuraEnabled public String label { get; set; }
        /** @description Payment Configuration Component : For value. */
        @AuraEnabled public String value { get; set; }
        /** @description Payment Configuration Component : For fieldType. */
        @AuraEnabled public String fieldType { get; set; }
        /** @description Payment Configuration Component : For required. */
        @AuraEnabled public boolean required { get; set; }
        /** @description Payment Configuration Component : For referencedObjectApiName. */
        @AuraEnabled public String  referencedObjectApiName{ get; set; }
        
        /**
         * @description Payment Configuration Component : Constructor for direct access.
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
     * @description From getPaymentConfiguration, getCustomerFieldsNConfiguration() & getInvoiceFields methods.
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
     * @description Payment Configuration Component.
     * @param objectApiName - Default object from custom setting.
     * @param type - Payment.
     * @return Object Data
     */
    @AuraEnabled public static PaymentObjectWrapper getPaymentCusSettingFields(String objectApiName, String type){
        PaymentObjectWrapper paymentObjectWrap =  new PaymentObjectWrapper();
        try{
            list<Picklistwrapper> objectFields = getFieldMap(objectApiName);
            system.debug('### objectFields: '+objectFields);
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            system.debug('### objDescribe: '+objDescribe);
            List<ObjectInfo> labelValueList = new List<ObjectInfo>();
            String query = 'SELECT Name, KTMYOB__MYOB_Field_Api_Name__c, KTMYOB__Field_API_Name__c , KTMYOB__Field_Value__c, KTMYOB__Data_Type__c, KTMYOB__Required__c, KTMYOB__Read_Only__c, KTMYOB__Help_Text__c, KTMYOB__Sequence_Number__c FROM ';
            if (type == 'Payment') {
                query += 'KTMYOB__Payment_Fields_Mapping__c';
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
            paymentObjectWrap.Objectfields = objectFields;
            paymentObjectWrap.customSettingObjectFields = labelValueList;
        }catch(Exception e){
            system.debug('$$$ getPaymentCusSettingFields Error: ' + e);
            HandleCustomException.LogException(e);
            throw new AuraHandledException(e.getMessage());
        }
        return paymentObjectWrap;
    }

    /**
     * @description Payment Configuration Component : For Mapping Payment (Default: Payment - MYOB Invoice Payment )
     * @param paymentObject - Fields data & Object names to save in custom setting
     * @return Object Data
     */
    @AuraEnabled public static Boolean updatePaymentConfig(string paymentObject){
        boolean updated = false;
        try{
            KTMYOB__MYOB_Objects_Configurations__c objConfig = [ SELECT Id, Name, SetupOwnerId, KTMYOB__Payment_Object_Api_Name__c	
                                                              FROM KTMYOB__MYOB_Objects_Configurations__c 
                                                              WHERE SetupOwnerId =: UserInfo.getOrganizationId() 
                                                              WITH SECURITY_ENFORCED ]; 
            if(paymentObject != ''){
                objConfig.KTMYOB__Payment_Object_Api_Name__c = paymentObject;
            }
            Database.SaveResult sR = Database.update(objConfig);
            updated = sR.isSuccess();
            system.debug('$$$ updatePaymentConfig:' +sR);
            return updated;
        }catch (Exception e) {
            system.debug('$$$ updatePaymentConfig:' +e);
            HandleCustomException.LogException(e);
            return updated;
        }
    }

    /**
     * @description Payment Configuration Component : To save ui data to custom setting.
     * @param objectFields - Default object from custom setting
     * @param objectType - Payment
     * @return Boolean
     */
    @AuraEnabled public static boolean saveObjectConfiguration(List<ObjectInfo> objectFields, string objectType){
        boolean updated = false;
        try{
            system.debug('@@@ saveObjectConfiguration objectFields: ' + objectFields);
            List<sObject> objectConfigurationListToUpdate = new List<sObject>();
            List<sObject> existingSettings = new list<sObject>();
            if(objectType=='Payment'){
                existingSettings = KTMYOB__Payment_Fields_Mapping__c.getAll().values();
                system.debug('$$$ Payment saveObjectConfiguration: ' + existingSettings);
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