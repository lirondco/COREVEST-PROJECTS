public without sharing class PostClosingHelper {
  public static Map<String, String> dealIdPathMap = new Map<String, String>{
    'Opportunity' => 'Id',
    'Property__c' => 'Deal__c',
    'Advance__c' => 'Deal__c',
    'Deal_Contact__c' => 'Deal__c',
    'Property_Advance__c' => 'Advance__r.Deal__c'
  };

  public static Map<String, String> recordTypeNameField = new Map<String, String>{
    'Opportunity' => 'Record_Type_Name__c',
    'Deal_Contact__c' => 'Record_Type_Name__c',
    'Advance__c' => 'Deal_RecordType__c'
  };

  // Map<String, String>

  public static void createPostClose(Map<Id, Opportunity> recordMap) {
    Map<Id, Post_Closing__c> postClosingMap = new Map<Id, Post_Closing__c>();

    for (Id i : recordMap.keySet()) {
      postClosingMap.put(
        i,
        new Post_Closing__c(
          Deal__c = i,
          Name = recordMap.get(i).Deal_Loan_Number__c + '-PostClosing'
        )
      );
    }

    insert postClosingMap.values();

    List<Post_Closing_Section__c> sections = new List<Post_Closing_Section__c>();
    for (Post_Close_Setting__mdt section : [
      SELECT Id, Record_Type__c, Section_Order__c, sObject_Type__c, MasterLabel
      FROM Post_Close_Setting__mdt
      WHERE sobject_Type__C = 'Opportunity'
    ]) {
      for (Id i : recordMap.keySet()) {
        //system.debug('recordMap.get(i).Record_Type_Name__c');
        //system.debug(recordMap.get(i).Record_Type_Name__c);
        if (recordMap.get(i).Record_Type_Name__c == section.Record_Type__c) {
          Post_Closing_Section__c sect = new Post_Closing_Section__C();
          sect.Name = section.MasterLabel;
          sect.Post_Closing__c = postClosingMap.get(i).Id;
          sect.mdt_Id__c = section.Id;
          sections.add(sect);
        }
      }
    }

    if (sections.size() > 0) {
      insert sections;
    }
  }

  public static void createSections(
    Map<Id, sObject> recordMap,
    String sObjectName
  ) {
    String fieldName = dealIdPathMap.get(sObjectName);
    String recordTypeField = recordTypeNameField.get(sObjectName);

    Map<String, List<sObject>> dealMap = new Map<String, List<sObject>>();
    for (sobject record : recordMap.values()) {
      if (!dealMap.containsKey((String) record.get(fieldName))) {
        dealMap.put((String) record.get(fieldName), new List<sObject>());
      }

      dealMap.get((String) record.get(fieldName)).add(record);
    }

    List<Post_Closing__c> postClosings = [
      SELECT Id, Deal__c
      FROM Post_Closing__c
      WHERE Deal__c IN :dealMap.keySet()
    ];
    Map<Id, Post_Closing__c> postClosingMap = new Map<Id, Post_Closing__c>();

    for (Post_Closing__c postClosing : [
      SELECT Id, Deal__c
      FROM Post_Closing__c
      WHERE Deal__c IN :dealMap.keySet()
    ]) {
      postClosingMap.put(postClosing.Deal__c, postClosing);
    }

    List<Post_Closing_Section__c> sections = new List<Post_Closing_Section__c>();

    for (Post_Close_Setting__mdt section : [
      SELECT Id, Record_Type__c, Section_Order__c, sObject_Type__c, MasterLabel
      FROM Post_Close_Setting__mdt
      WHERE sobject_Type__c = :sObjectName
    ]) {
      for (Id i : recordMap.keySet()) {
        //system.debug('recordMap.get(i).Record_Type_Name__c');
        //system.debug(recordMap.get(i).Record_Type_Name__c);

        String recordType = (String) recordMap.get(i).get(recordTypeField);

        if (recordType == section.Record_Type__c) {
          Post_Closing_Section__c sect = new Post_Closing_Section__C();
          sect.Name = section.MasterLabel;
          //postClosingMap.get(i).Id;
          sect.mdt_Id__c = section.Id;
          sect.put('Advance__c', i);

          if (
            postClosingMap.containsKey((String) recordMap.get(i).get(fieldName))
          ) {
            sect.Post_Closing__c = postClosingMap.get(
                (String) recordMap.get(i).get(fieldName)
              )
              .Id;
            sections.add(sect);
          }
        }
      }
    }

    if (sections.size() > 0) {
      insert sections;
    }
    //for
  }

  public static void createPostClosingItems(
    Map<Id, sObject> recordMap,
    Map<Id, sObject> oldRecordMap,
    String sObjectName,
    String triggerContext
  ) {
    Map<String, List<Document_Structure__mdt>> recordTypeDocStructureMap = new Map<String, List<Document_Structure__mdt>>();

    Set<Id> dealIds = new Set<Id>();

    for (Document_Structure__mdt docStructure : [
      SELECT
        Id,
        Post_Close_Setting__c,
        Post_Closing_Item_Per_County__c,
        Post_Closing_Required__c,
        Post_Closing_Sort__c,
        Post_Closing_Trigger__c,
        Post_Closing_Criteria__c,
        Post_Closing_sObjectType__c,
        Folder_Structure_String__c,
        Document_Type__c,
        Recorded_Document__c,
        Post_Close_Setting__r.MasterLabel,
        Post_Close_Setting__r.Record_Type__c,
        Post_Close_Setting__r.Section_Order__c
      FROM Document_Structure__mdt
      WHERE
        Post_Closing_sObjectType__c = :sObjectName
        AND Post_Closing_Trigger__c = :triggerContext
    ]) {
      if (
        !recordTypeDocStructureMap.containsKey(
          docStructure.Post_Close_Setting__r.Record_Type__c
        )
      ) {
        recordTypeDocStructureMap.put(
          docStructure.Post_Close_Setting__r.Record_Type__c,
          new List<Document_Structure__mdt>()
        );
      }

      recordTypeDocStructureMap.get(
          docStructure.Post_Close_Setting__r.Record_Type__c
        )
        .add(docStructure);
    }
    List<Post_Closing_Item__c> postClosingItems = new List<Post_Closing_Item__c>();
    Map<Id, PostClosingStruct> sectionMap = new Map<Id, PostClosingStruct>();

    for (sObject record : recordMap.values()) {
      String recordTypeFieldNamePath = recordTypeNameField.get(sObjectName);

      // system.debug(Record_Type_Name__c);
      // system.debug(record.get(recordTypeFieldNamePath));
      system.debug(recordTypeFieldNamePath);
      String recordType = (String) record.get(recordTypeFieldNamePath);
      system.debug(recordType);
      if (!recordTypeDocStructureMap.containsKey(recordType)) {
        continue;
      }

      for (
        Document_Structure__mdt docStructure : recordTypeDocStructureMap.get(
          recordType
        )
      ) {
        String expressionString = docStructure.Post_Closing_Criteria__c;

        if (
          evaluateExpresionString(
            record,
            oldRecordMap.get((Id) record.get('Id')),
            expressionString
          )
        ) {
          if (!sectionMap.containsKey(docStructure.Post_Close_Setting__c)) {
            sectionMap.put(
              docStructure.Post_Close_Setting__c,
              new PostClosingStruct(docStructure.Post_Close_Setting__c)
            );
          }

          // String dealIdFieldName = dealIdPathMap.get( sObjectName);
          // String dealId = (String)record.get(dealIdFieldName);
          // dealIds.add(dealId);
          // sectionMap.get(docStructure.Post_Close_Setting__c).addItem(dealId, (String)record.get('Id'), docStructure, record);

          String dealId = (String) record.get('Id');

          if (sObjectName == 'Deal_Contact__c') {
            dealId = (String) record.get('Deal__c');
          }
          // system.debug('--deal id--');
          // system.debug(dealId);
          dealIds.add(dealId);

          if (
            docStructure.Post_Closing_Item_Per_County__c &&
            triggerContext == 'afterUpdate'
          ) {
            String oldCounties = (String) oldRecordMap.get(
                (Id) record.get('Id')
              )
              .get('Distinct_Counties__c');
            String newCounties = (String) record.get('Distinct_Counties__c');

            oldCounties = String.isBlank(oldCounties) ? '' : oldCounties;
            newCounties = String.isBlank(newCounties) ? '' : newCounties;

            Set<String> oldCountySet = new Set<String>(oldCounties.split(';'));
            Set<String> newCountySet = new Set<String>(newCounties.split(';'));

            system.debug(oldCountySet);
            system.debug(newCountySet);

            if (
              expressionString.toLowerCase()
                .contains('ischanged(distinct_counties__c)')
            ) {
              newCountySet.removeAll(oldCountySet);
            }

            // system.debug(newCountySet);

            for (String countyName : newCountySet) {
              sectionMap.get(docStructure.Post_Close_Setting__c)
                .addItem(
                  dealId,
                  (String) record.get('Id'),
                  docStructure,
                  record,
                  countyName
                );
            }
          } else {
            sectionMap.get(docStructure.Post_Close_Setting__c)
              .addItem(
                dealId,
                (String) record.get('Id'),
                docStructure,
                record,
                null
              );
          }
        }
      }

      system.debug(dealIds);
      system.debug(sectionMap);

      // for (Post_Closing_Section__c section : [
      //   SELECT Id, Post_Closing__r.Deal__c, mdt_Id__c, Advance__c
      //   FROM Post_Closing_Section__c
      //   WHERE
      //     (Post_Closing__r.Deal__c IN :dealIds
      //     OR Advance__c IN :dealIds)
      //     AND mdt_Id__c IN :sectionMap.keySet()
      // ]) {
      //   String key = section.Post_Closing__r.Deal__c;
      //   if (sObjectName == 'Advance__c') {
      //     key = section.Advance__c;
      //   }
      //   sectionMap.get(section.mdt_id__c).setIds(key, section.Id);

      //   // postClosingItems.addAll(
      //   //   sectionMap.get(section.mdt_id__c).returnItems()
      //   // );
      // }

      //system.debug(JSON.serialize(postClosingItems));

      // recordTypeDocStructureMap
    }

    for (Post_Closing_Section__c section : [
      SELECT Id, Post_Closing__r.Deal__c, mdt_Id__c, Advance__c
      FROM Post_Closing_Section__c
      WHERE
        (Post_Closing__r.Deal__c IN :dealIds
        OR Advance__c IN :dealIds)
        AND mdt_Id__c IN :sectionMap.keySet()
    ]) {
      String key = section.Post_Closing__r.Deal__c;
      if (sObjectName == 'Advance__c') {
        key = section.Advance__c;
      }
      sectionMap.get(section.mdt_id__c).setIds(key, section.Id);

      // postClosingItems.addAll(
      //   sectionMap.get(section.mdt_id__c).returnItems()
      // );
    }

    for (PostClosingStruct struct : sectionMap.values()) {
      postClosingItems.addAll(struct.returnItems());
    }

    if (postClosingItems.size() > 0) {
      insert postClosingItems;
    }
  }

  // public static String getRecords(String sObjectName){
  //     String
  // }

  public class PostClosingStruct {
    String postClosingSectionMDTid;
    Map<String, List<Post_Closing_Item__c>> postClosingItemDealMap; // = new Map<String, List<Post_Closing_Item__c>>();
    public PostClosingStruct(String postClosingSectionMDTid) {
      this.postClosingSectionMDTid = postClosingSectionMDTid;
      this.postClosingItemDealMap = new Map<String, List<Post_Closing_Item__c>>();
    }

    public void addItem(
      String dealId,
      String recordId,
      Document_Structure__mdt docStructure,
      Sobject record,
      String countyName
    ) {
      String sObjectType = docStructure.Post_Closing_sObjectType__c;

      Post_Closing_Item__c item = new Post_Closing_Item__c();
      item.Sort__c = docStructure.Post_Closing_Sort__c;
      item.Required__c = docStructure.Post_Closing_Required__c;
      // item.Folder_Structure_String__c = docStructure.Folder_Structure_String__c;
      item.mdt_id__c = docStructure.Id;
      item.Name = docStructure.Document_Type__c;
      Item.Recorded_Document__c = docStructure.Recorded_Document__c;
      item.County__c = countyName;

      if (sobjectType == 'Opportunity') {
        //
      } else if (sobjectType == 'Property_Advance__c') {
        item.Advance__c = (String) record.get('Advance__c');
      } else if (sobjectType == 'Deal_Contact__c') {
        item.Business_Entity__c = (String) record.get('Business_Entity__c');
        item.Contact__c = (String) record.get('Contact__c');
      }

      if (!postClosingItemDealMap.containsKey(dealId)) {
        postClosingItemDealMap.put(dealId, new List<Post_Closing_Item__c>());
      }

      postClosingItemDealMap.get(dealId).add(item);
    }

    public void setIds(String dealId, String sectionId) {
      if (!this.postClosingItemDealMap.containsKey(dealId)) {
        return;
      }

      //   this.sectionIdSet = true;

      for (
        Post_Closing_Item__c item : this.postClosingItemDealMap.get(dealId)
      ) {
        item.Post_Closing_Section__c = sectionId;
      }
    }

    public List<Post_Closing_Item__c> returnItems() {
      List<Post_Closing_Item__c> itemsList = new List<Post_Closing_Item__c>();
      for (List<Post_Closing_Item__c> items : postClosingItemDealMap.values()) {
        for (Post_Closing_Item__c item : items) {
          if (String.isNotBlank(item.Post_Closing_Section__c)) {
            itemsList.add(item);
          }
        }
        //if (items.size() > 0) {
        //itemsList.addAll(items);
        //}
      }
      return itemsList;
    }
  }

  public static Boolean evaluateExpresionString(
    sobject record,
    sobject oldrecord,
    String expressionString
  ) {
    system.debug(expressionString);
    if (String.isBlank(expressionString)) {
      return true;
    }
    // expressionString = expressionString.trim(' ', '');

    Boolean result = true;
    for (String expression : expressionString.split('\\|')) {
      if (!evaluateExpression(record, oldrecord, expression)) {
        result = false;
        break;
      }
    }
    return result;
  }

  public static Boolean evaluateExpression(
    sObject record,
    sobject oldrecord,
    String expression
  ) {
    if (String.isBlank(expression)) {
      return true;
    }

    Boolean result = false;

    system.debug(expression);
    if (expression.toLowerCase().contains('ischanged')) {
      String fieldName = expression.substringBetween('(', ')').trim();

      system.debug(fieldName);

      Object value = (Object) oldrecord.get(fieldName);
      Object expectedvalue = (Object) record.get(fieldName);

      system.debug('--is changed--');
      system.debug(value);
      system.debug(expectedvalue);

      result = expectedvalue != value;
    } else {
      List<String> terms = expression.split('-');
      String fieldName = terms[0];
      String operator = terms[1];
      Object expectedValue = terms[2];
      if (expectedValue == 'null') {
        expectedValue = null;
      }

      Object value = (Object) record.get(fieldName);

      // system.debug('--operator expression--');
      // system.debug(fieldName);
      // system.debug(value);
      // system.debug(operator);
      // system.debug(expectedValue);

      if (operator == '=') {
        result = (String) expectedValue == (String) value;
      } else if (operator == '!=') {
        result = (String) expectedValue != (String) value;
      } else if (operator == '>') {
        result =
          (Decimal) value > Decimal.valueOf(String.valueOf(expectedValue)); //(Decimal)expectedValue;
      } else if (operator == '<') {
        result =
          (Decimal) value < Decimal.valueOf(String.valueOf(expectedValue));
      }
    }

    system.debug(result);

    return result;
  }

  @AuraEnabled
  public static List<Deal_Document__c> createDealDocs(
    String recordId,
    List<String> docIds,
    String docStructureId,
    String itemId,
    String sobjectType
  ) {
    // system.debug(docString);

    String advanceId = null;
    if (sobjectType == 'Advance__c') {
      Id dealId = [SELECT Id, Deal__c FROM Advance__c WHERE Id = :recordId]
      .Deal__c;
      advanceId = recordId;
      recordId = dealId;
    }

    // List<String> docStringSplit = docString.split('\\|');
    // String docType = docStringSplit[1];
    // List<String> structStringSplit = docStringSplit[0].split(';');
    // String sectionType = structStringSplit[0];
    // String section = structStringSplit.size() > 1 ? structStringSplit[1] : '';

    List<Deal_Document__c> dealDocs = new List<Deal_Document__c>();

    List<Document_Structure__mdt> docStructure = [
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
        Required__c,
        Default_Exclude_from_Loan_Status__c,
        Upload_Notification_Closer__c,
        Upload_Notification_Loan_Coordinator__c,
        Upload_Notification_Originations__c,
        Upload_Notification_Underwriter__c,
        Document_Type__c,
        Legal_Review__c
      FROM Document_Structure__mdt
      WHERE ID = :docStructureId
    ];

    Map<Id, ContentDocument> docMap = new Map<Id, ContentDocument>(
      [
        SELECT id, LatestPublishedVersion.title, latestpublishedversionid
        FROM contentdocument
        WHERE ID IN :docIds
      ]
    );

    for (String docId : docIds) {
      Deal_Document__c dealDoc = new Deal_Document__c();
      dealDoc.Document_Loaded__c = true;
      dealDoc.Added_On__c = system.now();
      // dealDoc.Document_Type__c = docType;
      dealDoc.Active__c = true;
      dealDoc.Deal__c = recordId;
      dealDoc.Advance__c = advanceId;
      // dealDoc.Type__c = sectionType;
      // dealDoc.Section__c = section;
      // dealDoc.Property__c = propertyId;
      dealDoc.Added_By__c = UserInfo.getUserId();
      dealDoc.File_Name__c = docMap.get(docId).LatestPublishedVersion.title;
      dealDoc.ContentVersion_Id__c = docMap.get(docId).LatestPublishedVersionId;
      // dealDoc.Appraisal__c = appraisalId;
      dealDoc.Post_Closing_Item__c = itemId;
      if (docStructure.size() > 0) {
        List<String> structStringSplit = docStructure[0]
          .Folder_Structure_String__c.split(';');
        String sectionType = structStringSplit[0];
        String section = structStringSplit.size() > 1
          ? structStringSplit[1]
          : '';

        dealDoc.Document_Type__c = docStructure[0].Document_Type__c;
        dealDoc.Type__c = sectionType;
        dealDoc.Section__c = section;

        dealDoc.Public__c = docStructure[0].Public__c;
        dealDoc.Vendor_Access__c = docStructure[0].Vendor_Access__c;
        dealDoc.Borrower_Access__c = docStructure[0].Borrower_Access__c;
        dealDoc.Vendor_Type_Access__c = docStructure[0].Vendor_Type_Access__c;
        dealDoc.Confidential__c = docStructure[0].Confidential__c;
        dealDoc.Private__c = docStructure[0].Private__c;
        dealDoc.Include_for_Term_Sheet_Approval__c = docStructure[0]
          .Include_for_Term_Sheet_Approval__c;
        dealDoc.Upload_Notification_Closer__c = docStructure[0]
          .Upload_Notification_Closer__c;
        dealDoc.Upload_Notification_Loan_Coordinator__c = docStructure[0]
          .Upload_Notification_Loan_Coordinator__c;
        dealDoc.Upload_Notification_Originations__c = docStructure[0]
          .Upload_Notification_Originations__c;
        dealDoc.Upload_Notification_Underwriter__c = docStructure[0]
          .Upload_Notification_Underwriter__c;
        dealDoc.Legal_Review__c = docStructure[0]
          .Legal_Review__c;
      }

      dealDoc.Attachment_Id__c = docId;
      dealDocs.add(dealDoc);
    }

    insert dealDocs;

    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
    for (Deal_Document__c doc : dealDocs) {
      ContentDocumentLink link = new ContentDocumentLink();
      link.ShareType = 'I';
      link.LinkedEntityId = doc.Id;
      link.ContentDocumentId = doc.Attachment_Id__c;
      link.Visibility = 'AllUsers';

      links.add(link);
    }

    insert links;

    update new Post_Closing_Item__c(Id = itemId, Uploaded__c = true);

    return dealDocs;
  }

  @AuraEnabled
  public static string getFiles(String dealId, String itemId) {
    Map<String, String> resp = new Map<String, String>();

    List<Deal_Document__c> docs = [
      SELECT
        id,
        Attachment_Id__c,
        File_Name__c,
        Reviewed_On__c,
        Reviewed_By__c,
        Reviewed_By__r.Name
      FROM Deal_Document__c
      WHERE Post_Closing_Item__c = :itemId
    ];

    // system.debug(docInfoId);

    return JSON.serialize(docs);
  }

  @AuraEnabled
  public static void cloneItem(Id itemId) {
    Post_Closing_Item__c item = (Post_Closing_Item__c) util.getFullObjectById(
      'Post_Closing_Item__c',
      itemId
    );

    system.debug(item);
    // system.debug()

    insert item.clone(false, false, false, false);
  }

  @AuraEnabled(Cacheable=true)
  public static List<List<sObject>> search(String searchQuery) {
    return search.query(searchQuery);
  }
}