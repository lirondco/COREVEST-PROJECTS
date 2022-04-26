global class dealApprovalHandler implements Messaging.InboundEmailHandler {
  // static final String emailAddress = 'deal_approval_handler@1-2ubmvsr19x7o406nnymb5zkfzbl7wsflro23z72qyy25g7hr6z.5c-8jnxuay.cs62.apex.sandbox.salesforce.com';
  // static final String handlerAddressSB = 'dealapprovalhandler@y-1743xjz0wr71vsi0mlpa94d43nex0gxmqgq50qhxn2rb8ccjpn.3i-oe9uam.cs123.apex.sandbox.salesforce.com'; // Handler Email for FULL

  //static final String handlerAddress = 'dealapprovalhandler@pyo7p2pzqqm356qd6r207z35fsfvn6429vh6lwamowp6ctfb5.j-l4sceas.na54.apex.salesforce.com'; // Handler Email for Production
  // static final String handlerAddress = 'dealapprovalhandler@z-21v3s1rxdsiq86g66t7hglls19pn9knj4z9ipe9qmtde06twmy.z-9t6ahmas.cs11.apex.sandbox.salesforce.com';
  
  static final String handlerAddress = retrieveEmailServiceAddress();
  // static final Email_Addresses__c RYAN_SETTINGS = queryEmailAddress(
  //   'Ryan McBride'
  // );
  static final Email_Addresses__c BETH_SETTINGS = queryEmailAddress(
    'Beth O\'Brien'
  );
  static final Email_Addresses__c CHRIS_SETTINGS = queryEmailAddress(
    'Chris Hoeffel'
  );
  // static final Email_Addresses__c BRYON_SETTINGS = queryEmailAddress(
  //   'Bryon Harland'
  // );
  static final Email_Addresses__c BRAD_SETTINGS = queryEmailAddress(
    'Brad Chmura'
  );
  static final Email_Addresses__c MATT_SETTINGS = queryEmailAddress(
    'Matthew Orrino'
  );
  static final Email_Addresses__c MICAELA_SETTINGS = queryEmailAddress(
    'Micaela Lumpkin'
  );

  // static final String RYAN = RYAN_SETTINGS.Email_Address__c;
  static final String BETH = BETH_SETTINGS.Email_Address__c;
  static final String CHRIS = CHRIS_SETTINGS.Email_Address__c;
  // static final String BRYON = BRYON_SETTINGS.Email_Address__c;
  static final String BRAD = BRAD_SETTINGS.Email_Address__c;
  static final String MICAELA = MICAELA_SETTINGS.Email_Address__c;
  static final String MATT = MATT_SETTINGS.Email_Address__c;
  // static final String RYAN_CODE = RYAN_SETTINGS.Approver_Code__c.toLowerCase();
  static final String BETH_CODE = BETH_SETTINGS.Approver_Code__c.toLowerCase();
  static final String CHRIS_CODE = CHRIS_SETTINGS.Approver_Code__c.toLowerCase();
  // static final String BRYON_CODE = BRYON_SETTINGS.Approver_Code__c.toLowerCase();
  static final String BRAD_CODE = BRAD_SETTINGS.Approver_Code__c.toLowerCase();
  static final String MICAELA_CODE = MICAELA_SETTINGS.Approver_Code__c.toLowerCase();
  static final String MATT_CODE = MATT_SETTINGS.Approver_Code__c.toLowerCase();
  static final String BRIDGE_LIST = queryEmailAddress(
      'Bridge Term Sheet Mailing List'
    )
    .Email_Address__c;
  static final String TERM_LIST = queryEmailAddress('Term Sheet Mailing List')
    .Email_Address__c;

  // Below variables created for test coverage : Trivikram
  public static boolean performTestCoverageForBETH = false;
  public static boolean performTestCoverageForRYAN = false;
  public static boolean performTestCoverageForCHRIS = false;

  public static String retrieveEmailServiceAddress() {
    EmailServicesFunction emailFunction = [
      SELECT Id
      FROM EmailServicesFunction
      WHERE FunctionName = 'dealApprovalHandler'
    ];

    EmailServicesAddress emailServicesAddress = [
      SELECT Id, LocalPart, EmailDomainName
      FROM EmailServicesAddress
      WHERE FunctionId = :emailFunction.Id
    ];

    return (emailServicesAddress.LocalPart +
    '@' +
    emailServicesAddress.EmailDomainName);

  }



  public static Email_Addresses__c queryEmailAddress(String name) {
    Email_Addresses__c setting = Email_Addresses__c.getInstance(name);
    if (setting == null || setting.id == null) {
      setting = new Email_Addresses__c(
        Name = name,
        Email_Address__c = '',
        Approver_Code__c = ''
      );
      if (Test.isRunningTest()) {
        setting.Email_Address__c = userInfo.getUserEmail();
        setting.Approver_Code__c = 'test';
      }
    }
    return setting;
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

  public static void postToChatter(Opportunity deal, String subjectId, Boolean isGlc) {
    System.debug('postToChatter has been hit');
    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = deal.OwnerId; // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    String segmentText = ' ' + deal.Name + ' has been approved.';
    if(isGlc) {
      segmentText += ' This Deal requires GLC Approval.';
    }
    textSegment.text = segmentText;
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

  global Messaging.InboundEmailResult handleInboundEmail(
    Messaging.InboundEmail email,
    Messaging.InboundEnvelope envelope
  ) {
    System.debug('received email');

    Map<String, User> userMap = queryRyanAndBeth();
    Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

    String opportunityId;
    String fromAddress = email.fromAddress;
    System.debug('this is who it is from on the envelope');
    // System.debug(htmlBody);
    System.debug(fromAddress);

    Set<String> alreadySentTo = new Set<String>();
    Set<String> setEmails = new Set<String>();

    if (null != email.toAddresses && email.toAddresses.size() > 0) {
      for (String e : email.toAddresses) {
        // if (e != emailAddress && !setEmails.contains(e)){
        alreadySentTo.add(e);
        // }
      }
      System.debug(
        'this is who it is to on the envelope with the handler address'
      );
      System.debug(alreadySentTo);
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
    System.debug('this is the html body');
    System.debug(htmlBody);
    opportunityId = htmlBody.subStringBetween('DEALIDSTART', 'DEALIDEND')
      .replace('-', '');
    //Find the Deal
    Opportunity deal = queryOpportunity(opportunityId);
    deal.Apex_Context__c = true;
    System.debug('this is the deal');
    System.debug(deal);

    Set<String> alreadyCcs = new Set<String>();
    Set<String> setCcs = new Set<String>();
    // Set<String> ccAddressesSet = new Set<String>();

    if (null != email.ccAddresses && email.ccAddresses.size() > 0) {
      for (String c : email.ccAddresses) {
        // if (c != emailAddress && !setCcs.contains(c) && !setEmails.contains(c)){
        alreadyCcs.add(c);
        // }
      }

      System.debug(
        'this is who it CCs on the envelope with the handler address'
      );
      System.debug(alreadyCcs);
    }

    if (
      (deal.RecordType.DeveloperName == 'LOC_Loan' ||
      deal.RecordType.DeveloperName.contains('LOC_Loan')) &&
      !alreadySentTo.contains(BRIDGE_LIST) &&
      !alreadyCcs.contains(BRIDGE_LIST)
    ) {
      setCcs.add(BRIDGE_LIST);
    } else if (
      deal.RecordType.DeveloperName == 'Term_Loan' &&
      !alreadySentTo.contains(TERM_LIST) &&
      !alreadyCcs.contains(TERM_LIST)
    ) {
      setCcs.add(TERM_LIST);
    }

    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    // User ryanUser = userMap.get('Ryan McBride');
    User chrisUser = userMap.get('Christopher Hoeffel');
    User bethUser = userMap.get('Beth O\'Brien');
    // User bryonUser = userMap.get('Bryon Harland');
    User mattUser = userMap.get('Matthew Orrino');
    User bradUser = userMap.get('Brad Chmura');
    User micaelaUser = userMap.get('Micaela Lumpkin');

    Integer characterLim = 6 + email.Subject.length() <= 80
      ? email.Subject.length()
      : 80 - 6;
    Integer contentLim = originalBody.length() <= 131072
      ? originalBody.length()
      : 131072;
    String cvIds = htmlBody.subStringBetween('CONTENTIDSTART', 'CONTENTIDEND')
      .replace('-', '')
      .replace('"', '');
    String aIds = htmlBody.subStringBetween(
        'ATTACHMENTIDSTART',
        'ATTACHMENTIDEND'
      )
      .replace('-', '')
      .replace('"', '');
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
      AttachmentId__c = aIds,
      ContentVersionId__c = cvIds,
      Contents__c = originalBody.substring(0, contentLim)
    );

    insert e;

    if (deal != null) {
      String alternateAddress = '';
      if (fromAddress.contains('@cvest.com')) {
        alternateAddress = fromAddress.replace(
          '@cvest.com',
          '@colonyamericanfinance.com'
        );
      }

      if (
        fromAddress == deal.Owner.Email ||
        alternateAddress == deal.Owner.Email
      ) {
        System.debug('email is from the originator');

        if (String.isNotBlank(cvIds)) {
          List<String> contentIds = cvIds.split(';');
          Map<Id, Map<String, Object>> cvMap = queryContentVersions(contentIds);

          for (Id i : cvMap.keySet()) {
            ContentVersion cv = (ContentVersion) cvMap.get(i).get('cv');
            //contentDocumentIds.add(cv.ContentDocumentId);

            Deal_Document__c dealDoc = (Deal_Document__c) cvMap.get(i)
              .get('doc');

            if (
              dealDoc != null &&
              (dealDoc.Type__c == 'Term Sheet' ||
              dealDoc.Document_Type__c == 'Term Sheet' ||
              cv.PathOnClient.contains('TermSheet'))
            ) {
              deal.Last_Referenced_Term_Sheet__c = i;
              deal.Apex_Context__c = true;
              update deal;
              deal.Apex_Context__c = true;
            }
          }

          //for (ContentVersion cv : queryContentVersions(contentIds)){
          //    if (cv.PathOnClient.contains('TermSheet')){
          //        deal.Last_Referenced_Term_Sheet__c = cv.Id;
          //        deal.Apex_Context__c = true;
          //        update deal;
          //        deal.Apex_Context__c = true;
          //    }
          //}
        }
        // update deal here

        List<String> bossEmails = new List<String>{
          BETH,
          // RYAN,
          CHRIS,
          // BRYON,
          BRAD,
          MICAELA,
          MATT
        };
        for (String email1 : bossEmails) {
          if (!alreadySentTo.contains(email1) && !alreadyCcs.contains(email1)) {
            setEmails.add(email1);
          }
        }

        List<Id> ryanBethId = new List<Id>();
        for (String u : userMap.keySet()) {
          ryanBethId.add(userMap.get(u).Id);
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
          System.debug(
            'these are the people getting sent the handler email. No CCs'
          );
          System.debug(emailAddressesList);
        } else if (ccAddressesList.size() > 0) {
          sendEmail(email, deal, ccAddressesList, null);
          System.debug(
            'these are people who should be CCed getting sent the handler email b/c only new CCs appeared'
          );
          System.debug(ccAddressesList);
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
          ryanBethId,
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

        System.debug('email is not ator');
        Boolean b = false;
        if (
          !alreadySentTo.contains(deal.Owner.Email) &&
          !alreadyCcs.contains(deal.Owner.Email)
        ) {
          setEmails.add(deal.Owner.Email);
        }

        // if (!setEmails.contains(deal.Owner.Email) && !setCcs.contains(deal.Owner.Email)){
        //     toEmailsSet.add(deal.Owner.email);
        // }
        // emailAddresses.add(deal.Owner.Email);
        // List<String> cc = new List<String>();
        // if (null != ccAddresses && ccAddresses.size() > 0){
        //     cc.addAll(ccAddresses);
        // }
        Id toId;
        System.debug('fromAddress >>>>> ' + fromAddress);
        System.debug('BETH >>>>> ' + BETH);
        System.debug('alternateFromAddress >>>>> ' + alternateFromAddress);

        // Logic added for test class execution : Trivikram
        if (
          fromAddress == BETH ||
          alternateFromAddress == BETH ||
          (Test.isRunningTest() && performTestCoverageForBETH == true)
        ) {
          System.debug('email is from Beth');
          List<String> bossEmails = new List<String>{
            // RYAN,
            CHRIS,
            // BRYON,
            BRAD,
            MICAELA,
            MATT
          };
          for (String email2 : bossEmails) {
            if (
              !alreadySentTo.contains(email2) && !alreadyCcs.contains(email2)
            ) {
              setEmails.add(email2);
            }
          }

          toId = bethUser.Id;

          if (null != BETH_CODE && htmlBody.toLowerCase().contains(BETH_CODE)) {
            b = true;
            createAttachment(email, deal);
            postToChatter(deal, deal.Id, false);
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
            b
          );
          // sendEmail(email, deal, emailAddress, ccAddressesList);
        } else if (
          // fromAddress == RYAN ||
          fromAddress == CHRIS ||
          // fromAddress == BRYON ||
          fromAddress == BRAD ||
          fromAddress == MICAELA ||
          fromAddress == MATT ||
          // alternateFromAddress == RYAN ||
          alternateFromAddress == CHRIS ||
          // alternateFromAddress == BRYON ||
          alternateFromAddress == BRAD ||
          alternateFromAddress == MICAELA ||
          alternateFromAddress == MATT ||
          (Test.isRunningTest() && performTestCoverageForRYAN == true)
        ) {
          // Logic added for test class execution : Trivikram
          System.debug('email is from Ryan or Chris');

          if (!alreadySentTo.contains(BETH) && !alreadyCcs.contains(BETH)) {
            setEmails.add(BETH);
          }
          // cc.add(BETH);
          
          // if(fromAddress == RYAN || alternateFromAddress == RYAN) {
          //   toId = ryanUser.Id;
          // } else 
          if(fromAddress == CHRIS || alternateFromAddress == CHRIS) {
            toId = chrisUser.Id;
          } else if (fromAddress == BRAD || alternateFromAddress == BRAD) {
            toId = bradUser.Id;
          } else if (fromAddress == MICAELA || alternateFromAddress == MICAELA) {
            toId = micaelaUser.Id;
          } else  if (fromAddress == MATT || alternateFromAddress == MATT) {
            toId = mattUser.Id;
          }

          if (
            (null != CHRIS_CODE &&
            htmlBody.toLowerCase().contains(CHRIS_CODE)) ||
            // (null != BRYON_CODE &&
            // htmlBody.toLowerCase().contains(BRYON_CODE)) ||
            (null != BRAD_CODE && htmlBody.toLowerCase().contains(BRAD_CODE)) ||
            (null != MICAELA_CODE &&
            htmlBody.toLowerCase().contains(MICAELA_CODE)) ||
            (null != MATT_CODE && htmlBody.toLowerCase().contains(MATT_CODE))
          ) {
            b = true;
            Boolean isGLC = false;
            if(htmlBody.toLowerCase().contains(BRAD_CODE + ' glc')) {
              updateDealForGlc(deal.Id);
              isGLC = true;
            }
            createAttachment(email, deal);
            postToChatter(deal, deal.Id, isGLC);
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

          // List<String> emailAddress = new list<String>();
          // emailAddress.addAll(toEmailsSet);
          // ccAddressesList.addAll(ccAddressesSet);
          // System.debug('these are the people getting cced');
          // System.debug(ccAddressesList);
          // if ( fromAddress == BETH || fromAddress == RYAN || fromAddress == CHRIS ){
          // List<String> listEmails = new List<String>();
          // if (setEmails.size() > 0){
          //     listEmails.addAll(setEmails);
          // }
          //
          // List<String> listCcs = new List<String>();
          // if (setCcs.size() > 0){
          //     listCcs.addAll(setCcs);
          // }
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
            b
          );

          // sendEmail(email, deal, emailAddress, ccAddressesList);
        }

        // List<String> emailAddress = new list<String>();
        // emailAddress.addAll(toEmailsSet);
        // List<String> ccAddress = new List<String>();
        // ccAddress.addAll(ccAddressesSet);
        // // if ( fromAddress == BETH || fromAddress == RYAN || fromAddress == CHRIS ){
        //     createEmailHistory(email, deal, emailAddress, ccAddress, new List<Id>{deal.OwnerId}, toId, b);
        //     sendEmail(email, deal, emailAddress, ccAddress);
        // }
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
        Last_Referenced_Term_Sheet__c
      FROM Opportunity
      WHERE Id = :opportunityId
      LIMIT 1
    ];
    if (opptys.size() > 0) {
      return opptys[0];
    }

    return null;
  }

  public static Map<String, User> queryRyanAndBeth() {
    Map<String, User> userMap = new Map<String, User>();
    for (
      User u : [
        SELECT Id, Department, Email, Name
        FROM User
        WHERE
          Name = 'Beth O\'Brien'
          // OR Name = 'Ryan McBride'
          OR Name = 'Christopher Hoeffel'
          // OR Name = 'Bryon Harland'
          OR Name = 'Brad Chmura'
          OR Name = 'Micaela Lumpkin'
          OR Name = 'Matthew Orrino'
      ]
    ) {
      userMap.put(u.Name, u);
    }
    return userMap;
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
      em1.setToAddresses(new List<String>{ 'mcastillo@mkpartners.com' });
      em1.setHtmlBody('<html><body>' + errorMessage + '</html></body>');
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ em1 });
    }
  }

  public static void createAttachment(
    Messaging.InboundEmail em,
    Opportunity o
  ) {
    System.debug('createAttachment has been hit');
    // String aIds;
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
        //contentDocumentIds.add(cv.ContentDocumentId);

        Deal_Document__c dealDoc = (Deal_Document__c) cvMap.get(i).get('doc');

        if (
          dealDoc != null &&
          (dealDoc.Type__c == 'Term Sheet' ||
          dealDoc.Document_Type__c == 'Term Sheet' ||
          cv.PathOnClient.contains('TermSheet'))
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

      //for (ContentVersion cv : queryContentVersions(contentIds)){
      //    if (cv.PathOnClient.contains('TermSheet')){
      //        aList.add(
      //            new Attachment(
      //                Name = cv.PathOnClient
      //                , Body = cv.VersionData
      //                , ParentId = o.Id
      //            )
      //        );
      //    }
      //}

      if (aList.size() == 0 && o.Last_Referenced_Term_Sheet__c != null) {
        List<ContentVersion> cvList = [
          SELECT PathOnClient, VersionData
          FROM ContentVersion
          WHERE Id = :o.Last_Referenced_Term_Sheet__c
        ];

        if (cvList.size() > 0) {
          aList.add(
            new Attachment(
              Name = cvList[0].PathOnClient,
              Body = cvList[0].VersionData,
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

  //public static List<ContentVersion> queryContentVersions(List<Id> cIds){
  //    return [
  //        SELECT Id,ContentDocumentId,PathOnClient, VersionData
  //        FROM ContentVersion
  //        WHERE Id IN :cIds
  //    ];
  //}

  public static Map<Id, Map<String, Object>> queryContentVersions(
    List<Id> cIds
  ) {
    Map<Id, Map<String, Object>> respMap = new Map<Id, Map<String, Object>>();

    for (Id i : cIds) {
      respMap.put(i, new Map<String, Object>());
      // respMap.get(i).
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

    // return [
    //     SELECT Id,ContentDocumentId,PathOnClient, VersionData
    //     FROM ContentVersion
    //     WHERE Id IN :cIds
    // ];
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
    String aIds = '';
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
    aIds = htmlBody.subStringBetween('ATTACHMENTIDSTART', 'ATTACHMENTIDEND')
      .replace('-', '')
      .replace('"', '');

    List<String> contentIds = new List<String>();
    if (String.isNotBlank(cvIds)) {
      contentIds = cvIds.split(';');
    }
    List<Id> contentDocumentIds = new List<Id>();

    System.debug('these are the contentIds');
    System.debug(contentIds);
    if (null != contentIds && contentIds.size() > 0) {
      try {
        Map<Id, Map<String, Object>> cvMap = queryContentVersions(contentIds);

        for (Id i : cvMap.keySet()) {
          ContentVersion cv = (ContentVersion) cvMap.get(i).get('cv');
          contentDocumentIds.add(cv.ContentDocumentId);

          Deal_Document__c dealDoc = (Deal_Document__c) cvMap.get(i).get('doc');

          if (
            dealDoc != null &&
            (dealDoc.Type__c == 'Term Sheet' ||
            dealDoc.Document_Type__c == 'Term Sheet' ||
            cv.PathOnClient.contains('TermSheet')) &&
            approved == true
          ) {
            o.Approved_Term_Sheet__c = i;
            o.Approved_Term_Sheet_Name__c = cv.PathOnClient;
            o.Term_Sheet_Approval_Date__c = System.now();
            dealDoc.Executive_Approval_Date__c = system.now();
            update dealDoc;
            update o;
            //AlchemyAPI.sendTermSheet(o.Id, dealDoc.Id);
          }
        }
      } catch (Exception ex) {
        System.debug('update opp exception');
        System.debug(ex.getLineNumber());
        System.debug(ex.getStackTraceString());
        System.debug(ex.getTypeName());
        System.debug(ex.getMessage());
        sendExceptionEmails(ex);
      }
    }

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
      AttachmentId__c = aIds,
      ContentVersionId__c = String.join(contentIds, ';'),
      Contents__c = em.plainTextBody.substring(0, contentLim)
    );
    System.debug('this is the string value of recipients');
    System.debug(String.valueOf(recipients));

    System.debug('these are the headers');
    System.debug(em.headers);
    Date emailDate;
    if (em.headers != null) {
      for (Messaging.InboundEmail.Header ieh : em.headers) {
        if (ieh.name == 'Date') {
          System.debug('check the date');
          System.debug(ieh.value);
          Integer day = Integer.valueOf(ieh.value.substring(5, 7).trim());
          Integer month = dateMap.get(ieh.value.substring(7, 11).trim());
          Integer year = Integer.valueOf(ieh.value.substring(11, 16).trim());
          emailDate = Date.newInstance(year, month, day);
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

    System.debug('this is the new email record, reached');
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
    // message.setTemplateId(templateId);
    // message.setToAddresses(new String[] {uc.Contact.Email});
    // messages.add(message);
    // messaging.sendEmail(messages);
  }

  public static void sendExceptionEmails(Exception ex) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(
      new List<String>{ 'mcastillo@mkpartners.com', 'bryon@cvest.com' }
    );

    String body = '';
    body += 'Line Number: ' + ex.getLineNumber();
    body += '\nStacktrace: ' + ex.getStackTraceString();
    body += '\nType: ' + ex.getTypeName();
    body += '\nMessage:  ' + ex.getMessage();
    email.setPlainTextbody(body);
    email.setSubject('Deal Approval Handler Error');

    Messaging.sendEmail(new List<Messaging.SIngleEmailMessage>{ email });
  }

  @future
  public static void updateDealForGlc(String dealId) {
    Opportunity deal = new Opportunity(
      Id = dealId,
      GLC_Required__c = true,
      Approval_Email_Status__c = 'Submitted to GLC'
    );

    update deal;
  }
}