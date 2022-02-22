public without sharing class documentUploader_Controller {
  @AuraEnabled
  public static string getRecordType(String recordId, String sobjectType) {
    return (String) (database.query(
        'SELECT Id, RecordType.DeveloperName FROM ' +
        sobjectType +
        ' WHERE Id = \'' +
        recordId +
        '\''
      )[0]
      .getSObject('RecordType')
      .get('DeveloperName'));
  }

  @AuraEnabled
  public static Boolean deleteRecords(List<sObject> records) {
    return lightning_Controller.deleteRecords(records);
  }

  @AuraEnabled
  public static String getRecord(String i) {
    return JSON.serialize(util.queryRecordAllFields(Id.valueOf(i)));
  }

  @AuraEnabled
  public static String getAttachments(String recordId) {
    community_Controller.UserResource user = new community_Controller.UserResource(
      UserInfo.getUserId()
    );

    if (
      user.userType == 'standard' || CommunityController.checkAccess(recordId)
    ) {
      List<AttachmentWrapper> wrappers = new List<AttachmentWrapper>();
      for (Attachment a : [
        SELECT Id, Name, BodyLength
        FROM Attachment
        WHERE parentId = :recordId AND CreatedById = :UserInfo.getUserId()
      ]) {
        wrappers.add(new AttachmentWrapper(a));
      }
      if (
        Id.valueOf(recordId).getSobjectType().getDescribe().getName() ==
        'Property__c'
      ) {
        //
        Property__c property = [
          SELECT Id, Deal__c
          FROM Property__c
          WHERE Id = :recordId
          LIMIT 1
        ];

        for (Attachment a : [
          SELECT Id, Name, BodyLength
          FROM Attachment
          WHERE
            parentId = :property.Deal__c
            AND CreatedById = :UserInfo.getUserId()
        ]) {
          wrappers.add(new AttachmentWrapper(a));
        }
      } else if (
        Id.valueOf(recordId).getSobjectType().getDescribe().getName() ==
        'Advance__c'
      ) {
        Advance__c adv = [
          SELECT Id, Deal__c
          FROM Advance__c
          WHERE Id = :recordId
          LIMIT 1
        ];

        for (Attachment a : [
          SELECT Id, Name, BodyLength
          FROM Attachment
          WHERE parentId = :adv.Deal__c AND CreatedById = :UserInfo.getUserId()
        ]) {
          wrappers.add(new AttachmentWrapper(a));
        }
      }

      return JSON.serialize(wrappers);
    } else {
      return null;
    }
  }

  @AuraEnabled
  public static string getDocumentValidations(
    String sobjectType,
    String recordType,
    String userType,
    String accountId,
    String accountType
  ) {
    if (String.isBlank(userType)) {
      userType = 'standard';
    }

    //Boolean publicOnly = userType != 'standard';

    // Map<String, List<String>> picklists = new Map<String, List<String>>();
    Map<String, String> validatorMap = new Map<String, String>();
    if (
      recordType.contains('Bridge') && recordType != 'Single_Asset_Bridge_Loan'
    ) {
      recordType = 'LOC_Loan';
    }

    for (Document_Structure__mdt document : [
      SELECT
        Id,
        Document_Type__c,
        Folder_Structure_String__c,
        Sort__c,
        Confidential__c,
        Private__c,
        Public__c,
        Borrower_Access__c,
        Vendor_Access__c,
        Vendor_Type_Access__c
      FROM Document_Structure__mdt
      WHERE
        RecordType__c = :recordType
        AND sobject__c = :sobjectType
        AND Display_In_Internal_Picklist__c = TRUE
        AND ID IN (SELECT Document_Structure__c FROM Document_Validation__mdt)
      ORDER BY Sort__c DESC
    ]) {
      if (userType == 'standard') {
        String section = '';
        if (document.Folder_Structure_String__c != null) {
          for (String s : document.Folder_Structure_String__c.split(';')) {
            section += s + ' - ';
          }
        }
        section = section.substringBeforeLast('-');

        // if(!picklists.containsKey(section)){
        //  picklists.put(section, new List<String>{''});
        // }

        // picklists.get(section).add(document.Document_Type__c);

        validatorMap.put(
          section +
          ' | ' +
          document.Document_Type__c,
          document.Id
        );
      }
    }

    return JSON.serialize(validatorMap);
  }

  @AuraEnabled
  public static String getPicklists(
    String sobjectType,
    String recordType,
    String userType,
    String accountId,
    String accountType
  ) {
    if (String.isBlank(userType)) {
      userType = 'standard';
    }

    //Boolean publicOnly = userType != 'standard';

    Map<String, List<String>> picklists = new Map<String, List<String>>();

    if (
      recordType.contains('Bridge') && recordType != 'Single_Asset_Bridge_Loan'
    ) {
      recordType = 'LOC_Loan';
    }

    for (Document_Structure__mdt document : [
      SELECT
        Id,
        Document_Type__c,
        Folder_Structure_String__c,
        Sort__c,
        Confidential__c,
        Private__c,
        Public__c,
        Borrower_Access__c,
        Vendor_Access__c,
        Vendor_Type_Access__c
      FROM Document_Structure__mdt
      WHERE RecordType__c = :recordType AND sobject__c = :sobjectType
      ORDER BY Sort__c DESC
    ]) {
      system.debug('Document==' + document);
      if (userType == 'standard') {
        String section = '';
        if (document.Folder_Structure_String__c != null) {
          for (String s : document.Folder_Structure_String__c.split(';')) {
            section += s + ' - ';
          }
        }
        section = section.substringBeforeLast('-');

        if (!picklists.containsKey(section)) {
          picklists.put(section, new List<String>{});
        }

        picklists.get(section).add(document.Document_Type__c);
      } else if (userType == 'borrower') {
        //
        if (document.Borrower_Access__c) {
          String section = '';
          if (document.Folder_Structure_String__c != null) {
            for (String s : document.Folder_Structure_String__c.split(';')) {
              section += s + ' - ';
            }
          }
          section = section.substringBeforeLast('-');

          if (!picklists.containsKey(section)) {
            picklists.put(section, new List<String>{});
          }
          picklists.get(section).add(document.Document_Type__c);
        }
      } else if (userType == 'vendor') {
        Boolean isVisible = false;
        if (String.isNotBlank(document.Vendor_Type_Access__c)) {
          Set<String> filterSet = new Set<String>(
            document.Vendor_Type_Access__c.split(';')
          );
          isVisible =
            filterSet.contains(accountId) || filterSet.contains(accountType);
        }

        if (document.Vendor_Access__c && isVisible) {
          String section = '';
          if (document.Folder_Structure_String__c != null) {
            for (String s : document.Folder_Structure_String__c.split(';')) {
              section += s + ' - ';
            }
          }
          section = section.substringBeforeLast('-');

          if (!picklists.containsKey(section)) {
            picklists.put(section, new List<String>{});
          }
          picklists.get(section).add(document.Document_Type__c);
        }
      }
    }

    return JSON.serialize(picklists);
  }

  @AuraEnabled
  public static String saveFile(
    String fileJSON,
    String recordId,
    String sobjectType,
    String recordType
  ) {
    return saveFileGeneric(fileJSON, recordId, recordType, sobjectType);
  }

  public static String saveFileGeneric(
    String fileJSON,
    String recordId,
    String recordType,
    String sobjectType
  ) {
    AttachmentWrapper file = (AttachmentWrapper) JSON.deserialize(
      fileJSON,
      AttachmentWrapper.class
    );

    String folderString = file.section.replace(' - ', ';').trim();
    system.debug(folderString);

    //box_Api box = box_Api.getInstance();

    String apiFieldName = sobjectType;
    if (apiFieldName == 'Opportunity') {
      apiFieldName = 'Deal__c';
    } else if (!apiFieldName.contains('__c')) {
      apiFieldName = apiFieldName + '__c';
    }

    Attachment tempAttachment;
    Attachment a = [
      SELECT Id, Name, Body, ParentId, Description, ContentType, BodyLength
      FROM Attachment
      WHERE Id = :file.attachmentId
      LIMIT 1
    ];
    Deal_Document__c doc;
    List<Document_Structure__mdt> docStructure = new List<Document_Structure__mdt>();
    file.status = 'failed';
    doc = new Deal_Document__c();
    docStructure = [
      SELECT
        Id,
        Folder_Structure_String__c,
        Confidential__c,
        Private__c,
        Public__c,
        Borrower_Access__c,
        Vendor_Access__c,
        Vendor_Type_Access__c,
        Include_for_Term_Sheet_Approval__c,
        Recorded_Document__c,
        Upload_Notification_Closer__c,
        Upload_Notification_Loan_Coordinator__c,
        Upload_Notification_Originations__c,
        Upload_Notification_Underwriter__c
      FROM Document_Structure__mdt
      WHERE
        Folder_Structure_String__c = :folderString
        AND Sobject__c = :sobjectType
        AND Document_Type__c = :file.documentType
    ];
    if (docStructure.size() > 0) {
      doc.Public__c = docStructure[0].Public__c;
      doc.Vendor_Access__c = docStructure[0].Vendor_Access__c;
      doc.Borrower_Access__c = docStructure[0].Borrower_Access__c;
      doc.Vendor_Type_Access__c = docStructure[0].Vendor_Type_Access__c;
      doc.Confidential__c = docStructure[0].Confidential__c;
      doc.Private__c = docStructure[0].Private__c;
      doc.Include_for_Term_Sheet_Approval__c = docStructure[0]
        .Include_for_Term_Sheet_Approval__c;
      doc.Upload_Notification_Closer__c = docStructure[0]
        .Upload_Notification_Closer__c;
      doc.Upload_Notification_Loan_Coordinator__c = docStructure[0]
        .Upload_Notification_Loan_Coordinator__c;
      doc.Upload_Notification_Originations__c = docStructure[0]
        .Upload_Notification_Originations__c;
      doc.Upload_Notification_Underwriter__c = docStructure[0]
        .Upload_Notification_Underwriter__c;
      if (docStructure[0].Recorded_Document__c) {
        doc.Recording_Status__c = 'Pending';
      } else {
        doc.Recording_Status__c = 'N/A';
      }
    }

    List<String> folderList = folderString.split(';');
    doc.Type__c = folderList[0];

    if (folderList.size() > 1) {
      doc.Section__c = folderList[1];
    }
    doc.Document_Type__c = file.documentType;
    doc.Active__c = true;
    doc.put(apiFieldName, recordId);

    //doc.Deal__c = recordId;

    doc.Document_Loaded__c = true;
    doc.Added_On__c = System.now();
    system.debug('==saveFileGeneric::doc==' + doc);
    insert doc;

    system.debug(apiFieldName);

    if (apiFieldName == 'Deal__c') {
      boolean ldLDRPart1 = false;
      boolean ldLDRPart2 = false;
      boolean ldPLA = false;
      boolean lcmemo = false;
      boolean ldPSG = false;

      list<Deal_Document__c> dealdoclist = [
        SELECT
          id,
          Deal__c,
          type__c,
          section__c,
          Document_Type__c,
          Deal__r.Email_Send__c,
          Deal__r.Deal_Loan_Number__c,
          Deal__r.Name
        FROM deal_Document__c
        WHERE
          Deal__c = :doc.Deal__c
          AND (type__c = 'Ic Memo'
          OR type__c = 'Loan Document'
          OR section__c = 'LDR'
          OR section__c = 'Principle Loan Documents')
      ];

      if (dealdoclist != null && dealdoclist.size() > 0) {
        for (Deal_Document__c dc : dealdoclist) {
          if (!dc.Deal__r.Email_Send__c) {
            if (dc.type__c == 'Loan Document' && dc.section__c == 'LDR') {
              if (dc.Document_Type__c == 'LDR Part A') {
                ldLDRPart1 = true;
              } else if (dc.Document_Type__c == 'LDR Part B') {
                ldLDRPart2 = true;
              }
            }
            if (
              dc.type__c == 'Loan Document' &&
              dc.section__c == 'Principle Loan Documents'
            ) {
              if (dc.Document_Type__c == 'Loan Agreement') {
                ldPLA = true;
              } else if (dc.Document_Type__c == 'Sponsor Guaranty') {
                ldPSG = true;
              }
            }
            if (
              dc.type__c == 'Ic Memo' &&
              dc.Document_Type__c == 'Final IC Memo'
            ) {
              lcmemo = true;
            }
          } else {
            ldLDRPart1 = false;
          }
        }
      }

      if (ldLDRPart1 && ldLDRPart2 && ldPLA && ldPSG && lcmemo) {
        EmailTemplate et = new EmailTemplate();
        for (EmailTemplate mEmailTemplate : [
          SELECT Id, Subject, Body, HtmlValue
          FROM EmailTemplate
          WHERE
            developername = 'Alston_Bird_Docs_Ready_For_Review_1612504237176'
          LIMIT 1
        ]) {
          et = mEmailTemplate;
        }
        if (et.id != null) {
          system.debug('et:::' + et);
          String emailBody = et.HtmlValue;
          emailBody = emailBody.replace(
            '{{{Opportunity.Deal_Loan_Number__c}}}',
            dealdoclist[0].Deal__r.Deal_Loan_Number__c
          );
          emailBody = emailBody.replace(
            '{{{Opportunity.Name}}}',
            dealdoclist[0].Deal__r.Name
          );
          Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
          email.setToAddresses(new List<string>{ 'karen.wade@alston.com' });
          email.setCCAddresses(new List<string>{ 'leah@cvest.com', 'bryon.harland@cvest.com' });
          email.setTemplateId(et.id);
          email.setSubject('Documents are ready to review for a Term Loan');
          email.setHtmlBody(emailBody);
          email.setSaveAsActivity(true);
          list<Messaging.SendEmailResult> val = Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{ email }
          );

          list<Opportunity> oppList = new List<Opportunity>();

          for (Messaging.SendEmailResult mr : val) {
            if (mr.isSuccess()) {
              system.debug('isSuccess:::');
              Opportunity opp = new Opportunity();
              opp.id = doc.Deal__c;
              opp.email_Send__c = true;
              oppList.add(opp);
            }
          }
          update oppList;
        }
      }

      /*  if(dealdoclist!=null && dealdoclist.size()>=0)
        {   
            system.debug('==saveFileGeneric::dealdoclist=='+dealdoclist);
            
            if(dealdoclist != null && dealdoclist.size()>0)
            {
                for(Deal_Document__c dc : dealdoclist)
                {
                    if(dc.type__c=='Ic Memo')
                    {
                        lcmemo=true;
                    }
                    else if(dc.type__c=='Loan Document' && dc.section__c=='LDR' )
                    {
                        ldr=true;
                    }
                    else
                    {
                        LDP=true;
                    }   
                }
            }  
        } 
        
        system.debug('==saveFileGeneric::true boolean variable=='+'lcmemo='+lcmemo+' ldr='+ldr+' LDP='+LDP );
        if(!lcmemo || !ldr || !LDP)
        {
            system.debug('==saveFileGeneric::false boolean variable=='+'lcmemo'+lcmemo+'ldr'+ldr+'LDP'+LDP );
            if(!lcmemo && doc.type__c=='Ic Memo')
            {
                lcmemo=true;    
            }
            if(!ldr &&(doc.type__c=='Loan Document' && doc.section__c=='LDR'))
            { 
                ldr =true;
            }
            if(!LDP && (doc.type__c=='Loan Document' && doc.section__c=='Principle Loan Documents'))
            {
                LDP=true;
            }
        }   */

      //system.debug('befor if==='+'lcmemo'+lcmemo+'ldr'+ldr+'LDP'+LDP+'opp stage name' +opp[0].stagename );
      /*  if(lcmemo && ldr && LDP && opp[0].stagename=='Closed Won')
        {
            system.debug('==saveFileGeneric::sendemail');
            system.debug('account entity=='+opp[0].AccountId);
            system.debug('dealc=='+opp[0].Id); */
      /*   Account acc =[select id, name from Account where Name='Alston & bird' limit 1];

            Deal_Contact__c dealcon = new Deal_Contact__c(Account__c=acc.id,Deal__c=opp[0].Id,Deal_Contact_Type__c = 'Vendor',Entity_Type__c = 'Vendor',Vendor_Type__c = 'Securitization Legal Counsel');
            insert dealcon; */

      /* String emailBody = 'Dear User,\n\n All Document are Attached.\n \n'+'Ic Memo\n'+'Loan Document - Principle Loan Documents\n'+'Loan Document - LDR\n\n'+'https://cvest--full.lightning.force.com/lightning/r/Opportunity/' +opp[0].id+'/view \n'+'Best Regards,\n CoreVest Team\n';
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new list<string>{'Bryon.Harland@cvest.com'});
            email.setCCAddresses( new list<string>{'bhavesh.jha@cvest.com'});
            email.setSubject('All three Document are Attached');
            email.setPlainTextBody(emailBody);
            email.setSaveAsActivity(true); 
            list<Messaging.SendEmailResult> val = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            for (Messaging.SendEmailResult mr : val) 
            {
                if (mr.isSuccess()) {
                     EmailMessage emailMessage = new EmailMessage();
                     emailMessage.status = '3'; // email was sent
                     emailMessage.relatedToId = opp[0].id; 
                     emailMessage.fromName = 'Dan Perkins'; // from name
                     emailMessage.subject = 'All three Document are Attached'; // email subject
                     emailMessage.htmlBody = emailBody; // email body
                     emailMessage.toAddress = 'karen.wade@alston.com ,sauna.adams@alston.com';
                     emailMessage.ccAddress = 'leah@cvest.com ,gregory@cvest.com';
                     insert emailMessage;
                } 
            }   
            system.debug('dealcon=='+dealcon); */

      //}
    }
    system.debug('==saveFileGeneric::doc::before==' + doc);
    //insert doc;
    //system.debug('==saveFileGeneric::doc::After=='+doc +'lcmemo'+lcmemo +'ldr'+ldr+'LDP'+LDP);

    system.debug(doc);
    system.debug('inserted');
    saveAndLinkFile(doc.Id, 'Attachment_Id__c', a.Name, a.Body, a.contentType);

    delete a;
    file.uploaded = true;
    file.status = 'success';

    system.debug(file);

    //}

    return JSON.serialize(file);
  }

  public class AttachmentWrapper {
    public String name { get; set; }
    public String attachmentId { get; set; }
    public Integer size { get; set; }
    public String documentType { get; set; }
    public String section { get; set; }
    public List<String> typeOptions { get; set; }
    public Boolean uploaded { get; set; }
    public String status { get; set; }
    public Boolean missingType { get; set; }
    public Boolean requireValidations { get; set; }

    public AttachmentWrapper(Attachment a) {
      this.name = a.Name;
      this.attachmentId = a.Id;
      this.size = a.BodyLength;
      this.documentType = '';
      this.section = '';
      this.typeOptions = new List<String>();
      this.uploaded = false;
      this.status = '';
      this.missingType = false;
      this.requireValidations = false;
    }
  }

  @AuraEnabled
  public static Id saveAndLinkFile(
    Id parentId,
    String parentField,
    String fileName,
    Blob data,
    String contentType
  ) {
    Id fileId = saveFileDocument(parentId, fileName, data, contentType);

    FeedItem elm = new FeedItem();
    //elm.Body = base64Data;
    elm.ParentId = parentId;
    elm.RelatedRecordId = fileId;
    elm.Type = 'ContentPost';
    elm.visibility = 'AllUsers';
    insert elm;

    SObject parent = util.idToSObject(parentId);

    ContentVersion vers = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :fileId
    ];
    parent.put(parentField, vers.ContentDocumentId);

    upsert parent;
    return fileId;
  }

  @AuraEnabled
  public static void LinkFile(
    Id parentId,
    String parentField,
    String fileName,
    Id fileId
  ) {
    FeedItem elm = new FeedItem();
    //elm.Body = base64Data;
    elm.ParentId = parentId;
    elm.RelatedRecordId = fileId;
    elm.Type = 'ContentPost';
    elm.visibility = 'AllUsers';
    insert elm;

    SObject parent = util.idToSObject(parentId);

    ContentVersion vers = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :fileId
    ];
    parent.put(parentField, vers.ContentDocumentId);
    //system.debug(parent);
    upsert parent;
  }

  @AuraEnabled
  public static Id saveFileDocument(
    Id parentId,
    String fileName,
    Blob data,
    String contentType
  ) {
    //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

    ContentVersion cont = new ContentVersion();
    cont.Title = fileName;
    cont.PathOnClient = fileName;
    cont.VersionData = data;
    cont.isMajorVersion = false;
    insert cont;
    return cont.Id;
  }

  @AuraEnabled
  public static Map<String,String> getPropertyPicklistsFromDealDoc(String dealDocId){
    try {
      Deal_Document__c dealDoc = [SELECT Id, Deal__c from Deal_Document__c where Id = :dealDocId];

      return new Map<String,String>{'dealId' => dealDoc.Deal__c, 'properties' => getPropertyPicklists(dealDoc.Deal__c)};
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static String getPropertyPicklists(String dealId) {
    List<Map<String, String>> picklists = new List<Map<String, String>>();

    for (Property__c property : [
      SELECT Id, Status__c, Name
      FROM Property__c
      WHERE Deal__c = :dealId AND Status__c IN ('Active','Due Diligence','Pending','Closing')
      ORDER BY Name ASC
    ]) {
      Map<String, String> picklist = new Map<String, String>();
      picklist.put('label', property.Name);
      picklist.put('value', property.Id);

      picklists.add(picklist);
    }

    return JSON.serialize(picklists);
  }

  @AuraEnabled
  public static String getAdvancePicklists(String dealId) {
    List<Map<String, String>> advances = new List<Map<String, String>>();

    for (Advance__c advance : [
      SELECT Id, Name
      FROM Advance__c
      WHERE Deal__c = :dealId
    ]) {
      Map<String, String> picklist = new Map<String, String>();
      picklist.put('label', advance.Name);
      picklist.put('value', advance.Id);

      advances.add(picklist);
    }

    return JSON.serialize(advances);
  }
}