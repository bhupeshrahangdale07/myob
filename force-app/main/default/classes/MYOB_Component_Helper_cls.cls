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
}