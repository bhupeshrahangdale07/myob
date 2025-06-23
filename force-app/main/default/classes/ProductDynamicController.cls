public with sharing class ProductDynamicController {

    public static String productObjectApiName;
    public static SObject productSOBject;
    public static Map<String,KTMYOB__Product_Fields_Mapping__c> mapMYOBApiNameProductData = new Map<String,KTMYOB__Product_Fields_Mapping__c>();
    public static List<String> lstTaxCodeMtdIds = new List<String>();

    /* @description helper: to prepare the product data */ 
    public static void generateObjectFieldMapping(){
        try{
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
        }catch(Exception ex){
          HandleCustomException.LogException(ex);
        } 
    }


     /*
     * @description AuraMethod : To Sync All the MYOB Products to Salesforce
        @param productId - product record id.
        @param syncSingleProduct - boolean checks if Single product or All the products to be synced.
        @return component response
     */
    @AuraEnabled
    public static  MYOB_Callout_Helper.ComponentResponse fetchAllMyobProducts(String productId,Boolean syncSingleProduct,Boolean isItemActive,String itemType){
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
                calloutWrapper.helper = 'ProductDynamicController.fetchAllMyobProducts()';
                calloutWrapper.requestMethod = 'GET';  
                calloutWrapper.requestEndpoint='/Inventory/Item';
                calloutWrapper.dolog = false;

                //Getting the Items,by checking the Active or Inactive.
                String calloutQueryParams = '';
                if(isItemActive==true){
                    calloutQueryParams= 'IsActive eq true';
                }else{
                    calloutQueryParams='IsActive eq false';
                }

                //2. Preparing Callout for Single Product.
                if(String.isNotBlank(productId) && syncSingleProduct == true){
                    calloutWrapper.requestEndpoint+='/'+fetchProductGUID(productId);
                    calloutWrapper.dolog = true;
                }
                //3. Preparing Callout for Multiple Products.
                else if(itemType!='All'){  
                    if(itemType == 'IsSold'){
                        if(String.isNotBlank(calloutQueryParams)){
                            calloutQueryParams += ' and IsSold eq true';
                        }
                    }else if(itemType == 'IsBought'){
                        if(String.isNotBlank(calloutQueryParams)){
                            calloutQueryParams += ' and IsBought eq true';
                        }
                    }else if(itemType == 'IsInventoried'){
                        if(String.isNotBlank(calloutQueryParams)){
                            calloutQueryParams += ' and IsInventoried eq true';
                        }
                    }
                }
                if(String.isNotBlank(calloutQueryParams)){
                    calloutWrapper.requestEndpoint+='?$filter='+EncodingUtil.urlEncode(calloutQueryParams,'UTF-8');
                }
                
                //3. Generic method for Syncing MYOB Products to Salesforce.
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);
                if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
                    String syncStatus = '';
                    String successMsg = 'The Product has been successfully synced into your Salesforce.' ;
                    String errorMsg = 'The Product failed to Sync into your Saleforce. Please contact your system administrator to check the MYOB logs.' ;

                    List<MYOB_ProductResponse.cls_Items> lstProductsToSync = MYOB_ProductResponse.parse(objHTTP.response,syncSingleProduct);
                    System.debug('### lstProductsToSync ::: '+lstProductsToSync.size());
                    if(lstProductsToSync.size()>0){
                        syncStatus = upsertProducts(lstProductsToSync);
                    }

                    if(String.isBlank(syncStatus) || syncStatus == 'failed' || syncStatus == 'async-failed'){
                        objHTTP.isLogException = true;
                    }

                    //4.Publishing Response to UI i.e. handled in Lwc as Toast message.
                    cmpRes = MYOB_Callout_Helper.publishCalloutResponse(objHTTP,cmpRes,successMsg,errorMsg);
                }
            }
        }catch(Exception exp){
            HandleCustomException.LogException(exp);
        }
         //5. Creating the MYOB Logs.
         if(Schema.sObjectType.KTMYOB__MYOB_Log__c.isCreateable()){
            Insert MYOB_Callout_Helper.myobLogs; 
        }
        return cmpRes;
    }

//Helper Method : To get the UID of the Product for the Sync Process.
    public static string fetchProductGUID(String productId){
        if(String.isNotBlank(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c) && String.isNotBlank(productObjectApiName) && String.isNotBlank(productId)){
            String productQuery = 'SELECT Id,'+String.escapeSingleQuotes(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c)+' FROM '+String.escapeSingleQuotes(productObjectApiName)+' WHERE Id=:productId LIMIT 1';
            SObject productRecordQueried = Database.query(productQuery); 
            if(productRecordQueried != null){
                return (String) productRecordQueried.get((mapMYOBApiNameProductData.get('UID')).KTMYOB__Field_API_Name__c);
            }
        }
        return '';
    }

//Helper Method : To Upsert products in Salesforce.
    public static string upsertProducts(List<MYOB_ProductResponse.cls_Items> lstProductsToSync){

        //Iterating to get the related object details.
        for(MYOB_ProductResponse.cls_Items productObj : lstProductsToSync){
            if(String.isNotBlank(mapMYOBApiNameProductData.get('IncomeAccountName').KTMYOB__Field_API_Name__c)){
                lstTaxCodeMtdIds.add( productObj?.BuyingDetails?.TaxCode?.UID); 
                lstTaxCodeMtdIds.add( productObj?.SellingDetails?.TaxCode?.UID); 
            }
        }

        //fetching the Tax Code and FrieghtTax Code from MYOB Metadata.
        Map<String,Map<String,String>> mapMetaDataTypeMYOBId = MYOB_Callout_Helper.fetchMyobMetadata(lstTaxCodeMtdIds,false);

        String upsertStatus = '';
        List<SObject> lstProductsSynced = new List<SObject>();
        try{
            for(MYOB_ProductResponse.cls_Items productObj : lstProductsToSync){
                SObject product  = productSOBject.clone(false, true, false, false);

                if(String.isNotBlank(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c, productObj?.UID);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('RowVersion').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('RowVersion').KTMYOB__Field_API_Name__c, productObj?.RowVersion);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('Name').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('Name').KTMYOB__Field_API_Name__c, productObj?.Name);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('IsActive').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('IsActive').KTMYOB__Field_API_Name__c, productObj?.IsActive);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('Number').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('Number').KTMYOB__Field_API_Name__c, productObj?.S_Number);
                }

                //Storing MYOB Product Categories Details.
                if(String.isNotBlank(mapMYOBApiNameProductData.get('ExpenseAccountUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('ExpenseAccountUID').KTMYOB__Field_API_Name__c, productObj?.ExpenseAccount?.UID);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('ExpenseAccountName').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('ExpenseAccountName').KTMYOB__Field_API_Name__c, productObj?.ExpenseAccount?.Name);
                }

                if(String.isNotBlank(mapMYOBApiNameProductData.get('CostOfSalesAccountUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('CostOfSalesAccountUID').KTMYOB__Field_API_Name__c, productObj?.CostOfSalesAccount?.UID);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('CostOfSalesAccountName').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('CostOfSalesAccountName').KTMYOB__Field_API_Name__c, productObj?.CostOfSalesAccount?.Name);
                }

                if(String.isNotBlank(mapMYOBApiNameProductData.get('IncomeAccountUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('IncomeAccountUID').KTMYOB__Field_API_Name__c, productObj?.IncomeAccount?.UID);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('IncomeAccountName').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('IncomeAccountName').KTMYOB__Field_API_Name__c, productObj?.IncomeAccount?.Name);
                }

                if(String.isNotBlank(mapMYOBApiNameProductData.get('AssetAccountUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('AssetAccountUID').KTMYOB__Field_API_Name__c, productObj?.AssetAccount?.UID);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('AssetAccountName').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('AssetAccountName').KTMYOB__Field_API_Name__c, productObj?.AssetAccount?.Name);
                }

            //Storing MYOB Buying Details.
                if(String.isNotBlank(mapMYOBApiNameProductData.get('ItemsPerBuyingUnit').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('ItemsPerBuyingUnit').KTMYOB__Field_API_Name__c, productObj?.BuyingDetails?.ItemsPerBuyingUnit);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('BuyingTaxCodeUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('BuyingTaxCodeUID').KTMYOB__Field_API_Name__c, mapMetaDataTypeMYOBId.get('TAX_CODE').get(productObj?.BuyingDetails?.TaxCode?.UID));
                }
                //Supplier Details
                if(String.isNotBlank(mapMYOBApiNameProductData.get('SupplierUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('SupplierUID').KTMYOB__Field_API_Name__c, productObj?.BuyingDetails?.RestockingInformation?.Supplier?.UID);
                }

            //Storing Selling Details
                if(String.isNotBlank(mapMYOBApiNameProductData.get('ItemsPerSellingUnit').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('ItemsPerSellingUnit').KTMYOB__Field_API_Name__c, productObj?.SellingDetails?.ItemsPerSellingUnit);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('SellingTaxCodeUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('SellingTaxCodeUID').KTMYOB__Field_API_Name__c, mapMetaDataTypeMYOBId.get('TAX_CODE').get(productObj?.SellingDetails?.TaxCode?.UID));
                }

            //Storing Location Details : TODO Investigate futher because of Multiple locations options
                if(String.isNotBlank(mapMYOBApiNameProductData.get('LocationUID').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('LocationUID').KTMYOB__Field_API_Name__c, productObj?.LocationDetails?.get(0)?.Location?.UID);
                }
                if(String.isNotBlank(mapMYOBApiNameProductData.get('LocationName').KTMYOB__Field_API_Name__c)){
                    product.put(mapMYOBApiNameProductData.get('LocationName').KTMYOB__Field_API_Name__c, productObj?.LocationDetails?.get(0)?.Location?.Name);
                }
                lstProductsSynced.add(product);
            }


            if(lstProductsSynced.size()>0){

                if(Schema.getGlobalDescribe().get(productObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()
                    || Schema.getGlobalDescribe().get(productObjectApiName).getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
                    if(String.isNotBlank(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c) && String.isNotBlank(productObjectApiName)){
                        Schema.sObjectField productExternalID = Schema.getGlobalDescribe().get(productObjectApiName).getDescribe().fields.getMap().get(mapMYOBApiNameProductData.get('UID').KTMYOB__Field_API_Name__c);

                        //Upserting the Products based on the size
                        if(lstProductsSynced.size()<2){
                            Database.upsert(lstProductsSynced,productExternalID,true);
                            upsertStatus = 'success';
                        }else if(lstProductsSynced.size()<50000){ //APP LIMIT : we can only sync upto 50,000 record
                            System.debug('### lstProductsSynced multiple prods count ::: '+lstProductsSynced.size());
                            Database.executeBatch(new Batch_DMLSobjects(lstProductsSynced,'upsert',productExternalID),2000);
                            upsertStatus = 'async-success';
                        }else{
                            upsertStatus = 'async-failed';
                        }
                    }
                }
            }
        }catch(Exception e){
            HandleCustomException.LogException(e);
            upsertStatus = 'failed';
        }
        return upsertStatus;
    }


    // public class UpsertBulkRecordsQueueable implements Queueable {
    //     private Schema.SObjectField externalIdField;
    //     private List<SObject> LstProductRecords;
    
    //     public UpsertBulkRecordsQueueable(Schema.SObjectField externalIdField, List<SObject> LstProductRecords) {
    //         this.externalIdField = externalIdField;
    //         this.LstProductRecords = LstProductRecords;
    //     }
    
    //     public void execute(QueueableContext context) {
    //         try {
    //             if(LstProductRecords.size()>0 && externalIdField!=null){
    //                 Database.upsert(LstProductRecords,externalIdField,true);
    //             }else{
    //                 return;
    //             }
    //             System.debug('Upsert successful.');
    //         } catch (Exception e) {
    //             HandleCustomException.LogException(e);
    //         }
    //         //TODO : Send an Email to the System administrator regarding the success and failure of the products.
    //     }
    // }
    

}