@isTest
public with sharing class IcRejectionLinkControllerTest {
  @TestSetup
  static void makeData() {
    Test_Helper.setupProduct2();
    Account testAcc = Test_Helper.createBorrowerAccount();
    Contact testCtc = Test_Helper.createBorContact(testAcc);
    Opportunity testDeal = Test_Helper.createTermDeal(testAcc, testCtc);
    Opportunity testBridge = Test_Helper.createBridgeDeal(testAcc, testCtc);
    testDeal.StageName = 'Underwriting';
    testBridge.StageName = 'Underwriting';
    testBridge.Final_Sponsor_Tier__c = 'Tier 1';
    update new List<Opportunity>{testDeal, testBridge};
    Approval.ProcessSubmitRequest testAppr = new Approval.ProcessSubmitRequest();
    testAppr.setObjectId(testDeal.Id);
    testAppr.setProcessDefinitionNameOrId('Term_IC_Approval');
    Approval.ProcessResult result = Approval.process(testAppr);
    List<Id> newWorkItemIds = result.getNewWorkitemIds();
    for (Id w : newWorkItemIds) {
      Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
      req2.setComments('Approving request.');
      req2.setAction('Approve');
      req2.setWorkitemId(w);
      Approval.ProcessResult result2 = Approval.process(req2);
    }

    Approval.ProcessSubmitRequest testAppr2 = new Approval.ProcessSubmitRequest();
    testAppr2.setObjectId(testBridge.Id);
    testAppr2.setProcessDefinitionNameOrId('Bridge_IC_Approval');
    Approval.ProcessResult res = Approval.process(testAppr2);
    List<Id> newWorkItemIds2 = res.getNewWorkitemIds();
    for (Id w : newWorkItemIds2) {
      Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
      req2.setComments('Approving request.');
      req2.setAction('Approve');
      req2.setWorkitemId(w);
      Approval.ProcessResult result2 = Approval.process(req2);
    }
  }

  @isTest
  private static void testTermRejection() {
    Opportunity testDeal = [
      SELECT Id, IC_Approval__c
      FROM Opportunity
      WHERE Record_Type_Name__c LIKE '%Term%'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    System.assertEquals(
      'Approved',
      testDeal.IC_Approval__c,
      'IC Approval should be Approved'
    );
    PageReference pageRef = Page.IcRejectionLinkVf;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('id', testDeal.Id);


    IcRejectionLinkController controller = new IcRejectionLinkController();

    IcRejectionLinkController.rejectDeal();

    List<Opportunity> updatedDeal = [
      SELECT Id, IC_Approval__c
      FROM Opportunity
      WHERE Id = :testDeal.Id
      LIMIT 1
    ];

    System.assertEquals(
      null,
      updatedDeal[0].Ic_Approval__c,
      'Deal should not be in approved state.'
    );
  }

  @isTest
  private static void testBridgeRejection() {
    Opportunity testDeal = [
      SELECT Id, IC_Approval__c
      FROM Opportunity
      WHERE Record_Type_Name__c LIKE '%LOC%'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    System.assertEquals(
      'Approved',
      testDeal.IC_Approval__c,
      'IC Approval should be Approved'
    );
    PageReference pageRef = Page.IcRejectionLinkVf;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('id', testDeal.Id);


    IcRejectionLinkController controller = new IcRejectionLinkController();

    IcRejectionLinkController.rejectDeal();

    List<Opportunity> updatedDeal = [
      SELECT Id, IC_Approval__c
      FROM Opportunity
      WHERE Id = :testDeal.Id
      LIMIT 1
    ];

    System.assertEquals(
      null,
      updatedDeal[0].Ic_Approval__c,
      'Deal should not be in approved state.'
    );
  }
}