public without sharing class ContactDynamicController {
    public static KTMYOB__MYOB_Credential__c  myobInfo = MYOB_Authorization_cls.myobInfo;

    public static String contactCompanyObjectApiName;
    public static String contactIndividualObjectApiName;
    public static Boolean contactSavedInDiffOBj;
    public static SObject contactCompanySObject;
    public static SObject contactIndividualSObject;
    public static Map<String,KTMYOB__Contact_Company_Fields_Mapping__c> mapMYOBApiNameCompanyData = new Map<String,KTMYOB__Contact_Company_Fields_Mapping__c>();
    public static Map<String,KTMYOB__Contact_Individual_Fields_Mapping__c> mapMYOBApiNameIndividualData = new Map<String,KTMYOB__Contact_Individual_Fields_Mapping__c>();

    public static boolean isIndividualContact = false;

    
    public ContactDynamicController(){
        generateObjectFieldMapping();
    }
    
    /* @description helper: to prepare the contact data */ 
    public static void generateObjectFieldMapping(){
      try{
            KTMYOB__MYOB_Objects_Configurations__c myobObjectConfigs = KTMYOB__MYOB_Objects_Configurations__c.getOrgDefaults();
            contactCompanyObjectApiName = myobObjectConfigs.KTMYOB__Contact_Company_Object_Api_Name__c;
            contactIndividualObjectApiName = myobObjectConfigs.KTMYOB__Contact_Individual_Object_Api_Name__c;
            contactSavedInDiffOBj = myobObjectConfigs.KTMYOB__Save_Contacts_in_Different_Object__c;

            if(contactCompanySObject == null){
                if(String.isNotBlank(contactCompanyObjectApiName)){
                    contactCompanySObject = Schema.getGlobalDescribe().get(contactCompanyObjectApiName).newSObject();
                }
            }
            if(contactIndividualSObject == null){
                if(String.isNotBlank(contactIndividualObjectApiName)){
                    contactIndividualSObject = Schema.getGlobalDescribe().get(contactIndividualObjectApiName).newSObject();
                }
            }
            for(KTMYOB__Contact_Company_Fields_Mapping__c companyCust : KTMYOB__Contact_Company_Fields_Mapping__c.getall().values()){
                if(String.isNotBlank(companyCust.KTMYOB__MYOB_Field_Api_Name__c)){
                    mapMYOBApiNameCompanyData.put(companyCust.KTMYOB__MYOB_Field_Api_Name__c,companyCust);
                }
            }
            for(KTMYOB__Contact_Individual_Fields_Mapping__c individualCust : KTMYOB__Contact_Individual_Fields_Mapping__c.getall().values()){
                if(String.isNotBlank(individualCust.KTMYOB__MYOB_Field_Api_Name__c)){
                    mapMYOBApiNameIndividualData.put(individualCust.KTMYOB__MYOB_Field_Api_Name__c,individualCust);
                }
            }
        }catch(Exception ex){
            HandleCustomException.LogException(ex);
        } 
    }

    /*
     * @description AuraMethod : To Create/Update the Contact from SF to MYOB.
        @param contactId - contact record id.
        @param operation - 'CreateOrUpdate'
        @return component response
     */
    //### Done no changes
    @AuraEnabled
    public static  MYOB_Callout_Helper.ComponentResponse createUpdateContact(String contactId,String objectApiName,Map<String,Object> mapMYOBContactFldNameSfValue,Boolean isIndividual){
        MYOB_Callout_Helper.ComponentResponse cmpRes = new MYOB_Callout_Helper.ComponentResponse();
        Map<String,Object> mapMYOBFldNameSFValue = new Map<String,Object>();
        try{
            system.debug('Inside Calss');
            //check if all Authourization steps are completed.
            cmpRes = MYOB_Callout_Helper.checkAuthorizationSteps();
            MYOB_Callout_Helper.CalloutDetails calloutWrapper;
            if(cmpRes.status.equalsIgnoreCase('Failed')){
                throw new MYOB_Callout_Helper.MYOBCustomException('MYOB Setup, Authorization/Authentication Connection Steps are pending.');
            }

            if(String.isNotBlank(contactId)){
                //1. Main generic method for Create/Update Qb invoices.
                if(mapMYOBContactFldNameSfValue != null){
                    isIndividualContact = isIndividual; //assigining to static variable
                    mapMYOBFldNameSFValue = mapMYOBContactFldNameSfValue;
                }else{
                    mapMYOBFldNameSFValue = fetchSfContact(contactId,'',objectApiName,true)[0];
                }

                if(mapMYOBFldNameSFValue.keyset().size()>0){
                    calloutWrapper = genericCreateContactBody(mapMYOBFldNameSFValue,contactId);
                }
                system.debug('calloutWrapper.requestBody- '+calloutWrapper.requestBody);
                //2. Creating response i.e. handled in Lwc as Toast message.
                calloutWrapper.recordId = contactId;
                calloutWrapper.helper = 'ContactDynamicController.createUpdateContact()';
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);
                
                //3. Publishing the Callout Response to UI
                String successMsg = 'The contact has been successfully synced into MYOB.' ;
                String errorMsg = 'The contact failed to Sync into MYOB.' ;
                cmpRes = MYOB_Callout_Helper.publishCalloutResponse(objHTTP,cmpRes,successMsg,errorMsg);

                //4. Callout to Query the currently created/updated customer from MYOB to Sf
                if (!objHTTP.isCalloutException && !objHTTP.isLogException && cmpRes.status =='Success') {
                    cmpRes = syncContactToSf(contactId,'');
                }
                
                //5. Insert Logs
                if(Schema.sObjectType.KTMYOB__MYOB_Log__c.isCreateable()){
                    Insert MYOB_Callout_Helper.myobLogs; 
                }
            }
            return cmpRes;
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
            return cmpRes;
        }
    }

    //### Done no changes
    @AuraEnabled
    public static List<Map<String,Object>> fetchSfContact(String contactId,String searchStr,String objectApiName,Boolean getNonNullInvoiceFields){
        // Map<String,Object> mapMYOBCompanyFldNameSfValue = new Map<String,Object>();
        // Map<String,Object> mapMYOBIndividualFldNameSfValue = new Map<String,Object>();
        List<Map<String,Object>> lstMapMyobContactFldNameSfValue = new List<Map<String,Object>>();
        Set<String> companyFieldsToQuery = new Set<String>();
        Set<String> individualFieldsToQuery = new Set<String>();
        String whereClause= ' WHERE ';
        try{
            generateObjectFieldMapping();
            if(String.isNotBlank(contactId)){
                whereClause+= 'Id=:contactId';
            }else if(String.isNotBlank(searchStr)){
                String partialMatches = '%' + searchStr + '%';
                whereClause+= 'Name LIKE :partialMatches';
            }
            //Logic Company Sync
            if(contactCompanyObjectApiName == objectApiName){
                for(KTMYOB__Contact_Company_Fields_Mapping__c custData : mapMYOBApiNameCompanyData.Values()){
                    if(String.isNotBlank(custData.KTMYOB__Field_API_Name__c)){
                        companyFieldsToQuery.add(custData.KTMYOB__Field_API_Name__c);
                    }
                }
                String contactQuery = 'SELECT Id,'+String.escapeSingleQuotes(String.join(companyFieldsToQuery, ','))+' FROM '+String.escapeSingleQuotes(contactCompanyObjectApiName)+whereClause;
                List<SObject> lstcontactRecordQueried = Database.query(contactQuery); 
                for(Sobject contactRecordQueried:lstcontactRecordQueried){
                    if(contactRecordQueried != null){
                        Map<String,Object> mapMYOBContactFldNameSfValue = new Map<String,Object>();
                        for(String myobFieldApiName : mapMYOBApiNameCompanyData.keyset()){
                            if(String.isNotBlank(myobFieldApiName)){
                                if(String.isNotBlank(mapMYOBApiNameCompanyData.get(myobFieldApiName).KTMYOB__Field_API_Name__c)){
                                    if((contactRecordQueried.get((mapMYOBApiNameCompanyData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c))!= null && getNonNullInvoiceFields == true){
                                        mapMYOBContactFldNameSfValue.put( myobFieldApiName,contactRecordQueried.get((mapMYOBApiNameCompanyData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c));
                                    }else if(getNonNullInvoiceFields == false){
                                        mapMYOBContactFldNameSfValue.put( myobFieldApiName,contactRecordQueried.get((mapMYOBApiNameCompanyData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c)??'');
                                    }
                                }
                            }
                        }
                        if(mapMYOBContactFldNameSfValue.keySet().size()>0){
                            lstMapMyobContactFldNameSfValue.add(mapMYOBContactFldNameSfValue);
                        }
                    }
                }
            }

            //Logic Individual Sync
            else if(contactIndividualObjectApiName == objectApiName){
                isIndividualContact = true;
                for(KTMYOB__Contact_Individual_Fields_Mapping__c custData : mapMYOBApiNameIndividualData.Values()){
                    if(String.isNotBlank(custData.KTMYOB__Field_API_Name__c)){
                        individualFieldsToQuery.add(custData.KTMYOB__Field_API_Name__c);
                    }
                }
                String contactQuery = 'SELECT Id,'+String.escapeSingleQuotes(String.join(individualFieldsToQuery, ','))+' FROM '+String.escapeSingleQuotes(contactIndividualObjectApiName)+whereClause;
                System.debug('### contactQuery ::: '+contactQuery);
                List<SObject> lstcontactRecordQueried = Database.query(contactQuery); 
                for(Sobject contactRecordQueried:lstcontactRecordQueried){
                    if(contactRecordQueried != null){
                        Map<String,Object> mapMYOBContactFldNameSfValue = new Map<String,Object>();
                        for(String myobFieldApiName : mapMYOBApiNameIndividualData.keyset()){
                            if(String.isNotBlank(myobFieldApiName)){
                                if(String.isNotBlank(mapMYOBApiNameIndividualData.get(myobFieldApiName).KTMYOB__Field_API_Name__c)){
                                    if((contactRecordQueried.get((mapMYOBApiNameIndividualData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c))!= null && getNonNullInvoiceFields == true){
                                        mapMYOBContactFldNameSfValue.put( myobFieldApiName,contactRecordQueried.get((mapMYOBApiNameIndividualData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c));
                                    }else if(getNonNullInvoiceFields == false){
                                        mapMYOBContactFldNameSfValue.put( myobFieldApiName,contactRecordQueried.get((mapMYOBApiNameIndividualData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c)??'');
                                    }
                                }
                            }
                        }
                        if(mapMYOBContactFldNameSfValue.keySet().size()>0){
                            lstMapMyobContactFldNameSfValue.add(mapMYOBContactFldNameSfValue);
                        }
                    }
                }
            }
            if(lstMapMyobContactFldNameSfValue.size()>0){
                return lstMapMyobContactFldNameSfValue;
            }
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
        }
        return new List<Map<String,Object>>();
    }



    //### Done no changes
    @AuraEnabled
    public static string updateContactInSF (Map<string,object> contactMap,String contactId,Boolean isIndividual){
        string status = '';
        string objectApiName='';
        SObject contactObject;
        try {
            generateObjectFieldMapping();
            if(isIndividual == true){
                contactObject  = contactIndividualSObject.clone(false, true, false, false);
                contactObject.put('Id',contactId);
                objectApiName = contactIndividualObjectApiName;
                for(String fld : contactMap.keyset()){
                    contactObject.put(mapMYOBApiNameIndividualData.get(fld).KTMYOB__Field_API_Name__c,contactMap.get(fld));
                }
            }else{
                contactObject  = contactCompanySObject.clone(false, true, false, false);
                objectApiName = contactCompanyObjectApiName;
                contactObject.put('Id',contactId);
                for(String fld : contactMap.keyset()){
                    contactObject.put(mapMYOBApiNameCompanyData.get(fld).KTMYOB__Field_API_Name__c,contactMap.get(fld));
                }
            }
            
            if(contactObject.get('Id')!= null && String.isNotBlank(objectApiName)){
                if(Schema.getGlobalDescribe().get(objectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
                    system.debug('#### contactObject ::: '+contactObject);
                    Database.update(contactObject);
                    status='success';
                }
            }else if(contactMap.keySet().size() > 0){
                status='failed';
            }
            return status;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //### Done no changes
    public static MYOB_Callout_Helper.CalloutDetails genericCreateContactBody(Map<String,Object> mapMYOBContactFldNameSfValue,String contactId){
        MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
        MYOB_CustomerResponse.cls_Items customerObj= new MYOB_CustomerResponse.cls_Items();
        String contactType = (String) mapMYOBContactFldNameSfValue.get('ContactType');
        String requestBody = '';
        try{
            //Generic Logic for all Contact Types(i.e. Customer,Supplier,Personal)
            // customerObj.UID = (String) mapMYOBContactFldNameSfValue.get('UID');
            if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('UID')) 
                && String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('RowVersion')) ){
                contactId = '';
                customerObj.UID = (String) mapMYOBContactFldNameSfValue.get('UID');
                customerObj.RowVersion = (String) mapMYOBContactFldNameSfValue.get('RowVersion');
                calloutWrapper.requestMethod = 'PUT';    
                calloutWrapper.requestEndpoint='/Contact/Customer/'+(String) mapMYOBContactFldNameSfValue.get('UID');
            }else{
                calloutWrapper.requestMethod = 'POST';  
                calloutWrapper.requestEndpoint='/Contact/Customer';
            }
            customerObj.IsIndividual = isIndividualContact;

            //Logic for Customer Type Contact
            if(contactType == 'Customer'){
                if(isIndividualContact == true){  
                    if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('FirstName'))){
                        customerObj.FirstName = (String) mapMYOBContactFldNameSfValue.get('FirstName');
                    }
                    if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('LastName'))){
                        customerObj.LastName = (String) mapMYOBContactFldNameSfValue.get('LastName');
                    }
                }else{
                    if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('CompanyName'))){
                        customerObj.CompanyName = (String) mapMYOBContactFldNameSfValue.get('CompanyName');
                    }
                }
            }

            //logic for returning data.
            MYOB_CustomerResponse.cls_Items finalCustomerObj = populateGenericFields(customerObj,mapMYOBContactFldNameSfValue,contactId);
            calloutWrapper.requestBody = JSON.serializePretty(finalCustomerObj,true);
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
        }
        return calloutWrapper;
    }

    //###Done no changes
    public static MYOB_CustomerResponse.cls_Items populateGenericFields( MYOB_CustomerResponse.cls_Items customerObj,Map<String,Object> mapMYOBContactFldNameSfValue,String contactId){

        //fetching the Tax Code and FrieghtTax Code from MYOB Metadata.
        Map<String,Map<String,String>> mapMetaDataTypeMYOBId = MYOB_Callout_Helper.fetchMyobMetadata((new List<String>{(String) mapMYOBContactFldNameSfValue.get('TaxCode'),(String) mapMYOBContactFldNameSfValue.get('FreightTaxCode')}),true);

        //Adding Generic Contact Details
        if(String.isNotBlank(contactId)){
            customerObj.DisplayID =contactId; 
        }else if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('DisplayID'))){
            customerObj.DisplayID = (String) mapMYOBContactFldNameSfValue.get('DisplayID');
        }
        if(mapMYOBContactFldNameSfValue.get('IsActive') != null){
            customerObj.IsActive = (Boolean) mapMYOBContactFldNameSfValue.get('IsActive');
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('Notes'))){
            customerObj.Notes = (String) mapMYOBContactFldNameSfValue.get('Notes');
        }

        //Adding Selling Details
        MYOB_CustomerResponse.cls_TaxCode taxCodes;
        MYOB_CustomerResponse.cls_FreightTaxCode freightTaxCodes;
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('TaxCode'))){
            taxCodes= new MYOB_CustomerResponse.cls_TaxCode();
            taxCodes.UID = mapMetaDataTypeMYOBId.get('TAX_CODE').get((String) mapMYOBContactFldNameSfValue.get('TaxCode'));
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('FreightTaxCode'))){
            freightTaxCodes = new MYOB_CustomerResponse.cls_FreightTaxCode();
            freightTaxCodes.UID = mapMetaDataTypeMYOBId.get('TAX_CODE').get((String) mapMYOBContactFldNameSfValue.get('FreightTaxCode'));
        }
        
        MYOB_CustomerResponse.cls_SellingDetails sellingDetails = new MYOB_CustomerResponse.cls_SellingDetails();
        sellingDetails.SaleLayout = 'NoDefault';
        sellingDetails.InvoiceDelivery = 'Print';
        if(taxCodes != null || freightTaxCodes != null){
            sellingDetails.FreightTaxCode = freightTaxCodes;
            sellingDetails.TaxCode = taxCodes;
        }
        customerObj.SellingDetails = sellingDetails;

        //Adding Billing and Shipping Addresses
        MYOB_CustomerResponse.cls_Addresses billaddress = new MYOB_CustomerResponse.cls_Addresses();
        billaddress.Location = 1;
        Boolean isBillingAddObjNull = true;
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrStreet'))){
            billaddress.Street = (String) mapMYOBContactFldNameSfValue.get('BillAddrStreet');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrCity'))){
            billaddress.City = (String) mapMYOBContactFldNameSfValue.get('BillAddrCity');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrState'))){
            billaddress.State = (String) mapMYOBContactFldNameSfValue.get('BillAddrState');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrPostalCode'))){
            billaddress.PostCode = (String) mapMYOBContactFldNameSfValue.get('BillAddrPostalCode');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrCountry'))){
            billaddress.Country = (String) mapMYOBContactFldNameSfValue.get('BillAddrCountry');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrPhone'))){
            billaddress.Phone1 = (String) mapMYOBContactFldNameSfValue.get('BillAddrPhone');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrToEmail'))){
            billaddress.Email = (String) mapMYOBContactFldNameSfValue.get('BillAddrToEmail');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrFax'))){
            billaddress.Fax = (String) mapMYOBContactFldNameSfValue.get('BillAddrFax');
            isBillingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('BillAddrWebsite'))){
            billaddress.Website = (String) mapMYOBContactFldNameSfValue.get('BillAddrWebsite');
            isBillingAddObjNull = false;
        }

        MYOB_CustomerResponse.cls_Addresses shipaddress = new MYOB_CustomerResponse.cls_Addresses();
        shipaddress.Location = 2;
        Boolean isShippingAddObjNull = true;
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrStreet'))){
            shipaddress.Street = (String) mapMYOBContactFldNameSfValue.get('ShipAddrStreet');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrCity'))){
            shipaddress.City = (String) mapMYOBContactFldNameSfValue.get('ShipAddrCity');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrState'))){
            shipaddress.State = (String) mapMYOBContactFldNameSfValue.get('ShipAddrState');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrPostalCode'))){
            shipaddress.PostCode = (String) mapMYOBContactFldNameSfValue.get('ShipAddrPostalCode');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrCountry'))){
            shipaddress.Country = (String) mapMYOBContactFldNameSfValue.get('ShipAddrCountry');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrPhone'))){
            shipaddress.Phone1 = (String) mapMYOBContactFldNameSfValue.get('ShipAddrPhone');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrToEmail'))){
            shipaddress.Email = (String) mapMYOBContactFldNameSfValue.get('ShipAddrToEmail');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrFax'))){
            shipaddress.Fax = (String) mapMYOBContactFldNameSfValue.get('ShipAddrFax');
            isShippingAddObjNull = false;
        }
        if(String.isNotBlank((String) mapMYOBContactFldNameSfValue.get('ShipAddrWebsite'))){
            shipaddress.Website = (String) mapMYOBContactFldNameSfValue.get('ShipAddrWebsite');
            isShippingAddObjNull = false;
        }

        List<MYOB_CustomerResponse.cls_Addresses> lstMYOBAddress = new List<MYOB_CustomerResponse.cls_Addresses>();     
        if(isBillingAddObjNull != true){
            lstMYOBAddress.add(billaddress);
        } 
        if(isShippingAddObjNull!= true){
            lstMYOBAddress.add(shipaddress);
        }
        if(lstMYOBAddress.size() > 0){
            customerObj.Addresses = lstMYOBAddress;
        }

        return customerObj;
    }

    //Auramethod : To query single contact record from myob to salesforce.
    @AuraEnabled
    public static String fetchSingleContactFromMYOB(String contactMYOBId){
        generateObjectFieldMapping();
        MYOB_Callout_Helper.ComponentResponse cmpRes = new MYOB_Callout_Helper.ComponentResponse();
        List<MYOB_CustomerResponse.cls_Items> lstcontactMYOBObj= new List<MYOB_CustomerResponse.cls_Items>();
        String response='';
        //check if all Authourization steps are completed.
        cmpRes = MYOB_Callout_Helper.checkAuthorizationSteps();
        if(cmpRes.status.equalsIgnoreCase('Failed')){
            throw new MYOB_Callout_Helper.MYOBCustomException('MYOB Setup, Authorization/Authentication Connection Steps are pending.');
        }

        if(String.isNotBlank(contactMYOBId)){ 
            //1. Preparing for Callout
            MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
            calloutWrapper.helper = 'ContactDynamicController.fetchSingleContactFromMYOB()';
            calloutWrapper.requestMethod = 'GET';  
            calloutWrapper.requestBody='';
            calloutWrapper.requestEndpoint='/Contact/Customer/'+contactMYOBId;

            //2. Generic method for Syncing MYOB Products to Salesforce.
            if(String.isNotBlank(calloutWrapper.requestEndpoint)){
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);
                if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
                    lstcontactMYOBObj.add(MYOB_CustomerResponse.parseContact(objHTTP.response));
                }
            }

            //3. Insert Logs
            if(Schema.sObjectType.KTMYOB__MYOB_Log__c.isCreateable()){
                System.debug(' ### MYOB_Callout_Helper.myobLogs ::: '+MYOB_Callout_Helper.myobLogs);
                Insert MYOB_Callout_Helper.myobLogs; 
            }
            if(lstcontactMYOBObj.size()>0){
                response =  JSON.serializePretty(lstcontactMYOBObj[0]);
            }
        }
        return response;
    }

    //Helper Method : To upsert synced contact to Salesforce.This method is called from createUpdateContact().
    //### Done no changes
    public static MYOB_Callout_Helper.ComponentResponse syncContactToSf(String contactId,String contactMYOBId){
        generateObjectFieldMapping();
        MYOB_Callout_Helper.ComponentResponse cmpRes = new MYOB_Callout_Helper.ComponentResponse();
        try{
            //check if all Authourization steps are completed.
            cmpRes = MYOB_Callout_Helper.checkAuthorizationSteps();
            if(cmpRes.status.equalsIgnoreCase('Failed')){
                throw new MYOB_Callout_Helper.MYOBCustomException('MYOB Setup, Authorization/Authentication Connection Steps are pending.');
            }

            //1. Preparing for Callout
            MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
            calloutWrapper.helper = 'ContactDynamicController.syncContactToSf()';
            calloutWrapper.requestMethod = 'GET';  
            calloutWrapper.requestBody='';

            //2. Check if to query based on DisplayID or UID.
            if(String.isNotBlank(contactMYOBId)){
                calloutWrapper.requestEndpoint='/Contact/Customer/'+contactMYOBId;
            }else if(String.isNotBlank(contactId)){
                //TODO : Priority
                String filterUrl = EncodingUtil.urlEncode('DisplayID eq ','UTF-8')+'\''+contactId+'\'';
                filterUrl = filterUrl.replace('+', '%20');
                calloutWrapper.requestEndpoint='/Contact/Customer?$filter='+filterUrl;
            }

            //3. Generic method for Syncing MYOB Products to Salesforce.
            if(String.isNotBlank(calloutWrapper.requestEndpoint)){
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);
                if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
                    String syncStatus = '';
                    List<MYOB_CustomerResponse.cls_Items> lstcontactMYOBObj= new List<MYOB_CustomerResponse.cls_Items>();
                    if(String.isNotBlank(contactMYOBId)){
                        lstcontactMYOBObj.add(MYOB_CustomerResponse.parseContact(objHTTP.response));
                    }else if(String.isNotBlank(contactId)){
                        MYOB_CustomerResponse.cls_Contacts customersParsed=MYOB_CustomerResponse.parseListOfContacts(objHTTP.response);
                        lstcontactMYOBObj = customersParsed.Items;
                    }

                    if(lstcontactMYOBObj.size()>0){
                        syncStatus = upsertCustomer(lstcontactMYOBObj,contactId);
                    }

                    if(String.isBlank(syncStatus) || syncStatus == 'Failed'){
                        objHTTP.isLogException = true;
                    }

                    //Publishing the Callout Response to UI
                    String successMsg = 'The contact was successfully synced to both MYOB and Salesforce.' ;
                    String errorMsg = 'The contact failed to sync into Salesforce. But was successfully synced into MYOB.' ;
                    cmpRes = MYOB_Callout_Helper.publishCalloutResponse(objHTTP,cmpRes,successMsg,errorMsg);
                }
            } 
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
        }
        return cmpRes;
    }


    //Helper Method : To Upsert customer in Salesforce. : This method is called from syncContactToSf().
    //### Done no changes
    public static string upsertCustomer(List<MYOB_CustomerResponse.cls_Items> lstcontactMYOBObj,String contactId){
        String upsertStatus = '';
        try{
            //1. Iterating to get the related object details.
            List<String> lstTaxCodeMtdIds = new List<String>();
            for(MYOB_CustomerResponse.cls_Items customerObj : lstcontactMYOBObj){
                if(String.isNotBlank(customerObj.SellingDetails.FreightTaxCode.UID)){
                    lstTaxCodeMtdIds.add(customerObj?.SellingDetails?.FreightTaxCode?.UID); 
                }else if(String.isNotBlank(customerObj.SellingDetails.TaxCode.UID)){
                    lstTaxCodeMtdIds.add(customerObj?.SellingDetails?.TaxCode?.UID); 
                }
            }

            //2. fetching the Tax Code and FrieghtTax Code from MYOB Metadata.
            Map<String,Map<String,String>> mapMetaDataTypeMYOBId = MYOB_Callout_Helper.fetchMyobMetadata(lstTaxCodeMtdIds,false);

            //3. Syncing all the contact field from MYOB to SF.
            String objectApiName = '';
            String ExternalIdFld = '';
            List<SObject> lstCustomerToSync = new List<SObject>();
            for(MYOB_CustomerResponse.cls_Items customerObj : lstcontactMYOBObj){
                SObject customer;
                
                //Making isIndiviual to false if Contact Saved in same object
                if(contactSavedInDiffOBj == false){
                    isIndividualContact = contactSavedInDiffOBj;
                }

                if(isIndividualContact==true){
                    //Saving the MYOB values to Salesforce Fields for Individual Customer.

                    objectApiName = contactIndividualObjectApiName;
                    customer = contactIndividualSObject.clone(false, true, false, false);
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('FirstName').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameIndividualData.get('FirstName').KTMYOB__Field_API_Name__c, customerObj?.FirstName);
                    }
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('LastName').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameIndividualData.get('LastName').KTMYOB__Field_API_Name__c, customerObj?.LastName);
                    }

                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('UID').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameIndividualData.get('UID').KTMYOB__Field_API_Name__c, customerObj?.UID);
                        ExternalIdFld = mapMYOBApiNameIndividualData.get('UID').KTMYOB__Field_API_Name__c;
                    }
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('RowVersion').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameIndividualData.get('RowVersion').KTMYOB__Field_API_Name__c, customerObj?.RowVersion);
                    }
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('DisplayID').KTMYOB__Field_API_Name__c) && String.isNotBlank(customerObj.DisplayID)){
                        customer.put(mapMYOBApiNameIndividualData.get('DisplayID').KTMYOB__Field_API_Name__c, customerObj?.DisplayID);
                    }
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('IsActive').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameIndividualData.get('IsActive').KTMYOB__Field_API_Name__c, customerObj?.IsActive);
                    }
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('Notes').KTMYOB__Field_API_Name__c) && String.isNotBlank(customerObj.Notes)){
                        customer.put(mapMYOBApiNameIndividualData.get('Notes').KTMYOB__Field_API_Name__c, customerObj?.Notes);
                    }
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ContactType').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameIndividualData.get('ContactType').KTMYOB__Field_API_Name__c,'Customer'); //harcoded as we are doing for customer only.
                    }

                    //Storing Tax Code and Freight Tax Codes Details
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('TaxCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.TaxCode?.UID)) ){
                        customer.put(mapMYOBApiNameIndividualData.get('TaxCode').KTMYOB__Field_API_Name__c, mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.TaxCode?.UID));
                    }
                    if(String.isNotBlank(mapMYOBApiNameIndividualData.get('FreightTaxCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.FreightTaxCode?.UID)) ){
                        customer.put(mapMYOBApiNameIndividualData.get('FreightTaxCode').KTMYOB__Field_API_Name__c, mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.FreightTaxCode?.UID));
                    }

                    //Billing and Shipping address details
                    for(MYOB_CustomerResponse.cls_Addresses address: customerObj.Addresses){
                        if(address.Location == 1){
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrStreet').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Street)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrStreet').KTMYOB__Field_API_Name__c, address?.Street);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrCity').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.City)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrCity').KTMYOB__Field_API_Name__c, address?.City);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrState').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.State)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrState').KTMYOB__Field_API_Name__c, address?.State);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrPostalCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.PostCode)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrPostalCode').KTMYOB__Field_API_Name__c, address?.PostCode);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrCountry').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Country)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrCountry').KTMYOB__Field_API_Name__c, address?.Country);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrPhone').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Phone1)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrPhone').KTMYOB__Field_API_Name__c, address?.Phone1);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrToEmail').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Email)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrToEmail').KTMYOB__Field_API_Name__c, address?.Email);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrWebsite').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Website)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrWebsite').KTMYOB__Field_API_Name__c, address?.Website);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('BillAddrContactPerson').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.ContactName)){
                                customer.put(mapMYOBApiNameIndividualData.get('BillAddrContactPerson').KTMYOB__Field_API_Name__c, address?.ContactName);
                            }
                        }else if(address.Location == 2){
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrStreet').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Street)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrStreet').KTMYOB__Field_API_Name__c, address?.Street);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrCity').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.City)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrCity').KTMYOB__Field_API_Name__c, address?.City);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrState').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.State)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrState').KTMYOB__Field_API_Name__c, address?.State);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrPostalCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.PostCode)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrPostalCode').KTMYOB__Field_API_Name__c, address?.PostCode);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrCountry').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Country)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrCountry').KTMYOB__Field_API_Name__c, address?.Country);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrPhone').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Phone1)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrPhone').KTMYOB__Field_API_Name__c, address?.Phone1);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrToEmail').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Email)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrToEmail').KTMYOB__Field_API_Name__c, address?.Email);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrWebsite').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Website)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrWebsite').KTMYOB__Field_API_Name__c, address?.Website);
                            }
                            if(String.isNotBlank(mapMYOBApiNameIndividualData.get('ShipAddrContactPerson').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.ContactName)){
                                customer.put(mapMYOBApiNameIndividualData.get('ShipAddrContactPerson').KTMYOB__Field_API_Name__c, address?.ContactName);
                            }
                        }
                    }
                }else{
                    //Saving the MYOB values to Salesforce Fields for Company Customer.
                    objectApiName = contactCompanyObjectApiName;
                    customer = contactCompanySObject.clone(false, true, false, false);
                    //check if Contact Saved in same object, if yes then do update first and last name
                    if(contactSavedInDiffOBj == false){
                        if(String.isNotBlank(mapMYOBApiNameCompanyData.get('FirstName').KTMYOB__Field_API_Name__c)){
                            customer.put(mapMYOBApiNameCompanyData.get('FirstName').KTMYOB__Field_API_Name__c, customerObj?.FirstName);
                        }
                        if(String.isNotBlank(mapMYOBApiNameCompanyData.get('LastName').KTMYOB__Field_API_Name__c)){
                            customer.put(mapMYOBApiNameCompanyData.get('LastName').KTMYOB__Field_API_Name__c, customerObj?.LastName);
                        }
                        //create mapping in Custom setting
                        // if(String.isNotBlank(mapMYOBApiNameCompanyData.get('IsIndividual').KTMYOB__Field_API_Name__c)){
                        //     customer.put(mapMYOBApiNameCompanyData.get('IsIndividual').KTMYOB__Field_API_Name__c, customerObj?.IsIndividual);
                        // }
                    }

                    //Saving the MYOB values to Salesforce Fields.
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('UID').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameCompanyData.get('UID').KTMYOB__Field_API_Name__c, customerObj?.UID);
                        ExternalIdFld = mapMYOBApiNameCompanyData.get('UID').KTMYOB__Field_API_Name__c;
                    }
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('RowVersion').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameCompanyData.get('RowVersion').KTMYOB__Field_API_Name__c, customerObj?.RowVersion);
                    }
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('CompanyName').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameCompanyData.get('CompanyName').KTMYOB__Field_API_Name__c, customerObj?.CompanyName);
                    }
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('DisplayID').KTMYOB__Field_API_Name__c) && String.isNotBlank(customerObj.DisplayID)){
                        customer.put(mapMYOBApiNameCompanyData.get('DisplayID').KTMYOB__Field_API_Name__c, customerObj?.DisplayID);
                    }
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('IsActive').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameCompanyData.get('IsActive').KTMYOB__Field_API_Name__c, customerObj?.IsActive);
                    }
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('Notes').KTMYOB__Field_API_Name__c) && String.isNotBlank(customerObj.Notes)){
                        customer.put(mapMYOBApiNameCompanyData.get('Notes').KTMYOB__Field_API_Name__c, customerObj?.Notes);
                    }
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ContactType').KTMYOB__Field_API_Name__c)){
                        customer.put(mapMYOBApiNameCompanyData.get('ContactType').KTMYOB__Field_API_Name__c,'Customer'); //harcoded as we are doing for customer only.
                    }

                    //Storing Tax Code and Freight Tax Codes Details
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('TaxCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.TaxCode?.UID)) ){
                        customer.put(mapMYOBApiNameCompanyData.get('TaxCode').KTMYOB__Field_API_Name__c, mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.TaxCode?.UID));
                    }
                    if(String.isNotBlank(mapMYOBApiNameCompanyData.get('FreightTaxCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.FreightTaxCode?.UID)) ){
                        customer.put(mapMYOBApiNameCompanyData.get('FreightTaxCode').KTMYOB__Field_API_Name__c, mapMetaDataTypeMYOBId.get('TAX_CODE').get(customerObj?.SellingDetails?.FreightTaxCode?.UID));
                    }

                    //Billing and Shipping address details
                    // add null checker for address
                    system.debug('customerObj.Addresses- '+customerObj.Addresses);
                    if(customerObj.Addresses != null){

                    for(MYOB_CustomerResponse.cls_Addresses address: customerObj.Addresses){
                        if(address.Location == 1){
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrStreet').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Street)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrStreet').KTMYOB__Field_API_Name__c, address?.Street);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrCity').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.City)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrCity').KTMYOB__Field_API_Name__c, address?.City);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrState').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.State)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrState').KTMYOB__Field_API_Name__c, address?.State);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrPostalCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.PostCode)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrPostalCode').KTMYOB__Field_API_Name__c, address?.PostCode);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrCountry').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Country)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrCountry').KTMYOB__Field_API_Name__c, address?.Country);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrPhone').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Phone1)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrPhone').KTMYOB__Field_API_Name__c, address?.Phone1);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrToEmail').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Email)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrToEmail').KTMYOB__Field_API_Name__c, address?.Email);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrWebsite').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Website)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrWebsite').KTMYOB__Field_API_Name__c, address?.Website);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('BillAddrContactPerson').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.ContactName)){
                                customer.put(mapMYOBApiNameCompanyData.get('BillAddrContactPerson').KTMYOB__Field_API_Name__c, address?.ContactName);
                            }
                        }else if(address.Location == 2){
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrStreet').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Street)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrStreet').KTMYOB__Field_API_Name__c, address?.Street);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrCity').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.City)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrCity').KTMYOB__Field_API_Name__c, address?.City);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrState').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.State)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrState').KTMYOB__Field_API_Name__c, address?.State);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrPostalCode').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.PostCode)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrPostalCode').KTMYOB__Field_API_Name__c, address?.PostCode);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrCountry').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Country)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrCountry').KTMYOB__Field_API_Name__c, address?.Country);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrPhone').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Phone1)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrPhone').KTMYOB__Field_API_Name__c, address?.Phone1);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrToEmail').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Email)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrToEmail').KTMYOB__Field_API_Name__c, address?.Email);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrWebsite').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.Website)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrWebsite').KTMYOB__Field_API_Name__c, address?.Website);
                            }
                            if(String.isNotBlank(mapMYOBApiNameCompanyData.get('ShipAddrContactPerson').KTMYOB__Field_API_Name__c) && String.isNotBlank(address.ContactName)){
                                customer.put(mapMYOBApiNameCompanyData.get('ShipAddrContactPerson').KTMYOB__Field_API_Name__c, address?.ContactName);
                            }
                        }
                    }
                }

                }
                if(customer != null){
                    if(String.isNotBlank(contactId)){
                        customer.put('Id',contactId);
                    }
                    lstCustomerToSync.add(customer);
                }
            }

            //Upserting the List of Customers.
            if(lstCustomerToSync.size()>0){
                if(Schema.getGlobalDescribe().get(objectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()
                    || Schema.getGlobalDescribe().get(objectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
                    if(String.isNotBlank(contactId)){
                        update lstCustomerToSync;
                        upsertStatus = 'success';
                    }else if(String.isNotBlank(ExternalIdFld) && String.isNotBlank(objectApiName)){
                        Schema.sObjectField customerExternalID = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().get(ExternalIdFld);
                        Database.upsert(lstCustomerToSync,customerExternalID,true);
                        upsertStatus = 'success';
                    }
                }
            }
        }catch(Exception e){
            system.debug('Exception here');
            HandleCustomException.LogException(e);
            upsertStatus = 'failed';
        }
        return upsertStatus;
    }

    @AuraEnabled(cacheable=true)
    public static List<KTMYOB__MYOB_MetaData__c> getTaxCodeList(){
        try {

            List<KTMYOB__MYOB_MetaData__c> taxCodeList = [Select Id, Name, KTMYOB__Tax_Code__c, KTMYOB__Active__c FROM KTMYOB__MYOB_MetaData__c WHERE KTMYOB__Active__c =: true];

            return taxCodeList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getRecordDetails(string recordId, string objectApiName){
        try {

            if(objectApiName == 'Account'){
                List<Account> accList = [Select Id,KTMYOB__MYOB_Contact_UID__c From Account Where Id =: recordId];
                string UID = accList[0].KTMYOB__MYOB_Contact_UID__c;
                system.debug('UID- '+accList[0].KTMYOB__MYOB_Contact_UID__c);
                if( UID == null){
                    system.debug('UID- '+accList[0].KTMYOB__MYOB_Contact_UID__c);
                    return '';
                }else{
                    return UID;
                }
                 
            }else if(objectApiName == 'Contact'){
                List<Contact> conList = [Select Id,KTMYOB__Contact_UID__c From Contact Where Id =: recordId];
                string UID = conList[0].KTMYOB__Contact_UID__c;
                if(UID == null){
                    return '';
                }else{
                    return UID;
                }
            } else {
                return 'Failed';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}