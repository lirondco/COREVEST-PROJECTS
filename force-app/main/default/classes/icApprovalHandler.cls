global class icApprovalHandler implements Messaging.InboundEmailHandler {
  static final String EMAIL_SERVICE_APINAME = 'icApprovalHandler';
  static final String HANDLERADDRESS = retrieveHandlerEmailAddress();
  

  public static Boolean ISSANDBOX = false;

  static final List<String> VALID_RECORDTYPES = new List<String>{
    'LOC_LOAN',
    'TERM_LOAN'
  };

  static final List<String> TWO_OF_THREE_APPROVALS = new List<String>{
    'LOC_LOAN'
  };

  static final String SANDBOX_EMAIL = 'ldecastro@mkpartners.com';
  

  public static final Map<String, Map<Id, User>> USERINFOMAP = new Map<String, Map<Id, User>>{
    'Bridge IC Process' => queryUserInfo('Bridge_IC_Approval'),
    'Term Sub-IC Process' => queryUserInfo('Term_Sub_IC'),
    'Term IC Process' => queryUserInfo('Term_IC_Approval'),
    'Bridge Sub-IC Process' => queryUserInfo('Term_Sub_IC')
  };

  public static final Set<String> BRIDGE_IC_GROUP = queryEmailAddresses(
    'Bridge_IC_Approval'
  );
  public static final Set<String> TERM_SUB_IC_GROUP = queryEmailAddresses(
    'Term_Sub_IC'
  );
  public static final Set<String> TERM_IC_GROUP = queryEmailAddresses(
    'Term_IC_Approval'
  );
  public static final Set<String> BRIDGE_SUB_IC_GROUP = queryEmailAddresses(
    'Term_Sub_IC'
  );

  public static final Set<String> ICDOCTYPES = new Set<String>{
    'Draft IC Memo',
    'Bridge Committee Memo',
    'Committee Memo'
  };

  public static String retrieveHandlerEmailAddress() {
    String handlerAddress = '';

    List<EmailServicesAddress> esas = [
      SELECT Id, LocalPart, EmailDomainName, DeveloperName
      FROM EmailServicesAddress
      WHERE DeveloperName = :EMAIL_SERVICE_APINAME
    ];

    if (esas.size() > 0) {
      handlerAddress = esas[0].LocalPart + '@' + esas[0].EmailDomainName;
    }

    return handlerAddress;
  }

  public static Set<String> queryEmailAddresses(String name) {
    Set<String> emailAdds = new Set<String>();
    Set<Id> userIds = new Set<Id>();
    Group gp = [
      SELECT (SELECT UserOrGroupId FROM GroupMembers)
      FROM Group
      WHERE DeveloperName = :name
    ];
    for (GroupMember gm : gp.GroupMembers) {
      userIds.add(gm.UserOrGroupId);
    }
    List<User> userList = [SELECT Email FROM User WHERE Id IN :userIds];
    for (User u : userList) {
      emailAdds.add(u.Email);
    }
    return emailAdds;
  }

  public static Map<Id, User> queryUserInfo(String name) {
    List<Id> userIds = new List<Id>();
    Group gp = [
      SELECT DeveloperName, (SELECT UserOrGroupId FROM GroupMembers)
      FROM Group
      WHERE DeveloperName = :name
    ];

    for (GroupMember gm : gp.GroupMembers) {
      userIds.add(gm.UserOrGroupId);
    }

    if (Test.isRunningTest()) {
      userIds.add(UserInfo.getUserId());
    }

    Map<Id, User> userMap = new Map<Id, User>(
      [
        SELECT Id, Email, Approver_Code__c, Department, Name
        FROM User
        WHERE Id IN :userIds
      ]
    );

    List<String> names = new List<String>();
    if (userMap.size() > 0) {
      for (Id key : userMap.keySet()) {
        String name2 = userMap.get(key).Name;
        if (name2.substring(0, 5) == 'Chris') {
          name2 = 'Chris Hoeffel';
        }
        names.add(name2);
      }
    }

    if (names.size() > 0 && userMap.size() > 0) {
      Map<String, Email_Addresses__c> settings = querySettings(names);

      if (settings.size() > 0) {
        for (Id key : userMap.keySet()) {
          User userInfo = userMap.get(key);
          String name3 = userInfo.Name;
          if (name3.substring(0, 5) == 'Chris') {
            name3 = 'Chris Hoeffel';
          }
          if (String.isNotEmpty(settings.get(name3).Email_Address__c)) {
            userInfo.Email = settings.get(name3).Email_Address__c;
          }
          if (String.isNotEmpty(settings.get(name3).Approver_Code__c)) {
            userInfo.Approver_Code__c = settings.get(name3)
              .Approver_Code__c.toLowerCase();
          }
          userMap.put(key, userInfo);
        }
      }

      return userMap;
    } else {
      return new Map<Id, User>();
    }
  }

  public static Map<String, Email_Addresses__c> querySettings(
    List<String> names
  ) {
    Map<String, Email_Addresses__c> allSettings = new Map<String, Email_Addresses__c>();
    for (String name : names) {
      Email_Addresses__c setting = Email_Addresses__c.getInstance(name);
      if (setting == null || setting.id == null) {
        setting = new Email_Addresses__c(
          Name = name,
          Email_Address__c = '',
          Approver_Code__c = ''
        );
        if (Test.isRunningTest()) {
          setting.Email_Address__c = UserInfo.getUserEmail();
          setting.Approver_Code__c = 'test';
          allSettings.put(name, setting);
        }
      }
      if (ISSANDBOX) {
        setting.Email_Address__c = SANDBOX_EMAIL;
      }
      allSettings.put(name, setting);
    }
    System.debug(alLSettings);
    return allSettings;
  }

  static Map<String, Integer> dateMap = new Map<String, Integer>{
    'Jan' => 1,
    'Feb' => 2,
    'Mar' => 3,
    'Apr' => 4,
    'May' => 5,
    'Jun' => 6,
    'Jul' => 7,
    'Aug' => 8,
    'Sep' => 9,
    'Oct' => 10,
    'Nov' => 11,
    'Dec' => 12
  };

  public static void postToChatter(String actionVerb, Opportunity deal, String subjectId) {
    System.debug('postToChatter has been hit');
    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = deal.OwnerId; // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ' ' + deal.Name + ' has been ' + actionVerb + '.';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    input.subjectId = subjectId;
    if (!Test.isRunningTest()) {
      ConnectApi.FeedElement fi = ConnectApi.ChatterFeeds.postFeedElement(
        Network.getNetworkId(),
        input
      );
    }
  }

  //
  global Messaging.InboundEmailResult handleInboundEmail(
    Messaging.InboundEmail email,
    Messaging.InboundEnvelope envelope
  ) {
    System.debug('received email');

    Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

    String opportunityId;
    String fromAddress = email.fromAddress;

    Set<String> alreadySentTo = new Set<String>();
    Set<String> setEmails = new Set<String>();
    Set<String> approverEmails = new Set<String>();

    if (null != email.toAddresses && email.toAddresses.size() > 0) {
      for (String e : email.toAddresses) {
        alreadySentTo.add(e);
      }
    }

    String htmlBody = '';
    String originalBody = '';

    if (String.isEmpty(email.htmlBody)) {
      htmlBody = email.plainTextBody;
      originalBody = email.plainTextBody;
    } else {
      htmlBody = email.htmlBody;
      originalBody = email.htmlBody;
    }

    htmlBody = htmlBody.replace('<wbr>', '');
    opportunityId = htmlBody.subStringBetween('DEALIDSTART', 'DEALIDEND')
      .replaceAll('-', '');
    //Find the Deal
    Opportunity deal = queryOpportunity(opportunityId);
    Approval_History__c appHis = [
      SELECT ProcessName__c, Approval_Type__c, Status__c
      FROM Approval_History__c
      WHERE Deal__c = :opportunityId AND Status__c = 'Submitted'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    System.debug('PROCESS NAME: ' + appHis.ProcessName__c);
    Map<Id, User> userMap = USERINFOMAP.get(appHis.ProcessName__c);
    System.debug('USERMAP: ' + userMap);
    deal.Apex_Context__c = true;
    Set<String> alreadyCcs = new Set<String>();
    Set<String> setCcs = new Set<String>();

    if (null != email.ccAddresses && email.ccAddresses.size() > 0) {
      for (String c : email.ccAddresses) {
        alreadyCcs.add(c);
      }
    }

    if (
      (deal.RecordType.DeveloperName == 'LOC_Loan' ||
      deal.RecordType.DeveloperName.contains('LOC_Loan')) &&
      ((!alreadySentTo.equals(BRIDGE_SUB_IC_GROUP) &&
      !alreadyCcs.equals(BRIDGE_SUB_IC_GROUP)) ||
      (!alreadySentTo.equals(BRIDGE_IC_GROUP) &&
      !alreadyCcs.equals(BRIDGE_IC_GROUP)))
    ) {
      if(Deal.Amount > 3000000) {
        setCcs.addAll(BRIDGE_IC_GROUP);
      } else {
        setCcs.addAll(BRIDGE_SUB_IC_GROUP);
      }
    } else if (
      deal.RecordType.DeveloperName == 'Term_Loan' &&
      ((!alreadySentTo.equals(TERM_SUB_IC_GROUP) &&
      !alreadyCcs.equals(TERM_SUB_IC_GROUP)) ||
      (!alreadySentTo.equals(TERM_IC_GROUP) &&
      !alreadyCcs.equals(TERM_IC_GROUP)))
    ) {
      if (deal.Amount > 2000000) {
        setCcs.addAll(TERM_IC_GROUP);
      } else {
        setCcs.addAll(TERM_SUB_IC_GROUP);
      }
    }

    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    Integer characterLim = 6 + email.Subject.length() <= 80
      ? email.Subject.length()
      : 80 - 6;
    Integer contentLim = originalBody.length() <= 131072
      ? originalBody.length()
      : 131072;
    String cvIds = htmlBody.subStringBetween('CONTENTIDSTART', 'CONTENTIDEND')
      .replace('-', '')
      .replace('"', '');
    if (String.isEmpty(cvIds)) {
      cvIds = 'None';
    }
    List<String> recips = new List<String>();
    List<String> ccs = new List<String>();

    recips.addAll(alreadySentTo);
    ccs.addAll(alreadyCcs);

    Email__c e = new Email__c(
      Deal__c = opportunityId,
      Recipient__c = String.join(recips, ';'),
      CC__c = String.join(ccs, ';'),
      Sender__c = email.fromAddress,
      Name = 'HTML: ' + email.Subject.substring(0, characterLim),
      ContentVersionId__c = cvIds,
      Contents__c = originalBody.substring(0, contentLim)
    );

    try {
      Database.insert(e, false);
    } catch (DmlException err) {
      System.debug(
        'Error inserting email__c: ' + JSON.serialize(err.getMessage())
      );
    }

    if (deal != null) {
      String alternateAddress = '';
      if (fromAddress.contains('@cvest.com')) {
        alternateAddress = fromAddress.replace(
          '@cvest.com',
          '@colonyamericanfinance.com'
        );
      }
      System.debug(userMap);
      for (Id key : userMap.keySet()) {
        if(userMap.get(key).Email != null) {
          approverEmails.add(userMap.get(key).Email);
        }
      }

      if (
        fromAddress == deal.Owner.Email ||
        alternateAddress == deal.Owner.Email
      ) {
        System.debug('email is from the originator');

        if (String.isNotBlank(cvIds)) {
          List<String> contentIds = cvIds.split(';');
          Map<Id, Map<String, Object>> cvMap = queryContentVersions(contentIds);

          List<Opportunity> dealsToUpdate = new List<Opportunity>();
          for (Id i : cvMap.keySet()) {
            ContentVersion cv = (ContentVersion) cvMap.get(i).get('cv');
            //contentDocumentIds.add(cv.ContentDocumentId);

            Deal_Document__c dealDoc = (Deal_Document__c) cvMap.get(i)
              .get('doc');
            if (
              dealDoc != null && ICDOCTYPES.contains(dealDoc.Document_Type__c)
            ) {
              deal.Apex_Context__c = true;
              dealsToUpdate.add(deal);
            }
          }

          try {
            Database.update(dealsToUpdate, false);
          } catch (DmlException err) {
            System.debug(
              'Error updating deals: ' +
              err.getLineNumber() +
              ': ' +
              err.getMessage()
            );
          }
        }

        List<String> emailAddressesList = new List<String>();
        List<String> ccAddressesList = new List<String>();

        for (String email1 : approverEmails) {
          if (!alreadySentTo.contains(email1) && !alreadyCcs.contains(email1)) {
            setEmails.add(email1);
          }
        }

        if (setEmails.size() > 0) {
          emailAddressesList.addAll(setEmails);
        }
        if (setCcs.size() > 0) {
          ccAddressesList.addAll(setCcs);
        }

        if (emailAddressesList.size() > 0 && ccAddressesList.size() > 0) {
          sendEmail(email, deal, emailAddressesList, ccAddressesList);
        } else if (emailAddressesList.size() > 0) {
          sendEmail(email, deal, emailAddressesList, null);
        } else if (ccAddressesList.size() > 0) {
          sendEmail(email, deal, ccAddressesList, null);
        }

        List<String> listEmails = new List<String>();
        if (alreadySentTo.size() > 0) {
          listEmails.addAll(alreadySentTo);
        }
        if (setEmails.size() > 0) {
          listEmails.addAll(setEmails);
        }

        List<String> listCcs = new List<String>();
        if (alreadyCcs.size() > 0) {
          listEmails.addAll(alreadyCcs);
        }
        if (setCcs.size() > 0) {
          listCcs.addAll(setCcs);
        }
        createEmailHistory(
          email,
          deal,
          listEmails,
          listCcs,
          new List<Id>(userMap.keySet()),
          deal.OwnerId,
          false
        );
      } else {
        String alternateFromAddress = '';
        if (fromAddress.contains('@cvest.com')) {
          alternateFromAddress = fromAddress.replace(
            '@cvest.com',
            '@colonyamericanfinance.com'
          );
        }

        Boolean approved = false;
        if (
          !alreadySentTo.contains(deal.Owner.Email) &&
          !alreadyCcs.contains(deal.Owner.Email)
        ) {
          setEmails.add(deal.Owner.Email);
        }

        Id toId;
        System.debug('--approver emails--');
        System.debug(approverEmails);
        if (
          approverEmails.contains(fromAddress) ||
          approverEmails.contains(alternateFromAddress)
        ) {
          User fromUser = new User();
          for (Id key : userMap.keySet()) {
            if (userMap.get(key).Email != null &&
              (userMap.get(key).Email.toLowerCase() == fromAddress ||
              userMap.get(key).Email.toLowerCase() == alternateFromAddress) &&
              (htmlBody.toLowerCase()
                .contains(userMap.get(key).Approver_Code__c.toLowerCase())
              || htmlBody.toLowerCase()
              .contains((userMap.get(key).Approver_Code__c.toLowerCase()).replace('approved', 'rejected'))
                )
            ) {
              toId = key;
              fromUser = userMap.get(key);
              break;
            }
          }
          System.debug('FROM USER :: ');
          System.debug(fromUser);
          


          if (
            null != fromUser.Approver_Code__c &&
            htmlBody.toLowerCase()
              .contains(fromUser.Approver_Code__c.toLowerCase())
          ) {
            approved = approveDeal(fromUser.Id, deal);
            createAttachment(email, deal);
            
          } else if (
            null != fromUser.Approver_Code__c &&
            htmlBody.toLowerCase()
              .contains((fromUser.Approver_Code__c.toLowerCase()).replace('approved', 'rejected'))
          ) {
            approved = rejectDeal(fromUser.Id, deal);
            createAttachment(email, deal);
            postToChatter('rejected', deal, deal.Id);
          }
        }

        if(approved) {
          postToChatter('approved', deal, deal.Id);
        }

        List<String> emailAddressesList = new List<String>();
        List<String> ccAddressesList = new List<String>();
        if (setEmails.size() > 0) {
          emailAddressesList.addAll(setEmails);
        }
        if (setCcs.size() > 0) {
          ccAddressesList.addAll(setCcs);
        }

        if (emailAddressesList.size() > 0 && ccAddressesList.size() > 0) {
          sendEmail(email, deal, emailAddressesList, ccAddressesList);
          System.debug(
            'these are the people getting cced on the handler email'
          );
          System.debug(ccAddressesList);
          System.debug('these are the people getting sent the handler email');
          System.debug(emailAddressesList);
        } else if (emailAddressesList.size() > 0) {
          sendEmail(email, deal, emailAddressesList, null);
          System.debug('these are the people getting sent the handler email');
          System.debug(emailAddressesList);
        } else if (ccAddressesList.size() > 0) {
          sendEmail(email, deal, ccAddressesList, null);
          System.debug(
            'these are people who should be CCed getting sent the handler email b/c only new CCs appeared'
          );
          System.debug(emailAddressesList);
        }

        List<String> listEmails = new List<String>();
        if (alreadySentTo.size() > 0) {
          listEmails.addAll(alreadySentTo);
        }
        if (setEmails.size() > 0) {
          listEmails.addAll(setEmails);
        }

        List<String> listCcs = new List<String>();
        if (alreadyCcs.size() > 0) {
          listEmails.addAll(alreadyCcs);
        }
        if (setCcs.size() > 0) {
          listCcs.addAll(setCcs);
        }
        createEmailHistory(
          email,
          deal,
          listEmails,
          listCcs,
          new List<Id>{ deal.OwnerId },
          toId,
          approved
        );
      }
    } else {
      //Reply with error
      System.debug('error sending email');
    }
    return result;
  } // End of handleInboundEmail method

  public static Opportunity queryOpportunity(String opportunityId) {
    List<Opportunity> opptys = [
      SELECT
        Id,
        Name,
        OwnerId,
        Owner.Email,
        Underwriter__c,
        Underwriter__r.Email,
        RecordType.DeveloperName,
        Amount
      FROM Opportunity
      WHERE Id = :opportunityId
      AND RecordType.DeveloperName IN :VALID_RECORDTYPES
      LIMIT 1
    ];
    if (opptys.size() > 0) {
      return opptys[0];
    }

    return null;
  }

  public static Messaging.EmailFileAttachment constructFileAttachment(
    Messaging.InboundEmail.TextAttachment t
  ) {
    Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
    a.setFileName(t.fileName);
    a.setContentType(t.mimeTypeSubType);
    a.setBody(Blob.valueOf(t.body));
    return a;
  }

  public static Messaging.EmailFileAttachment constructFileAttachment(
    Messaging.InboundEmail.BinaryAttachment b
  ) {
    Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
    a.setFileName(b.fileName);
    a.setContentType(b.mimeTypeSubType);
    a.setBody(b.body);
    return a;
  }

  public static void sendEmail(
    Messaging.InboundEmail em,
    Opportunity o,
    List<String> recipients,
    List<String> ccUsers
  ) {
    System.debug('inside sendEmail');
    Messaging.InboundEmail.BinaryAttachment[] binaryList = em.binaryattachments;
    Messaging.InboundEmail.TextAttachment[] textList = em.textAttachments;

    String subject = em.Subject;
    String htmlBody = em.htmlBody.replace('<img src="">', '')
      .replace('<img s', '<img width="500" s');

    if (
      em.htmlBody.indexOf(
        'CoreVest American Finance Lender LLC. All Rights Reserved.'
      ) != -1
    ) {
      String oneFooter = em.htmlBody.substring(
        0,
        em.htmlBody.indexOf(
          'CoreVest American Finance Lender LLC. All Rights Reserved.'
        )
      );
      htmlBody = oneFooter;
    }
    String fromAddress = em.fromAddress;

    System.debug('ccUsers inside sendEmail: ');
    System.debug(ccUsers);
    Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
    sem.setCcAddresses(ccUsers);
    sem.setSubject(subject);
    sem.setReplyTo(handlerAddress);
    sem.setToAddresses(recipients);
    sem.setSenderDisplayName(fromAddress);
    sem.setHtmlBody(htmlBody);

    List<Messaging.EmailFileAttachment> attachmentsList = new List<Messaging.EmailFileAttachment>();
    if (null != textList && textList.size() > 0) {
      for (Messaging.InboundEmail.TextAttachment t : textList) {
        attachmentsList.add(constructFileAttachment(t));
      }
      sem.setFileAttachments(attachmentsList);
    }
    if (null != binaryList && binaryList.size() > 0) {
      for (Messaging.InboundEmail.BinaryAttachment b : binaryList) {
        attachmentsList.add(constructFileAttachment(b));
      }
      sem.setFileAttachments(attachmentsList);
    }

    try {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ sem }
      );
    } catch (Exception e) {
      String errorMessage = '';
      errorMessage += JSON.serialize(recipients);
      errorMessage += '<br/>' + ccUsers == null
        ? 'null'
        : JSON.serialize(ccUsers);
      errorMessage += '<br/>' + JSON.serialize(fromAddress);
      Messaging.SingleEmailMessage em1 = new Messaging.SingleEmailMessage();
      em1.setSubject('mail error');
      em1.setToAddresses(new List<String>{ 'ldecastro@mkpartners.com' });
      em1.setHtmlBody('<html><body>' + errorMessage + '</html></body>');
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ em1 });
    }
  }

  public static void createAttachment(
    Messaging.InboundEmail em,
    Opportunity o
  ) {
    System.debug('createAttachment has been hit');
    String cvIds = '';
    String htmlBody = ''; //em.htmlBody;
    String originalBody = '';

    if (String.isNotBlank(em.htmlBody)) {
      htmlBody = em.htmlBody;
      originalBody = em.htmlBody;
    } else {
      htmlBody = em.plainTextBody;
      originalBody = em.plainTextBody;
    }
    if (String.isNotBlank(htmlBody) && htmlBody.contains('<wbr>')) {
      htmlBody = htmlBody.replace('<wbr>', '');
    }
    cvIds = htmlBody.subStringBetween('CONTENTIDSTART', 'CONTENTIDEND')
      .replace('-', '');
    System.debug('these are the cvIds');
    System.debug(cvIds);

    List<Attachment> aList = new List<Attachment>();
    if (String.isNotBlank(cvIds)) {
      List<String> contentIds = cvIds.split(';');

      Map<Id, Map<String, Object>> cvMap = queryContentVersions(contentIds);

      for (Id i : cvMap.keySet()) {
        ContentVersion cv = (ContentVersion) cvMap.get(i).get('cv');

        Deal_Document__c dealDoc = (Deal_Document__c) cvMap.get(i).get('doc');

        if (
          dealDoc != null &&
          (dealDoc.Type__c == 'IC Memo' ||
          dealDoc.Document_Type__c == 'Draft IC Memo' ||
          dealDoc.Document_Type__c == 'Committee Memo')
        ) {
          aList.add(
            new Attachment(
              Name = cv.PathOnClient,
              Body = cv.VersionData,
              ParentId = o.Id
            )
          );
        }
      }

      System.debug('this is the new attachment');
      System.debug(aList);
      insert aList;
    }
    System.debug('this is the body');
    System.debug(htmlBody);
  }

  public static Map<Id, Map<String, Object>> queryContentVersions(
    List<Id> cIds
  ) {
    Map<Id, Map<String, Object>> respMap = new Map<Id, Map<String, Object>>();

    for (Id i : cIds) {
      respMap.put(i, new Map<String, Object>());
    }

    for (ContentVersion cv : [
      SELECT Id, ContentDocumentId, PathOnClient, VersionData
      FROM ContentVersion
      WHERE Id IN :cIds
    ]) {
      // respMap.put(cv.ContentDocumentId, new Map<String, Object>>)
      respMap.get(cv.Id).put('cv', cv);
    }

    for (Deal_Document__c doc : [
      SELECT Id, ContentVersion_Id__c, Type__c, Document_Type__c
      FROM Deal_Document__c
      WHERE ContentVersion_Id__c IN :cIds
    ]) {
      respMap.get(doc.ContentVersion_Id__c).put('doc', doc);
    }

    return respMap;
  }

  public static void createEmailHistory(
    Messaging.InboundEmail em,
    Opportunity o,
    List<String> recipients,
    List<String> ccEmails,
    List<Id> recipientIds,
    Id uId,
    Boolean approved
  ) {
    System.debug('createEmailHistory and changing opp record has been hit');
    String cvIds = '';
    String htmlBody = ''; //em.htmlBody;
    String originalBody = '';

    if (String.isNotBlank(em.htmlBody)) {
      htmlBody = em.htmlBody;
      originalBody = em.htmlBody;
    } else {
      htmlBody = em.plainTextBody;
      originalBody = em.plainTextBody;
    }

    if (htmlBody.contains('<wbr>')) {
      htmlBody = htmlBody.replace('<wbr>', '');
    }

    cvIds = htmlBody.subStringBetween('CONTENTIDSTART', 'CONTENTIDEND')
      .replace('-', '')
      .replace('"', '');

    List<String> contentIds = new List<String>();
    if (String.isNotBlank(cvIds)) {
      contentIds = cvIds.split(';');
    }
    List<Id> contentDocumentIds = new List<Id>();

    System.debug('these are the contentIds');
    System.debug(contentIds);

    System.Savepoint sp = Database.setSavepoint();

    List<Id> ccEmailIds = new List<Id>();
    List<Id> recipientEmailIds = new List<Id>();
    Set<String> recipientEmailSet = new Set<String>();
    if (null != recipients && recipients.size() > 0) {
      recipientEmailSet.addAll(recipients);
    }
    Set<String> ccEmailSet = new Set<String>();
    if (null != ccEmails && ccEmails.size() > 0) {
      ccEmailSet.addAll(ccEmails);
    }

    List<User> uList = new List<User>();
    try {
      uList = [
        SELECT Id, Email
        FROM User
        WHERE Email IN :ccEmails OR Email IN :recipients
      ];
    } catch (Exception ex) {
      System.debug('error in looking for users');
      System.debug(ex.getMessage());
      sendExceptionEmails(ex);
    }
    if (uList.size() > 0) {
      for (User u : uList) {
        if (recipientEmailSet.contains(u.Email)) {
          recipientEmailIds.add(u.Id);
        } else if (ccEmailSet.contains(u.Email)) {
          ccEmailIds.add(u.Id);
        }
      }
    }

    String recipientStr = '';
    System.debug('these are the recipients');
    System.debug(recipients);
    if (null != recipients && recipients.size() > 0) {
      recipientStr = String.join(recipients, '; ');
    }
    String newToIds = '';
    if (null != recipientIds && recipientIds.size() > 0) {
      newToIds = String.join(recipientIds, '; ');
    }
    System.debug('this is newToIds');
    System.debug(newToIds);
    String ccStr = '';
    if (null != ccEmails && ccEmails.size() > 0) {
      for (String cc : ccEmails) {
        ccStr += cc + '; ';
      }
    }
    ccStr.substringBeforeLast(';');

    Integer characterLim = em.Subject.length() <= 80 ? em.Subject.length() : 80;
    Integer contentLim = em.plainTextBody.length() <= 32768
      ? em.plainTextBody.length()
      : 32768;

    Email__c e = new Email__c(
      Deal__c = o.Id,
      Recipient__c = String.join(recipients, ';'),
      Sender__c = em.fromAddress,
      Name = em.Subject.substring(0, characterLim),
      ContentVersionId__c = String.join(contentIds, ';'),
      Contents__c = em.plainTextBody.substring(0, contentLim)
    );
    System.debug('this is the string value of recipients');
    System.debug(String.valueOf(recipients));

    System.debug('these are the headers');
    System.debug(em.headers);
    DateTime emailDate;
    if (em.headers != null) {
      for (Messaging.InboundEmail.Header ieh : em.headers) {
        if (ieh.name == 'Date') {
          System.debug('check the date');
          System.debug(ieh.value);
          emailDate = system.now();
        }
      }
    }

    EmailMessage emm = new EmailMessage(
      FromAddress = em.fromAddress,
      FromName = em.fromName,
      MessageDate = emailDate,
      Subject = em.Subject,
      HtmlBody = em.htmlBody,
      TextBody = em.plainTextBody,
      ToAddress = recipientStr,
      RelatedToId = o.Id,
      Status = '3'
    );
    if (null != ccStr && ccStr.length() > 0) {
      emm.CcAddress = ccStr;
    }
    if (null != ccEmails && ccEmailIds.size() > 0) {
      emm.CcIds = ccEmailIds;
    }

    try {
      insert emm;
    } catch (Exception ex) {
      System.debug('insert emailMessage exception');
      System.debug(ex.getLineNumber());
      System.debug(ex.getStackTraceString());
      System.debug(ex.getTypeName());
      System.debug(ex.getMessage());
      Database.rollback(sp);
      sendExceptionEmails(ex);
    }

    List<EmailMessageRelation> emrInserts = new List<EmailMessageRelation>();
    Id recipientId;
    if (recipientIds.size() > 0) {
      recipientId = recipientIds[0];
    }
    emrInserts.add(
      constructEmailMessageRelation(
        emm.Id,
        recipients[0],
        recipientId,
        'ToAddress'
      )
    );
    emrInserts.add(
      constructEmailMessageRelation(emm.Id, em.FromAddress, uId, 'FromAddress')
    );

    try {
      insert emrInserts;
    } catch (Exception ex) {
      System.debug('insert emailMessageRelation exception');
      System.debug(ex.getLineNumber());
      System.debug(ex.getStackTraceString());
      System.debug(ex.getTypeName());
      System.debug(ex.getMessage());

      Database.rollback(sp);
      sendExceptionEmails(ex);
    }

    if (null != ccEmails && ccEmails.size() > 0) {
      e.CC__c = String.join(ccEmails, ';');
    }

    try {
      // insert emrInserts;
      insert e;
    } catch (Exception ex) {
      System.debug('insert custom email record exception');
      System.debug(ex.getLineNumber());
      System.debug(ex.getStackTraceString());
      System.debug(ex.getTypeName());
      System.debug(ex.getMessage());

      Database.rollback(sp);
      sendExceptionEmails(ex);
    }
  }

  public static EmailMessageRelation constructEmailMessageRelation(
    Id messageId,
    String relAddress,
    Id relId,
    String type
  ) {
    EmailMessageRelation emr = new EmailMessageRelation();
    emr.EmailMessageId = messageId;
    emr.RelationAddress = relAddress;
    emr.RelationId = relId;
    emr.RelationType = type;
    return emr;
  }

  public static void sendReply(Id opportunityId, Id UserId) {
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    message.setTargetObjectId(userId);
    message.setWhatId(opportunityId);
  }

  public static void sendExceptionEmails(Exception ex) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    email.setToAddresses(
      new List<String>{ ' logins+cvest@mkpartners.com', 'bryon@cvest.com' }
    );

    String body = '';
    body += 'Line Number: ' + ex.getLineNumber();
    body += '\nStacktrace: ' + ex.getStackTraceString();
    body += '\nType: ' + ex.getTypeName();
    body += '\nMessage:  ' + ex.getMessage();
    email.setPlainTextbody(body);
    email.setSubject('Deal Approval Handler Error');

    List<OrgWideEmailAddress> owea = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'caf-apps@cvest.com'
    ];
    
    if (owea.size() > 0) {
      email.setOrgWideEmailAddressId(owea.get(0).Id);
    }

    Messaging.sendEmail(new List<Messaging.SIngleEmailMessage>{ email });
  }

  public static Boolean approveDeal(Id userId, Opportunity deal) {
    
    List<ProcessInstanceWorkItem> wrkItem = [
      SELECT
        Id,
        ProcessInstance.TargetObjectId,
        ProcessInstance.Status,
        ActorId,
        Actor.Name,
        OriginalActorId,
        ProcessInstance.ProcessDefinition.DeveloperName,
        CreatedDate
      FROM ProcessInstanceWorkItem
      WHERE ActorId = :userId AND ProcessInstance.TargetObjectId = :deal.Id
      LIMIT 1
    ];

    System.debug('Approved deal method entry');
    if (wrkItem.size() > 0) {
      try {
        handleApproval('Approve', userId, deal, wrkItem, false);
        List<ProcessInstanceWorkItem> updatedWkrItem = [
          SELECT
            Id,
            ProcessInstance.TargetObjectId,
            ProcessInstance.Status,
            ActorId,
            Actor.Name,
            OriginalActorId,
            ProcessInstance.ProcessDefinition.DeveloperName,
            CreatedDate
          FROM ProcessInstanceWorkItem
          WHERE ProcessInstance.TargetObjectId = :deal.Id
        ];

        System.debug('RECORD TYPE DEV NAME IS: ' + deal.RecordType.DeveloperName);
        System.debug('THERE ARE ' + updatedWkrItem.size() + ' WORK ITEMS');
        System.debug('SHOULD 2/3 RUN? ' + (TWO_OF_THREE_APPROVALS.contains(deal.RecordType.DeveloperName.toUpperCase()) && updatedWkrItem.size() == 1));
        
        if (updatedWkrItem.size() > 0 && !TWO_OF_THREE_APPROVALS.contains(deal.RecordType.DeveloperName.toUpperCase())) {
          return false;
        } else if (TWO_OF_THREE_APPROVALS.contains(deal.RecordType.DeveloperName.toUpperCase()) && updatedWkrItem.size() == 1) {
          handleApproval('Approve', userId, deal, updatedWkrItem, true);
          return true;
        } else {
          return true;
        }

      } catch (Exception err) {
        System.debug(err.getMessage());
        sendExceptionEmails(err);
      }
    } else {
      return false;
    }

    return false;
  }

  public static Boolean rejectDeal(Id userId, Opportunity deal) {
    
    List<ProcessInstanceWorkItem> wrkItem = [
      SELECT
        Id,
        ProcessInstance.TargetObjectId,
        ProcessInstance.Status,
        ActorId,
        Actor.Name,
        OriginalActorId,
        ProcessInstance.ProcessDefinition.DeveloperName,
        CreatedDate
      FROM ProcessInstanceWorkItem
      WHERE ActorId = :userId AND ProcessInstance.TargetObjectId = :deal.Id
      LIMIT 1
    ];

    System.debug('Reject deal method entry');
    if (wrkItem.size() > 0) {
      try {
        handleApproval('Reject', userId, deal, wrkItem, false);
      } catch (Exception err) {
        System.debug(err.getMessage());
        sendExceptionEmails(err);
      }
    } else {
      return false;
    }
    return false;
  }

  public static void handleApproval(String actionType, Id userId, Opportunity deal, List<ProcessInstanceWorkItem> wrkItem, Boolean isTwoOfThree) {
    String actionVerb = '';
    if (actionType == 'Approve') {
      actionVerb = 'Approved';
    } else if (actionType == 'Reject') {
      actionVerb = 'Rejected';
    }
    String comments = actionVerb + ' from Email by ' + wrkItem[0].Actor.Name;
    if(isTwoOfThree) {
      comments = 'Automatic approval based on 2/3 approval.';
    }
    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    pwr.setComments(comments);
    pwr.setWorkitemId(wrkItem[0].Id);
    pwr.setAction(actionType);
    Approval.ProcessResult result = Approval.process(pwr);
    Id processInstanceId = result.getInstanceId();

    List<ProcessInstanceStep> pis = [
      SELECT Id, ProcessInstance.ProcessDefinition.DeveloperName
      FROM ProcessInstanceStep
      WHERE
        ProcessInstanceId = :processInstanceId
        AND StepStatus = :actionVerb
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    String pName = pis[0].ProcessInstance.ProcessDefinition.DeveloperName;

    String status = result.getInstanceStatus();

    List<Approval_History__c> ahListInit = [
      SELECT
        Id,
        Actor__c,
        Process_Id__c,
        Status__c,
        Comments__c,
        Parent_Status__c,
        Process_Instance_Id__c,
        Step_Item_Id__c
      FROM Approval_History__c
      WHERE Process_Id__c = :wrkItem[0].Id
      LIMIT 1
    ];

    if (ahListInit.size() > 0) {
      Approval_History__c ah = ahListInit[0];

      List<Approval_History__c> otherAh;

      if (null != ah) {
        otherAh = [
          SELECT
            Id,
            Actor__c,
            Process_Id__c,
            Status__c,
            Comments__c,
            Parent_Status__c,
            Process_Instance_Id__c,
            Step_Item_Id__c,
            Status_Text__c
          FROM Approval_History__c
          WHERE
            Process_Id__c != :wrkItem[0].Id
            AND Process_Instance_Id__c = :ah.Process_Instance_Id__c
            AND Status__c = 'Pending'
        ];

        ah.Actor__c = wrkItem[0].ActorId;
        ah.Approver__c = wrkItem[0].Actor.Name;
        ah.Status__c = actionVerb;
        ah.Status_Text__c = actionVerb;
        ah.Comments__c = comments;
        ah.Date_Acted__c = System.now();
        if (pis.size() > 0) {
          ah.Step_Item_Id__c = pis[0].Id;
        }
      }

      Id submitterId;

      if (null != processInstanceId && null != status) {
        List<Approval_History__c> ahList = [
          SELECT Id, Parent_Status__c, Actor__c, Status_Text__c
          FROM Approval_History__c
          WHERE Process_Instance_Id__c = :processInstanceId
        ];
        for (Approval_History__c ahc : ahList) {
          ahc.Parent_Status__c = status;
          if (
            (ahc.Status_Text__c == 'Submitted' ||
            ahc.Status_Text__c == 'Re-submitted') && null != ahc.Actor__c
          ) {
            submitterId = ahc.Actor__c;
          }
        }
        update ahList;
        ah.Parent_Status__c = status;
      }

      ah.Deal__c = deal.Id;
      update ah;
      
      if (null != otherAh && otherAh.size() > 0 && actionType == 'Reject') {
        for (Approval_History__c ahc : otherAh) {
          ahc.Status__c = actionVerb;
          ahc.Status_Text__c = actionVerb;
          ahc.Comments__c = comments;
          ahc.Date_Acted__c = System.now();
        }
        update otherAh;
      }
    }
  }
}