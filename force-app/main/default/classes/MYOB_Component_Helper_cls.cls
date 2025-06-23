public without sharing class MYOB_Component_Helper_cls {


    /**
     * @description 
     * Aura Method : To Get List of all company files in the users account and display it on MYOB Setup page.
     */ 
    @AuraEnabled
    public static List<MYOB_CompanyFiles_Response.XCompanyFileDetails> fetchCompanyFiles(){
        try {
            MYOB_Callout_Helper.HttpModel objHTTP = MYOB_Callout_Helper.fetchAllCompanyFiles(new Map<String,String>(),new MYOB_Callout_Helper.CalloutDetails());
            System.debug('### objHTTP ::: '+objHTTP);
            List<MYOB_CompanyFiles_Response.XCompanyFileDetails> lstResponseObj = MYOB_CompanyFiles_Response.parseJSON(objHTTP.response);
            System.debug('#### lstResponseObj ::: '+lstResponseObj);
            return lstResponseObj;
            
        } catch (Exception ex) {
            HandleCustomException.LogException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description 
     * Aura Method : To Get List of all the custom setting configs on UI.
     */
    @AuraEnabled(Cacheable=true)
    public static customSettingMappingWrapper fetchMYOBObCSConfig(){
        ContactDynamicController.generateObjectFieldMapping();
        InvoiceDynamicController.generateObjectFieldMapping();
        ProductDynamicController.generateObjectFieldMapping();

        customSettingMappingWrapper objWrapper = new customSettingMappingWrapper();
        objWrapper.invoiceObjectApiName = InvoiceDynamicController.invoiceObjectApiName;
        objWrapper.lineItemObjectApiName = InvoiceDynamicController.lineItemObjectApiName;  
        objWrapper.mapMYOBApiNameInvoiceData = InvoiceDynamicController.mapMYOBApiNameInvoiceData;
        objWrapper.mapMYOBApiNameLineItemData = InvoiceDynamicController.mapMYOBApiNameLineItemData;

        objWrapper.productObjectApiName = ProductDynamicController.productObjectApiName;
        objWrapper.mapMYOBApiNameProductData = ProductDynamicController.mapMYOBApiNameProductData;

        objWrapper.contactCompanyObjectApiName = ContactDynamicController.contactCompanyObjectApiName;
        objWrapper.contactIndividualObjectApiName = ContactDynamicController.contactIndividualObjectApiName;
        objWrapper.contactSavedInDiffOBj = ContactDynamicController.contactSavedInDiffOBj;
        objWrapper.mapMYOBApiNameCompanyData = ContactDynamicController.mapMYOBApiNameCompanyData;
        objWrapper.mapMYOBApiNameIndividualData = ContactDynamicController.mapMYOBApiNameIndividualData;

        //add more if you have create more custom setting in future.
        return objWrapper;
    }

    public class customSettingMappingWrapper{
        //For Invoice
        @AuraEnabled public String invoiceObjectApiName;
        @AuraEnabled public String lineItemObjectApiName;
        @AuraEnabled public Map<String,KTMYOB__Invoice_Fields_Mapping__c> mapMYOBApiNameInvoiceData ;
        @AuraEnabled public Map<String,KTMYOB__LineItem_Fields_Mapping__c> mapMYOBApiNameLineItemData ;

        //For Product
        @AuraEnabled public String productObjectApiName;
        @AuraEnabled public Map<String,KTMYOB__Product_Fields_Mapping__c> mapMYOBApiNameProductData ;

        //For Contact
        @AuraEnabled public String contactCompanyObjectApiName;
        @AuraEnabled public String contactIndividualObjectApiName;
        @AuraEnabled public Boolean contactSavedInDiffOBj;
        @AuraEnabled public Map<String,KTMYOB__Contact_Company_Fields_Mapping__c> mapMYOBApiNameCompanyData ;
        @AuraEnabled public Map<String,KTMYOB__Contact_Individual_Fields_Mapping__c> mapMYOBApiNameIndividualData ;
    }

}