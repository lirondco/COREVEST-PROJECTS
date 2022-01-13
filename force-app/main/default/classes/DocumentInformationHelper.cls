public without sharing class DocumentInformationHelper {
  public static void beforeInsert(List<Document_Information__c> newList) {
    Map<String, Map<String, List<Document_Information__c>>> docInfoMap = new Map<String, Map<String, List<Document_Information__c>>>();

    for (Integer i = 0; i < newList.size(); i++) {
      if (String.isNotBlank(newList[i].Doc_String__c)) {
        List<String> splitString = newList[i].Doc_String__c.split('\\|');
        newList[i].Folder__c = splitString[0].replace(';', ' - ');
        if (splitString.size() > 1) {
          newList[i].Document_Type__c = splitString[1];
        }

        String recordType = newList[i].RecordType__c;
        if (
          recordType.contains('Bridge') &&
          recordType != 'Single_Asset_Bridge_Loan'
        ) {
          recordType = 'LOC_Loan';
        }

        if (!docInfoMap.containsKey(recordType)) {
          docInfoMap.put(
            recordType,
            new Map<String, List<Document_Information__c>>()
          );
        }

        if (!docInfoMap.get(recordType).containsKey(newList[i].Doc_String__c)) {
          docInfoMap.get(recordType)
            .put(newList[i].Doc_String__c, new List<Document_Information__c>());
        }

        docInfoMap.get(recordType)
          .get(newList[i].Doc_String__c)
          .add(newList[i]);
      }
    }

    if (docInfoMap.size() > 0) {
      setDefaults(docInfoMap);
    }
  }

  public static void beforeUpdate(
    List<Document_Information__c> newList,
    List<Document_Information__c> oldList
  ) {
    Map<String, Map<String, List<Document_Information__c>>> docInfoMap = new Map<String, Map<String, List<Document_Information__c>>>();
    for (Integer i = 0; i < newList.size(); i++) {
      if (String.isNotBlank(newList[i].Doc_String__c)) {
        List<String> splitString = newList[i].Doc_String__c.split('\\|');
        newList[i].Folder__c = splitString[0].replace(';', ' - ');
        if (splitString.size() > 1) {
          newList[i].Document_Type__c = splitString[1];
        }
      }

      if (newList[i].Set_to_Defaults__c) {
        newList[i].Set_to_Defaults__c = false;
        String recordType = newList[i].RecordType__c;
        if (
          recordType.contains('Bridge') &&
          recordType != 'Single_Asset_Bridge_Loan'
        ) {
          recordType = 'LOC_Loan';
        }

        if (!docInfoMap.containsKey(recordType)) {
          docInfoMap.put(
            recordType,
            new Map<String, List<Document_Information__c>>()
          );
        }

        if (!docInfoMap.get(recordType).containsKey(newList[i].Doc_String__c)) {
          docInfoMap.get(recordType)
            .put(newList[i].Doc_String__c, new List<Document_Information__c>());
        }

        docInfoMap.get(recordType)
          .get(newList[i].Doc_String__c)
          .add(newList[i]);
      }

      if (docInfoMap.size() > 0) {
        setDefaults(docInfoMap);
      }
    }

    if (docInfoMap.size() > 0) {
      setDefaults(docInfoMap);
    }
  }

  public static void afterUpdate(
    List<Document_Information__c> newList,
    List<Document_Information__c> oldList
  ) {
    Set<Id> emailsToSend = new Set<Id>();

    for (Integer i = 0; i < newList.size(); i++) {
      if (
        String.isNotBlank(newList[i].External_Comments__c) &&
        !newList[i].Is_Portal_User__c &&
        newList[i].External_Comments__c != oldList[i].External_Comments__c
      ) {
        emailsToSend.add(newList[i].Id);
      }
    }

    if (emailsToSend.size() > 0) {
      sendNotificationEmails(emailsToSend);
    }
  }

  public static void setDefaults(
    Map<String, Map<String, List<Document_Information__c>>> docInfoMap
  ) {
    Map<String, Map<String, Document_Structure__mdt>> docStructureMap = new Map<String, Map<String, Document_Structure__mdt>>();

    for (Document_Structure__mdt docStructure : [
      SELECT
        Id,
        Folder_Structure_String__c,
        Document_Type__c,
        RecordType__c,
        Required__c,
        C2C_Required_Filtering__c,
        Default_Exclude_from_Loan_Status__c,
        Additional_Borrower_Checklist_Filtering__c
      FROM Document_Structure__mdt
    ]) {
      if (!docStructureMap.containsKey(docStructure.RecordType__c)) {
        docStructureMap.put(
          docStructure.RecordType__c,
          new Map<String, Document_Structure__mdt>()
        );
      }

      docStructureMap.get(docStructure.RecordType__c)
        .put(
          docStructure.Folder_Structure_String__c +
          '|' +
          docStructure.Document_Type__c,
          docStructure
        );
    }

    for (String recordType : docInfoMap.keySet()) {
      for (String folderString : docInfoMap.get(recordType).keySet()) {
        for (
          Document_Information__c docInfo : docInfoMap.get(recordType)
            .get(folderString)
        ) {
          //
          //
          system.debug('doc info stuff');
          system.debug(recordType);
          system.debug(folderString);
          // system.debug(
          //   docStructureMap.get(recordType)
          //     .get(folderString)
          //     .C2C_Required_Filtering__c
          // );
          // system.debug(docStructureMap.get(recordType).get(folderString));
          if(!docStructureMap.containsKey(recordType) ||
          !docStructureMap.get(recordType)
            .containsKey(folderString)) {
              continue;
            }

          if (
            docStructureMap.get(recordType)
              .get(folderString)
              .C2C_Required_Filtering__c == null
          ) {
            docInfo.Required_for_Clear_to_Close__c = docStructureMap.get(
                recordType
              )
              .get(folderString)
              .Required__c;
          } else {
            // docInfo.Required_for_Clear_to_Close__c = docStructureMap.get(recordType).get(folderString).Default_Exclude_from_Loan_Status__c;
            Set<String> dealTypes = opportunity_Helper.compileDealType(
              new Opportunity(LOC_Loan_Type__c = docInfo.Product_Type__c)
            );

            String additionalFilters = docStructureMap.get(recordType)
              .get(folderString)
              .C2C_Required_Filtering__c;
            Set<String> filters = new Set<String>(additionalFilters.split(';'));
            system.debug(filters);
            dealTypes.retainAll(filters);
            if (dealTypes.size() > 0) {
              system.debug(dealTypes);
              docInfo.Required_for_Clear_to_Close__c = true;
            } else {
              docInfo.Required_for_Clear_to_Close__c = false;
            }
          }

          if (
            docStructureMap.get(recordType)
              .get(folderString)
              .Additional_Borrower_Checklist_Filtering__c == null
          ) {
            docInfo.Exclude_from_Loan_Status__c = docStructureMap.get(
                recordType
              )
              .get(folderString)
              .Default_Exclude_from_Loan_Status__c;
          } else {
            // docInfo.Required_for_Clear_to_Close__c = docStructureMap.get(recordType).get(folderString).Default_Exclude_from_Loan_Status__c;
            Set<String> dealTypes = opportunity_Helper.compileDealType(
              new Opportunity(LOC_Loan_Type__c = docInfo.Product_Type__c)
            );

            String additionalFilters = docStructureMap.get(recordType)
              .get(folderString)
              .Additional_Borrower_Checklist_Filtering__c;
            Set<String> filters = new Set<String>(additionalFilters.split(';'));
            system.debug(filters);
            dealTypes.retainAll(filters);
            if (dealTypes.size() > 0) {
              system.debug(dealTypes);
              docInfo.Exclude_from_Loan_Status__c = docStructureMap.get(
                  recordType
                )
                .get(folderString)
                .Default_Exclude_from_Loan_Status__c;
            } else {
              docInfo.Exclude_from_Loan_Status__c = false;
            }
          }
        }
      }
    }
  }

  @future
  public static void sendNotificationEmails(Set<Id> docInfoIds) {
    Id templateId = [
      SELECT Id
      FROM EmailTemplate
      WHERE
        DeveloperName = 'Communities_Loan_Status_External_Comment_Notification'
      LIMIT 1
    ]
    .Id;
    Id orgEmailId = [
      SELECT Id, Address
      FROM OrgWideEmailAddress
      WHERE Address = 'caf-apps@cvest.com'
      LIMIT 1
    ]
    .Id;

    Map<Id, List<Id>> docInfoMap = new Map<Id, List<Id>>();
    for (Document_Information__c docInfo : [
      SELECT Id, Deal__c
      FROM Document_Information__c
      WHERE Id IN :docInfoIds
    ]) {
      if (!docInfoMap.containsKey(docInfo.Deal__c)) {
        docInfoMap.put(docInfo.Deal__c, new List<Id>());
      }

      docInfoMap.get(docInfo.Deal__c).add(docInfo.Id);
    }

    Set<Id> contactIds = new Set<Id>();
    Map<Id, Deal_Contact__c> dealContactMap = new Map<Id, Deal_Contact__c>();
    for (Opportunity o : [
      SELECT
        Id,
        Contact__c,
        (
          SELECT Id, Contact__c, Deal__c
          FROM Deal_Contacts__r
          WHERE Contact__c != NULL AND Entity_Type__c = 'Portal Access'
        )
      FROM Opportunity
      WHERE Id IN :docInfoMap.keySet()
    ]) {
      contactIds.add(o.Contact__c);
      if (o.Deal_Contacts__r != null) {
        for (Deal_Contact__c c : o.Deal_Contacts__r) {
          contactIds.add(c.Contact__c);
          dealContactMap.put(c.Contact__c, c);
        }
      }
    }

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    for (User u : [
      SELECT Id, ContactId, Contact.Email, Email
      FROM User
      WHERE ContactId IN :contactIds
    ]) {
      contactIds.remove(u.ContactId);

      if (dealContactMap.containsKey(u.ContactId)) {
        Deal_Contact__c jc = dealContactMap.get(u.ContactId);

        for (Id docId : docInfoMap.get(jc.Deal__c)) {
          Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
          email.setTemplateId(templateId);
          email.setTargetObjectId(u.ContactId);
          email.setWhatId(docId);
          email.setOrgWideEmailAddressId(orgEmailId);
          emails.add(email);
        }
      }
    }

    if (emails.size() > 0) {
      //system.debug(emails);
      List<Messaging.SendEMailResult> results = Messaging.sendEmail(emails);
    }
  }
}