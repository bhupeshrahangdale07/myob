public with sharing class InvoiceDynamicController{
    public static String invoiceObjectApiName;
    public static String lineItemObjectApiName;
    public static String productObjectApiName;
    public static SObject invoiceSOBject;
    public static SObject lineItemSOBject;
    public static Map<String,KTMYOB__Invoice_Fields_Mapping__c> mapMYOBApiNameInvoiceData = new Map<String,KTMYOB__Invoice_Fields_Mapping__c>();
    public static Map<String,KTMYOB__LineItem_Fields_Mapping__c> mapMYOBApiNameLineItemData = new Map<String,KTMYOB__LineItem_Fields_Mapping__c>();
    public static Map<String,KTMYOB__Product_Fields_Mapping__c> mapMYOBApiNameProductData = new  Map<String,KTMYOB__Product_Fields_Mapping__c>();

    public static Map<String,Map<String,String>> mapTaxCodeMtdMYOBId = new Map<String,Map<String,String>>();//For getting all the Metadata's needed in entire process.
    public static List<String> lstTaxCodeMtdIds = new List<String>();

    public static Map<String,Object> mapMYOBInvoiceFldNameSfValue = new Map<String,Object>(); //@Piyush Key : MyobapiName , value : field value
    public static List<Map<String,Object>> lstMapMYOBLineItemFldNameSfValue = new List<Map<String,Object>>(); 
    
    public static Map<String,String> mapLineItemUIDRecId = new Map<String,String>();

    /* @description helper: to prepare the contact data */ 
    public static void generateObjectFieldMapping(){
        try{
            KTMYOB__MYOB_Objects_Configurations__c myobObjectConfigs = KTMYOB__MYOB_Objects_Configurations__c.getOrgDefaults();
            invoiceObjectApiName = myobObjectConfigs.KTMYOB__Invoice_Object_Api_Name__c;
            lineItemObjectApiName = myobObjectConfigs.KTMYOB__LineItem_Object_Api_Name__c;

            if(invoiceSOBject == null){
                if(String.isNotBlank(invoiceObjectApiName)){
                    invoiceSOBject = Schema.getGlobalDescribe().get(invoiceObjectApiName).newSObject();
                }
            }
            if(lineItemSOBject == null){
                if(String.isNotBlank(lineItemObjectApiName)){
                    lineItemSOBject = Schema.getGlobalDescribe().get(lineItemObjectApiName).newSObject();
                }
            }
            for(KTMYOB__Invoice_Fields_Mapping__c invoiceCust : KTMYOB__Invoice_Fields_Mapping__c.getall().values()){
                if(String.isNotBlank(invoiceCust.KTMYOB__MYOB_Field_Api_Name__c)){
                mapMYOBApiNameInvoiceData.put(invoiceCust.KTMYOB__MYOB_Field_Api_Name__c,invoiceCust);
                }
            }
            for(KTMYOB__LineItem_Fields_Mapping__c lineItemCust : KTMYOB__LineItem_Fields_Mapping__c.getall().values()){
                if(String.isNotBlank(lineItemCust.KTMYOB__MYOB_Field_Api_Name__c)){
                mapMYOBApiNameLineItemData.put(lineItemCust.KTMYOB__MYOB_Field_Api_Name__c,lineItemCust);
                }
            }

            //For gettinga all the Custom Setting mapping for the Products.
            ProductDynamicController.generateObjectFieldMapping();
            productObjectApiName = ProductDynamicController.productObjectApiName; //Product Name
            mapMYOBApiNameProductData= ProductDynamicController.mapMYOBApiNameProductData; //Map MYOBApi,CS Record.
        }catch(Exception ex){
          HandleCustomException.LogException(ex);
        } 
    }

    public InvoiceDynamicController(){
        generateObjectFieldMapping();
    }

    /*
     * @description AuraMethod : This method gets invoice data from UI in json body and parse it and calls createUpdateInvoiceInMYOB().
        @param wrp - Invoice Data in Json body(String).
     */

    @AuraEnabled
    public static MYOB_Callout_Helper.ComponentResponse createUpdateInvoiceParse(String wrp){
        System.debug('### ::::::wrp ::: '+wrp);
        MYOB_Callout_Helper.ComponentResponse cmpRes = new MYOB_Callout_Helper.ComponentResponse();
        InvoiceDetailsWrapper invoiceWrp = new InvoiceDetailsWrapper();
        try{
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(wrp);

            invoiceWrp.mapInvoiceDetails = (Map<String, Object>) resultMap.get('mapInvoiceDetails'); 
            invoiceWrp.invoiceId = (String)resultMap.get('invoiceId');
            for (Object obj : (List<Object>) resultMap.get('lstMapLineItemDetails')) {
                invoiceWrp.lstMapLineItemDetails.add((Map<String, Object>) obj);
            }
            if(invoiceWrp.mapInvoiceDetails.keySet().size()>0 && invoiceWrp.lstMapLineItemDetails.size()>0){
                cmpRes =  createUpdateInvoiceInMYOB(invoiceWrp);
                return cmpRes;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return cmpRes;
    }

    /*
     * @description AuraMethod : To Create/Update the Invoice from SF to QB.
        @param mapInvoiceSObjectValues - Invoice Map<MYOBAPIFieldName,FieldValue>
        @param lstMapLineItemSObjectValues - List of Line Items Map<MYOBAPIFieldName,FieldValue>
     */
    @AuraEnabled
    public static MYOB_Callout_Helper.ComponentResponse createUpdateInvoiceInMYOB(InvoiceDetailsWrapper invoiceWrp){
        generateObjectFieldMapping();
        MYOB_Callout_Helper.ComponentResponse cmpRes = new MYOB_Callout_Helper.ComponentResponse();
        try{
            //check if all Authourization steps are completed.
            cmpRes = MYOB_Callout_Helper.checkAuthorizationSteps();
            if(cmpRes.status.equalsIgnoreCase('Failed')){
                throw new MYOB_Callout_Helper.MYOBCustomException('MYOB Setup, Authorization/Authentication Connection Steps are pending.');
            }

            if(mapMYOBInvoiceFldNameSfValue != null
                && lstMapMYOBLineItemFldNameSfValue != null){

                //1. Assign the map and list<map>, containing details of Invoice and its line items.
                mapMYOBInvoiceFldNameSfValue = invoiceWrp.mapInvoiceDetails;
                lstMapMYOBLineItemFldNameSfValue = invoiceWrp.lstMapLineItemDetails;

                //2. Creating response i.e. handled in Lwc as Toast message.
                MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
                calloutWrapper = createCalloutBodyForInvoice();
                if(String.isNotBlank(invoiceWrp.invoiceId)){
                    calloutWrapper.recordId = invoiceWrp.invoiceId;
                }
                calloutWrapper.helper = 'InvoiceDynamicController.createUpdateInvoiceInMYOB()';
                System.debug('### calloutWrapper ::: '+calloutWrapper);

                //2. Callout to create/update the Invoice and its line items
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);       

                //3. Callout to Query the currently created/updated invoice from MYOB to Sf
                if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
                    cmpRes = syncInvoiceToSf('');
                } 
                
                //4. Publishing the Callout Response to UI
                String successMsg = 'The invoice has been successfully synced into MYOB.' ;
                String errorMsg = 'The invoice failed to Sync into MYOB.' ;
                cmpRes = MYOB_Callout_Helper.publishCalloutResponse(objHTTP,cmpRes,successMsg,errorMsg);

                //5. Insert Logs
                if(Schema.sObjectType.KTMYOB__MYOB_Log__c.isCreateable()){
                    System.debug(' ### MYOB_Callout_Helper.myobLogs ::: '+MYOB_Callout_Helper.myobLogs);
                    Insert MYOB_Callout_Helper.myobLogs; 
                }
                return cmpRes; 
            }       
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return cmpRes;
    }


//helper : To get the Invoice and related Line items dynamically.
    public static MYOB_Callout_Helper.CalloutDetails createCalloutBodyForInvoice(){
        MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
        MYOB_InvoiceResponse.cls_Items invoiceObj= new MYOB_InvoiceResponse.cls_Items();
        String requestBody = '';
        try{
            if(mapMYOBInvoiceFldNameSfValue.keyset().size()>0 && lstMapMYOBLineItemFldNameSfValue.size()>0){

                //Generic Logic for all Contact Types(i.e. Customer,Supplier,Personal)
                invoiceObj.UID = (String) mapMYOBInvoiceFldNameSfValue.get('UID');
                if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('UID')) 
                    && String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('RowVersion')) ){
                    invoiceObj.RowVersion = (String) mapMYOBInvoiceFldNameSfValue.get('RowVersion');
                    calloutWrapper.requestMethod = 'PUT';    
                    calloutWrapper.requestEndpoint='/Sale/Invoice/Item/'+(String) mapMYOBInvoiceFldNameSfValue.get('UID');
                }else{
                    calloutWrapper.requestMethod = 'POST';  
                    calloutWrapper.requestEndpoint='/Sale/Invoice/Item';
                }

                //logic for returning data.
                MYOB_InvoiceResponse.cls_Items finalInvoiceObj = populateGenericFields(invoiceObj);
                String invoiceJsonBody = JSON.serializePretty(finalInvoiceObj,true);
                
                //Adding the Non Parsed Varaibales due to Reserved Keyword issue For Invoice.
                invoiceJsonBody = generateJsonForNonParsableVar(invoiceJsonBody); 
                calloutWrapper.requestBody = invoiceJsonBody;
            }
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
        }
        return calloutWrapper;
    }

//helper : To create a reponse body for the Invoice.
    public static MYOB_InvoiceResponse.cls_Items populateGenericFields( MYOB_InvoiceResponse.cls_Items invoiceObj){
        //fetching the Tax Code and FrieghtTax Code from MYOB Metadata.
        if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('TaxCode'))){
            lstTaxCodeMtdIds.add((String) mapMYOBInvoiceFldNameSfValue.get('TaxCode'));
        }
        if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('FreightTaxCode'))){
            lstTaxCodeMtdIds.add((String) mapMYOBInvoiceFldNameSfValue.get('FreightTaxCode'));
        }

        //Adding Invoice Generic Details.
        if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('Number'))){
            invoiceObj.S_Number = (String) mapMYOBInvoiceFldNameSfValue.get('Number');
        }
        
        if(String.isNotBlank ((String)mapMYOBInvoiceFldNameSfValue.get('Date')) ){
            invoiceObj.S_Date = MYOB_Callout_Helper.convertDateToUTC(date.parse((String)mapMYOBInvoiceFldNameSfValue.get('Date')));
        }

        if( String.isNotBlank( (String) mapMYOBInvoiceFldNameSfValue.get('CustomerPurchaseOrderNumber')) ){
            invoiceObj.CustomerPurchaseOrderNumber = (String) mapMYOBInvoiceFldNameSfValue.get('CustomerPurchaseOrderNumber');
        }

        if( ((Boolean) mapMYOBInvoiceFldNameSfValue.get('IsTaxInclusive')) != null){
            invoiceObj.IsTaxInclusive = (Boolean) mapMYOBInvoiceFldNameSfValue.get('IsTaxInclusive');
        }

        if( ((Double) mapMYOBInvoiceFldNameSfValue.get('Subtotal')) > 0){
            invoiceObj.Subtotal = (Double) mapMYOBInvoiceFldNameSfValue.get('Subtotal');
        }

        if( ((Double) mapMYOBInvoiceFldNameSfValue.get('TotalAmount')) > 0){
            invoiceObj.TotalAmount = (Double) mapMYOBInvoiceFldNameSfValue.get('TotalAmount');
        }
        
        if( ((Double) mapMYOBInvoiceFldNameSfValue.get('Freight')) > 0){
            invoiceObj.Freight = (Double) mapMYOBInvoiceFldNameSfValue.get('Freight');
        }

        if( ((Double) mapMYOBInvoiceFldNameSfValue.get('BalanceDueAmount')) > 0){
            invoiceObj.BalanceDueAmount = (Double) mapMYOBInvoiceFldNameSfValue.get('BalanceDueAmount');
        }
        
        if( ((Double) mapMYOBInvoiceFldNameSfValue.get('TotalTax')) > 0){
            invoiceObj.TotalTax = (Double) mapMYOBInvoiceFldNameSfValue.get('TotalTax');
        }

        if( String.isNotBlank( (String) mapMYOBInvoiceFldNameSfValue.get('Comment')) ){
            invoiceObj.Comment = (String) mapMYOBInvoiceFldNameSfValue.get('Comment');
        }


        //Adding Customer Details
        MYOB_InvoiceResponse.cls_Customer invoiceCustomer = new MYOB_InvoiceResponse.cls_Customer();
        invoiceCustomer.UID = fetchRelatedCustomerDetails(); // TODO : We can throw error when the customer is null, and later capture that on the UI.
        invoiceObj.Customer = invoiceCustomer;


        //TODO :: HARDCODED FOR TESTING PURPOSE
        MYOB_InvoiceResponse.cls_Terms invoiceTerms = new MYOB_InvoiceResponse.cls_Terms();
        invoiceTerms.PaymentIsDue = 'DayOfMonthAfterEOM';
        invoiceTerms.DiscountDate = 1;
        invoiceTerms.BalanceDueDate = 30;
        invoiceTerms.DiscountForEarlyPayment = 5;
        invoiceObj.Terms = invoiceTerms;

        //Adding Line Item Details
        invoiceObj.Lines =populateLineItemsFields();
        return invoiceObj;
    }


//helper method : To fetch the Customer UID related to the invoice. [DONE]
    public static string fetchRelatedCustomerDetails(){
        Boolean doCreateInvoiceForCompany = true;
        try{
            ContactDynamicController.generateObjectFieldMapping();
            if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('CompanyUID')) && String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('IndividualUID'))){
                doCreateInvoiceForCompany = false;
            } 

            if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('CompanyUID')) && doCreateInvoiceForCompany == true){
                if(String.isNotBlank((String) ContactDynamicController.mapMYOBApiNameCompanyData.get('UID').KTMYOB__Field_API_Name__c) 
                && String.isNotBlank(ContactDynamicController.contactCompanyObjectApiName)){
                    String contactQuery = 'SELECT Id,'+String.escapeSingleQuotes((String) ContactDynamicController.mapMYOBApiNameCompanyData.get('UID').KTMYOB__Field_API_Name__c)+' FROM '+String.escapeSingleQuotes(ContactDynamicController.contactCompanyObjectApiName)+' WHERE Id=\''+ String.escapeSingleQuotes((String) mapMYOBInvoiceFldNameSfValue.get('CompanyUID'))+'\' LIMIT 1';
                    SObject invoiceCustomer = Database.query(contactQuery);
                    return (String) invoiceCustomer.get(ContactDynamicController.mapMYOBApiNameCompanyData.get('UID').KTMYOB__Field_API_Name__c);
                }
            }else if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('IndividualUID'))){
                if(String.isNotBlank((String) ContactDynamicController.mapMYOBApiNameIndividualData.get('UID').KTMYOB__Field_API_Name__c)
                && String.isNotBlank(ContactDynamicController.contactIndividualObjectApiName)){
                    String contactQuery = 'SELECT Id,'+String.escapeSingleQuotes((String) ContactDynamicController.mapMYOBApiNameIndividualData.get('UID').KTMYOB__Field_API_Name__c)+' FROM '+String.escapeSingleQuotes(ContactDynamicController.contactIndividualObjectApiName)+' WHERE Id=\''+String.escapeSingleQuotes((String) mapMYOBInvoiceFldNameSfValue.get('IndividualUID'))+'\' LIMIT 1';
                    SObject invoiceCustomer = Database.query(contactQuery);
                    return (String) invoiceCustomer.get(ContactDynamicController.mapMYOBApiNameIndividualData.get('UID').KTMYOB__Field_API_Name__c);
                }
            }
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
        }
        return '';
    }


//helper method : to populate the Invoice Line Items. [DONE]
    public static List<MYOB_InvoiceResponse.cls_Lines> populateLineItemsFields(){
        List<MYOB_InvoiceResponse.cls_Lines> lstLineItems = new List<MYOB_InvoiceResponse.cls_Lines>();
        List<String> lstItemProductIds = new List<String>(); 
        Map<String,SObject> mapLineItemsProducts = new Map<String,SObject>();

        //Iterating to get the related object details.
        for(Map<String,Object> lineMap : lstMapMYOBLineItemFldNameSfValue){
            if(lineMap.containsKey('ProductId')){
                lstItemProductIds.add((String) lineMap.get('ProductId')); //getting the Product
            }
        }

        //Mapping Products Details for Line Item
        if(lstItemProductIds.size() > 0){
            mapLineItemsProducts = fetchProductDetails(lstItemProductIds);
        }

        //TODO: Iterating to map all the fields for the Line Items.
        for(Map<String,Object> lineMap : lstMapMYOBLineItemFldNameSfValue){
            MYOB_InvoiceResponse.cls_Lines lineObj = new MYOB_InvoiceResponse.cls_Lines();
            
            if(lineMap.containsKey('ShipQuantity')){
                // lineObj.ShipQuantity =(Decimal) lineMap.get('ShipQuantity');
                lineObj.ShipQuantity =Decimal.valueOf((String) lineMap.get('ShipQuantity'));
            }
            if(lineMap.containsKey('UnitPrice')){
                // lineObj.UnitPrice =(Decimal) lineMap.get('UnitPrice');
                lineObj.UnitPrice =Decimal.valueOf((String) lineMap.get('UnitPrice'));
            }
            if(lineMap.containsKey('UnitCount')){
                // lineObj.UnitCount =(Decimal) lineMap.get('UnitCount');
                lineObj.UnitCount =Decimal.valueOf((String) lineMap.get('UnitCount'));
            }
            if(lineMap.containsKey('UnitPriceForeign')){
                // lineObj.UnitPriceForeign =(Decimal) lineMap.get('UnitPriceForeign');
                lineObj.UnitPriceForeign =Decimal.valueOf((String) lineMap.get('UnitPriceForeign'));
            }
            if(lineMap.containsKey('Total')){
                // lineObj.Total =(Decimal) lineMap.get('Total');
                lineObj.Total =Decimal.valueOf((String) lineMap.get('Total'));
            }
            if(lineMap.containsKey('TotalForeign')){
                // lineObj.TotalForeign =(Decimal) lineMap.get('TotalForeign');
                lineObj.TotalForeign =Decimal.valueOf((String) lineMap.get('TotalForeign'));
            }
            if(lineMap.containsKey('RowID')){
                lineObj.RowID =Integer.valueOf((String) lineMap.get('RowID'));
            }
            if(lineMap.containsKey('RowVersion')){
                lineObj.RowVersion =(String) lineMap.get('RowVersion');
            }

            if(lineMap.containsKey('ProductId') && mapLineItemsProducts.keySet().size() > 0){
                Sobject lineItemproduct = mapLineItemsProducts.get((String) lineMap.get('ProductId'));

                if(lineItemproduct != null){
                    if(String.isNotBlank((String) lineItemproduct.get(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c))){
                        MYOB_InvoiceResponse.cls_Item itemObj = new MYOB_InvoiceResponse.cls_Item();
                        itemObj.UID = (String) lineItemproduct.get(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c);
                        lineObj.Item = itemObj;  
                    }
                    
                    //Inventory of the Products and Services 
                    if(String.isNotBlank((String) lineItemproduct.get(mapMYOBApiNameProductData.get('IncomeAccountUID').KTMYOB__Field_API_Name__c))){
                        MYOB_InvoiceResponse.cls_Account accountObj = new MYOB_InvoiceResponse.cls_Account();
                        accountObj.UID = (String) lineItemproduct.get(mapMYOBApiNameProductData.get('IncomeAccountUID').KTMYOB__Field_API_Name__c);
                        lineObj.Account = accountObj;
                    }

                    //Location : Check if the Product is Stored in any location in MYOB , if not then dont include in callout.
                    if(String.isNotBlank((String) lineItemproduct.get(mapMYOBApiNameProductData.get('LocationUID').KTMYOB__Field_API_Name__c))){
                        MYOB_InvoiceResponse.cls_Location locationObj = new MYOB_InvoiceResponse.cls_Location();
                        locationObj.UID = (String) lineItemproduct.get(mapMYOBApiNameProductData.get('LocationUID').KTMYOB__Field_API_Name__c);
                        lineObj.Location = locationObj;
                    }

                    //Tax Code : Whenever the tax inclusive is checked/true then add the tax code from the Product.
                    if(String.isNotBlank((String) lineItemproduct.get(mapMYOBApiNameProductData.get('SellingTaxCodeUID').KTMYOB__Field_API_Name__c)) 
                    && mapTaxCodeMtdMYOBId.get('TAX_CODE').keySet().size()>0){
                        MYOB_InvoiceResponse.cls_TaxCode taxCodeObj = new MYOB_InvoiceResponse.cls_TaxCode();
                        taxCodeObj.UID = mapTaxCodeMtdMYOBId.get('TAX_CODE').get((String) lineItemproduct.get(mapMYOBApiNameProductData.get('SellingTaxCodeUID').KTMYOB__Field_API_Name__c));
                        lineObj.TaxCode = taxCodeObj;
                    }
                }
            }
            lstLineItems.add(lineObj);
        }
        return lstLineItems;
    }


//Helper : Fetching All the  Products related to Invoice Line Items. [DONE]
    public static Map<String,SObject> fetchProductDetails(List<String> lstItemProductIds){
        Map<String,SObject> mapMYOBLineItemFldNameSfValue = new Map<String,SObject>();

        List<String> productFieldsToQuery = new List<String>();
        if(lstItemProductIds.size()>0){
            for(KTMYOB__Product_Fields_Mapping__c custData : mapMYOBApiNameProductData.Values()){
                if(String.isNotBlank(custData.KTMYOB__Field_API_Name__c)){
                    productFieldsToQuery.add(custData.KTMYOB__Field_API_Name__c);
                }
            }

            if(productFieldsToQuery.size()>0 && String.isNotBlank(productObjectApiName)){
                String productQuery = 'SELECT Id,'+String.escapeSingleQuotes(String.join(productFieldsToQuery, ','))+' FROM '+String.escapeSingleQuotes(productObjectApiName)+' WHERE Id=:lstItemProductIds';
                
                for(SObject productRecordQueried : Database.query(productQuery)){
                    mapMYOBLineItemFldNameSfValue.put((String) productRecordQueried.get('Id'),productRecordQueried);
                    if(String.isNotBlank((String) productRecordQueried.get((mapMYOBApiNameProductData.get('BuyingTaxCodeUID')).KTMYOB__Field_API_Name__c))){
                        lstTaxCodeMtdIds.add((String) productRecordQueried.get((mapMYOBApiNameProductData.get('BuyingTaxCodeUID')).KTMYOB__Field_API_Name__c));
                    }
                    if(String.isNotBlank((String) productRecordQueried.get((mapMYOBApiNameProductData.get('SellingTaxCodeUID')).KTMYOB__Field_API_Name__c))){
                        lstTaxCodeMtdIds.add((String) productRecordQueried.get((mapMYOBApiNameProductData.get('SellingTaxCodeUID')).KTMYOB__Field_API_Name__c));
                    }
                }
            }

            //fetching the Tax Code and FrieghtTax Code from MYOB Metadata.
            if(lstTaxCodeMtdIds.size()>0){
                mapTaxCodeMtdMYOBId = MYOB_Callout_Helper.fetchMyobMetadata(lstTaxCodeMtdIds,true);
            }
        }
        return mapMYOBLineItemFldNameSfValue;
    }   



// //Helper : To parse the JSON body for those varibale causing error of reserved keywords.
    public static string generateJsonForNonParsableVar(String jsonBody){
        if(jsonBody.containsIgnoreCase('S_Number')){
            jsonBody = jsonBody.replace('S_Number','Number');
        }
        if(jsonBody.containsIgnoreCase('S_Date')){
            jsonBody = jsonBody.replace('S_Date','Date');
        }
        return jsonBody;
    }
    


//Helper: To query the Invoice Record from MYOB and upsert in Salesforce
    public static MYOB_Callout_Helper.ComponentResponse syncInvoiceToSf(String invoiceId){
        generateObjectFieldMapping();
        MYOB_Callout_Helper.ComponentResponse cmpRes = new MYOB_Callout_Helper.ComponentResponse();
        try{
            //check if all Authourization steps are completed.
            cmpRes = MYOB_Callout_Helper.checkAuthorizationSteps();
            if(cmpRes.status.equalsIgnoreCase('Failed')){
                throw new MYOB_Callout_Helper.MYOBCustomException('MYOB Setup, Authorization/Authentication Connection Steps are pending.');
            }

            if(String.isNotBlank(productObjectApiName)){
                //1. Preparing for Callout
                MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
                calloutWrapper.helper = 'InvoiceDynamicController.queryInvoice()';
                calloutWrapper.requestMethod = 'GET';  
                calloutWrapper.requestEndpoint='/Sale/Invoice/Item';
                calloutWrapper.requestBody='';

                //2. Preparing Callout for Single Invoice. 
                //Query : query the invoice from MYOB based on the Invoice GUID and sync with Salesforce
                //Create/Update : query the invoice created/updated latest from Salesforce.
                if(mapMYOBInvoiceFldNameSfValue.KeySet().size() == 0 && String.isNotBlank(invoiceId)){
                    fetchInvoiceNLineItems(invoiceId,true);
                    if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('UID'))){
                        calloutWrapper.requestEndpoint+='/'+mapMYOBInvoiceFldNameSfValue.get('UID');
                    }
                }else if(mapMYOBInvoiceFldNameSfValue.KeySet().size() > 0){ 
                    String twoMinuteAgo = MYOB_Callout_Helper.convertDateTimetoUTC(System.now().addMinutes(-2));
                    String currentTime = MYOB_Callout_Helper.convertDateTimetoUTC(System.now());
                    
                    String filterUrl = EncodingUtil.urlEncode('LastModified ge datetime'+'\''+twoMinuteAgo+'\''
                        +' and LastModified lt datetime'+'\''+currentTime+'\''
                        +' and Customer/UID eq guid'+'\''+fetchRelatedCustomerDetails()+'\'','UTF-8');
                    filterUrl = filterUrl.replace('+', '%20');
                    calloutWrapper.requestEndpoint+='?$filter='+filterUrl;
                }
                
                //3. Generic method for Syncing MYOB Products to Salesforce.
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);
                if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
                    String syncStatus = '';
                    List<MYOB_InvoiceResponse.cls_Items> lstInvoicesToSync = new List<MYOB_InvoiceResponse.cls_Items>();
                    if(String.isNotBlank(invoiceId)){
                        lstInvoicesToSync = MYOB_InvoiceResponse.parse(objHTTP.response,true);
                    }else{
                        lstInvoicesToSync = MYOB_InvoiceResponse.parse(objHTTP.response,false);
                    }
                    
                    if(lstInvoicesToSync.size()>0){
                        syncStatus = upsertInvoices(lstInvoicesToSync);
                    }

                    if(String.isBlank(syncStatus) || syncStatus == 'Failed'){
                        objHTTP.isLogException = true;
                    }
                }

                //4.Publishing Response to UI i.e. handled in Lwc as Toast message.
                String successMsg = 'The Invoice has been successfully synced into your Salesforce.' ;
                String errorMsg = 'The Invoice failed to Sync into your Saleforce.' ;
                cmpRes = MYOB_Callout_Helper.publishCalloutResponse(objHTTP,cmpRes,successMsg,errorMsg);
            }
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
        }
        return cmpRes;
    }

//Helper Method : To Upsert invoices in Salesforce.
    public static string upsertInvoices(List<MYOB_InvoiceResponse.cls_Items> lstInvoicesToSync){
        //Iterating to get the related object details.
        for(MYOB_InvoiceResponse.cls_Items invoiceObj : lstInvoicesToSync){
            lstTaxCodeMtdIds.add(invoiceObj?.FreightTaxCode?.UID); 
            for(MYOB_InvoiceResponse.cls_Lines linesObj: invoiceObj.Lines){
                lstTaxCodeMtdIds.add(linesObj?.TaxCode?.UID); 
            }
        }

        //fetching the Tax Code and FrieghtTax Code from MYOB Metadata.
        Map<String,Map<String,String>> mapMetaDataTypeMYOBId = MYOB_Callout_Helper.fetchMyobMetadata(lstTaxCodeMtdIds,false);

        String upsertStatus = '';
        List<SObject> lstInvoiceSynced = new List<SObject>();
        List<SObject> lstLineItemsSynced = new List<SObject>();
        try{
            for(MYOB_InvoiceResponse.cls_Items invoiceObj : lstInvoicesToSync){
                SObject invoice  = invoiceSOBject.clone(false, true, false, false);

                //Storing the Invoice Generic Details
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('UID').KTMYOB__Field_API_Name__c)){
                    invoice.put(mapMYOBApiNameInvoiceData.get('UID').KTMYOB__Field_API_Name__c, invoiceObj?.UID);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('RowVersion').KTMYOB__Field_API_Name__c)){
                    invoice.put(mapMYOBApiNameInvoiceData.get('RowVersion').KTMYOB__Field_API_Name__c, invoiceObj?.RowVersion);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('Number').KTMYOB__Field_API_Name__c)){
                    invoice.put(mapMYOBApiNameInvoiceData.get('Number').KTMYOB__Field_API_Name__c, invoiceObj?.S_Number);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('InvoiceName').KTMYOB__Field_API_Name__c)){
                    invoice.put(mapMYOBApiNameInvoiceData.get('InvoiceName').KTMYOB__Field_API_Name__c,'Invoice '+invoiceObj?.S_Number);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('Date').KTMYOB__Field_API_Name__c)){
                    invoice.put(mapMYOBApiNameInvoiceData.get('Date').KTMYOB__Field_API_Name__c, date.valueOf(invoiceObj?.S_Date));
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('CustomerPurchaseOrderNumber').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('CustomerPurchaseOrderNumber').KTMYOB__Field_API_Name__c,invoiceObj?.CustomerPurchaseOrderNumber);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('IsTaxInclusive').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('IsTaxInclusive').KTMYOB__Field_API_Name__c,invoiceObj?.IsTaxInclusive);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('Subtotal').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('Subtotal').KTMYOB__Field_API_Name__c,invoiceObj?.Subtotal);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('TotalAmount').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('TotalAmount').KTMYOB__Field_API_Name__c,invoiceObj?.TotalAmount);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('Freight').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('Freight').KTMYOB__Field_API_Name__c,invoiceObj?.Freight);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('BalanceDueAmount').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('BalanceDueAmount').KTMYOB__Field_API_Name__c,invoiceObj?.BalanceDueAmount);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('TotalTax').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('TotalTax').KTMYOB__Field_API_Name__c,invoiceObj?.TotalTax);
                }
                if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('Comment').KTMYOB__Field_API_Name__c )){
                    invoice.put(mapMYOBApiNameInvoiceData.get('Comment').KTMYOB__Field_API_Name__c,invoiceObj?.Comment);
                }                

                //Storing the Invoice Line Items Generic Details
                for(MYOB_InvoiceResponse.cls_Lines linesObj: invoiceObj.Lines){
                    SObject lineItem  = lineItemSOBject.clone(false, true, false, false);

                    lineItem.Id= mapLineItemUIDRecId.get(linesObj?.RowID?.format()); //assigning the record id to the Line items.

                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c, linesObj?.RowID+'');
                    }
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('RowVersion').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('RowVersion').KTMYOB__Field_API_Name__c, linesObj?.RowVersion);
                    }
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('ShipQuantity').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('ShipQuantity').KTMYOB__Field_API_Name__c, linesObj?.ShipQuantity);
                    }
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('UnitPrice').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('UnitPrice').KTMYOB__Field_API_Name__c, linesObj?.UnitPrice);
                    }
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('UnitCount').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('UnitCount').KTMYOB__Field_API_Name__c, linesObj?.UnitCount);
                    }
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('UnitPriceForeign').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('UnitPriceForeign').KTMYOB__Field_API_Name__c, linesObj?.UnitPriceForeign);
                    }
                    //Commented : as the Amount field we 
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('Total').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('Total').KTMYOB__Field_API_Name__c, linesObj?.Total);
                    }
                    //Storing Line Items Tax Code Details
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('TaxCode').KTMYOB__Field_API_Name__c)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('TaxCode').KTMYOB__Field_API_Name__c, mapMetaDataTypeMYOBId.get('TAX_CODE').get(linesObj?.TaxCode?.UID));
                    }
                    //Storing Invoice Details on Line Items
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('Invoice').KTMYOB__Field_API_Name__c)){
                        SObject realtedInvoice  = invoiceSOBject.clone(false, true, false, false);
                        realtedInvoice.put(mapMYOBApiNameInvoiceData.get('UID').KTMYOB__Field_API_Name__c,(String) invoiceObj?.UID);
                        String lineParentInvName = invoiceObjectApiName;
                        if(lineParentInvName.containsIgnoreCase('__c')){
                            lineParentInvName = lineParentInvName.replace('__c', '__r');
                        }
                        lineItem.putSObject(
                            lineParentInvName,
                            realtedInvoice
                        );
                    }
                    lstLineItemsSynced.add(lineItem); //adding Line Items for Upsert.
                }
                lstInvoiceSynced.add(invoice); //adding Invoices for Upsert.
            }

            if(lstInvoiceSynced.size()>0){
                //Upserting the List of Invoices.
                if(Schema.getGlobalDescribe().get(invoiceObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()
                    || Schema.getGlobalDescribe().get(invoiceObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
                    if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('UID').KTMYOB__Field_API_Name__c) && String.isNotBlank(invoiceObjectApiName)){
                        Schema.sObjectField invoiceExternalID = Schema.getGlobalDescribe().get(invoiceObjectApiName).getDescribe().fields.getMap().get(mapMYOBApiNameInvoiceData.get('UID').KTMYOB__Field_API_Name__c);
                        Database.upsert(lstInvoiceSynced,invoiceExternalID,true);
                        upsertStatus = 'success';
                    }
                }
                if(lstLineItemsSynced.size()>0 && upsertStatus == 'success'){
                    //Upserting the List of Line Items.
                    if(Schema.getGlobalDescribe().get(lineItemObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()
                        || Schema.getGlobalDescribe().get(lineItemObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
                        if(String.isNotBlank(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c) && String.isNotBlank(lineItemObjectApiName)){
                            Schema.sObjectField lineItemExternalID = Schema.getGlobalDescribe().get(lineItemObjectApiName).getDescribe().fields.getMap().get(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c);
                            Database.upsert(lstLineItemsSynced,lineItemExternalID,true);
                            upsertStatus = 'success';
                        }
                    }
                }
                System.debug('### lstInvoiceSynced ::: '+lstInvoiceSynced);
                System.debug('### lstLineItemsSynced ::: '+lstLineItemsSynced);
            }
        }catch(Exception e){
            HandleCustomException.LogException(e);
            upsertStatus = 'failed';
        }
        return upsertStatus;
    }

    //Helper : To fetch all the fields of the Invoice and its related line items.
    //getNonNullInvoiceFields : if true gets invoice with fields which are not null or if false gets all fields irrespective if they are null or not.
    public static void fetchInvoiceNLineItems(String invoiceId,Boolean getNonNullInvoiceFields){
        generateObjectFieldMapping();
        Set<String> invoiceFieldsToQuery = new Set<String>();
        Set<String> lineItemFieldsToQuery = new Set<String>();
        String invoiceQuery;
        String lineItemQuery;
        String requestBody ='';
        
        //Logic invoice Sync
        if(String.isNotBlank(invoiceObjectApiName)){
            for(KTMYOB__Invoice_Fields_Mapping__c invData : mapMYOBApiNameInvoiceData.Values()){
                if(String.isNotBlank(invData.KTMYOB__Field_API_Name__c)){
                    invoiceFieldsToQuery.add(invData.KTMYOB__Field_API_Name__c);
                }
            }
            invoiceQuery='SELECT Id,'+String.escapeSingleQuotes(String.join(invoiceFieldsToQuery, ',')) + ' FROM '+String.escapeSingleQuotes(invoiceObjectApiName)+' WHERE Id=:invoiceId LIMIT 1';
            
            System.debug('### invoiceQuery ::: '+invoiceQuery);
            SObject invoiceRecordQueried = Database.query(invoiceQuery); 
            for(String myobFieldApiName : mapMYOBApiNameInvoiceData.keyset()){
                if(String.isNotBlank(myobFieldApiName)){
                    if(String.isNotBlank(mapMYOBApiNameInvoiceData.get(myobFieldApiName).KTMYOB__Field_API_Name__c)){
                        if((invoiceRecordQueried.get((mapMYOBApiNameInvoiceData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c))!= null && getNonNullInvoiceFields == true){
                            mapMYOBInvoiceFldNameSfValue.put( myobFieldApiName,invoiceRecordQueried.get((mapMYOBApiNameInvoiceData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c));
                        }else if(getNonNullInvoiceFields == false){
                            mapMYOBInvoiceFldNameSfValue.put( myobFieldApiName,invoiceRecordQueried.get((mapMYOBApiNameInvoiceData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c)??'');
                        }
                    }
                }
            }
        } 
        
        //Logic invoice line Item Sync
        if(String.isNotBlank(lineItemObjectApiName)){
            for(KTMYOB__LineItem_Fields_Mapping__c lineData : mapMYOBApiNameLineItemData.Values()){
                if(String.isNotBlank(lineData.KTMYOB__Field_API_Name__c)){
                    lineItemFieldsToQuery.add(lineData.KTMYOB__Field_API_Name__c);
                }
            }
            lineItemQuery ='SELECT Id,'+String.escapeSingleQuotes(String.join(lineItemFieldsToQuery, ','))+' FROM '+String.escapeSingleQuotes(lineItemObjectApiName)+' WHERE '+String.escapeSingleQuotes(mapMYOBApiNameLineItemData.get('Invoice').KTMYOB__Field_API_Name__c)+'=:invoiceId';
            System.debug('### lineItemQuery ::: '+lineItemQuery);
            
            for(SObject lineItemRecordQueried : Database.query(lineItemQuery)){
                Map<String,Object> mapMYOBLineItemFldNameSfValue = new Map<String,Object>();
                for(String myobFieldApiName : mapMYOBApiNameLineItemData.keyset()){
                    if(String.isNotBlank(myobFieldApiName)){
                        if(String.isNotBlank(mapMYOBApiNameLineItemData.get(myobFieldApiName).KTMYOB__Field_API_Name__c)){
                            if((lineItemRecordQueried.get((mapMYOBApiNameLineItemData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c))!= null && getNonNullInvoiceFields == true){
                                mapMYOBLineItemFldNameSfValue.put( myobFieldApiName,lineItemRecordQueried.get((mapMYOBApiNameLineItemData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c));
                                //capturing UID:Id of line items.
                                if(myobFieldApiName == 'RowId'){
                                    mapLineItemUIDRecId.put((String) lineItemRecordQueried.get((mapMYOBApiNameLineItemData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c),(String) lineItemRecordQueried.get('Id'));
                                }
                            }else if(getNonNullInvoiceFields == false){
                                mapMYOBLineItemFldNameSfValue.put( myobFieldApiName,lineItemRecordQueried.get((mapMYOBApiNameLineItemData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c)??'');
                                //capturing UID:Id of line items.
                                if(myobFieldApiName == 'RowId'){
                                    mapLineItemUIDRecId.put((String) lineItemRecordQueried.get((mapMYOBApiNameLineItemData.get(myobFieldApiName)).KTMYOB__Field_API_Name__c),(String) lineItemRecordQueried.get('Id'));
                                }
                            }
                        }
                    }
                }
                lstMapMYOBLineItemFldNameSfValue.add(mapMYOBLineItemFldNameSfValue);
            }
        }
        System.debug('### mapMYOBInvoiceFldNameSfValue ::: '+mapMYOBInvoiceFldNameSfValue);
        System.debug('### lstMapMYOBLineItemFldNameSfValue ::: '+lstMapMYOBLineItemFldNameSfValue);
    }


    //Aura Method : To Simply sync the MYOB Invoices from MYOB to SF
    @AuraEnabled
    public static MYOB_Callout_Helper.ComponentResponse syncInvoiceMYOBSF(String invoiceId){
        MYOB_Callout_Helper.ComponentResponse cmpRes = new MYOB_Callout_Helper.ComponentResponse();
        try {
            if(String.isNotBlank(invoiceId)){
                //1. to sync invoice from MYOB to SF.
                cmpRes = syncInvoiceToSf(invoiceId);

                //2. Insert Logs
                if(Schema.sObjectType.KTMYOB__MYOB_Log__c.isCreateable()){
                    Insert MYOB_Callout_Helper.myobLogs; 
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return cmpRes;
    }

//Aura Method : to display and populate invoice and its line items values on UI(Lwc).
    @AuraEnabled
    public static InvoiceDetailsWrapper displayInvoiceNLineItems(String invoiceId, Boolean getNonNullInvoiceFields){
        InvoiceDetailsWrapper wrp = new InvoiceDetailsWrapper();
        try {
            if(String.isNotBlank(invoiceId)){
                wrp.invoiceId=invoiceId;
                fetchInvoiceNLineItems(invoiceId,getNonNullInvoiceFields);
                if(mapMYOBInvoiceFldNameSfValue.keySet().size()>0){
                    wrp.mapInvoiceDetails = mapMYOBInvoiceFldNameSfValue;
                }
                if(lstMapMYOBLineItemFldNameSfValue.size()>0){
                    wrp.lstMapLineItemDetails = lstMapMYOBLineItemFldNameSfValue;
                }
            }
            System.debug('### wrp ::: '+wrp);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrp;
    }

    //Aura Method : To pass date to Sync Invoice Table.
    @AuraEnabled
    public static String getSingleInvoice(String invoiceId){
        List<MYOB_InvoiceResponse.cls_Items> lstInvoicesToSync = new List<MYOB_InvoiceResponse.cls_Items>();
        if( String.isNotBlank(invoiceId)){
            fetchInvoiceNLineItems(invoiceId,true);
            if(mapMYOBInvoiceFldNameSfValue.KeySet().size() > 0){
                //1. Preparing for Callout
                MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
                calloutWrapper.helper = 'InvoiceDynamicController.queryInvoice()';
                calloutWrapper.requestMethod = 'GET';  
                calloutWrapper.requestEndpoint='/Sale/Invoice/Item';
                calloutWrapper.requestBody='';
                calloutWrapper.dolog = true;
        
                //2. Preparing Callout for Single Invoice. 
                if(String.isNotBlank((String) mapMYOBInvoiceFldNameSfValue.get('UID'))){
                    calloutWrapper.requestEndpoint+='/'+mapMYOBInvoiceFldNameSfValue.get('UID');
                }

                //3. Callout and Parsing the reponse.
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);
                if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
                    String syncStatus = '';
                    lstInvoicesToSync = MYOB_InvoiceResponse.parse(objHTTP.response,true);
                    if(String.isBlank(syncStatus) || syncStatus == 'Failed'){
                        objHTTP.isLogException = true;
                    }
                }
            }
        }
        //4. Insert Logs
        if(Schema.sObjectType.KTMYOB__MYOB_Log__c.isCreateable()){
            System.debug(' ### MYOB_Callout_Helper.myobLogs ::: '+MYOB_Callout_Helper.myobLogs);
            Insert MYOB_Callout_Helper.myobLogs; 
        }
        System.debug('@@@ lstInvoicesToSync ::: '+lstInvoicesToSync);
        return JSON.serializePretty(lstInvoicesToSync[0]);
    }

    @AuraEnabled
    public static string updateInvoiceInSf(Map<string,object> invoiceMap,Map<string,Map<String,object>> lineItemsMap,Map<String,String> lineItemRowIDMap,String invoiceId){
        String status = '';
        try {
            generateObjectFieldMapping();
            SObject invoice  = invoiceSOBject.clone(false, true, false, false);
            
            if(String.isNotBlank(invoiceId)){
                invoice.put('Id',invoiceId);
            }

            //Iterating the map of invoice fields and storing the invoice fields.
            if(invoiceMap.KeySet().size() > 0 && String.isNotBlank(invoiceId)){
               for(String key : invoiceMap.keySet()){
                    if(String.isNotBlank(mapMYOBApiNameInvoiceData.get(key).KTMYOB__Field_API_Name__c)){
                        invoice.put(mapMYOBApiNameInvoiceData.get(key).KTMYOB__Field_API_Name__c, invoiceMap.get(key));
                    }
                }
            }   

            List<SObject> lstLineItemsObject = new List<SObject>();
            if(lineItemsMap.KeySet().size() > 0 && String.isNotBlank(invoiceId)){
                for(String linefieldMap : lineItemsMap.keySet()){
                    SObject lineItem  = lineItemSOBject.clone(false, true, false, false);
                    for(String key : lineItemsMap.get(linefieldMap).keySet()){
                        if(String.isNotBlank(mapMYOBApiNameLineItemData.get(key).KTMYOB__Field_API_Name__c)){
                            lineItem.put(mapMYOBApiNameLineItemData.get(key).KTMYOB__Field_API_Name__c, lineItemsMap.get(linefieldMap).get(key));
                        }
                    }
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c) && lineItemRowIDMap.containsKey(linefieldMap)){
                        lineItem.put(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c,lineItemRowIDMap.get(linefieldMap)+'');
                        lstLineItemsObject.add(lineItem);
                    }else{
                        continue;
                    }
               }
            }

            System.debug(' ### invoice ::: '+invoice);
            System.debug(' ### lstLineItemsObject ::: '+lstLineItemsObject);

            if(invoice.get('Id')!= null){
                if(Schema.getGlobalDescribe().get(invoiceObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
                    if(String.isNotBlank(mapMYOBApiNameInvoiceData.get('UID').KTMYOB__Field_API_Name__c) && String.isNotBlank(invoiceObjectApiName)){
                        Database.update(invoice);
                        status='success';
                    }
                }
            }else if(invoiceMap.keySet().size() > 0){
                status='failed';
            }

            if(lstLineItemsObject.size()>0){
                //Upserting the List of Line Items.
                if(Schema.getGlobalDescribe().get(lineItemObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
                    if(String.isNotBlank(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c) && String.isNotBlank(lineItemObjectApiName)){
                        Schema.sObjectField lineItemExternalID = Schema.getGlobalDescribe().get(lineItemObjectApiName).getDescribe().fields.getMap().get(mapMYOBApiNameLineItemData.get('RowID').KTMYOB__Field_API_Name__c);
                        Database.upsert(lstLineItemsObject,lineItemExternalID,true);
                        status='success';
                    }
                }
            }else if(lineItemsMap.KeySet().size() > 0){
                status='failed';
            }
            return status;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    

    public class InvoiceDetailsWrapper{
        @AuraEnabled
        public Map<String,Object> mapInvoiceDetails = new Map<String,Object>(); 

        @AuraEnabled
        public List<Map<String,Object>> lstMapLineItemDetails = new List<Map<String,Object>>(); 

        @AuraEnabled
        public string invoiceId = '';
    }


    // TESTING PURPOSE METHOD BELOW
    @AuraEnabled(Cacheable =true)
    public static InvoiceDetailsWrapper testingMethod(){
        fetchInvoiceNLineItems('a05al00000BzRUnAAN',true);
        InvoiceDetailsWrapper wrp= new InvoiceDetailsWrapper();
        wrp.mapInvoiceDetails = mapMYOBInvoiceFldNameSfValue;
        wrp.lstMapLineItemDetails = lstMapMYOBLineItemFldNameSfValue;
        wrp.invoiceId = 'a05al00000BzRUnAAN';
        return wrp;
    }

}


/* TODO 01: Invoice terms format which is required.
    Terms": {
        "PaymentIsDue": "DayOfMonthAfterEOM",
        "DiscountDate": 1,
        "BalanceDueDate": 30,
        "DiscountForEarlyPayment": 5.0,
        "LatePaymentFeePercentage": 1.5
    }


    Terms.PaymentIsDue Attibute values
    ========================================

    1. InAGivenNumberOfDays - [Due in a number of days after the issue date]
        - BalanceDueDate [User input value eg: 22]
        - DueDate [BalanceDueDate + invoice date] [22 + 01/10/2024] = 23/10/2024
    2. DayOfMonthAfterEOM - [Due on date of next month] (same as InAGivenNumberOfDays)
    3. NumberOfDaysAfterEOM - [Due in a number of days after the end of the month] (same as InAGivenNumberOfDays)
    4. OnADayOfTheMonth - [Due on this day] (same as InAGivenNumberOfDays)

    5. Prepaid - [Prepaid]
        - BalanceDueDate [Takes the last set date or days]
        - DueDate [Takes the last set date and set the PaymentIsDue : as Prepaid] 
    6. CashOnDelivery - [CashOnDelivery] (Same as Prepaid)
*/



/*
**** Invoice Create Test : Sf to MYOB ****

InvoiceDynamicController.fetchInvoiceNLineItems('a05al00000BwocPAAR');
InvoiceDynamicController.InvoiceDetailsWrapper wrp= new InvoiceDynamicController.InvoiceDetailsWrapper();
wrp.mapInvoiceDetails = InvoiceDynamicController.mapMYOBInvoiceFldNameSfValue;
wrp.lstMapLineItemDetails = InvoiceDynamicController.lstMapMYOBLineItemFldNameSfValue;
MYOB_Callout_Helper.ComponentResponse cmpRes = InvoiceDynamicController.createUpdateInvoiceInMYOB(wrp);
System.debug('###Cmpres ::: '+cmpRes);

*/

/**** FORMAT OF DATA TO BE RECIEVED FROM UI
{
  "invoiceId": "a05al00000BzRUnAAN",
  "lstMapLineItemDetails": [
    {
      "ShipQuantity": 10,
      "UnitPrice": 600,
      "Total": 6000,
      "TaxCode": "a06al0000084bfWAAQ",
      "Invoice": "a05al00000BzRUnAAN",
      "ProductId": "01tal000004Kt7hAAC",
      "RowVersion": "-821312096204488704",
      "RowID": "3697"
    }
  ],
  "mapInvoiceDetails": {
    "UID": "c636c371-f687-4348-9ea3-e75669c2813e",
    "Date": "2025-01-10",
    "RowVersion": "-4496249392138813440",
    "CompanyUID": "001al00000wLuQsAAK",
    "Number": "1005",
    "Freight": 0,
    "TotalTax": 600,
    "BalanceDueAmount": 6600,
    "IsTaxInclusive": false,
    "TotalAmount": 6600,
    "Subtotal": 6000,
    "InvoiceName": "Invoice 1005"
  }
}
****/