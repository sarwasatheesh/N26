public with sharing class FetchContactProductInfo {
    @AuraEnabled
    public static List<PricebookEntry> getContactProductInfo(String caseRecId){        
        Contact contObj = [SELECT Id, Home_Country__c, Product__c FROM Contact WHERE Id IN (SELECT ContactId FROM Case WHERE Id := caseRecId)];
        String prodCode = contObj.Product__c + '%';
        return [select ProductCode, UnitPrice from pricebookentry
          WHERE ProductCode LIKE :prodCode AND Currency := contObj.Home_Country__c] AND UseStandardPrice = false);        
    }
}