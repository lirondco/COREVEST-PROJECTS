@isTest
public with sharing class securitizationHelperTest {
  @isTest
  public static void testMethod1() {
    Account testAcc = Test_Helper.createBrokerAccount();
    Contact testCtc = Test_Helper.createContact(testAcc);
    Opportunity testDeal = Test_Helper.createTermDeal(testAcc, testCtc);
    


    Securitization__c testSc = Test_Helper.createSecuritization();

    Funding_Vehicle__c testFv = [
      SELECT Id,Securitization__c
      FROM Funding_Vehicle__c
      WHERE Securitization__c = :testSc.Id
    ];

    testSc.Close_Date__c = (Date) system.today();

    update testSc;

    Deal_x_Funding_Vehicle__c newDxfv = new Deal_x_Funding_Vehicle__c();
    newDxfv.Include_Yes_No__c = true;
    newDxfv.Deal__c = testDeal.Id;
    newDxfv.Funding_Vehicle__c = testFv.Id;
    newDxfv.Start_Date__c = testSc.Close_Date__c;
    
    insert newDxfv;

    System.assertEquals(testFv.Securitization__c, testSc.Id, 'Funding_Vehicle__c.Securitization__c should be equal to Securitization__c');

    

    testDeal.Securitization__c = testSc.Id;

    update testDeal;

    Opportunity returnedDeal = [
      SELECT Securitization__c, Securitized__c
      FROM Opportunity
      WHERE Id = :testDeal.Id
      LIMIT 1
    ];

    System.assertEquals(returnedDeal.Securitization__c, testSc.Id, 'Deal should have securitization');

    List<Deal_x_Funding_Vehicle__c> dfvs = [
      SELECT
        Id,
        End_Date__c,
        Deal__c,
        Deal__r.Warehouse_Line__c,
        Funding_Vehicle__r.Securitization__c
      FROM Deal_x_Funding_Vehicle__c
      WHERE Funding_Vehicle__r.Securitization__c = :testSc.Id
    ];
    
    testSc.Status__c = 'Redeemed';
    testSc.Redemption_Date__c = System.today();
    update testSc;
    // System.assertEquals(true, dfvs.size() > 0, 'A connection record should have been created');

    
  }
}