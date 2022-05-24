public without sharing class ConfirmationOfTermsController {
  public static final EmailTemplate template = [
    SELECT
      Id,
      Name,
      DeveloperName,
      NamespacePrefix,
      Body,
      HtmlValue,
      Markup,
      Subject,
      Description,
      TemplateType,
      IsActive
    FROM EmailTemplate
    WHERE DeveloperName = 'Confirmation_of_Terms'
  ];
  // can change if needed
  public static String APPROVED_COMMENT = 'Approval Status: Approved';
  public static String REJECTED_COMMENT = 'Approval Status: Rejected';
  public static String RECALLED_COMMENT = 'Approval Status: Recalled';
  public static String SUBMITTED_COMMENT = 'Approval Status: Pending';
  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
  .isSandbox;
  @AuraEnabled
  public static List<Map<String, String>> getApprovalPicklists(Id recordId) {
    List<Map<String, String>> picklists = new List<Map<String, String>>();
    picklists.add(new Map<String, String>{ 'label' => '', 'value' => '' });

    for (Approval_History__c history : [
      SELECT Id, Status__c, Process_Instance_Id__c, CreatedDate
      FROM Approval_History__c
      WHERE
        Tracking_Status__c = 'Closer'
        AND Approval_Type__c = 'Confirmation Of Terms'
        AND Deal__c = :recordId
      ORDER BY CREATEDDATE DESC
    ]) {
      String label =
        'Submission ' +
        history.CreatedDate.date().format() +
        ' - ' +
        history.Status__c;
      String value = history.Process_Instance_Id__c;
      picklists.add(
        new Map<String, String>{ 'label' => label, 'value' => value }
      );
    }

    return picklists;
  }

  @AuraEnabled
  public static Map<String, List<String>> getDependentPicklistValues(String loanTerm) {
    // YM_Prepayment_Penalty__c
    // Stepdown_Prepayment_Period__c
    // Term_Loan_Type__c

    Map<String, List<String>> picklists = new Map<String, List<String>>();
    picklists.put('YM_Prepayment_Penalty__c', new List<String>());
    picklists.put('Stepdown_Prepayment_Period__c', new List<String>());

    if(String.isNotEmpty(loanTerm)) {
      Map<String, List<String>> ymPrepayAll = lightning_Util.GetDependentOptions('Opportunity', 'Term_Loan_Type__c','YM_Prepayment_Penalty__c');
      Map<String, List<String>> stepdownPrepayAll = lightning_Util.GetDependentOptions('Opportunity', 'Term_Loan_Type__c','Stepdown_Prepayment_Period__c');
      if(ymPrepayAll.containsKey(loanTerm)) {
        picklists.put('YM_Prepayment_Penalty__c', ymPrepayAll.get(loanTerm));
      }
      if(stepdownPrepayAll.containsKey(loanTerm)) {
        picklists.put('Stepdown_Prepayment_Period__c', stepdownPrepayAll.get(loanTerm));
      }
    }

    return picklists;
  }

  private static void sendEmailForConfirmation(
    Id approvalHistoryID,
    Id oppRecordID,
    string submittedBy
  ) {
    Opportunity opp = [
      SELECT
        id,
        Name,
        Contact__c,
        Contact__r.Name,
        Contact__r.Phone,
        Contact__r.Email,
        Contact__r.MailingStreet,
        Contact__r.MailingCity,
        Contact__r.MailingState,
        Contact__r.MailingPostalCode,
        Closer__r.Email,
        Closer__r.Name,
        Closer__c,
        Owner.Email,
        Owner.Name,
        OwnerId,
        CAF_Analyst__r.Email,
        Underwriter__r.Email,
        Underwriter__r.Name,
        Underwriter__c
      FROM Opportunity
      WHERE id = :oppRecordID
      LIMIT 1
    ];

    // get detail about original submitter
    List<Approval_History__c> appHis = [
      SELECT Id, Actor__r.Email, Actor__c
      FROM Approval_History__c
      WHERE
        Deal__c = :oppRecordID
        AND Status__c = 'Submitted'
        AND Approval_Type__c = 'Confirmation Of Terms'
        AND Tracking_Status__c = 'Closer'
        AND Role__c = 'Submitter'
      ORDER BY Date_Acted__c DESC
      LIMIT 1
    ];

    Set<String> emailAddressSet = new Set<String>();
    Map<String, Object> senderInfo = new Map<String, Object>();
    Set<Id> recipientIds = new Set<Id>();

    if (appHis.size() > 0) {
      emailAddressSet.add(appHis[0].Actor__r.Email);
      recipientIds.add(appHis[0].Actor__c);
    }

    if (submittedBy == 'Closer') {
      createTask(submittedBy, oppRecordId, false, '');
      emailAddressSet.add(opp.Closer__r.Email);
      emailAddressSet.add(opp.Owner.Email);
      senderInfo.put('Id', opp.Closer__c);
      senderInfo.put('Name', opp.Closer__r.Name);
      senderInfo.put('Email', opp.Closer__r.Email);
      recipientIds.add(opp.Closer__c);
      recipientIds.add(opp.OwnerId);
      // toEmailAddressList.add(opp.Closer__r.Email);
      // toEmailAddressList.add(opp.Owner.Email);
      if (opp.CAF_Analyst__r.Email != null && opp.CAF_Analyst__r.Email != '') {
        // toEmailAddressList.add(opp.CAF_Analyst__r.Email);
        emailAddressSet.add(opp.CAF_Analyst__r.Email);
        recipientIds.add(opp.CAF_Analyst__c);
      }
      // toEmailAddressList.add(opp.Underwriter__r.Email);
      emailAddressSet.add(opp.Underwriter__r.Email);
      recipientIds.add(opp.Underwriter__c);
    } else if (submittedBy == 'Originator') {
      // toEmailAddressList.add(opp.Closer__r.Email);
      // toEmailAddressList.add(opp.Owner.Email);
      // toEmailAddressList.add(opp.Underwriter__r.Email);
      senderInfo.put('Id', opp.OwnerId);
      senderInfo.put('Name', opp.Owner.Name);
      senderInfo.put('Email', opp.Owner.Email);
      emailAddressSet.add(opp.Closer__r.Email);
      emailAddressSet.add(opp.Owner.Email);
      emailAddressSet.add(opp.Underwriter__r.Email);
      recipientIds.add(opp.Closer__c);
      recipientIds.add(opp.OwnerId);
      recipientIds.add(opp.Underwriter__c);

      if (opp.CAF_Analyst__r.Email != null && opp.CAF_Analyst__r.Email != '') {
        // toEmailAddressList.add(opp.CAF_Analyst__r.Email);
        emailAddressSet.add(opp.CAF_Analyst__r.Email);
        recipientIds.add(opp.CAF_Analyst__c);
      }
    } else if (submittedBy == 'Underwriter') {
      // toEmailAddressList.add(opp.Closer__r.Email);
      // toEmailAddressList.add(opp.Owner.Email);
      senderInfo.put('Id', opp.Underwriter__c);
      senderInfo.put('Name', opp.Underwriter__r.Name);
      senderInfo.put('Email', opp.Underwriter__r.Email);
      emailAddressSet.add(opp.Closer__r.Email);
      emailAddressSet.add(opp.Owner.Email);
      recipientIds.add(opp.Closer__c);
      recipientIds.add(opp.OwnerId);
      recipientIds.add(opp.Underwriter__c);
      if (opp.CAF_Analyst__r.Email != null && opp.CAF_Analyst__r.Email != '') {
        // toEmailAddressList.add(opp.CAF_Analyst__r.Email);
        emailAddressSet.add(opp.CAF_Analyst__r.Email);
        recipientIds.add(opp.CAF_Analyst__c);
      }
      // toEmailAddressList.add(opp.Underwriter__r.Email);
      emailAddressSet.add(opp.Underwriter__r.Email);
      recipientIds.add(opp.Underwriter__c);
    }

    list<string> toEmailAddressList = new List<String>();
    toEmailAddressList.addAll(emailAddressSet);
    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    list<string> ccEmailAddressList = new List<string>();
    //ccEmailAddressList.add('micaela.lumpkin@cvest.com');
    //ccEmailAddressList.add('sbhumani@gmail.com');
    // ccEmailAddressList.add('mcastillo@mkpartners.com');

    list<string> bccEmails = new List<string>();
    if (isSandbox) {
      bccEmails.add('bryon.harland@cvest.com.invalid');
    } else {
      bccEmails.add('bryon.harland@cvest.com');
    }

    system.debug('toEmailAddressList:::::' + toEmailAddressList);

    Messaging.SingleEmailMessage theMessage = new Messaging.SingleEmailMessage();
    //theMessage.setOrgWideEmailAddressId(UserInfo.getUserId());
    theMessage.setToAddresses(toEmailAddressList);
    theMessage.setCcAddresses(ccEmailAddressList);
    theMessage.setBccAddresses(bccEmails);
    theMessage.setTemplateId(template.id);
    // theMessage.setPlainTextBody('testing');
    // theMessage.setSubject('confirm testing');
    theMessage.setSaveAsActivity(true);
    theMessage.setWhatId(approvalHistoryID);
    theMessage.setTargetObjectId(opp.Contact__c);
    theMessage.setTreatTargetObjectAsRecipient(false);

    messages.add(theMessage);

    //system.debug('messages::::' + messages);
    //Messaging.sendEmail(messages);
    system.debug(approvalHistoryId);
    System.debug(recipientIds);
    // if (Test.isRunningTest()) {
  try {
    List<Messaging.SendEmailResult> results = Messaging.sendEmail(
      messages,
      true
    );
    if (results.get(0).isSuccess()) {
      EmailMessage emm = new EmailMessage(
        FromAddress = (String) senderInfo.get('Email'),
        FromName = (String) senderInfo.get('Name'),
        MessageDate = System.now(),
        EmailTemplateId = template.id,
        RelatedToId = oppRecordID,
        toIds = new List<Id>(recipientIds),
        Status = '3',
        HTMLBody = messages[0].getHtmlBody(),
        Subject = template.subject,
        BccAddress = String.join(bccEmails, ','),
        CcAddress = String.join(ccEmailAddressList, ',')
      );

      insert emm;

      List<EmailMessageRelation> emrList = new List<EmailMessageRelation>();
      EmailMessageRelation emsender = new EmailMessageRelation();
      emsender.EmailMessageId = emm.Id;
      emsender.RelationId = (Id) senderInfo.get('Id');
      emsender.RelationType = 'FromAddress';
      emrList.add(emsender);

      for (Id recipId : recipientIds) {
        EmailMessageRelation emrecipient = new EmailMessageRelation();
        emrecipient.EmailMessageId = emm.Id;
        emrecipient.RelationId = recipId;
        emrecipient.RelationType = 'ToAddress';
        emrList.add(emrecipient);
      }

      insert emrList;
    } else {
      system.debug('Email failed to send');
    }
  } catch (Exception err) {
    system.debug(err.getMessage() + ' ' + err.getLineNumber() + ' ' + err.getStackTraceString());
  }
    // }
  }

  @AuraEnabled
  public static String getRecordDetails(String recordId, Id processInstanceId) {
    Opportunity deal = [
      SELECT
        Id,
        Deposit_Amount__c,
        Final_Spread__c,
        Recourse__c,
        Foreign_National_picklist__c,
        Broker_Fees__c,
        Term_Loan_Type__c,
        Amortization_Term__c,
        Holdback_Multiplier__c,
        Cash_Management__c,
        CAF_Upfront_Fee__c,
        YSP_perc__c,
        Current_Loan_Amount__c,
        Property_Management__c,
        Property_Management_Adjustment__c,
        Contact__c,
        Contact__r.Name,
        Contact__r.Phone,
        Contact__r.Email,
        Contact__r.MailingStreet,
        Contact__r.MailingCity,
        Contact__r.MailingState,
        Contact__r.MailingPostalCode,
        YM_Prepayment_Penalty__c,
        Stepdown_Prepayment_Period__c,
        YM_Prepayment_Penalty_Description__c
      FROM Opportunity
      WHERE Id = :recordId
    ];

    SubmissionPanel submissionDetails = new SubmissionPanel(deal);
    CurrentPanel currentDetails = new CurrentPanel(deal);
    Comments comments = new Comments();
    Panels panels = new Panels();
    List<ProcessInstanceWorkitem> workItems = [
      SELECT Id, ProcessInstanceId
      FROM ProcessInstanceWorkitem
      WHERE
        ProcessInstance.TargetObjectId = :recordId
        AND ProcessInstance.processdefinition.developername = 'Term_Confirmation_of_Terms'
    ];

    // processInstanceId = null;
    system.debug(processInstanceId);

    panels.isInApproval = workItems.size() > 0;

    if (processInstanceId == null && workItems.size() > 0) {
      processInstanceId = workItems[0].ProcessInstanceId;
    }
    system.debug(processInstanceId);

    if (processInstanceId != null) {
      Approval_History__c closerHistory = [
        SELECT
          Id,
          Comments__c,
          Deposit_Amount__c,
          Spread__c,
          Final_Spread__c,
          Recourse__c,
          Foreign_National_picklist__c,
          Holdback_Multiplier__c,
          Broker_Fee__c,
          Term_Loan_Type__c,
          Amortization_Term__c,
          Cash_Management__c,
          Broker_YSP__c,
          Current_Loan_Amount__c,
          Property_Management__c,
          Property_Management_Adjustment__c,
          Origination_Fee__c,
          Status__c,
          Amortization_Status__c,
          Amortization_Status_Comment__c,
          YM_Par_Prepayment_Period__c,
          YM_Par_Prepayment_Comment__c,
          Stepdown_Prepayment_Period__c,
          Stepdown_Prepayment_Comment__c,
          YM_Prepayment_Penalty_Comment__c,
          YM_Prepayment_Penalty_Description__c,
          Yield_Maintenance__c,
          Yield_Maintenance_Comment__c,
          Contact_Name__c,
          Contact_Email__c,
          Contact_Phone__c,
          Contact_Address__c
        FROM Approval_History__c
        WHERE
          Tracking_Status__c = 'Closer'
          AND Deal__c = :recordId
          AND Process_Instance_Id__c = :processInstanceId
        LIMIT 1
      ];
      panels.status = closerHistory.Status__c;
      submissionDetails.setHistory(closerHistory);
      comments.submissionComments = closerHistory.Comments__c;
      Approval_History__c originationsHistory = [
        SELECT
          Id,
          Comments__c,
          Deposit_Amount__c,
          Deposit_Amount_Comment__c,
          Spread__c,
          Final_Spread__c,
          Final_Spread_Comment__c,
          Recourse__c,
          Recourse_Comment__c,
          Foreign_National_picklist__c,
          Foreign_National_Comment__c,
          Holdback_Multiplier__c,
          Holdback_Multiplier_Comment__c,
          Broker_Fee__c,
          Broker_Fee_Comment__c,
          Term_Loan_Type__c,
          Term_Loan_Type_Comment__c,
          Amortization_Term__c,
          Amortization_Term_Comment__c,
          Cash_Management__c,
          Cash_Management_Comment__c,
          Broker_YSP__c,
          Broker_YSP_Comment__c,
          Current_Loan_Amount__c,
          Current_Loan_Amount_Comment__c,
          Property_Management__c,
          Property_Management_Comment__c,
          Property_Management_Adjustment__c,
          Property_Management_Adjustment_Comment__c,
          Origination_Fee__c,
          Origination_Fee_Comment__c,
          Status__c,
          Amortization_Status__c,
          Amortization_Status_Comment__c,
          YM_Par_Prepayment_Period__c,
          YM_Par_Prepayment_Comment__c,
          Stepdown_Prepayment_Period__c,
          Stepdown_Prepayment_Comment__c,
          Yield_Maintenance__c,
          Yield_Maintenance_Comment__c,
          Servicer_Contact_Name__c,
          Servicer_Contact_Email__c,
          Servicer_Contact_Phone__c,
          Servicer_Contact_Address__c,
          Contact_Name_Comment__c,
          Contact_Email_Comment__c,
          Contact_Phone_Comment__c,
          Contact_Address_Comment__c,
          YM_Prepayment_Penalty_Comment__c,
          YM_Prepayment_Penalty_Description__c
        FROM Approval_History__c
        WHERE
          Tracking_Status__c = 'Originations'
          AND Deal__c = :recordId
          AND Process_Instance_Id__c = :processInstanceId
        LIMIT 1
      ];

      panels.originationsStatus = originationsHistory.Status__c;

      if (
        originationsHistory.Status__c == 'Approved' ||
        originationsHistory.Status__c == 'Recalled' ||
        originationsHistory.Status__c == 'Rejected'
      ) {
        currentDetails.setOriginationsHistory(originationsHistory);
        comments.setOriginationsComments(originationsHistory);
      }

      Approval_History__c underWriterHistory = [
        SELECT
          Id,
          Comments__c,
          Deposit_Amount__c,
          Deposit_Amount_Comment__c,
          Spread__c,
          Final_Spread__c,
          Final_Spread_Comment__c,
          Recourse__c,
          Recourse_Comment__c,
          Foreign_National_picklist__c,
          Foreign_National_Comment__c,
          Holdback_Multiplier__c,
          Holdback_Multiplier_Comment__c,
          Broker_Fee__c,
          Broker_Fee_Comment__c,
          Term_Loan_Type__c,
          Term_Loan_Type_Comment__c,
          Amortization_Term__c,
          Amortization_Term_Comment__c,
          Cash_Management__c,
          Cash_Management_Comment__c,
          Broker_YSP__c,
          Broker_YSP_Comment__c,
          Current_Loan_Amount__c,
          Current_Loan_Amount_Comment__c,
          Property_Management__c,
          Property_Management_Comment__c,
          Property_Management_Adjustment__c,
          Property_Management_Adjustment_Comment__c,
          Origination_Fee__c,
          Status__c,
          Total_Annual_Cap_Ex__c,
          Total_Annual_Cap_Ex_Comment__c,
          Valuations_Invoices__c,
          Valuations_Invoices_Comment__c,
          Valuation_Invoice_uploaded_to_SF__c,
          Valuation_Invoice_uploaded_to_SF_Comment__c,
          Lease_and_PP_review_complete__c,
          Lease_and_PP_review_complete_Comment__c,
          Insurance_complete__c,
          Insurance_complete_Comment__c,
          Model_up_to_date__c,
          Model_up_to_date_Comment__c,
          Clear_to_Lock__c,
          Clear_to_Lock_Comment__c,
          Amortization_Status__c,
          Amortization_Status_Comment__c
        FROM Approval_History__c
        WHERE
          Tracking_Status__c = 'Underwriter'
          AND Deal__c = :recordId
          AND Process_Instance_Id__c = :processInstanceId
        LIMIT 1
      ];

      panels.underwriterStatus = underwriterHistory.Status__c;

      if (
        underwriterHistory.Status__c == 'Approved' ||
        underwriterHistory.Status__c == 'Recalled' ||
        underwriterHistory.Status__c == 'Rejected'
      ) {
        currentDetails.setUnderwriterHistory(underwriterHistory);
        comments.setUnderwriterComments(underwriterHistory);
      }
    }

    panels.comments = comments;
    panels.submissionDetails = submissionDetails;
    panels.currentDetails = currentDetails;

    return JSON.serialize(panels);
  }

  @AuraEnabled
  public static void submitApproval(
    Id recordId,
    String comment,
    String submissionDetails
  ) {
    try {
      system.debug('--submit approval--');
      system.debug('recordId');
      system.debug(recordId);
      system.debug('--approval comment--');
      system.debug(comment);

      Id userId = UserInfo.getUserId();

      // Map<String, Object> submission = (Map<String, Object>) JSON.deserializeUntyped(
      //   submissionDetails
      // );

      SubmissionPanel submission = (SubmissionPanel) JSON.deserialize(
        submissionDetails,
        SubmissionPanel.class
      );

      system.debug('--submissionDetails--');
      system.debug(submission);

      //   Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
      //   req.setComments(comments);
      //   req.setObjectId(recordId);
      //   req.setSubmitterId(UserInfo.getUserId());
      //   req.setSkipEntryCriteria(true);
      //   req.setProcessDefinitionNameOrId('Term_Confirmation_of_Terms');
      //   Approval.ProcessResult result = Approval.process(req);

      String processName = 'Term_Confirmation_of_Terms';

      Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
      req.setComments(comment);
      req.setObjectId(recordId);
      req.setSubmitterId(userId);
      req.setSkipEntryCriteria(true);
      req.setProcessDefinitionNameOrId('Term_Confirmation_of_Terms');
      Approval.ProcessResult result = Approval.process(req);
      Id processInstanceId = result.getInstanceId();
      String status = result.getInstanceStatus();
      List<Id> workItemIds = result.getNewWorkitemIds();

      Opportunity deal = [
        SELECT Id, Name
        FROM Opportunity
        WHERE Id = :recordId
      ];

      List<Approval_History__c> ahList = new List<Approval_History__c>();
      Approval_History__c ahc = new Approval_History__c(
        Process_Instance_Id__c = processInstanceId,
        Parent_Status__c = status,
        Deal__c = recordId,
        Name = 'Approval Request: ' + deal.Name.left(50),
        ProcessName__c = processName.replace('_', ' '),
        Approver__c = UserInfo.getName(),
        Actor__c = UserInfo.getUserId(),
        Role__c = 'Submitter',
        Date_Acted__c = System.now(),
        Status__c = 'Submitted',
        Status_Text__c = 'Submitted',
        Comments__c = comment,
        Approval_Type__c = 'Confirmation Of Terms',
        Tracking_Status__c = 'Closer'
      );

      /* 
            this.yieldMaintenance = String.isNotEmpty(history.Yield_Maintenance__c)
        ? history.Yield_Maintenance__c
        : null;
      this.stepdownPrepayment = String.isNotEmpty(history.Stepdown_Prepayment_Period__c)
        ? history.Stepdown_Prepayment_Period__c
        : null;
      this.ymParPrepayment = String.isNotEmpty(history.YM_Par_Prepayment_Period__c)
        ? history.YM_Par_Prepayment_Period__c
        : null;  

      */

      ahc.Yield_Maintenance__c = submission.yieldMaintenance;
      ahc.Stepdown_Prepayment_Period__c = submission.stepdownPrepayment;
      ahc.YM_Par_Prepayment_Period__c = submission.ymParPrepayment;
      ahc.YM_Prepayment_Penalty_Description__c = submission.ymPrepaymentDescription;

      ahc.Deposit_Amount__c = submission.depositCollected;
      ahc.Final_Spread__c = submission.finalSpread;
      if (ahc.Final_Spread__c != null) {
        ahc.Final_Spread__c *= 100;
      }
      ahc.Recourse__c = submission.recourse; // (String) submission.get('recourse');
      ahc.Foreign_National_picklist__c = submission.foreignNational; //(Boolean) submission.get('foreignNational');
      ahc.Holdback_Multiplier__c = submission.holdback;
      ahc.Broker_Fee__c = submission.brokerFees;
      
      ahc.Contact_Name__c = submission.contactName;
      ahc.Contact_Email__c = submission.contactEmail;
      ahc.Contact_Phone__c = submission.contactPhone;
      ahc.Contact_Address__c = submission.contactAddress;

      if (ahc.Broker_Fee__c != null) {
        ahc.Broker_Fee__c *= 100;
      }
      //(Decimal) submission.get('brokerFees');
      ahc.Term_Loan_Type__c = submission.termLoanType; //(String) submission.get('termLoanType');
      ahc.Amortization_Term__c = submission.amortizationTerm; //(String) submission.get('amortizationTerm');
      ahc.Cash_Management__c = submission.cashManagement; //(String) submission.get('cashManagement');
      ahc.Broker_YSP__c = submission.brokerYSP;
      if (ahc.Broker_YSP__c != null) {
        ahc.Broker_YSP__c *= 100;
      }
      ////((Decimal) submission.get('brokerYSP')) * 100;
      ahc.Current_Loan_Amount__c = submission.currentLoanAmount;
      ahc.Property_Management__c = submission.propertyManagement;
      ahc.Property_Management_Adjustment__c = submission.propertyManagementAdjustment;
      if (ahc.Property_Management_Adjustment__c != null) {
        ahc.Property_Management_Adjustment__c *= 100;
      }



      ahc.Origination_Fee__c = submission.originationFee; //(Decimal) submission.get('originationFee');

      if (ahc.Origination_Fee__c != null) {
        ahc.Origination_Fee__c *= 100;
      }
      // ahc.Deposit_Amount__c = (Decimal) submission.get('depositCollected');
      // ahc.Spread__c = ((Decimal) submission.get('finalSpread')) * 100;
      // ahc.Recourse__c = (String) submission.get('recourse');
      // ahc.Foreign_National__c = (Boolean) submission.get('foreignNational');
      // ahc.Broker_Fee__c = (Decimal) submission.get('brokerFees');
      // ahc.Term_Loan_Type__c = (String) submission.get('termLoanType');
      // ahc.Amortization_Term__c = (String) submission.get('amortizationTerm');
      // ahc.Cash_Management__c = (String) submission.get('cashManagement');
      // ahc.Broker_YSP__c = ((Decimal) submission.get('brokerYSP')) * 100;
      // ahc.Current_Loan_Amount__c = (Decimal) submission.get(
      //   'currentLoanAmount'
      // );
      // ahc.Property_Management__c = (String) submission.get(
      //   'propertyManagement'
      // );
      // ahc.Property_Management_Adjustment__c =
      //   ((Decimal) submission.get('propertyManagementAdjustment')) * 100;

      // ahc.Origination_Fee__c = (Decimal) submission.get('originationFee');

      ahList.add(ahc);
      //insert ahc;

      for (Integer i = 0; i < workItemIds.size(); i++) {
        Approval_History__c a = new Approval_History__c(
          Process_Instance_Id__c = processInstanceId,
          Process_Id__c = workItemIds[i],
          ProcessName__c = processName.replace('_', ' '),
          Parent_Status__c = status,
          Deal__c = recordId,
          Name = 'Approval Request: ' + deal.Name.left(50),
          Approver__c = 'Approver',
          Status__c = 'Pending',
          Status_Text__c = 'Pending',
          Approval_Type__c = 'Confirmation Of Terms'
        );

        if (i == 0) {
          a.Status_Text__c = 'Pending: Underwriter Review';
          a.Tracking_Status__c = 'Underwriter';
        } else {
          a.Status_Text__c = 'Pending: Originations Review';
          a.Tracking_Status__c = 'Originations';
        }

        a.Deposit_Amount__c = submission.depositCollected;
        a.Final_Spread__c = submission.finalSpread;
        if (a.Final_Spread__c != null) {
          a.Final_Spread__c *= 100;
        }
        a.Recourse__c = submission.recourse; // (String) submission.get('recourse');
        a.Foreign_National_picklist__c = submission.foreignNational; //(Boolean) submission.get('foreignNational');
        a.Holdback_Multiplier__c = submission.holdback;
        a.Broker_Fee__c = submission.brokerFees;

        if (a.Broker_Fee__c != null) {
          a.Broker_Fee__c *= 100;
        }
        //(Decimal) submission.get('brokerFees');
        a.Term_Loan_Type__c = submission.termLoanType; //(String) submission.get('termLoanType');
        a.Amortization_Term__c = submission.amortizationTerm; //(String) submission.get('amortizationTerm');
        a.Cash_Management__c = submission.cashManagement; //(String) submission.get('cashManagement');
        a.Broker_YSP__c = submission.brokerYSP;
        if (a.Broker_YSP__c != null) {
          a.Broker_YSP__c *= 100;
        }
        ////((Decimal) submission.get('brokerYSP')) * 100;
        a.Current_Loan_Amount__c = submission.currentLoanAmount;
        a.Property_Management__c = submission.propertyManagement;
        a.Property_Management_Adjustment__c = submission.propertyManagementAdjustment;
        if (a.Property_Management_Adjustment__c != null) {
          a.Property_Management_Adjustment__c *= 100;
        }

        a.Origination_Fee__c = submission.originationFee; //(Decimal) submission.get('originationFee');

        if (a.Origination_Fee__c != null) {
          a.Origination_Fee__c *= 100;
        }

        ahList.add(a);
      }
      insert ahList;
      system.debug(ahList[0].id);
      system.debug(ahList[1].id);
      system.debug(ahList.size());
      // system.debug(ahlist[2].id);
      sendEmailForConfirmation(ahList[0].Id, recordId, 'Closer');
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static String getWrapperBundle(String recordId, Id processInstanceId) {
    boolean isUnderWriterPanel = false;
    boolean isCloserPanel = false;
    Opportunity dealRecord = [
      SELECT id, OwnerId, CAF_Analyst__c, Underwriter__c, Closer__c
      FROM Opportunity
      WHERE id = :recordId
      LIMIT 1
    ];

    // List<Approval_History__c> historyList = new List<Approval_History__c>(
    //   [
    //     SELECT id
    //     FROM Approval_History__c
    //     WHERE
    //       Deal__c = :recordId
    //       AND Status__c = 'Pending'
    //       AND Tracking_Status__c = 'Closer'
    //   ]
    // );

    List<ProcessInstanceWorkitem> workItems = [
      SELECT Id, ProcessInstanceId
      FROM ProcessInstanceWorkitem
      WHERE
        ProcessInstance.TargetObjectId = :recordId
        AND ProcessInstance.processdefinition.developername = 'Term_Confirmation_of_Terms'
    ];

    if (processInstanceId == null && workItems.size() > 0) {
      processInstanceId = workItems[0].ProcessInstanceId;
    }

    if (workItems != null) {
      list<PermissionSetAssignment> permissionSetAssignmentListForCloser = new List<PermissionSetAssignment>();

      permissionSetAssignmentListForCloser = [
        SELECT Id, AssigneeId, Assignee.Name
        FROM PermissionSetAssignment
        WHERE PermissionSet.Name = 'Term_Closer'
      ];
      //??????
      for (PermissionSetAssignment pa : permissionSetAssignmentListForCloser) {
        if (
          dealRecord.Underwriter__c != UserInfo.getUserId() &&
          (dealRecord.Closer__c == UserInfo.getUserId() ||
          UserInfo.getUserId() == pa.AssigneeId) &&
          (dealRecord.OwnerId != UserInfo.getUserId() ||
          dealRecord.CAF_Analyst__c != UserInfo.getUserId())
        ) {
          isCloserPanel = true;
        }
      }
    } else {
      if (dealRecord.Closer__c == UserInfo.getUserId()) {
        isCloserPanel = true;
      }
    }

    list<PermissionSetAssignment> permissionSetAssignmentListForUnderWriter = new List<PermissionSetAssignment>();

    permissionSetAssignmentListForUnderWriter = [
      SELECT Id, AssigneeId, Assignee.Name
      FROM PermissionSetAssignment
      WHERE
        PermissionSet.Name = 'Term_Underwriter'
        AND AssigneeId = :UserInfo.getUserId()
        // AND AssigneeId = :dealRecord.Underwriter__c
    ];

    isUnderWriterPanel = permissionSetAssignmentListForUnderWriter.size() > 0;

    ConfirmationOfTermsWrapper mConfirmationOfTermsWrapper = new ConfirmationOfTermsWrapper();

    mConfirmationOfTermsWrapper.isCloserPanel = isCloserPanel;

    mConfirmationOfTermsWrapper.isOriginatorPanel = (dealRecord.OwnerId ==
    UserInfo.getUserId() ||
    dealRecord.CAF_Analyst__c == UserInfo.getUserId());

    mConfirmationOfTermsWrapper.isUnderWriterPanel = isUnderWriterPanel;

    mConfirmationOfTermsWrapper.isEnabledCloserPanel = isCloserAccess(
      processInstanceId
    );

    mConfirmationOfTermsWrapper.isEnabledOriginatorPanel = isOriginatorAccess(
      processInstanceId
    );
    mConfirmationOfTermsWrapper.isEnabledUnderWriterPanel = isUnderwriterAccess(
      processInstanceId
    );

    return JSON.serialize(mConfirmationOfTermsWrapper);
  }

  private class ConfirmationOfTermsWrapper {
    Boolean isCloserPanel;
    Boolean isEnabledCloserPanel;

    Boolean isOriginatorPanel;
    Boolean isEnabledOriginatorPanel;

    Boolean isUnderWriterPanel;
    Boolean isEnabledUnderWriterPanel;

    public ConfirmationOfTermsWrapper() {
      this.isCloserPanel = false;
      this.isEnabledCloserPanel = false;
      this.isOriginatorPanel = false;
      this.isEnabledOriginatorPanel = false;
      this.isUnderWriterPanel = false;
      this.isEnabledUnderWriterPanel = false;
    }
  }

  private static Boolean isCloserAccess(Id processInstanceId) {
    List<Approval_History__c> historyList = [
      SELECT Id
      FROM Approval_History__c
      WHERE
        Tracking_Status__c = 'Closer'
        AND Process_Instance_Id__c = :processInstanceId
        AND Status__c = 'Submitted'
    ];
    return historyList.size() == 0;
  }

  private static Boolean isOriginatorAccess(Id processInstanceId) {
    List<Approval_History__c> historyList = [
      SELECT Id
      FROM Approval_History__c
      WHERE
        Tracking_Status__c = 'Originations'
        AND Process_Instance_Id__c = :processInstanceId
        AND Status__c = 'Pending'
    ];
    return historyList.size() > 0;
  }

  private static Boolean isUnderwriterAccess(Id processInstanceId) {
    List<Approval_History__c> historyList = [
      SELECT Id
      FROM Approval_History__c
      WHERE
        Process_Instance_Id__c = :processInstanceId
        AND Status__c = 'Pending'
        AND Tracking_Status__c = 'Underwriter'
    ];
    return historyList.size() > 0;
  }

  @AuraEnabled
  public static void recallApproval(Id recordId, String comment) {
    // system.debug(recordId);
    // system.debug(comment);
    Id processInstanceId;
    ProcessInstanceWorkitem[] Pval = [
      SELECT Id, ProcessInstanceId
      FROM ProcessInstanceWorkItem
      WHERE
        ProcessInstance.TargetObjectId = :recordId
        AND ProcessInstance.Status = 'Pending'
    ];

    if (Pval.size() > 0) {
      processInstanceId = pval[0].ProcessInstanceId;
      Approval.ProcessWorkItemRequest Preq = new Approval.ProcessWorkItemRequest();
      Preq.setAction('Removed');
      Preq.setWorkItemId(Pval[0].Id);
      preq.setComments(comment);
      Approval.ProcessResult result = Approval.process(Preq);
    }

    List<Approval_History__c> approvalHistories = new List<Approval_History__c>();

    for (Approval_History__c ah : [
      SELECT
        Id,
        Status__c,
        Status_Text__c,
        Parent_Status__c,
        Date_Acted__c,
        Tracking_Status__c
      FROM Approval_History__c
      WHERE Process_Instance_Id__c = :processInstanceId
    ]) {
      ah.Status__c = 'Recalled';
      ah.Status_Text__c = 'Recalled';
      ah.Date_Acted__c = system.now();
      ah.Parent_Status__c = 'Recalled';
      ah.Date_Acted__c = system.now();

      if (ah.Tracking_Status__c == 'Closer') {
        ah.Comments__c = comment;
      }

      approvalHistories.add(ah);
    }

    update approvalHistories;
    createTask('Closer', recordId, false, RECALLED_COMMENT);
    sendEmailForConfirmation(approvalHistories[0].Id, recordId, 'Closer');
  }
  @AuraEnabled
  public static void originatorApprove(
    Id recordId,
    String comment,
    String currentDetails,
    String comments
  ) {
    // system.debug('--submit approval--');
    // system.debug('recordId');
    // system.debug(recordId);
    // system.debug('--approval comment--');
    // system.debug(comment);

    Id userId = UserInfo.getUserId();

    // Map<String, Object> details = (Map<String, Object>) JSON.deserializeUntyped(
    //   currentDetails
    // );

    CurrentPanel details = (CurrentPanel) JSON.deserialize(
      currentDetails,
      CurrentPanel.class
    );

    Comments allComments = (Comments) JSON.deserialize(
      comments,
      Comments.class
    );

    ProcessInstanceWorkitem[] Pval = [
      SELECT Id, ProcessInstanceId
      FROM ProcessInstanceWorkItem
      WHERE
        ProcessInstance.TargetObjectId = :recordId
        AND ProcessInstance.Status = 'Pending'
    ];

    Id processInstanceId = pval[0].ProcessInstanceId;
    system.debug(processInstanceId);
    system.debug(recordId);
    Approval_History__c originatorHistory = [
      SELECT Id, Process_Id__c, Process_Instance_Id__c
      FROM Approval_History__c
      WHERE
        Deal__c = :recordId
        AND Tracking_Status__c = 'Originations'
        AND Process_Instance_Id__c = :processInstanceId
      LIMIT 1
    ];

    Id processId = originatorHistory.Process_Id__c;

    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    pwr.setComments(comments);
    pwr.setWorkitemId(processId);
    pwr.setAction('Approve');
    Approval.ProcessResult result = Approval.process(pwr);

    originatorHistory.Deposit_Amount__c = details.depositCollected;

    originatorHistory.Final_Spread__c = details.finalSpread; //((Decimal) details.get('finalSpread')) * 100;
    if (originatorHistory.Final_Spread__c != null) {
      details.finalSpread *= 100;
    }

    originatorHistory.Recourse__c = details.recourse;
    originatorHistory.Foreign_National_picklist__c = details.foreignNational;
    originatorHistory.Holdback_Multiplier__c = details.holdback;
    originatorHistory.Broker_Fee__c = details.brokerFees;
    if (originatorHistory.Broker_Fee__c != null) {
      originatorHistory.Broker_Fee__c *= 100;
    }
    originatorHistory.Term_Loan_Type__c = details.termLoanType;
    originatorHistory.Amortization_Term__c = details.amortizationTerm;
    originatorHistory.Cash_Management__c = details.cashManagement;
    originatorHistory.Broker_YSP__c = details.brokerYSP;
    if (originatorHistory.Broker_YSP__c != null) {
      originatorHistory.Broker_YSP__c *= 100;
    }

    originatorHistory.Servicer_Contact_Name__c = details.servicerContactName;
    originatorHistory.Servicer_Contact_Phone__c = details.servicerContactPhone;
    originatorHistory.Servicer_Contact_Email__c = details.servicerContactEmail;
    originatorHistory.Servicer_Contact_Address__c = details.servicerContactAddress;

    originatorHistory.Yield_Maintenance__c = details.yieldMaintenance;
    originatorHistory.Stepdown_Prepayment_Period__c = details.stepdownPrepayment;
    originatorHistory.YM_Par_Prepayment_Period__c = details.ymParPrepayment;

    originatorHistory.YM_Prepayment_Penalty_Description__c = details.ymPrepaymentDescription;
    originatorHistory.YM_Prepayment_Penalty_Comment__c = allComments.ymPrepaymentComments;
    
    originatorHistory.Yield_Maintenance_Comment__c = allComments.yieldMaintenance;
    originatorHistory.Stepdown_Prepayment_Comment__c = allComments.stepdownPrepayment;
    originatorHistory.YM_Par_Prepayment_Comment__c = allComments.ymParPrepayment;


    originatorHistory.Deposit_Amount_Comment__c = allComments.depositCollected;
    originatorHistory.Final_Spread_Comment__c = allComments.finalSpread;
    originatorHistory.Recourse_Comment__c = allComments.recourse;

    originatorHistory.Foreign_National_Comment__c = allComments.foreignNational;
    originatorHistory.Holdback_Multiplier_Comment__c = allComments.holdback;
    originatorHistory.Term_Loan_Type_Comment__c = allComments.termLoanType;
    originatorHistory.Broker_Fee_Comment__c = allComments.brokerFees;
    originatorHistory.Amortization_Term_Comment__c = allComments.amortizationTerm;
    originatorHistory.Cash_Management_Comment__c = allComments.cashManagement;
    originatorHistory.Origination_Fee_Comment__c = allComments.originationFee;
    originatorHistory.Broker_YSP_Comment__c = allComments.brokerYSP;

    originatorHistory.Contact_Name_Comment__c = allComments.contactNameComments;
    originatorHistory.Contact_Phone_Comment__c = allComments.contactPhoneComments;
    originatorHistory.Contact_Email_Comment__c = allComments.contactEmailComments;
    originatorHistory.Contact_Address_Comment__c = allComments.contactAddressComments;

    originatorHistory.Actor__c = UserInfo.getUserId();
    originatorHistory.Approver__c = UserInfo.getName();
    originatorHistory.Status__c = 'Approved';
    originatorHistory.Status_Text__c = 'Approved';
    originatorHistory.Comments__c = comment;
    originatorHistory.Date_Acted__c = System.now();

    update originatorHistory;
    createTask('Origination', recordId, true, APPROVED_COMMENT);

    Opportunity opp = new Opportunity(Id = recordId);
    opp.Deposit_Amount__c = originatorHistory.Deposit_Amount__c;
    update opp;

    Approval_History__c underwriterHistory = [
      SELECT Id, Status__c
      FROM Approval_History__c
      WHERE
        Deal__c = :recordId
        AND Tracking_Status__c = 'Underwriter'
        AND Process_Instance_Id__c = :processInstanceId
    ];

    if (underwriterHistory.Status__c == 'Approved') {
      Approval_History__c closerHistory = [
        SELECT Id, Status__c
        FROM Approval_History__c
        WHERE
          Deal__c = :recordId
          AND Tracking_Status__c = 'Closer'
          AND Process_Instance_Id__c = :processInstanceId
      ];

      closerHistory.Status__c = 'Approved';
      closerHistory.Status_Text__c = 'Approved';
      closerHistory.Date_Acted__c = System.now();

      update closerHistory;
    }

    sendEmailForConfirmation(originatorHistory.Id, recordId, 'Originator');
    postToChatter(recordId, 'Originator');
    // if()

    //
  }

  @AuraEnabled
  public static void originatorReject(Id recordId, String comment) {
    Id processInstanceId;
    ProcessInstanceWorkitem[] Pval = [
      SELECT Id, ProcessInstanceId
      FROM ProcessInstanceWorkItem
      WHERE
        ProcessInstance.TargetObjectId = :recordId
        AND ProcessInstance.Status = 'Pending'
    ];

    if (Pval.size() > 0) {
      processInstanceId = pval[0].ProcessInstanceId;
      Approval.ProcessWorkItemRequest Preq = new Approval.ProcessWorkItemRequest();
      Preq.setAction('Reject');
      Preq.setWorkItemId(Pval[0].Id);
      preq.setComments(comment);
      Approval.ProcessResult result = Approval.process(Preq);
    }

    List<Approval_History__c> approvalHistories = new List<Approval_History__c>();

    for (Approval_History__c ah : [
      SELECT
        Id,
        Status__c,
        Status_Text__c,
        Parent_Status__c,
        Date_Acted__c,
        Tracking_Status__c
      FROM Approval_History__c
      WHERE Process_Instance_Id__c = :processInstanceId
    ]) {
      ah.Status__c = 'Rejected';
      ah.Status_Text__c = 'Rejected';
      ah.Date_Acted__c = system.now();
      ah.Parent_Status__c = 'Rejected';
      ah.Date_Acted__c = system.now();
      if (ah.Tracking_Status__c == 'Originations') {
        ah.Comments__c = comment;
      }
      approvalHistories.add(ah);
    }

    update approvalHistories;

    createTask('Origination', recordId, true, REJECTED_COMMENT);
    createTask('Underwriter', recordId, true, REJECTED_COMMENT);

    sendEmailForConfirmation(approvalHistories[0].Id, recordId, 'Originator');
  }
  @AuraEnabled
  public static void underwriterApprove(
    Id recordId,
    String comment,
    String currentDetails,
    String comments
  ) {
    system.debug('--submit approval--');
    system.debug('recordId');
    system.debug(recordId);
    system.debug('--approval comment--');
    system.debug(comment);

    Id userId = UserInfo.getUserId();

    // Map<String, Object> details = (Map<String, Object>) JSON.deserializeUntyped(
    //   currentDetails
    // );

    // Map<String, Object> allComments = (Map<String, Object>) JSON.deserializeUntyped(
    //   comments
    // );

    CurrentPanel details = (CurrentPanel) JSON.deserialize(
      currentDetails,
      CurrentPanel.class
    );

    Comments allComments = (Comments) JSON.deserialize(
      comments,
      Comments.class
    );

    ProcessInstanceWorkitem[] Pval = [
      SELECT Id, ProcessInstanceId
      FROM ProcessInstanceWorkItem
      WHERE
        ProcessInstance.TargetObjectId = :recordId
        AND ProcessInstance.Status = 'Pending'
    ];

    Id processInstanceId = pval[0].ProcessInstanceId;

    Approval_History__c underwriterHistory = [
      SELECT Id, Process_Id__c, Process_Instance_Id__c
      FROM Approval_History__c
      WHERE
        Deal__c = :recordId
        AND Tracking_Status__c = 'Underwriter'
        AND Process_Instance_Id__c = :processInstanceId
      LIMIT 1
    ];

    Id processId = underwriterHistory.Process_Id__c;

    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    pwr.setComments(comments);
    pwr.setWorkitemId(processId);
    pwr.setAction('Approve');
    Approval.ProcessResult result = Approval.process(pwr);

    underwriterHistory.Current_Loan_Amount__c = details.currentLoanAmount;
    underwriterHistory.Property_Management_Adjustment__c = details.propertyManagementAdjustment;
    if (underwriterHistory.Property_Management_Adjustment__c != null) {
      underwriterHistory.Property_management_Adjustment__c *= 100;
    }
    underwriterHistory.Amortization_Status__c = details.amortizationStatus;
    underwriterHistory.Total_Annual_Cap_Ex__c = details.totalAnnualCapEx;
    underwriterHistory.Valuations_Invoices__c = details.valuationInvoices;
    underwriterHistory.Valuation_Invoice_uploaded_to_SF__c = details.valuationInvoiceUploaded ==
      'Yes'
      ? true
      : false;

    underwriterHistory.Insurance_complete__c = details.insuranceComplete ==
      'Yes'
      ? true
      : false;

    underwriterHistory.Model_up_to_date__c = details.modelUpToDate == 'Yes'
      ? true
      : false;

    underwriterHistory.Lease_and_PP_review_complete__c = details.leasePPReviewComplete ==
      'Yes'
      ? true
      : false;

    underwriterHistory.Clear_to_Lock__c = details.clearToLock == 'Yes'
      ? true
      : false;

    underwriterHistory.Current_Loan_Amount_Comment__c = allComments.currentLoanAmount;
    underwriterHistory.Property_Management_Comment__c = allComments.propertyManagement;
    underwriterHistory.Property_Management_Adjustment_Comment__c = allComments.propertyManagementAdjustment;

    underwriterHistory.Total_Annual_Cap_Ex_Comment__c = allComments.totalAnnualCapEx;

    underwriterHistory.Valuations_Invoices_Comment__c = allComments.valuationInvoices;
    underwriterHistory.Valuation_Invoice_uploaded_to_SF_Comment__c = allComments.valuationInvoiceUploaded;
    underwriterHistory.Lease_and_PP_review_complete_Comment__c = allComments.leasePPReviewComplete;
    underwriterHistory.Insurance_complete_Comment__c = allComments.insuranceComplete;
    underwriterHistory.Model_up_to_date_Comment__c = allComments.modelUpToDate;
    underwriterHistory.Clear_to_Lock_Comment__c = allComments.clearToLock;
    underwriterHistory.Amortization_Status_Comment__c = allComments.amortizationStatus;

    underwriterHistory.Actor__c = UserInfo.getUserId();
    underwriterHistory.Approver__c = UserInfo.getName();
    underwriterHistory.Status__c = 'Approved';
    underwriterHistory.Status_Text__c = 'Approved';
    underwriterHistory.Comments__c = comment;
    underwriterHistory.Date_Acted__c = System.now();

    update underwriterHistory;

    createTask('Underwriter', recordId, true, APPROVED_COMMENT);

    Approval_History__c originationsHistory = [
      SELECT Id, Status__c
      FROM Approval_History__c
      WHERE
        Deal__c = :recordId
        AND Tracking_Status__c = 'Originations'
        AND Process_Instance_Id__c = :processInstanceId
    ];

    if (originationsHistory.Status__c == 'Approved') {
      Approval_History__c closerHistory = [
        SELECT Id, Status__c
        FROM Approval_History__c
        WHERE
          Deal__c = :recordId
          AND Tracking_Status__c = 'Closer'
          AND Process_Instance_Id__c = :processInstanceId
      ];

      closerHistory.Status__c = 'Approved';
      closerHistory.Status_Text__c = 'Approved';
      closerHistory.Date_Acted__c = System.now();

      update closerHistory;
    }

    sendEmailForConfirmation(underwriterHistory.Id, recordId, 'Underwriter');
    postToChatter(recordId, 'Underwriter');
  }

  @AuraEnabled
  public static void underwriterReject(Id recordId, String comment) {
    Id processInstanceId;
    ProcessInstanceWorkitem[] Pval = [
      SELECT Id, ProcessInstanceId
      FROM ProcessInstanceWorkItem
      WHERE
        ProcessInstance.TargetObjectId = :recordId
        AND ProcessInstance.Status = 'Pending'
    ];

    if (Pval.size() > 0) {
      processInstanceId = pval[0].ProcessInstanceId;
      Approval.ProcessWorkItemRequest Preq = new Approval.ProcessWorkItemRequest();
      Preq.setAction('Reject');
      Preq.setWorkItemId(Pval[0].Id);
      preq.setComments(comment);
      Approval.ProcessResult result = Approval.process(Preq);
    }

    List<Approval_History__c> approvalHistories = new List<Approval_History__c>();

    for (Approval_History__c ah : [
      SELECT
        Id,
        Status__c,
        Status_Text__c,
        Parent_Status__c,
        Date_Acted__c,
        Tracking_Status__c
      FROM Approval_History__c
      WHERE Process_Instance_Id__c = :processInstanceId
    ]) {
      ah.Status__c = 'Rejected';
      ah.Status_Text__c = 'Rejected';
      ah.Date_Acted__c = system.now();
      ah.Parent_Status__c = 'Rejected';
      ah.Date_Acted__c = system.now();

      if (ah.Tracking_Status__c == 'Underwriter') {
        ah.Comments__c = comment;
      }

      approvalHistories.add(ah);
    }

    update approvalHistories;

    createTask('Underwriter', recordId, true, REJECTED_COMMENT);
    createTask('Origination', recordId, true, REJECTED_COMMENT);

    sendEmailForConfirmation(approvalHistories[0].Id, recordId, 'Underwriter');
  }

  public class Panels {
    public SubmissionPanel submissionDetails { get; set; }
    public CurrentPanel currentDetails { get; set; }
    public Comments comments { get; set; }

    public String status { get; set; }
    public String originationsStatus { get; set; }
    public String underwriterStatus { get; set; }

    public Boolean isInApproval { get; set; }

    Panels() {
      isInApproval = false;
      submissionDetails = null;
      currentDetails = null;
      comments = null;
      status = 'Pending';
      originationsStatus = 'Pending';
      underwriterStatus = 'Pending';
    }
  }

  public class SubmissionPanel {
    public Decimal depositCollected { get; set; }
    public Decimal finalSpread { get; set; }
    public String recourse { get; set; }
    public String foreignNational { get; set; }
    public Decimal holdback { get; set; }
    public Decimal brokerFees { get; set; }
    public String termLoanType { get; set; }
    public String amortizationTerm { get; set; }
    public String cashManagement { get; set; }
    public Decimal originationFee { get; set; }
    public Decimal brokerYSP { get; set; }
    public Decimal currentLoanAmount { get; set; }
    public String propertyManagement { get; set; }
    public Decimal propertyManagementAdjustment { get; set; }
    public String amortizationStatus { get; set; }
    public String contactName { get; set; }
    public String contactAddress { get; set; }
    public String contactEmail { get; set; }
    public String contactPhone { get; set; }
    public String yieldMaintenance { get; set; }
    public String stepdownPrepayment { get; set; }
    public String ymParPrepayment { get; set; }
    public String ymPrepaymentDescription { get; set; }

    SubmissionPanel(Opportunity deal) {
      this.recourse = deal.Recourse__c;
      this.depositCollected = deal.Deposit_Amount__c;
      this.finalSpread = deal.Final_Spread__c != null
        ? deal.Final_Spread__c / 100
        : null;
      this.foreignNational = deal.Foreign_National_picklist__c;
      this.holdback = deal.Holdback_Multiplier__c;
      this.brokerFees = deal.Broker_Fees__c != null
        ? deal.Broker_Fees__c / 100
        : null;
      this.termLoanType = deal.Term_Loan_Type__c;
      this.amortizationTerm = deal.Amortization_Term__c;
      this.cashManagement = deal.Cash_Management__c;
      this.originationFee = deal.CAF_Upfront_Fee__c != null
        ? deal.CAF_Upfront_Fee__c / 100
        : null;
      this.brokerYsp = deal.YSP_perc__c != null ? deal.YSP_Perc__c / 100 : null;
      this.currentLoanAmount = deal.Current_Loan_Amount__c;
      this.propertyManagement = deal.Property_Management__c;
      this.propertyManagementAdjustment = deal.Property_Management_Adjustment__c !=
        null
        ? deal.Property_Management_Adjustment__c / 100
        : null;
      this.amortizationStatus = null;
      this.yieldMaintenance = null;
      this.stepdownPrepayment = deal.Stepdown_Prepayment_Period__c;
      this.ymParPrepayment = deal.YM_Prepayment_Penalty__c;
      this.contactName = deal.Contact__r.Name;
      this.contactAddress = deal.Contact__r.MailingStreet + '\n' + deal.Contact__r.MailingCity +
        ', ' + deal.Contact__r.MailingState + ' ' + deal.Contact__r.MailingPostalCode;
      this.contactEmail = deal.Contact__r.Email;
      this.contactPhone = deal.Contact__r.Phone;
      this.ymPrepaymentDescription = deal.YM_Prepayment_Penalty_Description__c;
    }

    public void setHistory(Approval_History__c history) {
      this.recourse = history.Recourse__c;
      this.depositCollected = history.Deposit_Amount__c;
      this.finalSpread = history.Final_Spread__c != null
        ? history.Final_Spread__c / 100
        : history.Spread__c != null
          ? history.Spread__c / 100
          : null;
      this.foreignNational = history.Foreign_National_picklist__c;
      this.holdback = history.Holdback_Multiplier__c;
      this.brokerFees = history.Broker_Fee__c != null
        ? history.Broker_Fee__c / 100
        : null;
      this.termLoanType = history.Term_Loan_Type__c;
      this.amortizationTerm = history.Amortization_Term__c;
      this.cashManagement = history.Cash_Management__c;
      this.originationFee = history.Origination_Fee__c != null
        ? history.Origination_Fee__c / 100
        : null;
      this.brokerYsp = history.Broker_YSP__c != null
        ? history.Broker_YSP__c / 100
        : null;
      this.currentLoanAmount = history.Current_Loan_Amount__c;
      this.propertyManagement = history.Property_Management__c;
      this.propertyManagementAdjustment = history.Property_Management_Adjustment__c !=
        null
        ? history.Property_Management_Adjustment__c / 100
        : null;
      this.amortizationStatus = history.Amortization_Status__c != null
        ? history.Amortization_Status__c
        : null;
      this.contactName = history.Contact_Name__c;
      this.contactAddress = history.Contact_Address__c;
      this.contactEmail = history.Contact_Email__c;
      this.contactPhone = history.Contact_Phone__c;

      this.yieldMaintenance = String.isNotEmpty(history.Yield_Maintenance__c)
        ? history.Yield_Maintenance__c
        : null;
      this.stepdownPrepayment = String.isNotEmpty(history.Stepdown_Prepayment_Period__c)
        ? history.Stepdown_Prepayment_Period__c
        : null;
      this.ymParPrepayment = String.isNotEmpty(history.YM_Par_Prepayment_Period__c)
        ? history.YM_Par_Prepayment_Period__c
        : null;  
      this.ymPrepaymentDescription = String.isNotEmpty(history.YM_Prepayment_Penalty_Description__c)
        ? history.YM_Prepayment_Penalty_Description__c
        : null;
    }
  }

  public class CurrentPanel {
    public Decimal depositCollected { get; set; }
    public Decimal finalSpread { get; set; }
    public String recourse { get; set; }
    public String foreignNational { get; set; }
    public Decimal holdback { get; set; }
    public Decimal brokerFees { get; set; }
    public String termLoanType { get; set; }
    public String amortizationTerm { get; set; }
    public String cashManagement { get; set; }
    public Decimal originationFee { get; set; }
    public Decimal brokerYSP { get; set; }
    public Decimal currentLoanAmount { get; set; }
    public String propertyManagement { get; set; }
    public Decimal propertyManagementAdjustment { get; set; }
    public Decimal totalAnnualCapEx { get; set; }
    public Decimal valuationInvoices { get; set; }
    public String valuationInvoiceUploaded { get; set; }
    public String leasePPReviewComplete { get; set; }
    public String insuranceComplete { get; set; }
    public String modelUpToDate { get; set; }
    public String clearToLock { get; set; }
    public String amortizationStatus { get; set; }
    public String yieldMaintenance { get; set; }
    public String stepdownPrepayment { get; set; }
    public String ymParPrepayment { get; set; }
    public String ymPrepaymentDescription { get; set; }
    public String servicerContactName { get; set; }
    public String servicerContactAddress { get; set; }
    public String servicerContactEmail { get; set; }
    public String servicerContactPhone { get; set; }
    CurrentPanel(Opportunity deal) {
      this.recourse = deal.Recourse__c;
      this.depositCollected = null;
      this.finalSpread = deal.Final_Spread__c != null
        ? deal.Final_Spread__c / 100
        : null;
      this.foreignNational = deal.Foreign_National_picklist__c;
      this.holdback = deal.Holdback_Multiplier__c;
      this.brokerFees = deal.Broker_Fees__c != null
        ? deal.Broker_Fees__c / 100
        : null;
      this.termLoanType = deal.Term_Loan_Type__c;
      this.amortizationTerm = deal.Amortization_Term__c;
      this.cashManagement = deal.Cash_Management__c;
      this.originationFee = deal.CAF_Upfront_Fee__c != null
        ? deal.CAF_Upfront_Fee__c / 100
        : null;
      this.brokerYsp = deal.YSP_perc__c != null ? deal.YSP_Perc__c / 100 : null;
      this.currentLoanAmount = deal.Current_Loan_Amount__c;
      this.propertyManagement = deal.Property_Management__c;
      this.propertyManagementAdjustment = deal.Property_Management_Adjustment__c !=
        null
        ? deal.Property_Management_Adjustment__c / 100
        : null;

      this.totalAnnualCapEx = null;
      this.valuationInvoices = null;
      this.valuationInvoiceUploaded = '';
      this.leasePPReviewComplete = '';
      this.insuranceComplete = '';
      this.modelUpToDate = '';
      this.clearToLock = '';
      this.amortizationStatus = null;
      this.yieldMaintenance = '';
      this.stepdownPrepayment = '';
      this.ymParPrepayment = '';
      this.ymPrepaymentDescription = '';
    }

    public void setOriginationsHistory(Approval_History__c history) {
      this.recourse = history.Recourse__c;
      this.depositCollected = history.Deposit_Amount__c;
      this.finalSpread = history.Final_Spread__c != null
        ? history.Final_Spread__c / 100
        : history.Spread__c != null
          ? history.Spread__c / 100
          : null;
      this.foreignNational = history.Foreign_National_picklist__c;
      this.holdback = history.Holdback_Multiplier__c;
      this.brokerFees = history.Broker_Fee__c != null
        ? history.Broker_Fee__c / 100
        : null;
      this.termLoanType = history.Term_Loan_Type__c;
      this.amortizationTerm = history.Amortization_Term__c;
      this.cashManagement = history.Cash_Management__c;
      this.originationFee = history.Origination_Fee__c != null
        ? history.Origination_Fee__c / 100
        : null;
      this.brokerYsp = history.Broker_YSP__c != null
        ? history.Broker_YSP__c / 100
        : null;
      this.servicerContactName = history.Servicer_Contact_Name__c;
      this.servicerContactAddress = history.Servicer_Contact_Address__c;
      this.servicerContactEmail = history.Servicer_Contact_Email__c;
      this.servicerContactPhone = history.Servicer_Contact_Phone__c;
  
      this.yieldMaintenance = history.Yield_Maintenance__c;
      this.stepdownPrepayment = String.isNotEmpty(history.Yield_Maintenance__c) && history.Yield_Maintenance__c == 'Yes' ? history.Stepdown_Prepayment_Period__c : 'N/A';
      this.ymParPrepayment = String.isNotEmpty(history.Yield_Maintenance__c) && history.Yield_Maintenance__c == 'Yes' ? history.YM_Par_Prepayment_Period__c : 'N/A';
      this.ymPrepaymentDescription = String.isNotEmpty(history.YM_Prepayment_Penalty_Description__c) ? history.YM_Prepayment_Penalty_Description__c : '';
      /*
                YM_Par_Prepayment_Period__c,
          Stepdown_Prepayment_Period__c,
          Yield_Maintenance__c
 */
    }

    public void setUnderwriterHistory(Approval_History__c history) {
      this.currentLoanAmount = history.Current_Loan_Amount__c;
      this.propertyManagement = history.Property_Management__c;
      this.propertyManagementAdjustment = history.Property_Management_Adjustment__c !=
        null
        ? history.Property_Management_Adjustment__c / 100
        : null;
      this.totalAnnualCapEx = history.Total_Annual_Cap_Ex__c;
      this.valuationInvoices = history.Valuations_Invoices__c;
      this.valuationInvoiceUploaded = history.Valuation_Invoice_uploaded_to_SF__c
        ? 'Yes'
        : 'No';
      this.leasePPReviewComplete = history.Lease_and_PP_review_complete__c
        ? 'Yes'
        : 'No';
      this.insuranceComplete = history.Insurance_complete__c ? 'Yes' : 'No';
      this.modelUpToDate = history.Model_up_to_date__c ? 'Yes' : 'No';
      this.clearToLock = history.Clear_to_Lock__c ? 'Yes' : 'No';
      this.amortizationStatus = history.Amortization_Status__c != null
        ? history.Amortization_Status__c
        : null;
    }
  }

  public class Comments {
    public String depositCollected { get; set; }
    public String finalSpread { get; set; }
    public String recourse { get; set; }
    public String foreignNational { get; set; }
    public String holdback { get; set; }
    public String brokerFees { get; set; }
    public String termLoanType { get; set; }
    public String amortizationTerm { get; set; }
    public String cashManagement { get; set; }
    public String originationFee { get; set; }
    public String brokerYSP { get; set; }
    public String currentLoanAmount { get; set; }
    public String propertyManagement { get; set; }
    public String propertyManagementAdjustment { get; set; }
    public String totalAnnualCapEx { get; set; }
    public String valuationInvoices { get; set; }
    public String valuationInvoiceUploaded { get; set; }
    public String leasePPReviewComplete { get; set; }
    public String insuranceComplete { get; set; }
    public String modelUpToDate { get; set; }
    public String clearToLock { get; set; }
    public String amortizationStatus { get; set; }
    public String yieldMaintenance { get; set; }
    public String stepdownPrepayment { get; set; }
    public String ymParPrepayment { get; set; }
    public String ymPrepaymentComments { get; set; }

    public String submissionComments { get; set; }
    public String originationsComments { get; set; }
    public String underwriterComments { get; set; }

    public String contactNameComments { get; set; }
    public String contactAddressComments { get; set; }
    public String contactEmailComments { get; set; }
    public String contactPhoneComments { get; set; }
    

    Comments() {
      depositCollected = '';
      finalSpread = '';
      recourse = '';
      foreignNational = '';
      holdback = '';
      brokerFees = '';
      termLoanType = '';
      amortizationTerm = '';
      cashManagement = '';
      originationFee = '';
      brokerYSP = '';
      currentLoanAmount = '';
      propertyManagement = '';
      propertyManagementAdjustment = '';
      totalAnnualCapEx = '';
      valuationInvoices = '';
      valuationInvoiceUploaded = '';
      leasePPReviewComplete = '';
      insuranceComplete = '';
      modelUpToDate = '';
      clearToLock = '';
      amortizationStatus = '';
      yieldMaintenance = '';
      stepdownPrepayment = '';
      ymParPrepayment = '';
      ymPrepaymentComments = '';
      contactNameComments = '';
      contactAddressComments = '';
      contactEmailComments = '';
      contactPhoneComments = '';
    }

    public void setOriginationsComments(Approval_History__c history) {
      depositCollected = history.Deposit_Amount_Comment__c;
      finalSpread = history.Final_Spread_Comment__c;
      recourse = history.Recourse_Comment__c;
      foreignNational = history.Foreign_National_Comment__c;
      holdback = history.Holdback_Multiplier_Comment__c;
      brokerFees = history.Broker_Fee_Comment__c;
      termLoanType = history.Term_Loan_Type_Comment__c;
      amortizationTerm = history.Amortization_Term_Comment__c;
      cashManagement = history.Cash_Management_Comment__c;
      originationFee = history.Origination_Fee_Comment__c;
      brokerYSP = history.Broker_YSP_Comment__c;
      originationsComments = history.Comments__c;
      yieldMaintenance = history.Yield_Maintenance_Comment__c;
      stepdownPrepayment = history.Stepdown_Prepayment_Comment__c;
      ymParPrepayment = history.YM_Par_Prepayment_Comment__c;
      ymPrepaymentComments = history.YM_Prepayment_Penalty_Comment__c;
      contactNameComments = history.Contact_Name_Comment__c;
      contactAddressComments = history.Contact_Address_Comment__c;
      contactEmailComments = history.Contact_Email_Comment__c;
      contactPhoneComments = history.Contact_Phone_Comment__c;
    }

    public void setUnderwriterComments(Approval_History__c history) {
      currentLoanAmount = history.Current_Loan_Amount_Comment__c;
      propertyManagement = history.Property_Management_Comment__c;
      propertyManagementAdjustment = history.Property_Management_Adjustment_Comment__c;
      totalAnnualCapEx = history.Total_Annual_Cap_Ex_Comment__c;
      valuationInvoices = history.Valuations_Invoices_Comment__c;
      valuationInvoiceUploaded = history.Valuation_Invoice_uploaded_to_SF_Comment__c;
      leasePPReviewComplete = history.Lease_and_PP_review_complete_Comment__c;
      insuranceComplete = history.Insurance_complete_Comment__c;
      modelUpToDate = history.Model_up_to_date_Comment__c;
      clearToLock = history.Clear_to_Lock_Comment__c;
      amortizationStatus = history.Amortization_Status_Comment__c;
      underwriterComments = history.Comments__c;
    }
  }

  public static void createTask(
    String submittedBy,
    String opptId,
    Boolean isFromApproval,
    String description
  ) {
    Opportunity oppt = [
      SELECT Id, Name, Closer__c, OwnerId, Underwriter__c
      FROM Opportunity
      WHERE Id = :opptId
      LIMIT 1
    ];

    List<Task> taskList = new List<Task>();

    if (submittedBy == 'Closer' && description != RECALLED_COMMENT) {
      List<String> taskForList = new List<String>{
        'Closer',
        'Underwriter',
        'Origination'
      };
      for (String who : taskForList) {
        Task task = new Task();
        task.Status = who == 'Closer' ? 'Completed' : 'Open';
        task.Subject = who == 'Closer'
          ? 'CoT Submitted'
          : 'CoT ' + who + ' Approval - ' + oppt.Name;
        task.ActivityDate = System.today();
        task.Priority = 'Normal';
        task.WhatId = opptId;
        task.OwnerId = who == 'Closer'
          ? oppt.Closer__c
          : who == 'Underwriter' ? oppt.Underwriter__c : oppt.OwnerId;
        task.Description = who == 'Closer' ? '' : SUBMITTED_COMMENT;
        taskList.add(task);
      }
    } else if (submittedBy == 'Closer' && description == RECALLED_COMMENT) {
      List<Id> taskOwnerIds = new List<Id>{ oppt.OwnerId, oppt.Underwriter__c };

      List<Task> existingTasks = generateExistingTask(taskOwnerIds, opptId);
      if (existingTasks.size() > 0) {
        for (Task task : existingTasks) {
          if (task.Status != 'Completed' && task.Subject.startsWith('CoT')) {
            task.Status = 'Completed';
            task.Description = RECALLED_COMMENT;
            taskList.add(task);
          }
        }
      }
    } else if (isFromApproval) {
      Id taskOwnerId = submittedBy == 'Origination'
        ? oppt.OwnerId
        : oppt.Underwriter__c;

      List<Task> existingTasks = generateExistingTask(
        new List<Id>{ taskOwnerId },
        opptId
      );
      if (existingTasks.size() > 0) {
        for (Task task : existingTasks) {
          if (
            task.Subject.startsWith('CoT ' + submittedBy) &&
            task.Status != 'Completed'
          ) {
            task.Status = 'Completed';
            task.Description = description;
            taskList.add(task);
            break;
          }
        }
      }

      if (taskList.size() == 0) {
        Task task = new Task();
        task.Status = 'Completed';
        task.Subject = 'CoT ' + submittedBy + ' Approval - ' + oppt.Name;
        task.ActivityDate = System.today();
        task.Priority = 'Normal';
        task.WhatId = opptId;
        task.OwnerId = submittedBy == 'Underwriter'
          ? oppt.Underwriter__c
          : oppt.OwnerId;
        task.Description = description;
        taskList.add(task);
      }
    }

    upsert taskList;
  }

  public static List<Task> generateExistingTask(List<Id> ownerIds, Id whatId) {
    List<Task> tasks = [
      SELECT Id, OwnerId, WhatId, Subject, Status
      FROM Task
      WHERE
        OwnerId IN :ownerIds
        AND WhatId = :whatId
        AND IsDeleted = FALSE
        AND IsClosed = FALSE
    ];

    return tasks;
  }

  public static void postToChatter(Id oppId, String approver) {
    Opportunity deal = [SELECT Id, Name, Closer__c FROM Opportunity WHERE Id= :oppId];
    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = deal.Closer__c; // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    String segmentText = ' ' + deal.Name + ' has been approved by ' + approver + '.';
    textSegment.text = segmentText;
    messageInput.messageSegments.add(textSegment);

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    input.subjectId = deal.Id;
    if (!Test.isRunningTest()) {
      ConnectApi.FeedElement fi = ConnectApi.ChatterFeeds.postFeedElement(
        Network.getNetworkId(),
        input
      );
    }
  }
}