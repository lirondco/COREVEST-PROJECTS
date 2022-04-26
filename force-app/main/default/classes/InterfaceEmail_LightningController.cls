public without sharing class InterfaceEmail_LightningController {
  // Opportunity.OwnerId, CAF Originator (Lookup on User)
  // Opportunity.Closer__c, Closer (Lookup on User)
  // Opportunity.Guarantor__c, Guarantor (Lookup on Contact)
  // Opportunity.Internal_Referral__c, Internal Referral (Lookup on User)
  // Opportunity.Loan_Coordinator__c, Loan Coordinator (Lookup on User)
  // Opportunity.Primary_Contact__c, Primary Contact (Lookup on Contact)
  // Opportunity.Underwriter__c, Underwriter (Lookup on User)

  // Opportunity.Counsel__c, Counsel (Lookup on Account)
  // Opportunity.Insurance__c, Insurance__c (Lookup on Account)
  // Opportunity.Title__c, Title__c (Lookup on Account)
  // Opportunity.PNC__c (Lookup on Account)

  // public static final String emailAddress = 'dealapprovalhandler@1rcof8n96wj6plns2owu5ajq75yd8wlpy914j3zbt9jk5bfree.2f-crgzuas.cs91.apex.sandbox.salesforce.com';

  // public static final String emailAddress = 'deal_approval_handler@1-2ubmvsr19x7o406nnymb5zkfzbl7wsflro23z72qyy25g7hr6z.5c-8jnxuay.cs62.apex.sandbox.salesforce.com';
  // public static final String emailAddress = 'dealapprovalhandler@pyo7p2pzqqm356qd6r207z35fsfvn6429vh6lwamowp6ctfb5.j-l4sceas.na54.apex.salesforce.com';
  public static final String emailAddress = retrieveEmailServiceAddress();
  public static final String BETH = queryEmailAddress('Beth O\'Brien')
    .Email_Address__c;
  // public static final String RYAN = queryEmailAddress('Ryan McBride')
  //   .Email_Address__c;
  public static final String CHRIS = queryEmailAddress('Chris Hoeffel')
    .Email_Address__c;
  public static final String BRAD = queryEmailAddress('Brad Chmura')
    .Email_Address__c;
  public static final String MICAELA = queryEmailAddress('Micaela Lumpkin')
    .Email_Address__c;
  public static final String MATT = queryEmailAddress('Matthew Orrino')
    .Email_Address__c;
  public static final String BRYON = queryEmailAddress('Bryon Harland')
    .Email_Address__c;
  public static final String BRIDGE_LIST = queryEmailAddress(
      'Bridge Term Sheet Mailing List'
    )
    .Email_Address__c;
  public static final String TERM_LIST = queryEmailAddress(
      'Term Sheet Mailing List'
    )
    .Email_Address__c;

  // public static final String BRIDGE_LIST = 'caf.test@cvest.com';
  // public static final String TERM_LIST = 'caf.test@cvest.com';

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
      setting = new Email_Addresses__c(Name = name, Email_Address__c = '');
      if (Test.isRunningTest()) {
        setting.Email_Address__c = userInfo.getUserEmail();
      }
    }
    return setting;
  }

  // public static final String termDistList = m.get('Term Sheet Request').Email_Address__c;
  // public static final String bridgeDistList = m.get('Bridge Term Sheet Request').Email_Address__c;

  // public static Map<String,Email_Addresses__c> m = Email_Addresses__c.getAll();
  // public static final String emailAddress = m.get('dealApprovalHandler').Value__c;
  // public static final String termDistList = m.get('Term Sheet Request').Value__c;
  // public static final String bridgeDistList = m.get('Bridge Term Sheet Request').Value__c;
  //
  // User userBeth = [
  //     SELECT Id,Email
  //     FROM User
  //     WHERE Name = 'Beth O\'Brien'
  //     LIMIT 1
  // ];
  //
  // User userRyan = [
  //     SELECT Id,Email
  //     FROM User
  //     WHERE Name = 'Ryan McBride'
  //     LIMIT 1
  // ];
  // public static final String BETH = userBeth.Email;
  // public static final String RYAN = userRyan.Email;

  public static List<String> fields = new List<String>{
    // 'Opportunity.OwnerId',
    // 'Opportunity.Closer__c',
    // 'Opportunity.Internal_Referral__c',
    // 'Opportunity.Loan_Coordinator__c',
    // 'Opportunity.Contact__c',
    // 'Opportunity.Underwriter__c',

    'Opportunity.Owner.Email',
    // 'Opportunity.Closer__r.Email',
    // 'Opportunity.Internal_Referral__r.Email',
    // 'Opportunity.Loan_Coordinator__r.Email',
    // 'Opportunity.Contact__r.Email',
    // 'Opportunity.Underwriter__r.Email',

    // 'Opportunity.Owner.Name',
    // 'Opportunity.Closer__r.Name',
    // 'Opportunity.Internal_Referral__r.Name',
    // 'Opportunity.Loan_Coordinator__r.Name',
    // 'Opportunity.Contact__r.Name',
    // 'Opportunity.Underwriter__r.Name',
    'Name',
    'Record_Type_Name__c',
    'LOC_Program_Type__c',
    'Product_Sub_Type__c'
  };

  // public static Map<String,String> loansToTemplate = new Map<String,String>{
  //     'Term Loan' => 'TERM_Term_Sheet_Request',
  //     'LOC Loan Outside Guidelines' => 'BRIDGE_Term_Sheet_Request',
  //     'LOC Loan Within Guidelines' => 'BRIDGE_Term_Sheet_Request_Within_Pricing_Guidelines'
  // };

  public static Map<String, String> loansToTemplate = new Map<String, String>{
    'Term_Loan' => 'TERM_Term_Sheet_Request_VF',
    'LOC Loan Outside Guidelines' => 'BRIDGE_Term_Sheet_Outside_Guidelines_VF',
    'LOC Loan Within Guidelines' => 'BRIDGE_Term_Sheet_Within_Guidelines_VF'
  };

  public class Person {
    public Id Id;
    public String Name;
    public String Email;

    public Person currentUser() {
      Id = UserInfo.getUserId();
      Name = UserInfo.getUserId();
      Email = UserInfo.getUseremail();
      return this;
    }
  }

  @AuraEnabled
  public static String returnDeal(Id recordId) {
    Map<String, Object> m = new Map<String, List<Object>>();
    String qs = 'SELECT ';
    qs += String.join(fields, ', ');
    qs += ' FROM Opportunity WHERE Id = :recordId';

    List<sObject> oList = Database.query(qs);
    Opportunity o;

    String oRecordType;
    if (null != oList && oList.size() > 0) {
      o = (Opportunity) oList[0];
      oRecordType = o.Record_Type_Name__c;
      if (oRecordType == 'LOC_Loan' || oRecordType.contains('Bridge')) {
        // query for history
        //if (null == o.Product_Sub_Type__c){
        //    m.put('ValidationError', new List<String>{'true'});
        //    return JSON.serialize(m, true);
        //}

        if (
          null != o.LOC_Program_Type__c &&
          o.LOC_Program_Type__c == 'Custom'
        ) {
          List<ProcessInstance> pList = [
            SELECT Id, Status
            FROM ProcessInstance
            WHERE
              TargetObjectId = :o.Id
              AND (ProcessDefinition.Name = 'Bridge (LOC) Pricing Review'
              OR ProcessDefinition.Name = 'Bridge LOC Pricing Review-Capital Market'
              OR ProcessDefinition.Name = 'Standard SAB Pricing Review'
              OR ProcessDefinition.Name = 'Custom SAB Pricing Review')
            ORDER BY CreatedDate DESC
            LIMIT 1
          ];

          if (null == pList || pList.size() <= 0) {
            m.put('Error', new List<String>{ 'true' });
            return JSON.serialize(m, true);
          }

          if (pList[0].Status != 'Approved' && !Test.isRunningTest()) {
            m.put('Error', new List<String>{ 'true' });
            return JSON.serialize(m, true);
          }

          // List<ProcessInstanceStep> pis = [
          //     SELECT StepStatus
          //     FROM ProcessInstanceStep
          //     WHERE ProcessInstanceId = :pList[0].Id
          // ];

          // if (null != pis && pis.size() > 0){
          //     Boolean allApproved = true;
          //     for (ProcessInstanceStep p : pis){
          //         if (p.StepStatus != 'Approved' && p.StepStatus != 'Started'){
          //             allApproved = false;
          //             m.put('Error', new List<String>{'true'});
          //             return JSON.serialize(m, true);
          //         }
          //     }
          // if (allApproved == true){
          oRecordType = 'LOC Loan Outside Guidelines';
          //     } else {
          //         oRecordType = null;
          //         m.put('Error', new List<String>{'true'});
          //         return JSON.serialize(m, true);
          //     }
          // } else {
          //     m.put('Error', new List<String>{'true'});
          //     return JSON.serialize(m, true);
          // }
        } else if (
          null != o.LOC_Program_Type__c &&
          o.LOC_Program_Type__c == 'Standard'
        ) {
          System.debug('inside standard loan');
          oRecordType = 'LOC Loan Within Guidelines';
        } else {
          m.put('Error', new List<String>{ 'true' });
          return JSON.serialize(m, true);
        }
      } else if (oRecordType == 'Term_Loan') {
        List<ProcessInstance> pList = [
          SELECT Id, Status
          FROM ProcessInstance
          WHERE
            TargetObjectId = :o.Id
            AND (ProcessDefinition.Name = 'Term Pricing Review'
            OR ProcessDefinition.Name = 'Term Pricing Review - Capital Markets')
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];

        if (null == pList || pList.size() <= 0) {
          m.put('Error', new List<String>{ 'true' });
          return JSON.serialize(m, true);
        }

        if (pList[0].Status != 'Approved' && !Test.isRunningTest()) {
          m.put('Error', new List<String>{ 'true' });
          return JSON.serialize(m, true);
        }

        // List<ProcessInstanceStep> pis = [
        //     SELECT StepStatus
        //     FROM ProcessInstanceStep
        //     WHERE ProcessInstanceId = :pList[0].Id
        // ];

        // if (null != pis && pis.size() > 0){
        //     Boolean allApproved = true;
        //     for (ProcessInstanceStep p : pis){
        //         if (p.StepStatus != 'Approved' && p.StepStatus != 'Started'){
        //             allApproved = false;
        //             m.put('Error', new List<String>{'true'});
        //             return JSON.serialize(m, true);
        //         }
        //     }
        //     if (allApproved == true){
        //     } else {
        //         oRecordType = null;
        //         m.put('Error', new List<String>{'true'});
        //         return JSON.serialize(m, true);
        //     }
        // } else {
        //     m.put('Error', new List<String>{'true'});
        //     return JSON.serialize(m, true);
        // }
      } // closes if LOC Loan
    } // closes oList not null

    //query for contentversion
    // List<ContentDocumentLink> cdlList = [
    //     SELECT ContentDocumentId
    //     FROM ContentDocumentLink
    //     WHERE LinkedEntityId = :recordId
    // ];
    //
    // List<Id> cdi = new List<Id>();
    // for (ContentDocumentLink cdl : cdlList){
    //     if (null != cdl.ContentDocumentId){
    //         cdi.add(cdl.ContentDocumentId);
    //     }
    // }

    Integer versionNumber = 0;
    List<Deal_Document__c> ddList = [
      SELECT ContentVersion_Id__c, Attachment_Id__c, Type__c, Document_Type__c
      FROM Deal_Document__c
      WHERE
        Deal__c = :recordId
        AND ContentVersion_Id__c != NULL
        AND Document_Loaded__c = TRUE
        AND Is_Deleted__c = FALSE
        AND Include_for_Term_Sheet_Approval__c = TRUE
      // Type__c = 'Term Sheet'
    ];

    List<Id> ddCvIds = new List<Id>();
    Set<Id> termSheetIds = new Set<Id>();
    if (null != ddList && ddList.size() > 0) {
      for (Deal_Document__c ddc : ddList) {
        if (
          'Term Sheet' == ddc.Type__c ||
          'Term Sheet' == ddc.Document_Type__c
        ) {
          versionNumber += 1;
          termSheetIds.add(ddc.ContentVersion_Id__c);
        }
        if (null != ddc.ContentVersion_Id__c) {
          ddCvIds.add(ddc.ContentVersion_Id__c);
        }
      }
    }

    //
    // System.debug('this is ddList');
    // System.debug(ddList);
    // System.debug('these are ddCvIds');
    // System.debug(ddCvIds);
    //
    // List<ContentVersion> compiledCv = new List<ContentVersion>();
    List<ContentVersion> cvList = [
      SELECT Id, PathOnClient, Description
      FROM ContentVersion
      WHERE Id IN :ddCvIds
    ];

    for (ContentVersion cv : cvList) {
      if (termSheetIds.contains(cv.Id)) {
        cv.Description = 'Termsheet';
      }
    }

    // if (null != cvList && cvList.size() > 0){
    //     compiledCv.addAll(cvList);
    // }
    //
    // List<ContentVersion> cvList2 = [
    //     SELECT Id,PathOnClient
    //     FROM ContentVersion
    //     WHERE Id IN :ddCvIds
    // ];
    // if (null != cvList2 && cvList2.size() > 0){
    //     compiledCv.addAll(cvList2);
    // }
    //
    // System.debug('these are the files in cvList');
    // System.debug(cvList);
    //
    // Boolean exists = false;
    // for (ContentVersion cv : cvList){
    //     if (cv.PathOnClient.contains('TermSheet')){
    //         exists = true;
    //     }
    // }

    List<Person> p = new List<Person>{ new Person().currentUser() };
    EmailTemplate e;
    // Contact c = [
    //     SELECT Id FROM Contact LIMIT 1
    // ];

    if (versionNumber == 0) {
      // m.put('Error', new List<String>{'true'});
      m.put('TermSheetError', new List<String>{ 'true' });
      return JSON.serialize(m, true);
    }

    system.debug('--record type--');
    system.debug(oRecordType);
    if (null != oList && oList.size() > 0 && null != oRecordType) {
      List<EmailTemplate> eList = queryEmailTemplate(
        loansToTemplate.get(oRecordType)
      );
      if (eList.size() > 0) {
        e = eList[0];
      }
    }
    if (oList.size() > 0 && null != e) {
      Messaging.SingleEmailMessage mail;
      // Savepoint sp = Database.setSavepoint();
      // mail = sendMail(
      //     new String[]{'wluk@mkpartners.com'}, null, null, null, null,
      //     'WLUK', true, true, c.Id, e.Id, (Id)oList[0].get('Id')
      // );
      // Database.rollback(sp);

      mail = Messaging.renderStoredEmailTemplate(
        e.Id,
        null,
        (Id) oList[0].get('Id')
      );
      m.put('EmailContents', new List<Object>{ mail.getHTMLBody() });
      m.put('Subject', new List<Object>{ mail.getSubject() });
    }
    // replace in body w/ opp details
    m.put('Recipients', new List<Object>{ BRAD, MICAELA, MATT });
    if (null != oRecordType && oRecordType == 'Term_Loan') {
      m.put(
        'CC',
        new List<Object>{ o.Owner.Email, TERM_LIST, BETH, CHRIS }
      );
    }
    if (
      null != oRecordType &&
      (oRecordType.contains('LOC_Loan') ||
      oRecordType.contains('Bridge') ||
      oRecordType.contains('LOC'))
    ) {
      m.put(
        'CC',
        new List<Object>{ o.Owner.Email, BRIDGE_LIST, BETH, CHRIS }
      );
    }
    m.put('ContentVersions', cvList);
    m.put('CurrentUser', p);
    return JSON.serialize(m, true);
  }
  // close Return the Deal

  public static List<EmailTemplate> queryEmailTemplate(String templateName) {
    return [
      SELECT Id, Body
      FROM EmailTemplate
      WHERE DeveloperName = :templateName
      LIMIT 1
    ];
  }

  public static List<Attachment> queryAttachments(List<Id> aIds) {
    return [SELECT Name, Body, ContentType FROM Attachment WHERE Id IN :aIds];
  }

  public static List<ContentVersion> queryContentVersions(List<Id> cIds) {
    return [
      SELECT PathOnClient, VersionData, FileType
      FROM ContentVersion
      WHERE Id IN :cIds
    ];
  }

  public static Messaging.EmailFileAttachment constructFileAttachment(
    Attachment a
  ) {
    Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
    file.setFileName(a.Name);
    if (null != a.ContentType) {
      file.setContentType('application/' + a.ContentType.toLowerCase());
    }
    file.setBody(a.Body);
    return file;
  }

  public static Messaging.EmailFileAttachment constructFileAttachment(
    ContentVersion cv
  ) {
    Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
    file.setFileName(cv.PathOnClient);
    if (null != cv.FileType) {
      file.setContentType('application/' + cv.FileType.toLowerCase());
    }
    file.setBody(cv.VersionData);
    return file;
  }

  @AuraEnabled
  public static void sendEmail(String s, String attachIds, String cvIds) {
    Map<String, String> m = (Map<String, String>) JSON.deserialize(
      s,
      Map<String, String>.class
    );
    System.debug('this is m');
    System.debug(m.get('recipients'));
    System.debug(m.get('ccUsers'));

    List<String> recipientEmails = m.get('recipients').split(';');
    List<String> ccEmails = m.get('ccUsers').split('; ');

    List<Id> aIds = (List<Id>) JSON.deserialize(attachIds, List<Id>.class);
    List<Id> cIds = (List<Id>) JSON.deserialize(cvIds, List<Id>.class);
    List<Messaging.EmailFileAttachment> attachmentsList = new List<Messaging.EmailFileAttachment>();
    for (Attachment a : queryAttachments(aIds)) {
      attachmentsList.add(constructFileAttachment(a));
    }
    for (ContentVersion cv : queryContentVersions(cIds)) {
      attachmentsList.add(constructFileAttachment(cv));
    }

    List<String> addresses = new List<String>{ emailAddress };
    addresses.addAll(recipientEmails);

    String body = '';

    body +=
      '<span style="display:none;">--DEALIDSTART--' +
      m.get('recordId') +
      '--DEALIDEND--';
    body += '--ATTACHMENTIDSTART--';
    if (null != aIds & aIds.size() > 0) {
      for (Id aId : aIds) {
        body += aId + ';';
      }
    }
    body += '--ATTACHMENTIDEND--';
    body += '--CONTENTIDSTART--';
    if (null != cIds & cIds.size() > 0) {
      for (Id cId : cIds) {
        body += cId + ';';
      }
    }
    body += '--CONTENTIDEND--</span>';
    body += m.get('emailMessage');

    // if (String.isNotBlank(m.get('selectedCC'))){
    //     List<String> ccAddresses = m.get('selectedCC').split(';');
    //     body += '<span style="display:none;">--CCSTART--';
    //     for (String cc : ccAddresses){
    //         body += cc + ';';
    //     }
    //     body += '--CCEND--</span>';
    // }

    System.debug('these are the people included in IE_LC: ');
    System.debug(addresses);
    Opportunity op = [
      SELECT Contact__c, Id FROM Opportunity WHERE Id = :m.get('recordId')
    ];
    sendMail(
      addresses,
      m.get('emailSubject'),
      body,
      attachmentsList,
      ccEmails,
      m.get('currentUser'),
      null,
      true,
      op.Contact__c,
      null,
      op.Id
    );
  }

  public static Messaging.SingleEmailMessage sendMail(
    List<String> toAddresses,
    String subject,
    String htmlBody,
    List<Messaging.EmailFileAttachment> fileAttachments,
    List<String> ccAddresses,
    String senderDislayName,
    Boolean useSignature,
    Boolean saveAsActivity,
    Id targetObjectId,
    Id templateId,
    Id whatId
  ) {
    Messaging.reserveSingleEmailCapacity(1);
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    if (toAddresses != null && toAddresses.size() > 0) {
      mail.setToAddresses(toAddresses);
    }
    if (String.isNotblank(subject)) {
      mail.setSubject(subject);
    }
    if (String.isNotBlank(htmlBody)) {
      mail.setHtmlBody(htmlBody);
    }
    if (fileAttachments != null && fileAttachments.size() > 0) {
      mail.setFileAttachments(fileAttachments);
    }
    if (ccAddresses != null && ccAddresses.size() > 0) {
      mail.setCcAddresses(ccAddresses);
    }
    if (String.isNotBlank(senderDislayName)) {
      mail.setSenderDisplayName(senderDislayName);
    }
    if (useSignature != null) {
      mail.setUseSignature(false);
    }
    if (saveAsActivity != null) {
      mail.setSaveAsActivity(saveAsActivity);
    }
    if (targetObjectId != null) {
      mail.setTargetObjectId(targetObjectId);
      mail.setTreatTargetObjectAsRecipient(false);
    }
    if (templateId != null) {
      mail.setTemplateId(templateId);
    }
    if (whatId != null) {
      mail.setWhatId(whatId);
    }
    System.debug('this is the mail being sent');
    System.debug(mail);
    if (!Test.isRunningTest()) {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ mail }
      );
      System.debug('these are the results of sending your initial email: ');
      System.debug(results);
    }
    return mail;
  }
}