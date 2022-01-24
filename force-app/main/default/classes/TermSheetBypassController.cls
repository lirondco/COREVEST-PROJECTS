public without sharing class TermSheetBypassController {
  public static final String PERMISSIONSET_NAME = 'Allow_Termsheet_Bypass';
  public static final Map<String, String> validationMessages = new Map<String, String>{
    'noPermission' => 'You do not currently have permission to bypass Term Sheet Approval, please request permission through your Manager.',
    'notRepeatBorrower' => 'This Account is not a repeat Borrower, Term Sheet approval cannot be bypassed.',
    'loanSize' => 'Requested Loan Amount is equal or greater than $3M, Term Sheet approval cannot be bypassed.',
    'hasException' => 'This Deal has an Exception, Term Sheet approval cannot be bypassed.',
    'hasGLCApproval' => 'This Deal went through GLC Approval, Term Sheet approval cannot be bypassed.',
    'salesAnalyst' => 'If the CAF Originator on the deal is a Sales Analyst, Term Sheet approval cannot be bypassed.'
  };
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

  // public static final String BRIDGE_LIST = 'caf.test@cvest.com';
  // public static final String TERM_LIST = 'caf.test@cvest.com';

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
    'Account.Repeat_Borrower__c',
    'Loan_Size__c',
    'Exception__c',
    'GLC_Approved__c',
    'OwnerId'
  };

  // public static Map<String,String> loansToTemplate = new Map<String,String>{
  //     'Term Loan' => 'TERM_Term_Sheet_Request',
  //     'LOC Loan Outside Guidelines' => 'BRIDGE_Term_Sheet_Request',
  //     'LOC Loan Within Guidelines' => 'BRIDGE_Term_Sheet_Request_Within_Pricing_Guidelines'
  // };

  @AuraEnabled
  public static String returnDeal(Id recordId) {
    Map<String, Object> m = new Map<String, List<Object>>();
    List<String> validationErrors = new List<String>();
    String qs = 'SELECT ';
    qs += String.join(fields, ', ');
    qs += ' FROM Opportunity WHERE Id = :recordId';

    List<Opportunity> oList = Database.query(qs);
    Opportunity o = oList[0];

    List<User> ownerUser = [SELECT id, Profile.Name, Profile.Id FROM User WHERE Id=:o.OwnerId];

    if(ownerUser.size() > 0) {
      String profileName = ownerUser[0].Profile.Name;
      if(profileName == 'Sales Analyst') {
        validationErrors.add(validationMessages.get('salesAnalyst'));
      }
    }

    List<PermissionSetAssignment> psaList = [
      SELECT
        Id,
        PermissionSetId,
        PermissionSet.Name,
        PermissionSet.ProfileId,
        PermissionSet.Profile.Name,
        AssigneeId,
        Assignee.Name
      FROM PermissionSetAssignment
      WHERE
        PermissionSet.Name = 'Allow_Termsheet_Bypass'
        AND AssigneeId = :UserInfo.getUserId()
    ];

    if (psaList.size() == 0) {
      validationErrors.add(validationMessages.get('noPermission'));
    }

    Integer versionNumber = 0;
    List<Deal_Document__c> ddList = [
      SELECT ContentVersion_Id__c, Attachment_Id__c, Type__c
      FROM Deal_Document__c
      WHERE
        Deal__c = :recordId
        AND File_Name__c LIKE '%.pdf'
        AND ContentVersion_Id__c != NULL
        AND Document_Loaded__c = TRUE
        AND Is_Deleted__c = FALSE
        AND Type__c = 'Term Sheet'
    ];

    List<Id> ddCvIds = new List<Id>();
    if (null != ddList && ddList.size() > 0) {
      for (Deal_Document__c ddc : ddList) {
        if ('Term Sheet' == ddc.Type__c) {
          versionNumber += 1;
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
      SELECT Id, PathOnClient
      FROM ContentVersion
      WHERE Id IN :ddCvIds
    ];

    if (versionNumber == 0) {
      // m.put('Error', new List<String>{'true'});
      m.put('TermSheetError', new List<String>{ 'true' });
    }

    if (o.Account.Repeat_Borrower__c != true) {
      validationErrors.add(validationMessages.get('notRepeatBorrower'));
    } 
    if (o.Loan_Size__c >= 3000000) {
      validationErrors.add(validationMessages.get('loanSize'));
    } 
    if (o.Exception__c == true) {
      validationErrors.add(validationMessages.get('hasException'));
    } 
    if (o.GLC_Approved__c == true) {
      validationErrors.add(validationMessages.get('hasGLCApproval'));
    }

    if (validationErrors.size() > 0) {
      m.put('ValidationError', validationErrors);
    }

    // }

    //m.put('ContentVersions', cvList);
    return JSON.serialize(m, true);
  }

  @AuraEnabled
  public static String bypassDeal(String recordId) {
    try {
      Deal_Document__c termSheet = [
        SELECT ContentVersion_Id__c, Attachment_Id__c, Type__c, File_Name__c
        FROM Deal_Document__c
        WHERE
          Deal__c = :recordId
          AND File_Name__c LIKE '%.pdf'
          AND ContentVersion_Id__c != NULL
          AND Document_Loaded__c = TRUE
          AND Is_Deleted__c = FALSE
          AND Type__c = 'Term Sheet'
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];

      Attachment a = createAttachmentFromCv(termSheet.ContentVersion_Id__c);
      a.ParentId = recordId;
      insert a;

      Opportunity o = new Opportunity(
        Id = recordId,
        Bypass_To_Underwriting__c = true,
        Approved_Term_Sheet__c = termSheet.ContentVersion_Id__c,
        Approved_Term_Sheet_Name__c = termSheet.File_Name__c
      );

      update o;

      return 'This record has successfully been bypassed';
    } catch (DmlException e) {
      throw new AuraException(e.getMessage());
    }
  }

  public static Attachment createAttachmentFromCV(Id contentVersionId) {
    ContentVersion cv = [
      SELECT Id, PathOnClient, VersionData
      FROM ContentVersion
      WHERE Id = :contentVersionId
    ];

    return new Attachment(Name = cv.PathOnClient, Body = cv.VersionData);
  }

  // close Return the Deal
}
