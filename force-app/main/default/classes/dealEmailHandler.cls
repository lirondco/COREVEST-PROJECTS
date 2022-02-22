global class dealEmailHandler implements Messaging.InboundEmailHandler {
  global Messaging.InboundEmailResult handleInboundEmail(
    Messaging.InboundEmail email,
    Messaging.InboundEnvelope envelope
  ) {
    String subject = email.Subject;
    String parsedSubject = subject.substringAfter('#');
    parsedSubject = parsedSubject.replaceAll('_', ' ');

    while (parsedSubject.startsWith(' ')) {
      parsedSubject = parsedSubject.substringAfter(' ');
    }

    

    String dealLoanNumber = parsedSubject.contains(' ')
      ? parsedSubject.substringBefore(' ')
      : parsedSubject;

    while(!(dealLoanNumber.right(1)).isNumeric()) {
      dealLoanNumber = dealLoanNumber.removeEnd(dealLoanNumber.right(1));
    }

    System.debug(
      subject +
      ' is the subject and loan number is ' +
      dealLoanNumber
    );
    List<Opportunity> dealRecord = [
      SELECT Id
      FROM Opportunity
      WHERE Deal_Loan_Number__c = :dealLoanNumber
      LIMIT 1
    ];

    if (dealRecord.size() > 0) {
      try {
        saveEmailMessage(email, dealRecord[0]);
      } catch (Exception e) {
        sendExceptionEmails(e, subject, email.fromAddress);
        System.debug(
          'Error in handler while sending email message ' +
          e.getMessage() +
          ' on line ' +
          e.getLineNumber()
        );
      }
    } else {
      CalloutException e = new CallOutException();
      e.setMessage('Deal not found for loan number: ' + dealLoanNumber);
      sendExceptionEmails(e, subject, email.fromAddress);
      System.debug(
        'Error in handler and skipped sending email message ' +
        e.getMessage() +
        ' on line ' +
        e.getLineNumber()
      );
    }

    return new Messaging.InboundEmailResult();
  }

  public static void saveEmailMessage(
    Messaging.InboundEmail email,
    Opportunity deal
  ) {
    String subject = email.Subject;

    String fromAddress = email.fromAddress;
    List<String> toAddresses = email.toAddresses != null
      ? email.toAddresses
      : new List<String>();

    if (toAddresses.size() == 0) {
      toAddresses = email.ccAddresses != null
        ? email.ccAddresses
        : new List<String>();
    }

    List<String> ccAddresses = email.ccAddresses != null &&
      email.toAddresses != null
      ? email.ccAddresses
      : new List<String>();

    Id senderId = null;
    List<Id> recipientIds = new List<Id>();
    List<Id> ccRecipientIds = new List<Id>();

    for (User sender : [
      SELECT Id
      FROM User
      WHERE Email = :fromAddress
      LIMIT 1
    ]) {
      senderId = sender.Id;
    }

    for (User recipient : [
      SELECT Id, Email
      FROM User
      WHERE Email IN :toAddresses
    ]) {
      recipientIds.add(recipient.Id);
      if (toAddresses.contains(recipient.Email)) {
        toAddresses.remove(toAddresses.indexOf(recipient.Email));
      }
    }

    if (ccAddresses.size() > 0) {
      for (User ccRecipient : [
        SELECT Id, Email
        FROM User
        WHERE Email IN :ccAddresses
      ]) {
        ccRecipientIds.add(ccRecipient.Id);
        if (ccAddresses.contains(ccRecipient.Email)) {
          ccAddresses.remove(ccAddresses.indexOf(ccRecipient.Email));
        }
      }
    }

    Integer characterLim = subject.length() <= 50 ? subject.length() : 50;
    Integer contentLim = String.isNotEmpty(email.plainTextBody) && email.plainTextBody.length() <= 32768
      ? email.plainTextBody.length()
      : 32768;

    Savepoint sp = Database.setSavepoint();

    try {
      EmailMessage emailMessage = new EmailMessage();
      emailMessage.Status = '3';
      emailMessage.CcAddress = String.join(ccAddresses, ';');
      emailMessage.CcIds = ccRecipientIds;
      emailMessage.FromAddress = fromAddress;
      emailMessage.FromName = email.FromName;

      emailMessage.Subject = subject.substring(0, characterLim);

      System.debug(
        'EMAIL SUBJECT CHARACTER COUNT: ' + emailMessage.Subject.length()
      );

      if (String.isNotEmpty(email.htmlBody)) {
        emailMessage.HtmlBody = email.htmlBody.substring(
          0,
          email.htmlBody.length() <= 32768 ? email.htmlBody.length() : 32768
        );
      }
      emailMessage.MessageDate = System.now();
      if (String.isNotEmpty(email.plainTextBody)) {
        emailMessage.TextBody = email.plainTextBody.substring(0, contentLim);
      }
      emailMessage.RelatedToId = deal.Id;
      emailMessage.ToAddress = String.join(toAddresses, ';');
      emailMessage.ToIds = recipientIds;

      if (Test.isRunningTest()) {
        System.debug('Saving email message');
        System.debug(emailMessage);
      }

      insert emailMessage;

      if (email.textAttachments != null && email.textAttachments.size() > 0) {
        List<Attachment> attachments = new List<Attachment>();
        for (
          Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments
        ) {
          Attachment attachment = new Attachment();

          attachment.Name = tAttachment.fileName;
          attachment.Body = Blob.valueOf(tAttachment.body);
          attachment.ParentId = emailMessage.Id;
          attachments.add(attachment);
        }

        insert attachments;
      }

      Email__c customEmailRecord = new Email__c(
        Deal__c = deal.Id,
        Recipient__c = String.join(toAddresses, ';'),
        CC__c = String.join(ccAddresses, ';'),
        Sender__c = fromAddress,
        Name = 'HTML: ' + subject.substring(0, characterLim),
        ContentVersionId__c = 'None',
        Contents__c = String.isNotEmpty(email.plainTextBody) ? email.plainTextBody.substring(0, contentLim) : ''
      );

      if (
        email.binaryAttachments != null &&
        email.binaryAttachments.size() > 0
      ) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (
          Messaging.InboundEmail.binaryAttachment binAttach : email.binaryAttachments
        ) {
          ContentVersion cv = new ContentVersion();
          cv.VersionData = binAttach.body;
          cv.Title = binAttach.fileName;
          cv.PathOnClient = binAttach.fileName;

          contentVersions.add(cv);
        }

        insert contentVersions;

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

        String cvIdString = '';

        for (ContentVersion cv : [
          SELECT Id, ContentDocumentId
          FROM ContentVersion
          WHERE Id IN :contentVersions
        ]) {
          ContentDocumentLink cdl = new ContentDocumentLink();
          cdl.LinkedEntityId = emailMessage.Id;
          cdl.ContentDocumentId = cv.ContentDocumentId;
          cdl.ShareType = 'V';
          cdlList.add(cdl);
          cvIdString += cv.Id + ';';
        }

        cvIdString = cvIdString.removeEnd(';');
        if(cvIdString.length() > 255) {
          cvIdString = cvIdString.substring(0, 230) + ' [...]';
        }

        customEmailRecord.ContentVersionId__c = cvIdString;

        insert cdlList;
      }

      insert customEmailRecord;

      Map<String, Map<String, List<String>>> emailRelationsMap = new Map<String, Map<String, List<String>>>{
        'ToAddress' => new Map<String, List<String>>{
          'relationAddresses' => toAddresses,
          'relationIds' => (List<String>) recipientIds
        },
        'CcAddress' => new Map<String, List<String>>{
          'relationAddresses' => ccAddresses,
          'relationIds' => (List<String>) ccRecipientIds
        },
        'FromAddress' => new Map<String, List<String>>{
          'relationAddresses' => senderId != null
            ? new List<String>()
            : new List<String>{ fromAddress },
          'relationIds' => new List<String>{
            senderId != null ? String.valueOf(senderId) : 'none'
          }
        }
      };

      for (String relationType : emailRelationsMap.keySet()) {
        List<String> relationAddresses = emailRelationsMap.get(relationType)
          .get('relationAddresses');

        List<String> relationIds = !emailRelationsMap.get(relationType)
            .get('relationIds')
            .contains('none')
          ? (List<Id>) emailRelationsMap.get(relationType).get('relationIds')
          : new List<Id>();

        createEmailMessageRelations(
          emailMessage.Id,
          relationAddresses,
          relationIds,
          relationType
        );
      }
    } catch (Exception e) {
      Database.rollback(sp);
      System.debug(
        'Error saving email message ' +
        e.getMessage() +
        ' at ' +
        e.getLineNumber()
      );
      throw e;
    }
  }

  public static void createEmailMessageRelations(
    Id messageId,
    List<String> relationAddresses,
    List<Id> relationIds,
    String relationType
  ) {
    List<EmailMessageRelation> emailMessageRelations = new List<EmailMessageRelation>();

    for (String ra : relationAddresses) {
      EmailMessageRelation externalEmr = new EmailMessageRelation();
      externalEmr.EmailMessageId = messageId;
      externalEmr.RelationAddress = ra;
      externalEmr.RelationType = relationType;
      emailMessageRelations.add(externalEmr);
    }

    for (Id ri : relationIds) {
      EmailMessageRelation internalEmr = new EmailMessageRelation();
      internalEmr.EmailMessageId = messageId;
      internalEmr.RelationId = ri;
      internalEmr.RelationType = relationType;
      emailMessageRelations.add(internalEmr);
    }

    insert emailMessageRelations;
  }

  public static void sendExceptionEmails(
    Exception ex,
    String subject,
    String senderAddress
  ) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    email.setToAddresses(
      new List<String>{
        'logins+cvest@mkpartners.com',
        'bryon.harland@cvest.com',
        'jonathan.lay@cvest.com'
      }
    );

    String body = '';
    body += 'Line Number: ' + ex.getLineNumber();
    body += '\nStacktrace: ' + ex.getStackTraceString();
    body += '\nType: ' + ex.getTypeName();
    body += '\nMessage:  ' + ex.getMessage();
    body += '\nSubject: ' + subject;
    body += '\nSender: ' + senderAddress;
    email.setPlainTextbody(body);
    email.setSubject('Deal Approval Handler Error');

    Messaging.sendEmail(new List<Messaging.SIngleEmailMessage>{ email });
  }
}