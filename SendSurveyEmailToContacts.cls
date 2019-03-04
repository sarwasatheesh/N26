global class SendSurveyEmailToContacts implements Database.Batchable < sobject >{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr;
        Date todayDt = date.today();
        //Query to fetch the contacts whose survey date is today date
        queryStr = 'SELECT FirstName, Id, Email, language__c, survey_date__c From Contact WHERE survey_date__c =: todayDt ';
        return Database.getquerylocator(queryStr);
    }

    global void execute(Database.BatchableContext bc, List <Contact> contactsList) {
        List < Messaging.SingleEmailMessage > emailsList = new List < Messaging.SingleEmailMessage > ();
        List<Contact> updateContactList = new List<Contact>();              
        for(Contact contactRecord : contactsList) {
            contactRecord.survey_date__c = NULL;
            updateContactList.add(contactRecord);

            //Frame the emaill with necessary parameters
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {contactRecord.Email});
            email.setSaveAsActivity(false);

            //if block to update email body based on langauge code. 
            //We can create a email template and refer the same if we will modify the templates frequently                     
            if (contactRecord.language__c == 'de')
                email.setPlainTextBody('Hey  ' + contactRecord.FirstName + ',\n\n' + ' bitte fülle unsere Umfrage aus: http://n26.com/survey/' + contactRecord.Id);
            else          
                email.setPlainTextBody('Hey  ' + contactRecord.FirstName + ',\n\n' + ' please fill out our survey: http://n26.com/survey/' + contactRecord.Id);
            emailsList.add(email);                 
        }
        // If block to reserve the email capacity for current transaction based on the list size
        if (emailsList.size() > 1000)
            Messaging.reserveMassEmailCapacity(1000);
        else
            Messaging.reserveMassEmailCapacity(emailsList.size());

        //Code to update the surveydate filed as null once the email sent successfully
        Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(emailsList);
        String emailErrorReport;
        Boolean errFlag = false;
        for (Messaging.SendEmailResult result : emailResults){
            if(!result.isSuccess()){  // this will return true if Emails not sent successfully.              
                //Code to capture the failed emails                     
                for( Messaging.SendEmailError currentError : result.getErrors() ) {
                    emailErrorReport = emailErrorReport + '(' + currentError.getTargetObjectId() + ',' + currentError.getStatusCode() +','+ currentError.getMessage() +  ') ' + '\r' ;
                }                
                system.debug('emailErrorReport is :: '+emailErrorReport); 
                errFlag = true;              
            }
        }
        if (errFlag == false) update updateContactList;
    }

    global void finish(Database.BatchableContext bc) {}
}