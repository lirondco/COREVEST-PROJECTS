public class UnderwritingApproval_LightningController {
  public static Id userId = UserInfo.getUserId();

  public static Set<String> stageNames = new Set<String>{
    'Term Sheet Signed/Deposit Collected'
  };

  public static Map<String, String> bridgeFields = new Map<String, String>{
    'StageName' => 'Stage',
    'Contact__r.FirstName' => 'Primary Contact First Name',
    'Contact__r.LastName' => 'Primary Contact Last Name',
    'Deposit_Amount__c' => 'Deposit Amount',
    'Deposit_Collected__c' => 'Deposit Collected',
    'Deposit_Fed_Reference__c' => 'Deposit Fed Reference',
    'Term_Sheet_Issued__c' => 'Term Sheet Issued',
    'Term_Sheet_Signed__c' => 'Term Sheet Signed',
    'Contact__r.MailingStreet' => 'Primary Contact Mailing Street',
    'Contact__r.MailingCity' => 'Primary Contact Mailing City',
    'Contact__r.MailingPostalCode' => 'Primary Contact Mailing Zipcode',
    'Contact__r.Phone' => 'Primary Contact Business Phone Number',
    'Contact__r.Email' => 'Primary Contact Email Address'
  };

  public static Map<String, String> termFields = new Map<String, String>{
    'StageName' => 'Stage',
    'Contact__r.FirstName' => 'Primary Contact First Name',
    'Contact__r.LastName' => 'Primary Contact Last Name',
    'Property_Management__c' => 'Property Management',
    'Deposit_Amount__c' => 'Deposit Amount',
    'Deposit_Collected__c' => 'Deposit Collected',
    'Deposit_Fed_Reference__c' => 'Deposit Fed Reference',
    'Term_Sheet_Issued__c' => 'Term Sheet Issued',
    'Term_Sheet_Signed__c' => 'Term Sheet Signed',
    'Bridge_Borrower__c' => 'Bridge Borrower',
    'Term_Borrower__c' => 'Term Borrower',
    'CAF_YSP__c' => 'CAF YSP',
    'YSP_perc__c' => 'Broker YSP %',
    'YM_Prepayment_Penalty__c' => 'YM Par Prepayment Period',
    'Stepdown_Prepayment_Period__c' => 'Stepdown Prepayment Period',
    // 'Rate_Lock_Picklist__c' => 'Rate Lock Type',
    'Contact__r.MailingStreet' => 'Primary Contact Mailing Street',
    'Contact__r.MailingCity' => 'Primary Contact Mailing City',
    'Contact__r.MailingPostalCode' => 'Primary Contact Mailing Zipcode',
    'Contact__r.Phone' => 'Primary Contact Business Phone Number',
    'Contact__r.Email' => 'Primary Contact Email Address'
  };

  public static Set<String> bridgeRequiredDocuments = new Set<String>{
    //'CAF Application'
    'Executed Term Sheet',
    'Credit Report'
  };

  public static Set<String> termRequiredDocuments = new Set<String>{
    'Executed Term Sheet',
    'CAF Application',
    'Wire Confirmation',
    'Background and Credit Search',
    'Early Rate Lock Agreement',
    'Determination Notice'
    // 'Acquisition Purchase Agreement'
    //'Sponsor Clear Search'
  };

  @AuraEnabled
  public static String validateRecord(String recordId) {
    Settings__mdt universalSetting = lightning_Controller.queryUniversalSettings();
    String queryString = 'SELECT Id, GLC_Required__c, GLC_Approved__c, RecordType.DeveloperName, OwnerId, Name, Contact__r.RecordType.DeveloperName, Account.RecordType.DeveloperName,Account.Number_of_Contacts__c,Current_Approval_Process__c,Rate_Lock_Picklist__c,';

    for (String field : termFields.keySet()) {
      if (!queryString.contains(field + ',')) {
        queryString += field + ',';
      }
    }

    for (String field : bridgeFields.keySet()) {
      if (!queryString.contains(field + ',')) {
        queryString += field + ',';
      }
    }

    queryString += ' (SELECT Id, Status__c, Property_Type__c, Red_Bell_Sync__c, Deal__c FROM Properties__r), Foreign_National__c, Loan_Purpose__c, ';
    queryString += ' (SELECT Id, Document_Type__c, Other_Document_Type__c, Type__c, Document_Loaded__c FROM Deal_Documents__r ';
    queryString += '    WHERE Document_Loaded__c = true AND (Document_Type__c IN : bridgeRequiredDocuments OR Document_Type__c IN : termRequiredDocuments))';
    queryString += ' FROM Opportunity WHERE Id =: recordId LIMIT 1';

    Opportunity o = (Opportunity) Database.query(queryString);

    //String recordTypeName = o.RecordType.Name;
    // if(o.GLC_Required__c && !o.GLC_Approved__c) {
    //   termRequiredDocuments.add('Greenlight Deck');
    // }

    Set<String> requiredDocuments;
    Map<String, String> requiredFields;
    switch on o.RecordType.DeveloperName {
      when 'Term_Loan' {
        requiredDocuments = termRequiredDocuments;
        requiredFields = termFields;
      }
      when 'LOC_Loan' {
        requiredDocuments = bridgeRequiredDocuments;
        requiredFields = bridgeFields;
      }
      when 'Single_Asset_Bridge_Loan' {
        requiredDocuments = bridgeRequiredDocuments;
        requiredFields = bridgeFields;
      }
    }

    Map<String, Object> response = new Map<String, Object>();

    response.put('result', 'success');
    response.put('recordType', o.RecordType.DeveloperName);

    List<Deal_Contact__c> dealContacts = [
      SELECT Id
      FROM Deal_Contact__c
      WHERE
        Deal__c = :recordId
        AND Entity_Type__c = 'Applicant'
        AND Contact__c != NULL
    ];

    List<String> errorMsgs = new List<String>();

    if (o.Current_Approval_Process__c != null) {
      errorMsgs.add(
        'Deal is already in an Approval Process.  See Approvals Tab for details'
      );
      response.put('result', 'error');
    }

    if (dealContacts.size() == 0) {
      //errorMsg +=
      errorMsgs.add('Please add an “Applicant” Contact to this Deal');
      // response.put('errorMsg', 'Please add an “Applicant” Contact to this Deal');
      response.put('result', 'error');
    }

    if (o.Contact__r.RecordType.DeveloperName != 'Borrower') {
      errorMsgs.add(
        'The Primary Contact on this Deal is not a Borrower record, please update the Primary Contact'
      );
      // response.put('errorMsg', 'The Primary Contact on this Deal is not a Borrower record, please update the Primary Contact');
      response.put('result', 'error');
    }

    if (o.Account.RecordType.DeveloperName != 'Borrower') {
      errorMsgs.add(
        'The Account on this Deal is not a Borrower record, please update the Account'
      );
      // response.put('errorMsg', 'The Account on this Deal is not a Borrower record, please update the Account');
      response.put('result', 'error');
    }

    if (o.Account.Number_of_Contacts__c == 0) {
      response.put('result', 'error');
      errorMsgs.add(
        'Account does not have any related Contact. Please add Contact before submitting.'
      );
    }

    if (!stageNames.contains(o.StageName)) {
      response.put('result', 'error');
      errorMsgs.add(
        'Stage must be Term Sheet Signed/Deposit Collected to submit to Underwriting'
      );
      // response.put('errorMsg', 'Stage must be Term Sheet Signed/Deposit Collected to submit to Underwriting');
    }
    // response.put('errorMsg', 'Stage cannot be changed to "Submitted to Underwriting" until at least one Property has been synced with Red Bell');
    // }

    if (o.RecordType.DeveloperName == 'Term_Loan') {
      if (
        universalSetting.Require_AVM_Sync_on_UW_Submission__c &&
        !propertiesHaveBeenRedBellSynced(o.Properties__r)
      ) {
        response.put('result', 'error');
        errorMsgs.add(
          'This Deal cannot be submitted into Underwriting until Properties have been synced with Red Bell. Go to the RedBell Data Tab under the Properties Tab'
        );
      }

      if (
        universalSetting.Require_X_Author_Validation_on_UW_Submis__c &&
        !lightning_Controller.isXAuthorSaved(recordId)
      ) {
        response.put('result', 'error');
        errorMsgs.add(
          'Saving the model in X-Author is required before submitting'
        );
      }

      if (universalSetting.Require_Address_Val_on_UW_Submit__c) {
        Decimal percentageValidated =
          100 * lightning_Controller.calculateSmartyStreetsVerified(recordId);

        if (
          universalSetting.Validated_Address_Threshold__c != null &&
          universalSetting.Validated_Address_THreshold__c > percentageValidated
        ) {
          response.put('result', 'error');
          errorMsgs.add(
            // universalSetting.Validated_Address_Threshold__c +
            // '% of properties must be validated with SmartyStreets'
            'Properties must be validated with SmartyStreets. Go to the Validated Addresses Tab under the Properties Tab'
          );
        }
      }
    }

    //else {

    List<String> nullFields = new List<String>();

    for (String field : requiredFields.keySet()) {
      if (field.contains('.')) {
        //system.debug(field);
        List<String> fieldSplit = field.split('\\.');
        //system.debug(fieldSplit);
        if (null == o.getSObject(fieldSplit[0]).get(fieldSplit[1])) {
          nullFields.add(requiredFields.get(field));
        }
      } else if (null == o.get(field)) {
        nullFields.add(requiredFields.get(field));
      }
    }

    if (nullFields.size() > 0) {
      String errorString = 'The following field(s) are required: ';
      for (String field : nullFields) {
        errorString += field + ',';
      }

      errorString = errorString.substringBeforeLast(',') + '.';
      //response.put('errorMsg', errorString);
      errorMsgs.add(errorString);
      response.put('result', 'error');
    } else {
      Set<String> loadedDocuments = new Set<String>();
      for (Deal_Document__c doc : o.Deal_Documents__r) {
        loadedDocuments.add(doc.Document_Type__c);
        loadedDocuments.add(doc.Type__c);
        loadedDocuments.add(doc.Other_Document_Type__c);
      }
      requiredDocuments.removeAll(loadedDocuments);

      if (o.Foreign_National__c) {
        requiredDocuments.remove('Background and Credit Search');
        requiredDocuments.remove('Credit Report');
      }

      if (o.Rate_Lock_Picklist__c != 'Early Rate Lock') {
        requiredDocuments.remove('Early Rate Lock Agreement');
        requiredDocuments.remove('Determination Notice');
      }

      // Remove Acquisition Purchase Agreement
      // if (o.Loan_Purpose__c == 'Refinance') {
      //   requiredDocuments.remove('Acquisition Purchase Agreement');
      // }

      if (requiredDocuments.size() > 0) {
        String errorString = 'The following document(s) are required: ';
        for (String doc : requiredDocuments) {
          errorString += doc + ',';
        }

        errorString = errorString.substringBeforeLast(',') + '.';
        //response.put('errorMsg', errorString);
        errorMsgs.add(errorString);
        response.put('result', 'error');
      }
    }

    //}

    //CIP-2191-RS.4/4/22.Begin.
    // if (universalSetting.Request_Beekin_Rental_Data_Validation__c && PricingReviewRequest_LightningController.beekingRentalInfoCheck(recordId))
    //   {
    // 	errorMsgs.add(
    //         'Please reterieve rental estimates from Beekin on all the properties before moveing the deal to Underwriting.'
    //       );
    //   }
    ////CIP-2191-RS.4/4/22.End.
    response.put('errorMsg', errorMsgs);

    return JSON.serialize(response);
  }

  @AuraEnabled
  public static String startApproval(
    String comments,
    String recordId,
    String recordType
  ) {
    // Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    // req.setComments(comments);
    // req.setObjectId(recordId);
    // req.setSubmitterId(userId);
    // req.setSkipEntryCriteria(true);

    // if (recordType == 'Term_Loan'){
    // 	req.setProcessDefinitionNameOrId('Submit_Term_Deal_to_UW_Approval');
    // } else if (recordType == 'LOC_Loan'){
    // 	req.setProcessDefinitionNameOrId('Submit_Bridge_Deal_to_UW_Approval');
    // }

    // Approval.ProcessResult result = Approval.process(req);

    Map<String, Object> response = new Map<String, Object>();

    Opportunity o = [
      SELECT
        Id,
        Name,
        StageName,
        RecordType.DeveloperName,
        Term_Sheet_Signed__c,
        Loan_Size__c,
        Exit_Fee__c,
        CAF_Upfront_Fee__c,
        Fee__c,
        Swap_Rate__c,
        Spread_BPS__c
      FROM Opportunity
      WHERE Id = :recordId
    ];
    Id userId = UserINfo.getUserId();

    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setComments(comments);
    req.setObjectId(recordId);
    req.setSubmitterId(userId);
    req.setSkipEntryCriteria(true);

    String processName = '';

    if (o.RecordType.DeveloperName == 'Term_Loan') {
      processName = 'Submit_Term_Deal_to_UW_Approval';
    } else if (
      o.RecordType.DeveloperName == 'LOC_Loan' ||
      o.RecordType.DeveloperName.containsIgnoreCase('bridge')
    ) {
      processName = 'Submit_Bridge_Deal_to_UW_Approval';
    }

    req.setProcessDefinitionNameOrId(processName);

    Map<String, Boolean> unlockApprovalMap = util.compileApprovalUnlockMap();

    try {
      Approval.ProcessResult result = Approval.process(req);
      Id processInstanceId = result.getInstanceId();
      Id oppId = result.getEntityId();
      String status = result.getInstanceStatus();
      List<Id> workItemIds = result.getNewWorkitemIds();

      if (unlockApprovalMap.get(processName)) {
        Approval.UnlockResult lr = Approval.unlock(oppId);
      }

      // System.debug('this is workItemIds');
      // System.debug(workItemIds);

      // List<Approval_History__c> history = [
      //   SELECT Id
      //   FROM Approval_History__c
      //   WHERE Deal__c = :oppId
      // ];
      String customStatus = 'Submitted';
      // if (history.size() > 0){
      //   customStatus = 'Re-submitted';
      // }

      List<Approval_History__c> ahList = new List<Approval_History__c>();
      Approval_History__c ahc = new Approval_History__c(
        Process_Instance_Id__c = processInstanceId,
        Parent_Status__c = status,
        Deal__c = oppId,
        Name = 'Submission to UW Approval: ' + o.Name.left(50),
        Approver__c = UserInfo.getName(),
        Actor__c = UserInfo.getUserId(),
        Role__c = 'Submitter',
        Date_Acted__c = System.now(),
        Status__c = customStatus,
        Status_Text__c = customStatus,
        Comments__c = comments,
        Approval_Type__c = 'Submission into UW'
      );
      insert ahc;
      for (Integer i = 0; i < 1; i++) {
        Approval_History__c a = new Approval_History__c(
          Process_Instance_Id__c = processInstanceId,
          Process_Id__c = workItemIds[i],
          Parent_Status__c = status,
          Deal__c = oppId,
          Name = 'Submission to UW Approval: ' + o.Name.left(50),
          Approver__c = 'Approver',
          Status__c = 'Pending',
          Status_Text__c = 'Pending: Approval into UW',
          Approval_Type__c = 'Submission into UW',
          Requested_Loan_Size__c = o.Loan_Size__c,
          Requested_Exit_Fee__c = o.Exit_Fee__c,
          Origination_Fee__c = o.CAF_Upfront_Fee__c,
          Deal_Stage_At_Time_of_Submission__c = o.StageName,
          Advance_Fee_Percent__c = o.Fee__c,
          Swap_Rate__c = o.Swap_Rate__c,
          Spread__c = o.Spread_BPS__c
        );
        // if (i == 0){
        // a.Approver__c = 'Underwriter';
        // a.Name = 'Underwriter Approval: ' + o.Name;
        // a.Role__c = 'Underwriter';
        // } else if (i == 1){
        // a.Approver__c = 'Capital Market';
        // a.Name = 'Capital Market Approval: ' + o.Name;
        // a.Role__c = 'Capital Market';
        // }
        ahList.add(a);
      }
      insert ahList;
      //System.debug('this is ahList');
      //System.debug(ahList);
      if (result.isSuccess()) {
        Task t = new Task(
          WhatId = recordId,
          Description = 'Submitted to UW For: ' + o.Name,
          Status = 'Completed',
          Subject = 'UW Approval'
        );
        insert t;
        System.debug(t);

        // List<Opportunity> oList = [
        //   SELECT Id, Name, RecordType.DeveloperName, OwnerId, CAF_Analyst__c
        //   FROM Opportunity
        //   WHERE Id = :oppId
        //   LIMIT 1
        // ];

        // if (oList.size() > 0){
        //   Opportunity o = oList[0];
        //   String s = ' ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' has submitted ' + o.Name + 'for approval into underwriting. ';
        //   ApprovalAttachments_lightningController.createNotification(o, UserInfo.getUserId(), 'all', s, workItemIds);
        //   System.debug('successful notification');
        // }
      }
      return 'The record has been submitted for review.';
    } catch (Exception e) {
      System.debug(e.getMessage());
      return e.getMessage();
    }
  }

  public static Boolean propertiesHaveBeenRedBellSynced(
    List<Property__c> props
  ) {
    if (props == null) {
      return true;
    }
    Boolean condoSfaOrTownhomeExists = false;
    Boolean condoSfaOrTownhomeSynced = false;

    for (Property__c prop : props) {
      if (
        (prop.Property_Type__c == 'Condo' ||
        prop.Property_Type__c == 'SFR' ||
        prop.Property_Type__c == 'Townhome') && prop.Status__c == 'Active'
      ) {
        condoSfaOrTownhomeExists = true;
        if (prop.Red_Bell_Sync__c) {
          condoSfaOrTownhomeSynced = true;
        }
      }
    }

    return (!condoSfaOrTownhomeExists || condoSfaOrTownhomeSynced);
  }
}