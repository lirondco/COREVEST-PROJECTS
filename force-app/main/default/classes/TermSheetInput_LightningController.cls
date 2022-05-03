public without sharing class TermSheetInput_LightningController {
  public static List<String> termFields = new List<String>{
    'Name',
    'Loan_Size__c',
    'Number_of_Properties__c',
    'Distinct_States__c',
    'Swap_Rate__c',
    'Floor__c',
    'Spread_BPS__c',
    'Term_Loan_Type__c',
    'IO_Term__c',
    'Amortization_Term__c',
    'CAF_Upfront_Fee__c',
    'Recourse__c',
    'YM_Prepayment_Penalty__c',
    'Stepdown_Prepayment_Period__c',
    // 'Deposit_Amount__c',
    'Owner_Name__c',
    'Owner_Phone__c',
    // 'Owner.Name',
    'Deposit_Legal_Counsel_Diligence__c',
    'Deposit_Broker_Price_Opinions_Appraisal__c',
    'Deposit_Insurance_Review__c',
    'Deposit_Lender_Out_of_Pocket__c',
    'Deal_Loan_Number__c',
    'Deal_Intro_Source__c',
    'Account.BillingStreet',
    'Account.BillingCity',
    'Account.BillingPostalCode',
    'Contact__r.MailingStreet',
    'Contact__r.MailingCity',
    'Contact__r.MailingPostalCode',
    'Contact__r.Phone',
    'Contact__r.Email',
    'Deposit_Amount_Requested__c',
    'YSP_perc__c',
    'Rate_Lock_Picklist__c'
  };
  // trigger, initiated by the originator,
  // docusign identify which fields need to be the signature lines
  // I'll start reading document
  // inside the document
  // move to full
  // email to Willie
  // standard, goes to request
  // not, goes

  // bridge validations
  public static List<String> bridgeFields = new List<String>{
    'Name',
    'Requested_Revolving__c',
    'Recourse__c',
    // 'LOC_Commitment__c',
    'Active_States__c',
    'Loan_Size__c',
    //'Term_Sheet_Issued__c',
    'LOC_Loan_Type__c',
    'Requested_LTC_Max__c',
    'Requested_LTV_Max__c',
    // 'Requested_Total_Loan_LTC__c',
    // 'Requested_ARV_LTV__c',
    // 'Requested_Max_Reno_Cost_Reimbursement__c',
    // 'Requested_Reno_Limit__c',
    'Line_Expiration__c',
    // 'Extension_Fee__c',
    'Draw_Period__c',
    'Requested_Interest_Type__c',
    //'Rate__c',
    // 'Origination_Fee__c',
    'Requested_Origination_Fee__c',
    'Requested_Draw_Fee__c',
    'Requested_Exit_Fee__c',
    'Broker_Fees__c',
    'Owner_Name__c',
    'Owner_Phone__c',
    'Deal_Intro_Source__c',
    //'Deal_Intro_Sub_Source__c',
    'Account.BillingStreet',
    'Account.BillingCity',
    'Account.BillingPostalCode',
    'Contact__r.MailingStreet',
    'Contact__r.MailingCity',
    'Contact__r.MailingPostalCode',
    'Contact__r.Phone',
    'Contact__r.Email',
    'Deposit_Amount_Requested__c',
    'Broker_Fee_Paid_By_Whom__c',
    'Broker_Fee_Paid_When__c'
  };

  public static List<String> sabFields = new List<String>{
    'Name',
    'Requested_Revolving__c',
    'Recourse__c',
    'Loan_Size__c',
    'LOC_Loan_Type__c',
    'Requested_LTC_Max__c',
    'Requested_LTV_Max__c',
    // 'Requested_Total_Loan_LTC__c',
    // 'Requested_ARV_LTV__c',
    // 'Requested_Max_Reno_Cost_Reimbursement__c',
    // 'Requested_Reno_Limit__c',
    'Line_Expiration__c',
    // 'Extension_Fee__c',
    'Draw_Period__c',
    'Requested_Interest_Type__c',
    'Requested_Origination_Fee__c',
    'Requested_Draw_Fee__c',
    'Requested_Exit_Fee__c',
    'Broker_Fees__c',
    'Owner_Name__c',
    'Owner_Phone__c',
    'Deal_Intro_Source__c',
    //'Deal_Intro_Sub_Source__c',
    'Account.BillingStreet',
    'Account.BillingCity',
    'Account.BillingPostalCode',
    'Contact__r.MailingStreet',
    'Contact__r.MailingCity',
    'Contact__r.MailingPostalCode',
    'Contact__r.Phone',
    'Contact__r.Email',
    'Deposit_Amount_Requested__c',
    'Broker_Fee_Paid_By_Whom__c',
    'Broker_Fee_Paid_When__c'
  };

  public static Map<String, String> fieldLabels = new Map<String, String>{
    // 'Term_Sheet_Issued__c' => 'Term Sheet Issued',
    'Account.BillingStreet' => 'Account Billing Street',
    'Account.BillingState' => 'Account Billing State',
    'Account.BillingCity' => 'Account Billing City',
    'Account.BillingPostalCode' => 'Account Billing Postal Code',
    'Contact__r.MailingStreet' => 'Primary Contact Mailing Street',
    'Contact__r.MailingState' => 'Primary Contact Mailing State',
    'Contact__r.MailingCity' => 'Primary Contact Mailing City',
    'Contact__r.MailingPostalCode' => 'Primary Contact Mailing Postal Code',
    'Contact__r.Phone' => 'Primary Contact Business Phone',
    'Contact__r.Email' => 'Primary Contact Email Address',
    'Name' => 'Name',
    'Loan_Size__c' => 'Requested Loan Size',
    'CAF_Upfront_Fee__c' => 'CAF Upfront Fee',
    'Requested_Revolving__c' => 'Requested Revolving',
    'Primary_Contact__c' => 'Primary Contact Name',
    'Final_Loan_Amount__c' => 'Final Loan Amount',
    'Number_of_Properties__c' => 'Number of Properties',
    'Distinct_States__c' => 'Distinct States',
    // 'Servicer_LTV__c' => 'LTV',
    'Swap_Rate__c' => 'Swap Rate',
    'Floor__c' => 'Floor %',
    'Spread_BPS__c' => 'Spread (BPS)',
    'Term_Loan_Type__c' => 'Term Loan Type',
    'IO_Term__c' => 'IO Term',
    'Amortization_Term__c' => 'Amortization Term',
    'Requested_Draw_Fee__c' => 'Requested Advance Fee %',
    'Recourse__c' => 'Recourse',
    'YM_Prepayment_Penalty__c' => 'YM Par Prepayment Period',
    'Stepdown_Prepayment_Period__c' => 'Stepdown Prepayment Period',
    'Deposit_Amount__c' => 'Deposit Amount',
    'Owner_Name__c' => 'Owner Name',
    'Owner_Phone__c' => 'Owner Phone',
    // 'Owner.Name',
    // 'Phone__c' => 'Phone',
    'Deposit_Legal_Counsel_Diligence__c' => 'Deposit - Legal Counsel, Diligence',
    'Deposit_Broker_Price_Opinions_Appraisal__c' => 'Deposit, Broker Price Opinions/Appraisal',
    // 'Deposit_Insurance_Review__c' => 'Deposit - Insurance Review',
    'Deposit_Lender_Out_of_Pocket__c' => 'Deposit - Lender Out of Pocket',
    'Deal_Loan_Number__c' => 'Deal Loan Number',
    'LOC_Commitment__c' => 'LOC Commitment',
    'Active_States__c' => 'Active States',
    'LOC_Loan_Type__c' => 'Product Type',
    'Requested_LTC_Max__c' => 'Requested Initial LTC %',
    'Requested_LTV_Max__c' => 'Requested Initial LTV %',
    'Requested_Total_Loan_LTC__c' => 'Requested Total Loan LTC %',
    'Requested_ARV_LTV__c' => 'Requested ARV LTV %',
    'Requested_Max_Reno_Cost_Reimbursement__c' => 'Requested Max Reno Cost Reimbursement %',
    'Requested_Reno_Limit__c' => 'Requested Reno Limit (% Acq Cost)',
    'Line_Expiration__c' => 'Requested Line Term',
    'Extension_Fee__c' => 'Extension Fee',
    'Broker_Fees__c' => 'Broker Fee %',
    'Draw_Period__c' => 'Requested Advance Period',
    'Requested_Interest_Type__c' => 'Requested Interest Type',
    //'Rate__c' => 'Interest Rate',
    'Requested_Origination_Fee__c' => 'Requested Origination Fee',
    'Requested_Exit_Fee__c' => 'Requested Exit Fee',
    // 'Refinance_Count__c' => 'Refinance Unit Count',
    // 'Acquisition_Count__c' => 'Acquisition Unit Count',
    // 'Refinance_Property_Count__c' => 'Refinance Property Count',
    // 'Acquisition_Property_Count__c' => 'Acquisition Property Count',

    'Aggregate_Payoffs__c' => 'Aggregate Payoffs',
    // 'Product_Sub_Type__c' => 'Product Sub-Type',
    'Deal_Intro_Source__c' => 'Deal Intro Source',
    'Deal_Intro_Sub_Source__c' => 'Deal Intro Sub Source',
    'Deposit_Amount_Requested__c' => 'Deposit Amount Requested',
    'YSP_perc__c' => 'Broker YSP %',
    'Broker_Fee_Paid_By_Whom__c' => 'Broker Fee Paid By Whom',
    'Broker_Fee_Paid_When__c' => 'Broker Fee Paid When'
  };

  @AuraEnabled
  public static Map<String, List<String>> findRecordType(Id recordId) {
    Map<String, List<String>> m = new Map<String, List<String>>();
    String qs = 'SELECT ';
    Set<String> fields = util.getAllFieldNamesForObject('Opportunity');

    for (String fieldName : termFields) {
      fields.add(fieldName);
    }

    for (String fieldName : bridgeFields) {
      fields.add(fieldName);
    }

    for (String fieldName : sabFields) {
      fields.add(fieldName);
    }

    for (String field : fields) {
      qs += field + ',';
    }
    qs += 'RecordType.DeveloperName FROM Opportunity WHERE Id = :recordId LIMIT 1';
    Opportunity o = (Opportunity) Database.query(qs);
    o.Apex_Context__c = true;
    System.debug('this is the record type');
    System.debug(o.RecordType.DeveloperName);
    m.put('RecordType', new List<String>{ o.RecordType.DeveloperName });

    // get current user's role

    String roleId = UserInfo.getUserRoleId();
    Map<Id, UserRole> roleList = new Map<Id, UserRole>(
      [SELECT Id, Name FROM UserRole]
    );
    Set<String> acceptableRoles = new Set<String>{
      'Bridge Manager',
      'Term Manager',
      'Origination Manager',
      'Administrator'
    };

    if (acceptableRoles.contains(roleList.get(roleId).Name)) {
      m.put('GenerateDocPermission', new List<String>{ 'true' });
    }

    // first thing is to check Record Type and then, if Bridge, check LOC_Program_Type__C
    m.put('incorrectLoanType', new List<String>());
    if (
      (o.LOC_Loan_Type__c == 'Multifamily/CRE' ||
      o.LOC_Loan_Type__c == 'Build to Rent') &&
      !acceptableRoles.contains(roleList.get(roleId).Name)
    ) {
      m.get('incorrectLoanType').add('true');
    }

    m.put('Approved', new List<String>{ 'true' });
    
    if (
      (o.RecordType.DeveloperName == 'LOC_Loan' ||
      o.RecordType.DeveloperName.contains('Bridge')) &&
      o.LOC_Program_Type__c != null &&
      o.LOC_Program_Type__c == 'Standard'
    ) {
      m.put('Approved', new List<String>{ 'true' });
    } else {
      List<ProcessInstanceStep> pis = [
        SELECT StepStatus
        FROM ProcessInstanceStep
        WHERE
          ProcessInstance.TargetObjectId = :recordId
          AND ProcessInstance.Status = 'Approved'
        ORDER BY CreatedDate DESC
        LIMIT 2
      ];

      // this is the validation for approved / not approved
      if (null != pis && pis.size() > 1) {
        // maybe more logic here
        System.debug(pis);
        m.put('Approved', new List<String>{ 'true' });
      } else {
        m.put('Approved', new List<String>{ 'false' });
        // m.put('Approved', new List<String>{'true'});
      }
    } 


    List<String> nullFields = new List<String>();
    List<String> selectedList;
    if (null != o && null != o.RecordType.DeveloperName) {
      if (o.RecordType.DeveloperName == 'LOC_Loan') {
        selectedList = bridgeFields;
        if (
          o.LOC_Loan_Type__c == 'Credit Line' &&
          o.Product_Sub_Type__c == 'Renovation'
        ) {
          bridgeFields.add('Requested_Total_Loan_LTC__c');
          bridgeFields.add('Requested_ARV_LTV__c');
          bridgeFields.add('Requested_Max_Reno_Cost_Reimbursement__c');
          bridgeFields.add('Requested_Reno_Limit__c');
        }
      } else if (o.Recordtype.DeveloperName == 'Term_Loan') {
        selectedList = termFields;
      } else if (o.Recordtype.DeveloperName == 'Single_Asset_Bridge_Loan') {
        selectedList = sabFields;
      }
      for (String field : selectedList) {
        if (
          field == 'Deal_Intro_Sub_Source__c' &&
          (o.Deal_Intro_Source__c == 'Email' ||
          o.Deal_Intro_Source__c == 'Broker' ||
          o.Deal_Intro_Source__c == 'Prospecting' ||
          o.Deal_Intro_Source__c == 'Website' ||
          o.Deal_Intro_Source__c == 'Hotline')
        ) {
          continue;
        } else if (field.contains('.')) {
          system.debug(field);
          List<String> fieldSplit = field.split('\\.');
          system.debug(o.getSObject(fieldSplit[0]));

          if (null == o.getSObject(fieldSplit[0]).get(fieldSplit[1])) {
            nullFields.add(fieldLabels.get(field));
          }
        } else if (null == o.get(field)) {
          nullFields.add(fieldLabels.get(field));
        }
      }
    }
    System.debug('these are nullFields');
    System.debug(nullFields);

    // if (null != o && (null == nullFields || nullFields.size() <= 0)){
    //     System.debug('insider here');
    //     m.put('RecordType', new List<String>{o.RecordType.Name});
    //     m.put('MissingFields', null);
    // } else {
    //     System.debug('insider nullFields exists');
    //     m.put('RecordType', null);
    //     m.put('MissingFields', nullFields);
    // }

    if (
      o.RecordType.DeveloperName == 'Single_Asset_Bridge_Loan' &&
      nullFields.contains('Distinct States')
    ) {
      nullFields.remove(nullFields.indexOf('Distinct States'));
    }

    if (
      (o.RecordType.DeveloperName == 'LOC_Loan' ||
      o.RecordType.DeveloperName.contains('Bridge')) &&
      o.LOC_Program_Type__c != null &&
      o.LOC_Program_Type__c == 'Standard'
    ) {
      m.put('MissingFields', null);
    } else if (nullFields.size() > 0) {
      m.put('MissingFields', nullFields);
    } else {
      m.put('MissingFields', null);
    }
    System.debug(m);

    m.put('Checkboxes', new List<String>{ 'true' });

    if (
      (String.isNotEmpty(o.Project_Strategy__c) &&
      o.Project_Strategy__c.toLowerCase().contains('clo')) ||
      (String.isNotEmpty(o.Project_Strategy__c) &&
      (o.Project_Strategy__c == 'Ground Up Construction' ||
      o.Project_Strategy__c == 'Build to Rent')) ||
      (o.LOC_Loan_Type__c == 'Multifamily/CRE' &&
      String.isNotBlank(o.Renovation_Funding__c))
    ) {
      m.put('Checkboxes', new List<String>{ 'false' });
    }

    m.put('record', new List<String>{ JSON.serialize(o) });

    return m;
  }

  public static Opportunity queryOpportunity(Id recordId) {
    return [
      SELECT
        Product_Sub_Type__c,
        Name,
        LOC_Loan_Type__c,
        Negotiated_by_Counsel__c,
        NY_Counsel_Required__c,
        Include_Assumption__c,
        Include_Prop_Sub_Text__c,
        Include_3_Months_Min_Interest__c,
        Broker_Fees__c,
        Referral_Source_Contact__c,
        Project_Strategy__c,
        Renovation_Funding__c
      FROM Opportunity
      WHERE Id = :recordId
    ];
  }

  public static List<ContentDocumentLink> queryContentDocLink(Id recordId) {
    return [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId
    ];
  }

  public static Integer queryDealDocument(Id recordId) {
    return [
        SELECT COUNT()
        FROM Deal_Document__c
        WHERE
          Deal__c = :recordId
          AND Type__c = 'Term Sheet'
          AND ContentVersion_Id__c != NULL
          AND Document_Loaded__c = TRUE
      ] + 1;
  }

  public static List<ContentVersion> queryContentVersion(List<Id> recordIds) {
    return [SELECT Id, PathOnClient FROM ContentVersion WHERE Id IN :recordIds];
  }

  public static void updateIfLocLoan(Opportunity o, List<Boolean> m, Date d) {
    System.debug('inside update method');
    o.put('Negotiated_by_Counsel__c', m[0]);
    o.put('Include_3_Months_Min_Interest__c', m[1]);
    o.put('Term_Sheet_Expiration_Date__c', d);
    o.put('Term_Sheet_Generated__c', System.now());
    // o = new Opportunity(
    //     Term_Sheet_Issued__c = System.today(),
    //     Negotiated_by_Counsel__c = Boolean.valueOf(m.get('Negotiated_by_Counsel__c')),
    //     Term_Sheet_Expiration_Date__c = d,
    //     Id = m.get('Id')
    // );
    update o;
    System.debug('update was successful');
  }

  public static void updateIfTermLoan(Opportunity o, List<Boolean> m, Date d) {
    o.put('NY_Counsel_Required__c', m[0]);
    o.put('Include_Assumption__c', m[1]);
    o.put('Include_Prop_Sub_Text__c', m[2]);
    o.put('Term_Sheet_Expiration_Date__c', d);
    o.put('Term_Sheet_Generated__c', System.now());
    // o = new Opportunity(
    //     Term_Sheet_Issued__c = System.today(),
    //     NY_Counsel_Required__c = Boolean.valueOf(m.get('NY_Counsel_Required__c')),
    //     Include_Assumption__c = Boolean.valueOf(m.get('Include_Assumption__c')),
    //     Include_Prop_Sub_Text__c = Boolean.valueOf(m.get('Include_Prop_Sub_Text__c')),
    //     Term_Sheet_Expiration_Date__c = d,
    //     Id = m.get('Id')
    // );
    System.debug('this is the opportunity: ' + o);
    update o;
  }

  public static String stringTerm(
    String termLoan,
    String o,
    List<String> splitDate,
    Integer i,
    String s
  ) {
    String docReference =
      termLoan +
      o +
      '&month=' +
      Integer.valueOf(splitDate[1]) +
      '&day=' +
      Integer.valueOf(splitDate[2]) +
      '&year=' +
      Integer.valueOf(splitDate[0]) +
      '&todaymonth=' +
      System.today().month() +
      '&todayday=' +
      System.today().day() +
      '&todayyear=' +
      System.today().year() +
      '&version=' +
      String.valueOf(i);

    if (String.isNotBlank(s)) {
      docReference += '&s=' + EncodingUtil.base64Encode(Blob.valueOf(s));
    }

    return docReference;
  }

  public static String stringTerm(
    String termLoan,
    String o,
    List<String> splitDate
  ) {
    String docReference =
      termLoan +
      o +
      '&month=' +
      Integer.valueOf(splitDate[1]) +
      '&day=' +
      Integer.valueOf(splitDate[2]) +
      '&year=' +
      Integer.valueOf(splitDate[0]) +
      '&todaymonth=' +
      System.today().month() +
      '&todayday=' +
      System.today().day() +
      '&todayyear=' +
      System.today().year();
    return docReference;
  }

  public static void createContent(
    Integer i,
    Opportunity o,
    String recordType,
    PageReference p,
    Boolean doc
  ) {
    System.debug('we are inside createContent');
    Blob content;
    ContentVersion cv;
    if (Test.isRunningTest()) {
      content = Blob.valueOf('UNIT.TEST');
      cv = new ContentVersion(
        PathOnClient = o.Name + '- TermSheet_v' + String.valueOf(i) + '.doc',
        VersionData = content
      );
    } else if (doc == true) {
      System.debug('doing a doc');
      content = p.getContent();
      cv = new ContentVersion(
        PathOnClient = o.Name + '- TermSheet_v' + String.valueOf(i) + '.doc',
        VersionData = content
      );
    } else {
      content = p.getContentAsPdf();
      cv = new ContentVersion(
        PathOnClient = o.Name + '- TermSheet_v' + String.valueOf(i) + '.pdf',
        VersionData = content
      );
    }
    System.debug('this is the content version');
    System.debug(cv);
    insert cv;
    System.debug('cv was successfully inserted');

    // link to record
    ContentVersion queryCv = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ];

    // insert contentdocumentlink

    Deal_Document__c dd = new Deal_Document__c(
      ContentVersion_Id__c = queryCv.Id,
      Attachment_Id__c = queryCv.ContentDocumentId,
      Type__c = 'Term Sheet',
      Section__c = 'Term Sheet',
      Document_Type__c = 'Term Sheet',
      Deal__c = o.Id,
      Added_On__c = System.now(),
      Added_By__c = UserInfo.getUserId(),
      Document_Loaded__c = true,
      Include_for_Term_Sheet_Approval__c = true
    );

    System.debug('this is the deal document:');
    System.debug(dd);

    String fileExtension;
    if (doc == true) {
      fileExtension = '.doc';
    } else {
      fileExtension = '.pdf';
    }

    if ((recordType == 'LOC_Loan' || recordType.contains('Bridge'))) {
      dd.Other_Document_Type__c =
        'TermSheet_v' +
        String.valueOf(i) +
        fileExtension;
      dd.File_Name__c = 'TermSheet_v' + String.valueOf(i) + fileExtension;
    } else if (recordType == 'Term_Loan') {
      dd.File_Name__c = 'TermSheet_v' + String.valueOf(i) + fileExtension;
    }

    insert dd;

    // below is for testing DocuSign only
    // Attachment a = new Attachment(
    //     Body = content,
    //     Name = 'TermSheet_v' + String.valueOf(i) + '.pdf',
    //     ParentId = o.Id
    // );
    // insert a;

    ContentDocumentLink cdl = new ContentDocumentLink(
      LinkedEntityId = dd.Id,
      ContentDocumentId = queryCv.ContentDocumentId,
      ShareType = 'V'
    );

    insert cdl;
    System.debug(dd);
  }

  @AuraEnabled
  public static String generateSheet(String s, String recordType) {
    System.debug('this is the string received: ' + s);

    Map<String, String> m = (Map<String, String>) JSON.deserialize(
      s,
      Map<String, String>.class
    );
    Approval.UnlockResult lr = Approval.unlock(m.get('Id'));

    List<String> splitDate = m.get('Term_Sheet_Expiration_Date__c').split('-');
    Date d = Date.newInstance(
      Integer.valueOf(splitDate[0]),
      Integer.valueOf(splitDate[1]),
      Integer.valueOf(splitDate[2])
    );
    Opportunity o = queryOpportunity(m.get('Id'));
    o.Apex_Context__c = true;
    PageReference p;
    Integer i = queryDealDocument(o.Id);

    if ((recordType == 'LOC_Loan' || recordType.contains('Bridge'))) {
      List<Boolean> mList = new List<Boolean>{
        Boolean.valueOf(m.get('Negotiated_by_Counsel__c')),
        Boolean.valueOf(m.get('Include_3_Months_Min_Interest__c'))
      };
      updateIfLocLoan(o, mList, d);
    } else if (recordType == 'Term_Loan') {
      List<Boolean> mList = new List<Boolean>{
        Boolean.valueOf(m.get('NY_Counsel_Required__c')),
        Boolean.valueOf(m.get('Include_Assumption__c')),
        Boolean.valueOf(m.get('Include_Prop_Sub_Text__c'))
      };
      updateIfTermLoan(o, mList, d);
    }

    if ((String) m.get('Generate_Word_Doc') == 'true') {
      if (o.LOC_Loan_Type__c == 'Term Loan') {
        String termLoanString = '/apex/TermSheetDoc?id=';
        String docReference = stringTerm(termLoanString, o.Id, splitDate, i, s);
        p = new PageReference(docReference);
        createContent(i, o, recordType, p, true);
        return docReference;
      } else if (
        o.LOC_Loan_Type__c == 'Single Asset (1-4 Unit)' ||
        o.LOC_Loan_Type__c == 'Single Asset (5-10 Unit)'
      ) {
        String assetString = '/apex/SingleAssetBridgeTermSheetDoc?id=';
        String docReference = stringTerm(assetString, o.Id, splitDate, i, s);
        p = new PageReference(docReference);
        createContent(i, o, recordType, p, true);
        return docReference;
      } else {
        String bridgeString = '/apex/BridgeTermSheetDoc?id=';
        String docReference = stringTerm(bridgeString, o.Id, splitDate, i, s);
        p = new PageReference(docReference);
        createContent(i, o, recordType, p, true);
        System.debug('this is the pageReference');
        System.debug(docReference);
        return docReference;
      } 
    } else {
      if (o.LOC_Loan_Type__c == 'Term Loan') {
        p = new PageReference(
          stringTerm('/apex/TermSheetPDF?id=', o.Id, splitDate, i, s)
        );
      } else if (o.LOC_Loan_Type__c == 'Credit Line') {
        p = new PageReference(
          stringTerm('/apex/BridgeTermSheetPDF?id=', o.Id, splitDate, i, s)
        );
      } else if (o.LOC_Loan_Type__c.contains('Single Asset')) {
        p = new PageReference(
          stringTerm(
            '/apex/SingleAssetBridgeTermSheet?id=',
            o.Id,
            splitDate,
            i,
            s
          )
        );
      } else if (o.LOC_Loan_Type__c == 'Multifamily/CRE') {
        if (
          String.isNotEmpty(o.Project_Strategy__c) &&
          o.Project_Strategy__c.toLowerCase().contains('clo')
        ) {
          String assetString = '/apex/BridgeCRE_CLO_MF_Term_Sheet?id=';
          String docReference = stringTerm(assetString, o.Id, splitDate, i, s);
          p = new PageReference(docReference);
          createContent(i, o, recordType, p, true);
          return docReference;
        }
      } else if (
        String.isNotEmpty(o.Project_Strategy__c) &&
        o.Project_Strategy__c.toLowerCase().contains('clo')
      ) {
        if (String.isNotBlank(o.Renovation_Funding__c)) {
          String assetString;
          switch on o.Renovation_Funding__c {
            when 'Yes' {
              assetString = '/apex/BridgeMultifamily_Renovation_Term_Sheet?id=';
            }
            when else {
              assetString = '/apex/BridgeMultifamily_No_Renovation_Term_She?id=';
            }
          }
        }
      } else {
        p = new PageReference(
          stringTerm('/apex/TermSheetPDF?id=', o.Id, splitDate, i, s)
        );
      }
      System.debug('this is the pageReference');
      System.debug(p);

      // Integer i;
      // if (null != termSheets && termSheets.size() > 0){
      //     i = termSheets.size() + 1;
      // } else {
      //     i = 1;
      // }

      createContent(i, o, recordType, p, false);

      // Attachment a = new Attachment();
      // a.Name = cv.PathOnClient;
      // a.Body = cv.VersionData;
      // a.ParentId = o.Id;
      //
      // insert a;
      // delete cdl;

      // System.debug('this is the deal document');
      // Approval.LockResult lr2 = Approval.lock(m.get('Id'));
      // System.debug('this is the lock result' + lr2);

      return 'ok';
    }
  }
}