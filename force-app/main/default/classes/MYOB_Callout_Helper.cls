public without sharing class MYOB_Callout_Helper {

    public static KTMYOB__MYOB_Credential__c  myobInfo = MYOB_Authorization_cls.myobInfo;
    public Static List<KTMYOB__MYOB_Log__c> myobLogs = new List<KTMYOB__MYOB_Log__c>();


    /**
     * @description 
     * Callout Method : Generic Method for all API Callouts
    */ 
    public static HTTPModel genericCalloutMethod(String requestBody,Map<String,String> mapRequestHeaders,CalloutDetails apiDetails) {    
        mapRequestHeaders.put('Content-Type','application/json');
        mapRequestHeaders.put('x-myobapi-key',Utils.processDecryption(myobInfo.KTMYOB__Client_Id__c));
        mapRequestHeaders.put('x-myobapi-version','v2'); //TODO ::: need to store this somewhere in Salesforce.
        mapRequestHeaders.put('Accept','application/json');

        return doHTTPCallout(
            myobInfo.KTMYOB__Base_Url__c+Utils.processDecryption(myobInfo.KTMYOB__Company_File_Id__c)+apiDetails.requestEndpoint,
            apiDetails.requestMethod,
            mapRequestHeaders,
            requestBody,
            apiDetails
        );
    }

    /**
     * @description 
     * Callout Method : To Get List of all company files in the users account
    */   
    public static HTTPModel fetchAllCompanyFiles(Map<String,String> mapRequestHeaders,CalloutDetails apiDetails) {    
        mapRequestHeaders.put('Content-Type','application/json');
        mapRequestHeaders.put('x-myobapi-key',Utils.processDecryption(myobInfo.KTMYOB__Client_Id__c));
        mapRequestHeaders.put('Accept','application/json');

        return doHTTPCallout(
            'https://api.myob.com/accountright',
            'GET',
            mapRequestHeaders,
            '',          
            apiDetails
        );
    }

    /**
     * @description Main Method : Actual Method used for the callout.
     * @param method
     * @param contentType
     * @param apiPath
     * @param dataBody
     * @param credObj
     * @return HTTPModel warapper
     */
    public static HTTPModel doHTTPCallout(String endpoint,String method,Map<String,String> mapRequestHeaders,String dataBody,CalloutDetails credObj){
        boolean tempBoolean = false; //For scanning
        HTTPModel model = new HTTPModel();
        CalloutDetails apiDetails = (CalloutDetails)JSON.deserialize(JSON.serialize(credObj), CalloutDetails.class);
        try {
            if(myobInfo!=null){
                HttpRequest req = new HttpRequest();
                req.setMethod(method);
                for(String headerKey : mapRequestHeaders.KeySet()){
                    req.setHeader(headerKey, mapRequestHeaders.get(headerKey));
                }
                req.setEndpoint(endpoint);
                req.setHeader('Authorization', 'Bearer ' +  Utils.processDecryption(myobInfo.KTMYOB__Access_Token__c));
            
                System.debug('### dataBody ::: '+dataBody);
                if (String.isNotBlank(dataBody)){
                    req.setBody(dataBody);
                }                
                req.setTimeout(12 * 10000);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                model.isCalloutException = false;
                model.response = res.getBody();
            
                if(res.getStatusCode() >= 300){
                    model.isCalloutException = true;  
                    // //To do Re-Authentication after Authentiction Failure and resuming the callout opertion unintereptedly.
                    // Boolean isAuthenticationError = false;
                    // QBErrorResponse.errorCls errorObj =  QBErrorResponse.parseJSON(model.response);
                    // if(errorObj.Fault.type.equalsIgnoreCase('AUTHENTICATION') || errorObj.Fault.type.equalsIgnoreCase('VALIDATION')){
                    //     for(QBErrorResponse.cls_Error er: errorObj.Fault.Error){
                    //         System.debug('@@@ Qb error Message :: '+er.Message+' Status code :: '+res.getStatusCode());
                    //         //TODO : we will add these error codes to custom label or custom setting after discussion.
                    //         if((er.code.equalsIgnoreCase('3200') || er.code.equalsIgnoreCase('3202')) && res.getStatusCode() >= 400){
                    //         // if(er.Message.containsIgnoreCase('message=AuthenticationFailed') && res.getStatusCode() == 401){
                    //             isAuthenticationError = true;
                    //             break;
                    //         }
                    //     }
                    //     if(isAuthenticationError == true){
                    //         if(qbInfo.KTQB__Refresh_Token_Life_Days__c >0 && String.isNotBlank(qbInfo.KTQB__Refresh_Token__c)){
                    //             QuickBooksIntegerationController qb = new QuickBooksIntegerationController();
                    //             KTQB__Quickbook_Info__c qbInfoRecord = qb.fetchAccessTokenUsingRefreshToken(false);
                    //             if(String.isNotBlank(qbInfoRecord.KTQB__Access_Token__c) && String.isNotBlank(qbInfoRecord.KTQB__Refresh_Token__c)){
                    //                 if(isCalloutReAuthenticated == false){
                    //                     qbinfo.KTQB__Access_Token__c = qbInfoRecord.KTQB__Access_Token__c;
                    //                     qbinfo.KTQB__Refresh_Token__c = qbInfoRecord.KTQB__Refresh_Token__c;
                    //                     qbinfo.KTQB__Last_Refresh_Token_Date__c = qbInfoRecord.KTQB__Last_Refresh_Token_Date__c;
                    //                     isCalloutReAuthenticated = true;
                    //                     HTTPModel httpDetails = doHTTPCallout(method,contentType,apiPath,dataBody,credObj);
                    //                     if(Schema.sObjectType.KTQB__Quickbook_Info__c.isUpdateable() && httpDetails.isCalloutException == false){
                    //                         UPDATE qbInfoRecord;
                    //                     }
                    //                     model = httpDetails;
                    //                 }else{
                    //                     //TODO NOW: log error if the Re-Authentication is failed more than once .
                    //                     tempBoolean = true; 
                    //                     throw new QBSfSyncCustomException('Salesforce Re-Authentiction failed , please check the setup configurations settings and if needed re-authenticate again from setup page.');
                    //                 }
                    //             }
                    //         }
                    //     }
                    // }
                }

                //For Logging :
                if(apiDetails!=null){
                    apiDetails.requestBody = '{ Method: ' + req.getMethod() + '\n' +
                   'Endpoint: ' + req.getEndpoint() + '\n' +
                   'Headers[x-myobapi-key]: ' + req.getHeader('x-myobapi-key') + '\n' + 
                   'Headers[Content-Type]: ' + req.getHeader('Content-Type') + '\n' + 
                   'Headers[Accept]: ' + req.getHeader('Accept') + '\n' + 
                   'Body: ' + req.getBody()+ '\n' + 
                    ' }';
                    // apiDetails.requestBody = '{endpoint:'+endpoint +',method:'+method+',body:'+dataBody+',authorizationHeader:'+'Bearer ' + Utils.processDecryption(myobInfo.KTMYOB__Access_Token__c)+'}';
                    // apiDetails.requestBody = dataBody;
                    apiDetails.requestEndpoint =  endpoint;
                    apiDetails.requestMethod=  method;
                    apiDetails.responsebody =  res.getBody();
                    apiDetails.status =  res.getStatus();
                    apiDetails.statusCode =   res.getStatusCode();
                    apiDetails.errorMsg = model.isCalloutException == true ? 'Failed':'Success';
                    if(apiDetails.dolog == true){
                        system.debug('### apiDetails : '+apiDetails);
                        system.debug('### Do Log : '+apiDetails.dolog);
                        creatMYOBLog(apiDetails);
                    }
                }   
            }
        }
        catch (Exception ex) {
            HandleCustomException.LogException(ex);
            model.isCalloutException = true;
            model.response = ex.getLineNumber() + ' ' + ex.getMessage();
        }
        return model;
    }

// Creating MYOB Logs method
    //Callout Log
    public static void creatMYOBLog(CalloutDetails cred){
        String charLimitUp = '...more data ahead,cannot be displayed due to salesforce field limit.';//69 chars : do not add more chars or letter,limit will exceed and can cause error.
        try{
            KTMYOB__MYOB_Log__c exc = new KTMYOB__MYOB_Log__c();
            exc.KTMYOB__Callout_Log__c = true;
            // HttpRequest request info
            if(cred.requestEndpoint.getChars().size() <= 131072){
                exc.KTMYOB__Request_Endpoint__c = cred.requestEndpoint;
            }else{
                exc.KTMYOB__Request_Endpoint__c = cred.requestEndpoint.left(131000)+charLimitUp;
            }
            if(cred.requestbody.getChars().size() <= 131072){
                exc.KTMYOB__Request__c =  cred.requestbody;
            }else{
                exc.KTMYOB__Request__c =  cred.requestbody.left(131000)+charLimitUp;
            }
            exc.KTMYOB__Request_Method__c =  cred.requestMethod;
            exc.KTMYOB__Record_Id__c = cred.recordId;
            
            // HttpResponse response info
            if(cred.responsebody.getChars().size() <= 131072){
                exc.KTMYOB__Response__c =  cred.responsebody;
            }else{
                exc.KTMYOB__Response__c =  cred.responsebody.left(131000)+charLimitUp;
            }
            exc.KTMYOB__Status_Code__c = String.valueOf(cred.statusCode);
            exc.KTMYOB__Status__c =  cred.status;
            exc.KTMYOB__Helper__c =  cred.helper;
            if( cred.statusCode == 200){
                exc.KTMYOB__Error_Message__c = 'Success';
            }else{ 
                exc.KTMYOB__Error_Message__c = 'Error';
            }
            myobLogs.add(exc);
            
         }catch(Exception e){
            System.debug('CalloutUtlityController.createMYOBLog, e.getMessage() : ' + e.getMessage());
            System.debug('CalloutUtlityController.createMYOBLog, e.getLineNumber() : ' + e.getLineNumber());
        }
    }

//Helper Method : to check if all the Authentication steps are completed on the MYOB Setup page.
    @AuraEnabled
    public static ComponentResponse checkAuthorizationSteps(){
        ComponentResponse cmpRes = new ComponentResponse();
        if(myobInfo.KTMYOB__Completed_Steps__c == 4){
            cmpRes.status = 'Success';
        }else if(myobInfo.KTMYOB__Completed_Steps__c < 4){
            cmpRes.status = 'Failed';
            cmpRes.isConnectionError = true;
            cmpRes.message = 'Please complete all the Connection Steps on QuickBook Setup page.'; 
        }
        return cmpRes;
    }

//Helper Method : To Publish the Callout response on the UI.
    public static ComponentResponse publishCalloutResponse(HTTPModel objHTTP,ComponentResponse cmpRes,String successMsg,String errorMsg){
        System.debug('### objHTTP ::: '+objHTTP);
        if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
            //TODO : Create a method over here to query the currently synced contact to save its UID and Row Version.
            cmpRes.status = 'Success';
            cmpRes.message = successMsg;
        }else if(objHTTP.isLogException){
            cmpRes.status = 'Failed';
            cmpRes.message = errorMsg+'Please Contact your System Administrator to check the MYOB Logs.';
        }else{
            cmpRes.status = 'Failed';
            if(objHTTP.isCalloutException && objHTTP.response.contains('"Error"')){
                MYOB_ErrorResponse.ErrorsCls errorObj = MYOB_ErrorResponse.parseJSON(objHTTP.response);
                for(MYOB_ErrorResponse.SingleErrorCls error: errorObj.Errors){
                    System.debug('### Errors ::: '+error);
                }
                cmpRes.multipleMessage = JSON.serialize(errorObj.Errors);
            }else{
                cmpRes.message ='Please Contact your System Administrator to check the MYOB Logs.';
            }   
        }
        return cmpRes;
    }

//Helper : To get the Tax Codes from MYOB MetaData Custom Object
    public static Map<String,Map<String,String>> fetchMyobMetadata(List<String> lstTaxCodeMtdIds,Boolean isSyncSFToMYOB){
        Map<String,Map<String,String>> mapTaxCodeMtdMYOBId = new Map<String,Map<String,String>>();
        String query  = 'SELECT Id,KTMYOB__Metadata_Type__c, KTMYOB__Tax_Code__c,  KTMYOB__MYOB_Id__c FROM KTMYOB__MYOB_MetaData__c ';
        if(isSyncSFToMYOB == true){
            query += 'WHERE Id IN:lstTaxCodeMtdIds';
            for(KTMYOB__MYOB_MetaData__c metaData : Database.query(query)){
                if(mapTaxCodeMtdMYOBId.containsKey(metaData.KTMYOB__Metadata_Type__c)){
                    mapTaxCodeMtdMYOBId.get(metaData.KTMYOB__Metadata_Type__c).put(metaData.Id,metaData.KTMYOB__MYOB_Id__c);
                }else{
                    mapTaxCodeMtdMYOBId.put(metaData.KTMYOB__Metadata_Type__c,new Map<String,String>{metaData.Id=>metaData.KTMYOB__MYOB_Id__c});
                }
            }
        }else{
            query += 'WHERE KTMYOB__MYOB_Id__c IN:lstTaxCodeMtdIds';
            for(KTMYOB__MYOB_MetaData__c metaData : Database.query(query)){
                if(mapTaxCodeMtdMYOBId.containsKey(metaData.KTMYOB__Metadata_Type__c)){
                    mapTaxCodeMtdMYOBId.get(metaData.KTMYOB__Metadata_Type__c).put(metaData.KTMYOB__MYOB_Id__c,metaData.Id);
                }else{
                    mapTaxCodeMtdMYOBId.put(metaData.KTMYOB__Metadata_Type__c,new Map<String,String>{metaData.KTMYOB__MYOB_Id__c=>metaData.Id});
                }
            }
        }
        return mapTaxCodeMtdMYOBId;
    }

//Helper : To convert the dattime to utc for the Integration purpose.
    public static string convertDateTimetoUTC(DateTime dt){
        String newDateTime =  '';
 
        String dtMonth = dt.month()<10?'0'+dt.month().format() : dt.month().format();
        String dtDay = dt.day()<10?'0'+dt.day().format() : dt.day().format();
        String dtHour = dt.hourGmt()<10?'0'+dt.hourGmt().format() : dt.hourGmt().format();
        String dtMinute = dt.minuteGmt()<10?'0'+dt.minuteGmt().format() : dt.minuteGmt().format();
        String dtSecond = dt.secondGmt()<10?'0'+dt.secondGmt().format() : dt.secondGmt().format();
        String dtMilliSecond = dt.millisecondGmt()<10?'00'+dt.millisecondGmt().format() : dt.millisecondGmt()<100 ? '0'+dt.millisecondGmt().format(): dt.millisecondGmt().format();
 
        if(String.isNotBlank(dtMonth) && String.isNotBlank(dtDay)
         && String.isNotBlank(dtHour) && String.isNotBlank(dtMinute) 
         && String.isNotBlank(dtSecond) && String.isNotBlank(dtMilliSecond)){
             newDateTime = dt.year()+'-'+dtMonth+'-'+dtDay+'T'+dtHour+':'+dtMinute+':'+dtSecond+'.'+dtMilliSecond;
         }
         return newDateTime;
     }

//Helper : To convert the dattime to utc for the Integration purpose.
     public static string convertDateToUTC(Date dt){
         String newDate =  '';
         String dtMonth = dt.month()<10?'0'+dt.month().format() : dt.month().format();
         String dtDay = dt.day()<10?'0'+dt.day().format() : dt.day().format();
         if(String.isNotBlank(dtMonth) && String.isNotBlank(dtDay)){
             newDate = dt.year()+'-'+dtMonth+'-'+dtDay;
         }
         return newDate;
     }
    

    /** @description : Wrapper Class */
    public class HTTPModel {
        public String response = '';
        public Boolean isCalloutException = false;
        public Boolean isLogException = false;
    }


    /** @description : Wrapper Class */
    public class ComponentResponse{
        @AuraEnabled public string status;
        @AuraEnabled public string message;
        @AuraEnabled public string multipleMessage;
        @AuraEnabled public boolean isConnectionError;
        @AuraEnabled public List<Object> lstData;

        public ComponentResponse(){
            status= '';
            message= '';
            multipleMessage=''; //Add the error in JSON Format to add multiple messages.
            isConnectionError=false;
            lstData = new List<Object>();
        }
    }

     /** @description : Wrapper Class */
     public Class CalloutDetails{
        public string requestbody;
        public string requestEndpoint;
        public string requestMethod;
        public string responsebody;
        public string status;
        public Integer statusCode;
        public string errorMsg;
        public string helper;
        public string recordId;
        public boolean dolog;

        public CalloutDetails(){
            requestbody = '';
            requestEndpoint = '';
            requestMethod = '';
            responsebody = '';
            status = '';
            statusCode = 0;
            errorMsg = '';
            helper = '';
            dolog=true;
        }
    }

    /** @description : Custom Exception Class */
    public class MYOBCustomException extends Exception {}

    
}