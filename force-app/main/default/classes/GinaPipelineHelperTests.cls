@isTest
public with sharing class GinaPipelineHelperTests {
  @TestSetup
  static void makeData() {
    Account a = Test_Helper.createAccount();
    Contact c = Test_Helper.createContact(a);
    Opportunity d = Test_Helper.createBridgeDeal(a, c);
    List<Property__c> props = Test_Helper.createProperties(d);
    Advance__c adv = new Advance__c(
      Deal__c = d.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;
    adv.Target_Advance_Date__c = System.today().addDays(4);
    update adv;

    Id recTypeId = [
      SELECT Id
      FROM RecordType
      WHERE SobjectType = 'Property__c' AND DeveloperName = 'Bridge_Renovation'
      LIMIT 1
    ]
    .Id;

    for (Property__c p : props) {
      p.Initial_Advance__c = adv.Id;
      p.Status__c = 'Closing';
      p.recordTypeId = recTypeId;
    }
    update props;
  }

  @isTest
  public static void testPipeline() {
    GinaPipelineHelper.retrieveAllData();
  }
}
