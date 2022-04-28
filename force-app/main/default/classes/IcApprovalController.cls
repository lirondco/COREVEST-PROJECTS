public without sharing class IcApprovalController {
  // ! change in prod
  static final String HANDLERADDRESS = retrieveEmailServiceAddress();

  static final List<String> DEAL_TYPES = new List<String>{
    'Term Loan',
    'Bridge Loan'
  };

  // ? Setting the same group for both Bridge and Term sub IC processes because they're identical

  public static final Map<String, List<String>> EMAILSMAP = new Map<String, List<String>>{
    'Bridge IC' => queryEmailAddresses('Term_IC_Approval', 'group'),
    'Term Sub-IC' => queryEmailAddresses('Term_Sub_IC', 'group'),
    'Term IC' => queryEmailAddresses('Term_IC_Approval', 'group'),
    'Bridge Sub-IC' => queryEmailAddresses('Term_Sub_IC', 'group')
  };

  public static final Map<String, List<String>> CCMAP = new Map<String, List<String>>{
    'Term IC' => queryEmailAddresses('Micaela Lumpkin,Libby Burgeson', 'user'),
    'Term Sub-IC' => queryEmailAddresses('Libby Burgeson', 'user'),
    'Bridge IC' => queryEmailAddresses('Jimmy Rojas,Emily Bisogno', 'user'),
    'Bridge Sub-IC' => queryEmailAddresses('Libby Burgeson', 'user')
  };

  // public static final String BRIDGE_LIST = 'caf.test@cvest.com';
  // public static final String TERM_LIST = 'caf.test@cvest.com';

  public static final Map<String, String> APPROVALPROCESSES = new Map<String, String>{
    'Bridge IC' => 'Bridge_IC_Approval',
    'Term IC' => 'Term_IC_Approval',
    'Term Sub-IC' => 'Term_Sub_IC',
    'Bridge Sub-IC' => 'Bridge_Sub_IC'
  };

  public static final List<String> DOCTYPES = new List<String>{
    'Draft IC Memo',
    'Bridge Committee Memo',
    'Committee Memo'
  };

  public static final String APPROVALTYPEPICKLISTVAL = 'IC Memo';

  public static String retrieveEmailServiceAddress() {
    try {
      EmailServicesFunction emailFunction = [
        SELECT Id
        FROM EmailServicesFunction
        WHERE FunctionName = 'icApprovalHandler'
      ];

      EmailServicesAddress emailServicesAddress = [
        SELECT Id, LocalPart, EmailDomainName
        FROM EmailServicesAddress
        WHERE FunctionId = :emailFunction.Id
      ];

      return (emailServicesAddress.LocalPart +
      '@' +
      emailServicesAddress.EmailDomainName);
    } catch (Exception e) {
      throw new AuraHandledException('Error retrieving email service address. Please make sure that an Inbound Email Service was properly set up for IC Approvals. ' + e.getMessage());
    }
  }

  public static Boolean verifyPermission() {
    List<PermissionSetAssignment> permSets = [
      SELECT Id, PermissionSet.Name, AssigneeId
      FROM PermissionSetAssignment
      WHERE
        PermissionSet.Name = 'IC_Approval_Submitters'
        AND AssigneeId = :UserInfo.getUserId()
    ];

    return permSets.size() > 0;
  }

  public static List<String> queryEmailAddresses(String name, String type) {
    List<String> emailAdds = new List<String>();
    List<Id> userIds = new List<Id>();
    if (type == 'group') {
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
    } else if (type == 'user') {
      List<String> names = name.split(',');
      List<User> userList = [SELECT Email FROM User WHERE Name IN :names];
      for (User u : userList) {
        emailAdds.add(u.Email);
      }
    }
    return emailAdds;
  }

  public static List<Id> queryApproverIds(String name) {
    List<Id> userIds = new List<Id>();
    Group gp = [
      SELECT (SELECT UserOrGroupId FROM GroupMembers LIMIT 1)
      FROM Group
      WHERE DeveloperName = :name
    ];
    for (GroupMember gm : gp.GroupMembers) {
      userIds.add(gm.UserOrGroupId);
    }
    return userIds;
  }

  public static Map<String, String> loansToTemplate = new Map<String, String>{
    'Term IC' => 'Term_IC_Approval',
    'Term Sub-IC' => 'Term_Sub_IC_Approval',
    'Bridge IC' => 'Bridge_IC_Approval',
    'Bridge Sub-IC' => 'Bridge_Sub_IC_Approval'
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

  public static List<String> fields = new List<String>{
    'Opportunity.Owner.Email',
    'Name',
    'Record_Type_Name__c',
    'LOC_Program_Type__c',
    'Product_Sub_Type__c',
    'Amount',
    'Underwriter__r.Email',
    'Loan_Coordinator__r.Email',
    'Closer__r.Email',
    'IC_Approval__c',
    'StageName'
  };

  @AuraEnabled
  public static String returnDeal(Id recordId) {
    Map<String, Object> m = new Map<String, List<Object>>();
    if (!verifyPermission()) {
      m.put(
        'Error',
        new List<Object>{
          'You do not have the sufficient role to start this process.'
        }
      );
      return JSON.serialize(m);
    }
    String qs = 'SELECT ';
    qs += String.join(fields, ', ');
    qs +=
      ' FROM Opportunity WHERE Id = :recordId AND TYPE IN (\'' +
      String.join(DEAL_TYPES, '\',\'') +
      '\') AND (NOT record_type_name__c LIKE \'%Closed_Lost%\')  LIMIT 1';
    List<Opportunity> deal;
    try {
      deal = Database.query(qs);
      m.put('Deal', deal);
    } catch (AuraHandledException err) {
      System.debug(err.getMessage());
      m.put('Error', new List<AuraHandledException>{ err });
      return JSON.serialize(m);
    }

    if (deal.size() > 0) {
      Id dealId = deal[0].Id;
      List<ProcessInstance> pi = [
        SELECT Id, Status
        FROM ProcessInstance
        WHERE TargetObjectId = :dealId AND Status = 'Pending'
        LIMIT 1
      ];
      if (deal[0].StageName != 'Underwriting') {
        m.put('Error', new List<Object>{ 'Deal needs to be in Underwriting.' });
        return JSON.serialize(m);
      } else if (deal[0].IC_Approval__C == 'Approved') {
        m.put(
          'Error',
          new List<Object>{ 'Deal has already been approved by committee.' }
        );
        return JSON.serialize(m);
      } else if (pi.size() > 0) {
        m.put(
          'Error',
          new List<Object>{ 'Approval process for deal already exists.' }
        );
        return JSON.serialize(m);
      }
    } else {
      m.put('Error', new List<Object>{ 'Unable to process Deal.' });
      return JSON.serialize(m);
    }

    Integer versionNumber = 0;
    List<Deal_Document__c> ddList = [
      SELECT ContentVersion_Id__c, Attachment_Id__c, Type__c, Document_Type__c
      FROM Deal_Document__c
      WHERE
        Deal__c = :recordId
        AND ContentVersion_Id__c != NULL
        AND Document_Loaded__c = TRUE
        AND Is_Deleted__c = FALSE
        AND Document_Type__c IN :DOCTYPES
    ];

    List<Id> ddCvIds = new List<Id>();
    Set<Id> icMemoIds = new Set<Id>();
    if (null != ddList && ddList.size() > 0) {
      for (Deal_Document__c ddc : ddList) {
        versionNumber += 1;
        icMemoIds.add(ddc.ContentVersion_Id__c);
        if (null != ddc.ContentVersion_Id__c) {
          ddCvIds.add(ddc.ContentVersion_Id__c);
        }
      }
    }

    List<ContentVersion> cvList = [
      SELECT Id, PathOnClient, Description
      FROM ContentVersion
      WHERE Id IN :ddCvIds
    ];

    for (ContentVersion cv : cvList) {
      if (icMemoIds.contains(cv.Id)) {
        cv.Description = 'IC Memo';
      }
    }

    if (versionNumber == 0) {
      m.put('Error', new List<String>{ 'Unable to retrieve IC Memo.' });
      return JSON.serialize(m, true);
    }
    String oRecordType;
    List<Person> p = new List<Person>{ new Person().currentUser() };
    EmailTemplate e;
    String approvalType;
    oRecordType = deal[0].Record_Type_Name__c;
    if (null != deal && deal.size() > 0) {
      if (oRecordType == 'LOC_Loan') {
        if ((Decimal) deal[0].Amount > 3000000) {
          approvalType = 'Bridge IC';
        } else {
          approvalType = 'Bridge Sub-IC';
        }
      } else {
        if ((Decimal) deal[0].Amount > 2000000) {
          approvalType = 'Term IC';
        } else {
          approvalType = 'Term Sub-IC';
        }
      }

      m.put('ApprovalType', new List<String>{ approvalType });

      List<EmailTemplate> eList = queryEmailTemplate(
        loansToTemplate.get(approvalType)
      );
      m.put('eList', eList);
      if (eList.size() > 0) {
        e = eList[0];
      }
    }
    if (deal.size() > 0 && null != e) {
      Messaging.SingleEmailMessage mail;
      mail = Messaging.renderStoredEmailTemplate(
        e.Id,
        null,
        (Id) deal[0].get('Id')
      );
      m.put('EmailContents', new List<Object>{ mail.getHTMLBody() });
      m.put('Subject', new List<Object>{ mail.getSubject() });
    }
    m.put('Recipients', new List<Object>{ EMAILSMAP.get(approvalType) });
    if (null != oRecordType && oRecordType == 'Term_Loan') {
      m.put('CC', CCMAP.get(approvalType));
    }
    if (null != oRecordType && oRecordType == 'LOC_Loan') {
      m.put('CC', CCMAP.get(approvalType));
    }
    m.put('ContentVersions', cvList);
    m.put('CurrentUser', p);
    return JSON.serialize(m, true);
  }

  public static List<EmailTemplate> queryEmailTemplate(String templateName) {
    return [
      SELECT Id, Body
      FROM EmailTemplate
      WHERE DeveloperName = :templateName
      LIMIT 1
    ];
  }

  public static List<ContentVersion> queryContentVersions(List<Id> cIds) {
    return [
      SELECT PathOnClient, VersionData, FileType
      FROM ContentVersion
      WHERE Id IN :cIds
    ];
  }

  public static Messaging.EmailFileAttachment constructFileAttachment(
    ContentVersion cv
  ) {
    Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
    if (cv != null) {
      file.setFileName(cv.PathOnClient);
      if (null != cv.FileType) {
        file.setContentType('application/' + cv.FileType.toLowerCase());
      }
      file.setBody(cv.VersionData);
    }

    return file;
  }

  @AuraEnabled
  public static String sendEmail(String s, String attachIds) {
    Map<String, String> m = (Map<String, String>) JSON.deserialize(
      s,
      Map<String, String>.class
    );

    try {
      submitApproval((Id) m.get('recordId'), m.get('approvalType'));
    } catch (AuraHandledException e) {
      System.debug(e.getMessage());
      Map<String, String> err = new Map<String, String>{
        'Error' => 'FROM SUBMIT APPROVAL' + e.getMessage()
      };
      return JSON.serialize(err);
    }
    List<String> recipientEmails = m.get('recipients').split(';');
    List<String> ccEmails = String.isNotEmpty(m.get('cc'))
      ? m.get('cc').split(';')
      : new List<String>();

    List<Id> aIds = (List<Id>) JSON.deserialize(attachIds, List<Id>.class);
    List<Messaging.EmailFileAttachment> attachmentsList = new List<Messaging.EmailFileAttachment>();
    for (ContentVersion a : queryContentVersions(aIds)) {
      attachmentsList.add(constructFileAttachment(a));
    }

    List<String> addresses = new List<String>{ HANDLERADDRESS };
    addresses.addAll(recipientEmails);

    String body = '';

    body +=
      '<span style="display:none;">--DEALIDSTART--' +
      m.get('recordId') +
      '--DEALIDEND--';
    body += '--CONTENTIDSTART--';
    if (null != aIds & aIds.size() > 0) {
      for (Id aId : aIds) {
        body += aId + ';';
      }
    }

    body += '--CONTENTIDEND--</span>';
    body += m.get('emailBody');

    try {
      sendMail(
        addresses,
        m.get('subject'),
        body,
        attachmentsList,
        ccEmails,
        m.get('user'),
        null,
        null,
        null,
        null,
        null
      );
    } catch (Exception err) {
      Map<String, String> e = new Map<String, String>{
        'Error' => 'FROM SEND MAIL' + err.getMessage()
      };
      return JSON.serialize(e);
    }
    Map<String, String> r = new Map<String, String>{
      'Success' => 'Email Sent'
    };
    return JSON.serialize(r);
  }

  public static Opportunity queryOpportunity(Id recordId) {
    return [
      SELECT
        Id,
        Name,
        Deposit_Amount__c,
        Amortization_Term__c,
        Final_Spread__c,
        StageName,
        Recourse__c,
        Foreign_National__c,
        Broker_Fees__c,
        Term_Loan_Type__c,
        Cash_Management__c,
        Current_Loan_Amount__c,
        YSP_perc__c,
        Property_Management__c,
        Property_Management_Adjustment__c,
        CAF_Upfront_Fee__c
      FROM Opportunity
      WHERE Id = :recordId
    ];
  }

  public static void submitApproval(Id recordId, String approvalType) {
    Savepoint sp = Database.setSavepoint();
    try {
      Id userId = UserInfo.getUserId();

      String processName = APPROVALPROCESSES.get(approvalType);

      Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
      req.setObjectId(recordId);
      req.setSubmitterId(userId);
      req.setSkipEntryCriteria(true);
      req.setProcessDefinitionNameOrId(processName);
      // req.setNextApproverIds(
      //   queryApproverIds(APPROVALPROCESSES.get(approvalType))
      // );
      Approval.ProcessResult result = Approval.process(req);
      Id processInstanceId = result.getInstanceId();
      String status = result.getInstanceStatus();
      List<Id> workItemIds = result.getNewWorkitemIds();

      Opportunity deal = queryOpportunity(recordId);

      String dealStage = deal.StageName;

      String ahProcessName = (approvalType != 'Term Sub-IC' ||
        approvalType != 'Bridge Sub-IC')
        ? approvalType + ' Process'
        : approvalType;
      List<Approval_History__c> ahList = new List<Approval_History__c>();
      Approval_History__c ahc = new Approval_History__c(
        Process_Instance_Id__c = processInstanceId,
        Parent_Status__c = status,
        Deal__c = recordId,
        Name = 'Approval Request: ' + deal.Name.left(50),
        ProcessName__c = ahProcessName,
        Approver__c = UserInfo.getName(),
        Actor__c = UserInfo.getUserId(),
        Role__c = 'Submitter',
        Date_Acted__c = System.now(),
        Status__c = 'Submitted',
        Status_Text__c = 'Submitted',
        Approval_Type__c = APPROVALTYPEPICKLISTVAL,
        Tracking_Status__c = 'Closer',
        Deal_Stage_At_Time_of_Submission__c = dealStage
      );

      if (deal.Final_Spread__c != null) {
        ahc.Spread__c = deal.Final_Spread__c;
      }

      ahc.Origination_Fee__c = deal.CAF_Upfront_Fee__c;

      ahList.add(ahc);

      // TODO: loop through the actual work items
      for (ProcessInstanceWorkitem workItem : [
        SELECT Id, ActorId, Actor.Name
        FROM ProcessInstanceWorkItem
        WHERE Id IN :workItemIds
      ]) {
        Approval_History__c a = new Approval_History__c(
          Process_Instance_Id__c = processInstanceId,
          Process_Id__c = workItem.Id,
          ProcessName__c = ahProcessName,
          Actor__c = workItem.ActorId,
          Parent_Status__c = status,
          Deal__c = recordId,
          Name = 'Approval Request: ' + deal.Name.left(50),
          Approver__c = workItem.Actor.Name, // actor.name
          Status__c = 'Pending',
          Status_Text__c = 'Pending: Committee Review',
          Date_Acted__c = System.now(),
          Approval_Type__c = APPROVALTYPEPICKLISTVAL,
          Deal_Stage_At_Time_of_Submission__c = dealStage,
          Tracking_Status__c = 'Committee'
        );

        if (deal.Final_Spread__c != null) {
          a.Spread__c = deal.Final_Spread__c;
        }

        ahList.add(a);
      }
      insert ahList;
    } catch (Exception e) {
      Database.rollback(sp);
      throw new AuraHandledException(e.getMessage());
    }
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