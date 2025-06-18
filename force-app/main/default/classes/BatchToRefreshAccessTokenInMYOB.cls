public with sharing class BatchToRefreshAccessTokenInMYOB implements Database.Batchable<sObject>, Schedulable,Database.AllowsCallouts{
    public Database.QueryLocator start(Database.BatchableContext batchContext){
        String query = 'SELECT Id, KTMYOB__Access_Token__c,KTMYOB__Client_Id__c, KTMYOB__Client_Secret__c,'
                        +'KTMYOB__Last_Refresh_Token_Date__c, KTMYOB__Refresh_Token__c,KTMYOB__Refresh_Token_Life_Days__c'
                        +' FROM KTMYOB__MYOB_Credential__c WITH SECURITY_ENFORCED LIMIT 1';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext batchContext, List<KTMYOB__MYOB_Credential__c> scope){
        KTMYOB__MYOB_Credential__c myobInfo;
        for(KTMYOB__MYOB_Credential__c myobRec : scope){    
            if(String.isNotBlank(myobRec.KTMYOB__Refresh_Token__c)){
                MYOB_Authorization_cls myobAuth = new MYOB_Authorization_cls();
                myobInfo = myobAuth.fetchAccessTokenUsingRefreshToken(true);
            }
        }
        if(myobInfo!=null){
            if(Schema.sObjectType.KTMYOB__MYOB_Credential__c.isUpdateable() && String.isNotBlank(myobInfo.KTMYOB__Access_Token__c) && String.isNotBlank(myobInfo.KTMYOB__Refresh_Token__c)){
                UPDATE myobInfo;
            }
        }
    }
    public void finish(Database.BatchableContext batchContext){
        SetupConfigController.updateCusSettingndScheduleBatch();
    }

    public void execute(SchedulableContext sc) {
        BatchToRefreshAccessTokenInMYOB b = new BatchToRefreshAccessTokenInMYOB(); 
        database.executebatch(b,1);
        System.abortJob(sc.getTriggerId());
    }
}