@isTest
private class PricingReviewRequest_Tests {
  @isTest(SeeAllData=true)
  static void PricingReviewRequest_UnitTest() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);

    Test.startTest();
    PricingReviewRequest_LightningController.validateRecord(opp.Id);
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;

    update opp;
    PricingReviewRequest_LightningController.startApproval(
      opp.Id,
      'Opportunity',
      'comments',
      'Test Resolution',
      'LOC_Loan'
    );

    Test.stopTest();
  }

  @isTest(SeeAllData=true)
  static void PricingReviewRequest_UnitTest2() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    Test.startTest();
    PricingReviewRequest_LightningController.startApproval(
      opp.Id,
      'Opportunity',
      'comments',
      'Test Resolution',
      'Term_Loan'
    );
    PricingReviewRequest_LightningController.sendRepricingEmail(opp.Id);
    Test.stopTest();
  }
}