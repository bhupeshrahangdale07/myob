public with sharing class Batch_DMLSobjects implements Database.Batchable<sObject>{
    private List<SObject> LstProductRecords;
    private string dmlMethod;
    private Schema.SObjectField externalIdField;

    public Batch_DMLSobjects(List<SObject> LstProductRecords, string dmlMethod, Schema.SObjectField externalIdField) {
        this.LstProductRecords = LstProductRecords;
        this.dmlMethod = dmlMethod;
        this.externalIdField = externalIdField;
    }
    public Iterable<sObject> start(Database.BatchableContext BC){
        return this.LstProductRecords;
    }   
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        try {
            if(LstProductRecords.size()>0 ){
                if(dmlMethod == 'insert'){
                    Database.insert(LstProductRecords,true);
                }else if(dmlMethod == 'update'){
                    Database.update(LstProductRecords,true);
                }else if(dmlMethod == 'upsert' && externalIdField!=null){
                    Database.upsert(LstProductRecords,externalIdField,true);
                }else if(dmlMethod == 'delete'){
                    Database.delete(LstProductRecords,true);
                }
            }
            System.debug('Upsert successful.');
        } catch (Exception e) {
            HandleCustomException.LogException(e);
        }
    }
    public void finish(Database.BatchableContext BC){
        sendEmailToCurrentUser();
         //TODO : Send an Email to the System administrator regarding the success and failure of the products.
    }

//helper to send email to adminstrator.
    public static void sendEmailToCurrentUser() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Email FROM User WHERE Id = :currentUserId LIMIT 1];
        
        // Create a new email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Set the email properties
        email.setToAddresses(new String[] {currentUser.Email});
        email.setSubject('Test Email from Salesforce');
        email.setPlainTextBody('The products are successfully synced with Salesforce, if any failure please check in myob logs.');
        
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
}