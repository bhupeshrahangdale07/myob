/**
 * @Author : Kandisa Technologies
 * @description MYOB Setup : Generate Invoice Component [GenerateInvoice]
 * @created on        : 2024
 * @last modified on  : 16-10-2024
 * @last modified by  : Piyush V Ganorkar
 */ 
public with sharing class GenerateInvoiceController {
    public static String contactCompanyObjectApiName;
    public static String contactIndividualObjectApiName;
    public static SObject contactCompanySObject;
    public static SObject contactIndividualSObject;
    public static Map<String,KTMYOB__Contact_Company_Fields_Mapping__c> mapMYOBApiNameCompanyData = new Map<String,KTMYOB__Contact_Company_Fields_Mapping__c>();
    public static Map<String,KTMYOB__Contact_Individual_Fields_Mapping__c> mapMYOBApiNameIndividualData = new Map<String,KTMYOB__Contact_Individual_Fields_Mapping__c>();

    public static String productObjectApiName;
    public static SObject productSOBject;
    public static Map<String,KTMYOB__Product_Fields_Mapping__c> mapMYOBApiNameProductData = new Map<String,KTMYOB__Product_Fields_Mapping__c>();
	
    /** @description : Wrapper Class */
    public class generateInvoiceCustomerDetails {
        @AuraEnabled
        public Map<String,String> mapOfMyobFldApiNameNdSfFldApiNameCompany { get; set; }
        @AuraEnabled
        public Map<String,String> mapOfMyobFldApiNameNdSfFldApiNameIndividual { get; set; }
        @AuraEnabled
        public List<Map<String, Object>> listOfMapOfSelectedCustomer { get; set; }
        @AuraEnabled
        public Integer companyRecordNo { get; set; }
        // Constructor to initialize maps
        public generateInvoiceCustomerDetails() {
            this.mapOfMyobFldApiNameNdSfFldApiNameCompany = new Map<String,String>();
            this.mapOfMyobFldApiNameNdSfFldApiNameIndividual = new Map<String,String>();
            this.listOfMapOfSelectedCustomer = new List<Map<String,String>>();
        }
    }

    /** @description : Wrapper Class */
    public class generateInvoiceProductDetails {
        @AuraEnabled
        public List<Map<String, Object>> listOfMapOfSelectedProduct { get; set; }
        @AuraEnabled
        public Map<String,String> mapOfMyobFldApiNameNdSfFldApiNameProduct { get; set; }
        @AuraEnabled
        public List<sObject> metadataTypeNdRec { get; set; }
        // Constructor to initialize maps
        public generateInvoiceProductDetails() {
            this.listOfMapOfSelectedProduct= new List<Map<String, Object>>();
            this.mapOfMyobFldApiNameNdSfFldApiNameProduct = new Map<String,String>();
            this.metadataTypeNdRec = new List<sObject>();
        }
    }
    
    /**
     * @description Generate Invoice Component : For getting customer list.
     * @param Null
     * @return Void
     */
    @AuraEnabled 
    public static generateInvoiceCustomerDetails customerList(String searchStr, String customerID){
        generateInvoiceCustomerDetails wrapper = new generateInvoiceCustomerDetails();
        try{
            Set<String> companyFieldsToQuery = new Set<String>();
            Set<String> individualFieldsToQuery = new Set<String>();
            List<Map<String, Object>> listOfMapOfSelectedCustomerCompany = new List<Map<String, Object>>();
            List<Map<String, Object>> listOfMapOfSelectedCustomerIndividual = new List<Map<String, Object>>();

			ContactDynamicController cdc = new ContactDynamicController();

            if(String.isNotBlank(ContactDynamicController.contactCompanyObjectApiName) && String.isNotBlank(ContactDynamicController.contactIndividualObjectApiName) && ContactDynamicController.contactCompanySObject != null && ContactDynamicController.contactIndividualSObject != null){
                contactCompanyObjectApiName = ContactDynamicController.contactCompanyObjectApiName;
                contactIndividualObjectApiName = ContactDynamicController.contactIndividualObjectApiName;
                contactCompanySObject = ContactDynamicController.contactCompanySObject;
                contactIndividualSObject = ContactDynamicController.contactIndividualSObject;
                mapMYOBApiNameCompanyData = ContactDynamicController.mapMYOBApiNameCompanyData;
                mapMYOBApiNameIndividualData = ContactDynamicController.mapMYOBApiNameIndividualData;

                system.debug('$$$ contactCompanyObjectApiName: ' + contactCompanyObjectApiName + ' ' + 'contactIndividualObjectApiName: ' + contactIndividualObjectApiName);
                system.debug('$$$ contactCompanySObject: ' + contactCompanySObject + ' ' + 'contactIndividualSObject: ' + contactIndividualSObject);
                system.debug('$$$ mapMYOBApiNameCompanyData: ' + mapMYOBApiNameCompanyData + ' ' + 'mapMYOBApiNameIndividualData: ' + mapMYOBApiNameIndividualData);
            }
            
            if( String.isNotBlank(mapMYOBApiNameCompanyData.get('UID')?.KTMYOB__Field_API_Name__c) && String.isNotBlank(mapMYOBApiNameIndividualData.get('UID')?.KTMYOB__Field_API_Name__c) && 
                String.isNotBlank(contactCompanyObjectApiName) && String.isNotBlank(contactIndividualObjectApiName)) {
                String partialMatches = '%' + searchStr + '%';
                                
                if(!mapMYOBApiNameCompanyData.isEmpty() && mapMYOBApiNameCompanyData.size() >0){
                    for(KTMYOB__Contact_Company_Fields_Mapping__c custData : mapMYOBApiNameCompanyData.Values()){
                        if(String.isNotBlank(custData.KTMYOB__Field_API_Name__c)){
                            companyFieldsToQuery.add(custData.KTMYOB__Field_API_Name__c);
                        }
                    }
                    String contactQuery = 'SELECT Id,'+String.escapeSingleQuotes(String.join(companyFieldsToQuery, ','))+' FROM '+String.escapeSingleQuotes(contactCompanyObjectApiName);
                    if(String.isNotBlank(searchStr)){
                        contactQuery+= ' WHERE Name LIKE :partialMatches';
                    }else if (String.isNotBlank(customerID)){
                        contactQuery+= ' WHERE Id = :customerID';
                    }else{
                        contactQuery+= ' WHERE Name != Null';
                    }
                    system.debug('$$$ Company contactQuery: '+contactQuery);
                    
                    List<SObject> contactRecordsQueried = Database.query(contactQuery);
                    List<Map<String, Object>> listOfMapOfSelectedCustomer  = new List<Map<String, Object>>();
                    Map<String,String> mapOfMyobFldApiNameNdSfFldApiNameCompany = new Map<String,String>();

                    for(SObject contactRecordQueried : contactRecordsQueried) {
                        Map<String,Object> custFldMap = new Map<String,Object>();
                        //String recordUID = (String) contactRecordQueried.get(mapMYOBApiNameCompanyData.get('UID').KTMYOB__Field_API_Name__c);
                        //if (String.isNotBlank(recordUID)) {
                            custFldMap.put('Id',contactRecordQueried.get('Id'));
                            for (String myobFieldApiName : mapMYOBApiNameCompanyData.keySet()) {
                                if (String.isNotBlank(myobFieldApiName)) {
                                    if (String.isNotBlank(mapMYOBApiNameCompanyData.get(myobFieldApiName).KTMYOB__Field_API_Name__c)) {
                                        if(contactRecordQueried.get((mapMYOBApiNameCompanyData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c) != null){
                                            custFldMap.put(myobFieldApiName, contactRecordQueried.get((mapMYOBApiNameCompanyData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c));
                                            custFldMap.put('ObjectApiName',contactCompanyObjectApiName);
                                        }
                                        if(!mapOfMyobFldApiNameNdSfFldApiNameCompany.containsKey(myobFieldApiName)){
                                            mapOfMyobFldApiNameNdSfFldApiNameCompany.put(myobFieldApiName,mapMYOBApiNameCompanyData.get(myobFieldApiName).KTMYOB__Field_API_Name__c);
                                        }
                                    }                           
                                }
                            }
                        //}
                        if(custFldMap.size()>0){
                            listOfMapOfSelectedCustomer.add(custFldMap);
                        }
                    }
                    wrapper.mapOfMyobFldApiNameNdSfFldApiNameCompany = mapOfMyobFldApiNameNdSfFldApiNameCompany;
                    listOfMapOfSelectedCustomerCompany = listOfMapOfSelectedCustomer;
                    system.debug('$$$ mapOfMyobFldApiNameNdSfFldApiNameCompany: '+mapOfMyobFldApiNameNdSfFldApiNameCompany);
                }
                if(!mapMYOBApiNameIndividualData.isEmpty() && mapMYOBApiNameIndividualData.size() >0){
                    for(KTMYOB__Contact_Individual_Fields_Mapping__c custData : mapMYOBApiNameIndividualData.Values()){
                        if(String.isNotBlank(custData.KTMYOB__Field_API_Name__c)){
                            individualFieldsToQuery.add(custData.KTMYOB__Field_API_Name__c);
                        }
                    }
                    String contactQuery = 'SELECT Id,'+String.escapeSingleQuotes(String.join(individualFieldsToQuery, ','))+' FROM '+String.escapeSingleQuotes(contactIndividualObjectApiName);
                    if(String.isNotBlank(searchStr)){
                        contactQuery+= ' WHERE Name LIKE :partialMatches';
                    }else if (String.isNotBlank(customerID)){
                        contactQuery+= ' WHERE Id = :customerID';
                    }else{
                        contactQuery+= ' WHERE Name != Null';
                    }
                    system.debug('$$$ Individual contactQuery: '+contactQuery);
                    
                    List<SObject> contactRecordsQueried = Database.query(contactQuery);
					List<Map<String, Object>> listOfMapOfSelectedCustomer  = new List<Map<String, Object>>();
                    Map<String,String> mapOfMyobFldApiNameNdSfFldApiNameIndividual = new Map<String,String>();

                    for (SObject contactRecordQueried : contactRecordsQueried) {
                        Map<String,Object> custFldMap = new Map<String,Object>();
                        
                        //String recordUID = (String) contactRecordQueried.get(mapMYOBApiNameIndividualData.get('UID').KTMYOB__Field_API_Name__c);
                        //if (String.isNotBlank(recordUID)) {
                            custFldMap.put('Id',contactRecordQueried.get('Id'));
                            for (String myobFieldApiName : mapMYOBApiNameIndividualData.keySet()) {
                                if (String.isNotBlank(myobFieldApiName)) {
                                    if (String.isNotBlank(mapMYOBApiNameIndividualData.get(myobFieldApiName).KTMYOB__Field_API_Name__c)) {
                                        if(contactRecordQueried.get((mapMYOBApiNameIndividualData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c) != null){
                                            custFldMap.put(myobFieldApiName, contactRecordQueried.get((mapMYOBApiNameIndividualData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c));
                                            custFldMap.put('ObjectApiName',contactIndividualObjectApiName);
                                        }
                                        if(!mapOfMyobFldApiNameNdSfFldApiNameIndividual.containsKey(myobFieldApiName)){
                                            mapOfMyobFldApiNameNdSfFldApiNameIndividual.put(myobFieldApiName,mapMYOBApiNameIndividualData.get(myobFieldApiName).KTMYOB__Field_API_Name__c);
                                        }
                                    }                           
                                }
                            }
                        //}
                        if(custFldMap.size()>0){
                            listOfMapOfSelectedCustomer.add(custFldMap);
                        }
                    }
                    wrapper.mapOfMyobFldApiNameNdSfFldApiNameIndividual = mapOfMyobFldApiNameNdSfFldApiNameIndividual;
                    listOfMapOfSelectedCustomerIndividual = listOfMapOfSelectedCustomer;
                    system.debug('$$$ mapOfMyobFldApiNameNdSfFldApiNameIndividual: '+mapOfMyobFldApiNameNdSfFldApiNameIndividual);

                    // Combine company and individual data into a single list
                    List<Map<String, Object>> combinedCustomerList = new List<Map<String, Object>>();
                    combinedCustomerList.addAll(listOfMapOfSelectedCustomerCompany);
                    combinedCustomerList.addAll(listOfMapOfSelectedCustomerIndividual);
                    // Set the combined list to the wrapper
                    wrapper.listOfMapOfSelectedCustomer = combinedCustomerList;
                    wrapper.companyRecordNo = listOfMapOfSelectedCustomerCompany.size();
                }
                system.debug('$$$ listOfMapOfSelectedCustomerCompany' +listOfMapOfSelectedCustomerCompany);
                system.debug('$$$ listOfMapOfSelectedCustomerIndividual' +listOfMapOfSelectedCustomerIndividual);
            }
        } catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        return wrapper;
    }
    
    /**
     * @description Generate Invoice Component : For getting product list.
     * @param Null
     * @return Void
     */
    @AuraEnabled 
    public static generateInvoiceProductDetails productList(String searchStr){
       generateInvoiceProductDetails wrapper = new generateInvoiceProductDetails();
        try{
            Set<String> productFieldsToQuery = new Set<String>();

            KTMYOB__MYOB_Objects_Configurations__c myobObjectConfigs = KTMYOB__MYOB_Objects_Configurations__c.getOrgDefaults();
            productObjectApiName = myobObjectConfigs.KTMYOB__Product_Object_Api_Name__c;

            if(productSOBject == null){
                if(String.isNotBlank(productObjectApiName)){
                    productSOBject = Schema.getGlobalDescribe().get(productObjectApiName).newSObject();
                }
            }
            for(KTMYOB__Product_Fields_Mapping__c productCust : KTMYOB__Product_Fields_Mapping__c.getall().values()){
                if(String.isNotBlank(productCust.KTMYOB__MYOB_Field_Api_Name__c)){
                    mapMYOBApiNameProductData.put(productCust.KTMYOB__MYOB_Field_Api_Name__c,productCust);
                }
            }
            system.debug('$$$ productObjectApiName: ' + productObjectApiName + ' ' + 'productSOBject: ' + productSOBject + ' ' + 'mapMYOBApiNameProductData: ' + mapMYOBApiNameProductData);
            
            if(String.isNotBlank(mapMYOBApiNameProductData.get('UID')?.KTMYOB__Field_API_Name__c) && String.isNotBlank(productObjectApiName)) {
                system.debug('### 4');
                String partialMatches = '%' + searchStr + '%';
                
                if(!mapMYOBApiNameProductData.isEmpty() && mapMYOBApiNameProductData.size() >0){
                    for(KTMYOB__Product_Fields_Mapping__c custData : mapMYOBApiNameProductData.Values()){
                        if(String.isNotBlank(custData.KTMYOB__Field_API_Name__c)){
                            productFieldsToQuery.add(custData.KTMYOB__Field_API_Name__c);
                        }
                    }
                    String productQuery = 'SELECT Id,'+String.escapeSingleQuotes(String.join(productFieldsToQuery, ','))+' FROM '+String.escapeSingleQuotes(productObjectApiName);
                    if(String.isNotBlank(searchStr)){
                        productQuery+= ' WHERE Name LIKE :partialMatches';
                    }else{
                        productQuery+= ' WHERE Name != Null';
                    }
                    system.debug('$$$ productQuery: '+productQuery);
 
                    List<SObject> productRecordsQueried = Database.query(productQuery);
					List<Map<String, Object>> listOfMapOfSelectedCustomer  = new List<Map<String, Object>>();
                    Map<String,String> mapOfMyobFldApiNameNdSfFldApiNameProduct = new Map<String,String>();

                    for (SObject productRecordQueried : productRecordsQueried) {
                        Map<String,Object> custFldMap = new Map<String,Object>();

                        String recordUID = (String) productRecordQueried.get(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c);
                        if (String.isNotBlank(recordUID)) {
                            custFldMap.put('Id',productRecordQueried.get('Id'));
                            for (String myobFieldApiName : mapMYOBApiNameProductData.keySet()) {
                                if (String.isNotBlank(myobFieldApiName)) {
                                    if (String.isNotBlank(mapMYOBApiNameProductData.get(myobFieldApiName).KTMYOB__Field_API_Name__c)) {
                                        if(productRecordQueried.get((mapMYOBApiNameProductData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c) != null){
                                            custFldMap.put(myobFieldApiName, productRecordQueried.get((mapMYOBApiNameProductData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c));
                                        }
                                        if(!mapOfMyobFldApiNameNdSfFldApiNameProduct.containsKey(myobFieldApiName)){
                                            mapOfMyobFldApiNameNdSfFldApiNameProduct.put(myobFieldApiName,mapMYOBApiNameProductData.get(myobFieldApiName).KTMYOB__Field_API_Name__c);
                                        }
                                    }                           
                                }
                            }
                        }
                        if(custFldMap.size()>0){
                            listOfMapOfSelectedCustomer.add(custFldMap);
                        }
                    }
                    wrapper.mapOfMyobFldApiNameNdSfFldApiNameProduct = mapOfMyobFldApiNameNdSfFldApiNameProduct;
                    wrapper.listOfMapOfSelectedProduct = listOfMapOfSelectedCustomer;
                    system.debug('$$$ mapOfMyobFldApiNameNdSfFldApiNameProduct: '+mapOfMyobFldApiNameNdSfFldApiNameProduct);
                }
            }
            String metadataCategory;
            List<KTMYOB__MYOB_MetaData__c>  metadata = [ SELECT Id, Name, KTMYOB__MYOB_Id__c, KTMYOB__Metadata_Type__c, KTMYOB__Tax_Code__c, KTMYOB__Tax_Type__c, KTMYOB__Tax_Rate__c
                                                         FROM KTMYOB__MYOB_MetaData__c 
                                                         WHERE KTMYOB__Active__c = true AND KTMYOB__Metadata_Type__c = 'TAX_CODE'
                                                         WITH SECURITY_ENFORCED ];
            if (metadata != null && !metadata.isEmpty()) {
                for (KTMYOB__MYOB_MetaData__c record : metadata) {
                    wrapper.metadataTypeNdRec.add(record);
                }
            }
        } catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        system.debug('$$$ generateInvoiceProductDetails: '+wrapper);
        return wrapper;
    }

    
    /**
     * @description Generate Invoice Component : For getting product list.
     * @param Null
     * @return Void
     */
    @AuraEnabled 
    public static KTMYOB__MYOB_Objects_Configurations__c getCustomSettingDetails(){
        KTMYOB__MYOB_Objects_Configurations__c myobObjectConfigs;
        try{
            myobObjectConfigs = KTMYOB__MYOB_Objects_Configurations__c.getOrgDefaults();
        }catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        return myobObjectConfigs;
    }

}