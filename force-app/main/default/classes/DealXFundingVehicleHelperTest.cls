@isTest
public with sharing class DealXFundingVehicleHelperTest {
    @TestSetup
    static void makeData(){
        Account testAcc = Test_Helper.createBrokerAccount();
        Contact testCtc = Test_Helper.createContact(testAcc);
        Opportunity testDeal = Test_Helper.createTermDeal(testAcc, testCtc);
    }

    @isTest
    public static void testAfterUpdate() {
        Opportunity sampleDeal = [SELECT Id FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];
        Securitization__c testSc = Test_Helper.createSecuritization();
        sampleDeal.Securitization__c = testSc.Id;
        
        update sampleDeal;
        
        Deal_x_Funding_Vehicle__c testDealFv = [SELECT Id, Include_Yes_No__c, Deal__c FROM Deal_x_Funding_Vehicle__c ORDER BY CreatedDate DESC LIMIT 1];

        System.assertEquals(true, testDealFv.Include_Yes_No__c, 'Include_Yes_No__c should be true');

        testDealFv.Include_Yes_No__c = false;
        update testDealFv;

        Opportunity returnedDeal = [SELECT Id, Securitization__c, Securitized__c FROM Opportunity WHERE Id = :testDealFv.Deal__c LIMIT 1];

        System.assertEquals(false, returnedDeal.Securitized__c, 'Deal should not be securitized');
        System.assertEquals(null, returnedDeal.Securitization__c, 'Deal should not have a securitization');
    }
}