@isTest
public class SendSurveyEmailToContactsBatchTest {
    @testSetup 
    static void setup() {        
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        // insert 20 accounts
        for (Integer i=0;i<20;i++) {
            accounts.add(new Account(name='Account'+i,billingcity='Munich', billingcountry='Germany'));
        }
        insert accounts;
        // find the account just inserted. add contact for each
        for (Account account : [select id from account]) {
            for (Integer i=0;i<20;i++) {
            contacts.add(new Contact(firstname='first'+i, 
                lastname='last'+i,
                email = 'first'+i+'.'+'last'+i+'@gmail.com',
                accountId=account.id, 
                language__c = 'de', 
                survey_date__c = System.today()));
            }
        }
        insert contacts;
    }

    static testMethod void testSurveyBatchMethod(){
        User userId = [Select id from User where Id = :UserInfo.getUserId()];
        System.runAs(userId)
        {
            Test.startTest();
            SendSurveyEmailToContacts surveyEmail2Con = new SendSurveyEmailToContacts();
            Id batchId = Database.executeBatch(surveyEmail2Con);            
            Test.stopTest();
            
            // after the testing stops, assert records were updated properly
            //System.assertEquals(20, [select count() from account where billingcity = 'Munich']);    
        }
    }
}