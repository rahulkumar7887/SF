global class AccountCleanBatch implements Database.Batchable<Sobject>, Database.Stateful {
	List<AccountCleanBatchException> lstAccountCleanBatchException = new List<AccountCleanBatchException>();
    List<Error_Log__c> lstErrorLog = new List<Error_Log__c>();
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        //Batch size from Custom Settings
        Batch_Size__c objBatchSize = Batch_Size__c.getInstance('AccountCleanBatch');
        Integer defaultBatchSize = objBatchSize != null ? (Integer) objBatchSize.Batch_Size__c : 50000;
        
        String query = 'Select Id From Account Limit' + ' ' + defaultBatchSize;
        //String qry = Select Id, Name from Account Where Name Like '%test%'';
        //return Database.getQueryLocator([Select Id, Name from Account Where Name Like '%test%']);
        System.debug('#Query' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope){
        System.debug('##scope' + scope);
        List<Account> lstAccountsToDelete = scope;
        if(!lstAccountsToDelete.isEmpty()){
            Database.DeleteResult[] deleteResult = Database.delete(lstAccountsToDelete, false);
            for(Integer i = 0; i < deleteResult.size(); i++){
                Database.DeleteResult deleteResultInstance = deleteResult[i];
                if(!deleteResultInstance.isSuccess()){
                    for(Database.Error err : deleteResultInstance.getErrors()) {
                        //Add error to Database
                        Error_Log__c errorLog = new Error_Log__c();
                        errorLog.Record_Id__c = lstAccountsToDelete[i].Id;
                        errorLog.Module__c = 'Account Delete';
                        errorLog.Message__c = err.getMessage().left(200);
                        lstErrorLog.add(errorLog);      
                    }
                    //Add the error to exception list
                    lstAccountCleanBatchException.add(new AccountCleanBatchException(deleteResult[i].getId(), deleteResult[i].getErrors()));
                }
            }                        
        }
        
        //Inserts all errors into database
        if(!lstErrorLog.isEmpty()){
            insert lstErrorLog;
        }
        
        //System.debug('##mapErrors' + mapErrors);
        System.debug('##lstAccountCleanBatchException' + lstAccountCleanBatchException);
    }
    
    global void finish(Database.BatchableContext bc){
        sendMailInTableForm();
	}
    
    private void sendMailInTableForm() {

        // Step 1: Create a new Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Step 2: Set list of people who should get the email
        List<String> sendTo = new List<String>();
        sendTo.add('rahul.kumar9@cognizant.com');
        
        //Get emailIds from Custom setting
        //Batch_Status_Notification__c objBatchStatusNotification = Batch_Status_Notification__c.getInstance('Batch Recipient');
        //sendTo.add(objBatchStatusNotification.Recipient_Email__c);
        
        //Class
        //sendTo = BatchStatusNotification.getBatchNotificationRecipients('Batch');
        
        if(!sendTo.isEmpty()) {
            mail.setToAddresses(sendTo);
        }

        // Step 3: Set who the email is sent from
        mail.setReplyTo(UserInfo.getUserEmail());
        mail.setSenderDisplayName('Account Clean Batch');

        // Step 4. Set email contents - you can use variables!
        mail.setSubject('Account Clean Batch Status');

        String body = '';
        body = '<html>';
        body += '<body>';
        if(!lstAccountCleanBatchException.isEmpty()){
            body += '<table border = 1>';
            body += '<tr>';
            body += '<th>' + 'Accounts' + '</th>';
            body += '<th>' + 'Failure Messages' + '</th>';
            body += '</tr>';
            System.debug('---this.lstExceptions------>'+ lstAccountCleanBatchException);
            for (AccountCleanBatchException excp : lstAccountCleanBatchException) {
                System.debug('---excp------>'+excp);
                body += '<tr>';
                if(excp.recordId != null){
                    //if (this.mapImpactedUKProducts.containsKey(excp.recordId) && this.mapImpactedUKProducts.get(excp.recordId).Name != null) {
                       //body += '<td rowspan=\'' + excp.lstErrors.size() + '\'><a href=' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + excp.recordId + '>' + this.mapImpactedUKProducts.get(excp.recordId).Name + '</a></td>';
                    //} else {
                        body += '<td rowspan=\'' + excp.lstErrors.size() + '\'><a href=' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + excp.recordId + '>' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + excp.recordId + '</a></td>';
                    //}
                }else{
                    body +='<td></td>';
                } 
                if(!excp.lstErrors.isEmpty()){
                body += '<td>' + excp.lstErrors[0] + '</td>';}
                body += '</tr>';
                if (excp.lstErrors.size() > 1) {
                   body += '<tr>';
                   for (Integer i = 1; i < excp.lstErrors.size(); i++) {
                        body += '<td>' + excp.lstErrors[i] + '</td>';
                   }
                   body += '</tr>';
                } 
            }
            body += '<table>';
        } else {
            body +='All records processed successfully';
        }
        body += '</body>';
        body += '</html>';
        mail.setHtmlBody(body);

        // Step 6: Send all emails in the master list
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
    
    /*
    public void sendMail(){
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        String[] toadd = new String[]{'rahul.kumar9@cognizant.com'};
        mail.setToAddresses(toadd);
        mail.setSubject('Batch Status');
        mail.setPlainTextBody('Status of the Batch Class: Batch_AccountClean');
        mail.setHtmlBody('' + mapErrors);
        Messaging.sendEmail(new Messaging.singleEmailMessage[]{mail});
    }*/
    
    public class AccountCleanBatchException extends Exception{
        Id recordId;
        List<Database.Error> lstErrors;
        //List<String> lstErrors;
        
        public AccountCleanBatchException(Id recordId, List<Database.Error> lstError){
            this.recordId = recordId;
            this.lstErrors = lstErrors;
        }
    }
}