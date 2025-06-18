/**
 * @Author : Kandisa Technologies
 * @description MYOB Setup : Helper Controller
 * @created on        : 2024
 * @created by        : Piyush V Ganorkar
 * @last modified on  : 1-8-2024
 * @last modified by  : Piyush V Ganorkar
 */
public without sharing class CalloutUtlityController {
    public Static List<KTMYOB__MYOB_Log__c> myobLogs = new List<KTMYOB__MYOB_Log__c>();
    //Callout Log
    // public static void creatMYOBLog(CalloutCredentials cred, string recordId){
    //     try{
    //         KTMYOB__MYOB_Log__c exc = new KTMYOB__MYOB_Log__c();
    //         exc.KTMYOB__Callout_Log__c = true;
    //         // HttpRequest request info
    //         exc.KTMYOB__Request_Endpoint__c = cred.requestbody.getEndpoint();
    //         exc.KTMYOB__Request__c =  cred.requestbody.getBody();
    //         exc.KTMYOB__Request_Method__c =  cred.requestbody.getMethod();
    //         exc.KTMYOB__Record_Id__c = recordId;
    //         // HttpResponse response info
    //         exc.KTMYOB__Response__c =  cred.responsebody.getBody();
    //         exc.KTMYOB__Status_Code__c = String.valueOf( cred.responsebody.getStatusCode());
    //         exc.KTMYOB__Status__c =  cred.responsebody.getStatus();
    //         if( cred.responsebody.getStatusCode() == 200){
    //             exc.KTMYOB__Error_Message__c = 'Success';
    //         }else{ 
    //             exc.KTMYOB__Error_Message__c = 'Error';
    //         }
    //         myobLogs.add(exc);
            
    //      }catch(Exception e){
    //         System.debug('CalloutUtlityController.createMYOBLog, e.getMessage() : ' + e.getMessage());
    //         System.debug('CalloutUtlityController.createMYOBLog, e.getLineNumber() : ' + e.getLineNumber());
    //     }
    // }
    
    // public Class CalloutCredentials{
    //     public HttpRequest requestbody;
    //     public HttpResponse responsebody;
    // }
    
}