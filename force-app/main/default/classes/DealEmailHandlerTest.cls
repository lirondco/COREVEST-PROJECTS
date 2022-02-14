@isTest
public without sharing class DealEmailHandlerTest {
  @isTest
  public static void DealEmailHandlertest_UnitTest() {
    Account acc = Test_Helper.createAccount();
    Contact cont = Test_Helper.createContact(acc);
    Opportunity o = new Opportunity();
    o.Name = 'test';
    o.CloseDate = System.today();
    o.StageName = 'Initial Review';
    o.Loan_Size__c = 2000000;
    o.AccountId = acc.Id;
    o.Contact__c = cont.Id;
    o.Deal_Intro_Source__c = 'Hotline';
    o.Deal_Intro_Sub_Source__c = 'Main';
    o.Apex_Context__c = true;
    o.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Term_Loan'
    ]
    .Id;
    insert o;

    Opportunity dealWithLN = [
      SELECT Deal_Loan_Number__c
      FROM Opportunity
      WHERE Id = :o.id
      LIMIT 1
    ];

    System.debug(dealWithLN);

    String dealLoanNumber = dealWithLN.Deal_Loan_Number__c;

    Messaging.InboundEmail.Header h = new Messaging.InboundEmail.Header();
    h.Name = 'Test';
    h.Value = '      1   1 2000';
    Messaging.InboundEmail email = new Messaging.InboundEmail();
    email.headers = new List<Messaging.InboundEmail.Header>();
    email.headers.add(h);
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

    String subject = '#      ' + dealLoanNumber + '/+-$#%^ALCMD';

    for(Integer i = 1; i < 81; i++) {
      subject += ' Long Subject + ' + i;
    }

    email.subject = subject.substring(0, 80);
    email.fromAddress = UserInfo.getUserEmail();
    email.plainTextBody = 'email body\n2225256325\nTitle';
    String body = '<p>testHtmlBody</p>';
    email.htmlBody = body;

    email.toAddresses = new List<String>{ 'test@test.com' };

    Messaging.InboundEmail.BinaryAttachment mefa = new Messaging.InboundEmail.BinaryAttachment();
   
    mefa.Body= Blob.valueOf('test');
    mefa.mimeTypeSubType = 'application/pdf';
    mefa.fileName = 'Test.pdf';

    email.binaryAttachments = new List<Messaging.inboundEmail.BinaryAttachment> {mefa};


    dealEmailHandler cls = new dealEmailHandler();

    Test.startTest();
    cls.handleInboundEmail(email, env);
    Test.stopTest();

    List<EmailMessage> createdEmailMessage = [
      SELECT RelatedToId
      FROM EmailMessage
      WHERE RelatedToId = :o.Id
    ];

    System.assertEquals(
      true,
      createdEmailMessage.size() > 0,
      'email message should be created'
    );
  }

  @isTest
  public static void forceErrorTest() {
    Messaging.InboundEmail.Header h = new Messaging.InboundEmail.Header();
    h.Name = 'Test';
    h.Value = '      1   1 2000';
    Messaging.InboundEmail email = new Messaging.InboundEmail();
    email.headers = new List<Messaging.InboundEmail.Header>();
    email.headers.add(h);
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

    email.subject = '#1234';
    email.fromAddress = UserInfo.getUserEmail();
    email.plainTextBody = 'email body\n2225256325\nTitle';
    String body = '<p>testHtmlBody</p>';
    email.htmlBody = body;

    email.toAddresses = new List<String>{ 'test@test.com' };

    Messaging.InboundEmail.BinaryAttachment mefa = new Messaging.InboundEmail.BinaryAttachment();
   
    mefa.Body= Blob.valueOf('test');
    mefa.mimeTypeSubType = 'application/pdf';
    mefa.fileName = 'Test.pdf';

    email.binaryAttachments = new List<Messaging.inboundEmail.BinaryAttachment> {mefa};


    dealEmailHandler cls = new dealEmailHandler();

    Test.startTest();
    cls.handleInboundEmail(email, env);
    Test.stopTest();
  }
}