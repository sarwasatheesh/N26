global class SendSurveyEmailToContacts implements Database.Batchable <sobject>,Database.Stateful{
    global Integer recordsProcessed = 0; // instance member to retain state across transactions
    global String emailErrorReport; // instance member to track the id, status and message of failed records

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr; //varible to store the query
        Date todayDt = date.today(); // variable to capture the today date 
        //Query to fetch the contacts whose survey date is today date
        queryStr = 'SELECT FirstName, Id, Email, language__c, survey_date__c From Contact WHERE survey_date__c =: todayDt'+(Test.isRunningTest()?' LIMIT 200':'');
        return Database.getquerylocator(queryStr);
    }

    global void execute(Database.BatchableContext bc, List <Contact> contactsList) {
        List <Messaging.SingleEmailMessage> emailsList = new List <Messaging.SingleEmailMessage>(); //list to store all contact emails
        List<Contact> updateContactList = new List<Contact>();     
        Messaging.SendEmailResult[] emailResults;
        for(Contact contactRecord : contactsList) {
            contactRecord.survey_date__c = NULL; //update the survey_date__c as null
            updateContactList.add(contactRecord);

            //Frame the emaill with necessary parameters
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {contactRecord.Email});
            email.setSaveAsActivity(false);

            //if block to update email body based on langauge code. 
            //We can create a email template and refer the same if we will modify the email message frequently                     
            if (contactRecord.language__c == 'de')
                email.setPlainTextBody('Hey  ' + contactRecord.FirstName + ',\n\n' + ' bitte fülle unsere Umfrage aus: http://n26.com/survey/' + contactRecord.Id);
            else          
                email.setPlainTextBody('Hey  ' + contactRecord.FirstName + ',\n\n' + ' please fill out our survey: http://n26.com/survey/' + contactRecord.Id);
            emailsList.add(email);

            // increment the instance member counter
            recordsProcessed = recordsProcessed + 1;       
        }

        // If block to reserve the email capacity for current transaction based on the list size
        if (emailsList.size() > 1000)
            Messaging.reserveMassEmailCapacity(1000);
        else
            Messaging.reserveMassEmailCapacity(emailsList.size());

        //Code to update the surveydate filed as null once the email sent successfully
        if(emailsList.size() > 0 && Test.IsRunningTest() == false){
            emailResults = Messaging.sendEmail(emailsList);
        }
        Boolean errFlag = false;
        for (Messaging.SendEmailResult result : emailResults){
            if(!result.isSuccess()){  // execute if Emails not sent successfully.              
                //Block to capture the failed records id, status and message      
                for( Messaging.SendEmailError currentError : result.getErrors() ) {
                    emailErrorReport = emailErrorReport + '(' + currentError.getTargetObjectId() + ',' + currentError.getStatusCode() +','+ currentError.getMessage() +  ') ' + '\n' ;
                }                
                system.debug('emailErrorReport is :: '+emailErrorReport); 
                errFlag = true;              
            }
        }
        if (errFlag == false) update updateContactList; //Update the contact if email sent successfully
    }

    global void finish(Database.BatchableContext bc) {
        List<User> userList = new List<User>();
        userList = [SELECT Id,Email,IsActive FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = True] ;
        System.debug(recordsProcessed + ' records processed.');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];

        // call utility to send email
        List<String> toAddresses = new List<String>();
        for(User usr : userList)
        {           
            toAddresses.add(usr.Email);
        }  

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);        
        mail.setSubject('Send Survey emaisl to Contacts Batch Status - ' + job.Status);
        mail.setSaveAsActivity(false);
        mail.setPlainTextBody
        ('The batch Apex job completed on  ' + job.CompletedDate + ',\n\n' +
        'Job Status : ' + job.Status + '\n'+
        'Total Job Items processed : ' + job.TotalJobItems + '\n'+
        'Number of Job Items processed : ' + job.JobItemsProcessed + '\n' +
        'Number of Failures : '+ job.NumberOfErrors + '\n\n' + 
        'Id, Status Code, Error Message \n'+emailErrorReport);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });           
    }
}