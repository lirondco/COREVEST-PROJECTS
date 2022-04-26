@isTest
public with sharing class AdvanceClearToFundControllerTest {
    @isTest(seeAllData = true)
    public static void testInit() {
        Advance__c adv = [
            SELECT Id FROM Advance__c WHERE Deal__r.Record_Type_Name__c = 'Single_Asset_Bridge_Loan' ORDER BY CreatedDate DESC LIMIT 1 
        ];
        AdvanceClearToFundController.init(adv.Id);
    }
}
