@isTest
private class IcApprovalHandlerTest {
  static testMethod void IcApprovalHandlerTest_UnitTest() {
    Test_helper.setupProduct2();
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity deal = test_Helper.createOpportunity(acc, cont);
    Contentversion cv = new Contentversion();
    cv.Title = 'test.pdf';
    cv.PathOnClient = 'test.pdf';
    cv.VersionData = EncodingUtil.base64Decode(
      EncodingUtil.urlEncode('Unit Test Attachment Body', 'UTF-8')
    );
    insert cv;
    Id docId = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ]
    .ContentDocumentId;
    Deal_Document__c doc = new Deal_Document__c(
      Deal__c = deal.Id,
      Document_Type__c = 'Draft IC Memo',
      ContentVersion_Id__c =cv.Id,
      Attachment_Id__c = docId,
      File_Name__c = 'test.pdf'
    );

    insert doc;
    Messaging.InboundEmail.Header h = new Messaging.InboundEmail.Header();
    h.Name = 'Test';
    h.Value = '      1   1 2000';
    Messaging.InboundEmail email = new Messaging.InboundEmail();
    email.headers = new List<Messaging.InboundEmail.Header>();
    email.headers.add(h);
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

    email.subject = 'Create Contact';
    email.fromAddress = 'somefakeaddress@email.com.ua';
    email.plainTextBody = 'email body\n2225256325\nTitle';
    String body = '<wbr>';
    body += '--DEALIDSTART--' + deal.id + '--DEALIDEND--';
    body += '--CONTENTIDSTART--' + cv.Id + '--CONTENTIDEND--';
    body += 'CoreVest American Finance Lender LLC. All Rights Reserved.';
    email.htmlBody = body;

    Test.startTest();
    email.toAddresses = new List<String>{ 'test@test.com' };
    Approval_History__c appHis = new Approval_History__c(
        ProcessName__c='Bridge IC Process',
        Approval_Type__c='IC Memo',
        Status__c='Submitted',
        Deal__c = deal.Id
    );
    insert appHis;
    icApprovalHandler cls = new icApprovalHandler();
    cls.handleInboundEmail(email, env);
    icApprovalHandler.postToChatter(deal, 'test');

    Messaging.InboundEmail.TextAttachment t = new Messaging.InboundEmail.TextAttachment();
    t.fileName = 'Test';
    t.mimeTypeSubType = 'Test';
    t.body = 'Test';
    icApprovalHandler.constructFileAttachment(t);

    Messaging.InboundEmail.BinaryAttachment b = new Messaging.InboundEmail.BinaryAttachment();
    b.fileName = 'Test';
    b.mimeTypeSubType = 'Test';
    b.body = blob.valueOf('Test');
    icApprovalHandler.constructFileAttachment(b);

    icApprovalHandler.queryContentVersions(
      new List<Id>{ UserInfo.getUserId() }
    );
    icApprovalHandler.sendReply(deal.Id, UserInfo.getUserId());
    icApprovalHandler.createAttachment(email, deal);


    email.fromAddress = 'fakeFromAddress@fakeDomain.com.ua';
    cls.handleInboundEmail(email, env);

    List<Id> listTestUserid = new List<Id>();
    listTestUserid.add(UserInfo.getUserId());
    
    icApprovalHandler.createEmailHistory(
      email,
      deal,
      new List<String>{UserInfo.getUserEmail()},
      new List<String>{UserInfo.getUserEmail()},
      listTestUserid,
      UserInfo.getUserId(),
      true
    );

    icApprovalHandler.approveDeal(UserInfo.getUserId(), deal);
    Test.stopTest();
  }
}