public with sharing class MYOB_Authorization_cls {
    public static KTMYOB__MYOB_Credential__c  myobInfo = [SELECT Id, KTMYOB__Access_Token__c, KTMYOB__Access_Token_URL__c, 
                                                            KTMYOB__Authorization_URL__c, KTMYOB__Client_Id__c, KTMYOB__Client_Secret__c,
                                                            KTMYOB__Last_Refresh_Token_Date__c, KTMYOB__Redirect_URL__c, KTMYOB__Refresh_Token__c, 
                                                            KTMYOB__Refresh_Token_Life_Days__c, KTMYOB__Scope__c ,KTMYOB__Company_File_Id__c, KTMYOB__Base_Url__c,KTMYOB__Completed_Steps__c
                                                            FROM KTMYOB__MYOB_Credential__c 
                                                        WITH SECURITY_ENFORCED LIMIT 1];

    public static string salesforceUrl = URL.getOrgDomainUrl().toExternalForm();
    public static string decryptedClientId = Utils.processDecryption(myobInfo.KTMYOB__Client_Id__c);
    public static string decryptedClientSecret =  Utils.processDecryption(myobInfo.KTMYOB__Client_Secret__c);
    public static string decryptedRefreshToken = String.isNotBlank(myobInfo.KTMYOB__Refresh_Token__c) ? Utils.processDecryption(myobInfo.KTMYOB__Refresh_Token__c) : '';
    public static string authoziationCode;

    public MYOB_Authorization_cls(){}
    public MYOB_Authorization_cls(ApexPages.StandardController stdController) {}

    public  Pagereference fetchAuthorizationCode(){
        String url=myobInfo.KTMYOB__Authorization_URL__c+'?client_id='+decryptedClientId+'&redirect_uri='+myobInfo.KTMYOB__Redirect_URL__c+'&scope='+myobInfo.KTMYOB__Scope__c+'&response_type=code';
        // Pagereference pageRef = new PageReference(EncodingUtil.urlDecode(EncodingUtil.urlEncode(url,'utf-8'),'utf-8')); 
        System.debug('#### redirect_uri ::: '+myobInfo.KTMYOB__Redirect_URL__c);
        Pagereference pageRef = new PageReference(url);
        System.debug('### pageRef ::: '+pageRef);
        // Pagereference pageRef = new PageReference(url);
        return pageRef;
    }

    public Pagereference fetchAccessToken(){
        try{
            if(Apexpages.currentPage() != Null){
                authoziationCode = Apexpages.currentPage().getParameters().get('code');
            }  
            
            if(String.isNotBlank(authoziationCode)){
                String body = 'client_id='+decryptedClientId+'&client_secret='+decryptedClientSecret+'&grant_type=authorization_code&code='+authoziationCode+'&redirect_uri='+myobInfo.KTMYOB__Redirect_URL__c;
                AuthorizationWrapper authData = accessTokenHelperMethod(body,true); 
                KTMYOB__MYOB_Credential__c myobInfoObj = new KTMYOB__MYOB_Credential__c(Id=myobInfo.Id,
                                                        KTMYOB__Access_Token__c = Utils.processEncryption(authData.access_token),
                                                        KTMYOB__Refresh_Token__c = Utils.processEncryption(authData.refresh_token),
                                                        Refresh_Token_Life_Days__c =100,Last_Refresh_Token_Date__c = System.now());
                if(Schema.sObjectType.KTMYOB__MYOB_Credential__c.isUpdateable()){
                    Database.SaveResult sR = Database.update(myobInfoObj);
                }
                SetupConfigController.updateCusSettingndScheduleBatch(); 
                if(String.isNotBlank(salesforceUrl)){
                    String url = salesforceUrl;
                    PageReference pg = new PageReference(EncodingUtil.urlDecode(EncodingUtil.urlEncode(url,'utf-8'),'utf-8'));
                    // PageReference pg = new PageReference(url);
                    return pg.setRedirect(true);
                }
            }
            PageReference pg2 =  fetchAuthorizationCode();
            return pg2.setRedirect(true);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Multiple Components - For fetching access token using refresh token.
     * @return KTMYOB__MYOB_Credential__c Record Data.
     */
    public KTMYOB__MYOB_Credential__c fetchAccessTokenUsingRefreshToken(Boolean doGenerateLog){
        KTMYOB__MYOB_Credential__c myobInfoObj = new KTMYOB__MYOB_Credential__c();
        try{
            if(String.isNotBlank(decryptedRefreshToken)){
                String body = 'client_id='+decryptedClientId+'&client_secret='+decryptedClientSecret+'&refresh_token='+decryptedRefreshToken+'&grant_type=refresh_token';
                AuthorizationWrapper authData = accessTokenHelperMethod(body,doGenerateLog);
                myobInfoObj = new KTMYOB__MYOB_Credential__c(Id=myobInfo.Id,Last_Refresh_Token_Date__c = System.now(),
                            KTMYOB__Access_Token__c = Utils.processEncryption(authData.access_token),
                            KTMYOB__Refresh_Token__c = Utils.processEncryption(authData.refresh_token));
                return myobInfoObj;
            }
            return myobInfoObj;
        }catch(Exception e){
            HandleCustomException.LogException(e);
            return myobInfoObj;
        }
    }

    public AuthorizationWrapper accessTokenHelperMethod(String body,Boolean doGenerateLog){
        try{
            Http hp = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(myobInfo.KTMYOB__Access_Token_URL__c);
            req.setBody(body);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Basic '+EncodingUtil.base64Encode(Blob.valueOf(decryptedClientId+':'+decryptedClientSecret)));
            
            HttpResponse response = hp.send(req);
            // CalloutUtlityController.CalloutCredentials cred = new CalloutUtlityController.CalloutCredentials();
            // cred.requestbody = req;
            // cred.responsebody = response;

            // To create Log
            MYOB_Callout_Helper.CalloutDetails cred =  new MYOB_Callout_Helper.CalloutDetails();
            cred.requestEndpoint = req.getEndpoint();
            cred.requestMethod = req.getEndpoint();
            cred.requestbody = req.getBody();

            cred.responsebody = response.getBody();
            cred.status = response.getStatus();
            cred.statusCode = response.getStatusCode();
            cred.helper ='MYOB_Authorization_cls.accessTokenHelperMethod()';
            cred.recordId = myobInfo.Id;

            MYOB_Callout_Helper.creatMYOBLog(cred);
            // if(CalloutUtlityController.myobLogs.size() > 0 && doGenerateLog == true){
            //     insert CalloutUtlityController.myobLogs;
            // }
            AuthorizationWrapper authData = (AuthorizationWrapper) JSON.deserialize(response.getBody(), AuthorizationWrapper.class);    
            return authData;
        }catch(Exception e){
            HandleCustomException.LogException(e);
            throw new AuraHandledException(e.getMessage());
        }
    }


    /** @description Multiple Components : Wrapper Class. */
    public Class AuthorizationWrapper {
        public String access_token;
        public String refresh_token;
    }
}