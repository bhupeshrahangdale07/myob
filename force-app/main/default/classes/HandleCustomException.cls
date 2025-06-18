public without sharing class HandleCustomException extends Exception{
    public static void LogException(Exception e){
        try{
            system.debug('enter in exception class');
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.'); 
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
            Set<String> stringHelper = new Set<String>{className,methodName};
            String joinedString = String.join(new List<String>(stringHelper), '.');
            //Governer Limit of executingQuery 
            String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String dmLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String dmlStat = '3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String cPUT = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
            
            //Log information in object
            KTMYOB__MYOB_Log__c exc = new KTMYOB__MYOB_Log__c();
            exc.KTMYOB__Govt_Limit_in_Executing_Code__c = String.format('{0}\n{1}\n{2}\n{3}',new List<string>{queryLimit, dmLimit,dmlStat,cPUT});
            exc.KTMYOB__Error_Message__c = e.getMessage();
            exc.KTMYOB__Exception_Type__c = e.getTypeName();
            exc.KTMYOB__Line_Number__c = String.valueOf(e.getLineNumber());
            exc.KTMYOB__StackTrace__c = e.getStackTraceString();
            if(joinedString != null){
                exc.KTMYOB__Helper__c=joinedString;
            }
            //exc.ClassName__c=className;

            if(Schema.sObjectType.KTMYOB__MYOB_Log__c.isCreateable()){
                // database.insert(exc);
                Insert exc; 
            }
            system.debug('exc = '+exc);
        }catch(Exception ex){
            //HandleCustomException.LogException(e);
            System.debug('Exception-->'+ex);
        }            
    }
}