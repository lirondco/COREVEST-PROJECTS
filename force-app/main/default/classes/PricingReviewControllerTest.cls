@isTest
public with sharing class PricingReviewControllerTest {
  @isTest
  public static void testMethod1() {
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
    PricingReviewController controller = new PricingReviewController();
    controller.recId = opp.Id;
    ProcessInstanceStep approval = controller.ApprovalProcess;
    String comments = controller.approvalComments;
    String approvalUrl = controller.approvalUrl;
    String dealUrl = controller.dealUrl;
    Integer count = controller.repriceCount;
    Test.stopTest();
    System.assertEquals(true, approval != null, 'Approval Process is null');
    System.assertEquals(approval.Comments, comments, 'Comments');
    System.assertEquals(true, String.isNotEmpty(approvalUrl), 'Approval Url');
    System.assertEquals(true, String.isNotEmpty(dealUrl), 'Deal Url');
  }
}
