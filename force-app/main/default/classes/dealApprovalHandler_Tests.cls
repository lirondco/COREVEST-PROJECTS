@isTest(seeAllData=true)
private class dealApprovalHandler_Tests {
  static void setupTestData() {
    Email_Addresses__c BETH = dealApprovalHandler.queryEmailAddress(
      'Beth O\'Brien'
    );
    // Email_Addresses__c RYAN = dealApprovalHandler.queryEmailAddress('Ryan McBride');
    Email_Addresses__c CHRIS = dealApprovalHandler.queryEmailAddress(
      'Chris Hoeffel'
    );
    Email_Addresses__c BRIDGE_LIST = dealApprovalHandler.queryEmailAddress(
      'Bridge Term Sheet Mailing List'
    );
    Email_Addresses__c TERM_LIST = dealApprovalHandler.queryEmailAddress(
      'Term Sheet Mailing List'
    );
    upsert new List<Email_Addresses__c>{ BETH, CHRIS, BRIDGE_LIST, TERM_LIST };
  }

  static testMethod void dealApprovalHandler_Tests_UnitTest() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity deal = test_Helper.createOpportunity(acc, cont);
    Contentversion cv = new Contentversion();
    cv.Title = 'ABC';
    cv.PathOnClient = 'test';
    cv.VersionData = EncodingUtil.base64Decode(
      EncodingUtil.urlEncode('Unit Test Attachment Body', 'UTF-8')
    );
    insert cv;

    // create a new email and envelope object

    Messaging.InboundEmail.Header h = new Messaging.InboundEmail.Header();
    h.Name = 'Test';
    h.Value = '      1   1 2000';
    Messaging.InboundEmail email = new Messaging.InboundEmail();
    email.headers = new List<Messaging.InboundEmail.Header>();
    email.headers.add(h);
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

    // setup the data for the email
    email.subject = 'Create Contact';
    email.fromAddress = 'someaddress@email.com';
    email.plainTextBody = 'email body\n2225256325\nTitle';
    String body = '<wbr>';
    body += '--DEALIDSTART--' + deal.id + '--DEALIDEND--';
    body += '--CONTENTIDSTART--' + cv.Id + '--CONTENTIDEND--';
    body += '--ATTACHMENTIDSTART--' + '' + '--ATTACHMENTIDEND--';
    body += 'CoreVest American Finance Lender LLC. All Rights Reserved.';
    email.htmlBody = body;

    /* add an Binary attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf(test);
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        // add an Text attachment

        Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
        attachmenttext.body = 'my attachment text';
        attachmenttext.fileName = 'textfiletwo3.txt';
        attachmenttext.mimeTypeSubType = 'texttwo/plain';
        email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
        */
    // call the email service class and test it with the data in the testMethod
    dealApprovalHandler cls = new dealApprovalHandler();

    Test.startTest();
    deal = dealApprovalHandler.queryOpportunity(deal.Id);
    email.fromAddress = deal.Owner.email;
    email.toAddresses = new List<String>{ 'test@test.com' };

    cls.handleInboundEmail(email, env);

    dealApprovalHandler.postToChatter(deal, 'test', false);

    Messaging.InboundEmail.TextAttachment t = new Messaging.InboundEmail.TextAttachment();
    t.fileName = 'Test';
    t.mimeTypeSubType = 'Test';
    t.body = 'Test';
    dealApprovalHandler.constructFileAttachment(t);

    Messaging.InboundEmail.BinaryAttachment b = new Messaging.InboundEmail.BinaryAttachment();
    b.fileName = 'Test';
    b.mimeTypeSubType = 'Test';
    b.body = blob.valueOf('Test');
    dealApprovalHandler.constructFileAttachment(b);

    dealApprovalHandler.queryContentVersions(
      new List<Id>{ UserInfo.getUserId() }
    );
    dealApprovalHandler.sendReply(deal.Id, UserInfo.getUserId());
    dealApprovalHandler.createAttachment(email, deal);

    //Code Added by Trivikram : Start
    email.fromAddress = 'beth@cvest.com';
    dealApprovalHandler.performTestCoverageForBETH = true;
    cls.handleInboundEmail(email, env);

    email.fromAddress = 'ryan@cvest.com';
    dealApprovalHandler.performTestCoverageForBETH = false;
    dealApprovalHandler.performTestCoverageForRYAN = true;
    cls.handleInboundEmail(email, env);

    try {
      email.htmlBody = null;
      List<Id> listTestUserid = new List<Id>();
      listTestUserid.add(UserInfo.getUserId());
      dealApprovalHandler.createEmailHistory(
        email,
        deal,
        new List<String>(),
        new List<String>(),
        listTestUserid,
        UserInfo.getUserId(),
        true
      );
    } catch (Exception ex) {
      dealApprovalHandler.sendExceptionEmails(ex);
    }

    //Code Added by Trivikram : End
    Test.stopTest();
  }
}
