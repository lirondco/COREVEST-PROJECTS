public without sharing class lightning_Controller {
  //@AuraEnabled
  //public static List<sObject> getRecords(){
  //  //util.

  //  return util.queryRecords('SELECT FirstName, LastName, AccountId, Account.Name FROM CONTACT LIMIT 1000');
  //}

  public static Boolean dataTapeSaving = false;

  @AuraEnabled
  public static List<sObject> fetchLookUpValues(
    String searchKeyWord,
    String ObjectName
  ) {
    system.debug('ObjectName-->' + ObjectName);
    String searchKey = searchKeyWord + '%';

    List<sObject> returnList = new List<sObject>();

    // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
    // String sQuery =  'select id, Name ,Deal_Loan_Number__c from ' +ObjectName + ' where (Name LIKE: searchKey OR Deal_Loan_Number__c LIKE: searchKey) AND (RecordType.Name = Term Loan AND) order by createdDate DESC limit 5';
    //List < sObject > lstOfRecords = Database.query(sQuery);

    for (sObject obj : [
      SELECT id, Name, Deal_Loan_Number__c, RecordType.Name, StageName
      FROM opportunity
      WHERE
        (Name LIKE :searchKey
        OR Deal_Loan_Number__c LIKE :searchKey)
        AND RecordType.Name = 'Term Loan'
        AND StageName != 'Rejected'
        AND StageName != 'Withdrawn'
      ORDER BY createdDate DESC
      LIMIT 5
    ]) {
      returnList.add(obj);
    }
    system.debug('returnList:::' + returnList);
    return returnList;
  }

  @AuraEnabled
  public static Map<String, String> getPicklistFieldValue(
    string objectApiName,
    string fieldAPiName
  ) {
    Map<String, String> options = new Map<String, String>();

    //Schema.DescribeFieldResult fieldResult = Property__c.fieldAPiName.getDescribe();
    Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
      .get(objectApiName)
      .getDescribe()
      .fields.getMap()
      .get(fieldAPiName)
      .getDescribe();

    List<Schema.PicklistEntry> pValues = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry p : pValues) {
      options.put(p.getValue(), p.getLabel());
    }
    return options;
  }

  @AuraEnabled
  public static void createNewProperty(
    Property__c propertyObj,
    string propertyRecordType,
    string dealRecordId
  ) {
    system.debug('propertyObj::::' + propertyObj);
    system.debug('propertyRecordType::::' + propertyRecordType);
    system.debug('dealRecordId::::' + dealRecordId);

    list<Property__c> prList = new List<Property__c>();
    string recordTypeID = [
      SELECT Id, Name
      FROM RecordType
      WHERE Name = :propertyRecordType
      LIMIT 1
    ]
    .id;

    system.debug('recordTypeID::::' + recordTypeID);

    if (recordTypeID != '' && recordTypeID != null) {
      propertyObj.Status__c = 'Due Diligence';
      propertyObj.RecordTypeId = recordTypeID;
      propertyObj.Deal__c = dealRecordId;
    }

    prList.add(propertyObj);

    Database.SaveResult[] srList = Database.insert(prList, false);

    // Iterate through each returned result
    for (Database.SaveResult sr : srList) {
      if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug(
          'Successfully inserted Property. Property ID: ' + sr.getId()
        );
      } else {
        // Operation failed, so get all errors
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug(
            'Property fields that affected this error: ' + err.getFields()
          );
        }
      }
    }
  }

  @AuraEnabled
  public static Map<String, String> getDealIdFromProperty(String propertyId) {
    Map<String, String> response = new Map<String, String>();

    String dealId = [SELECT Deal__c FROM Property__c WHERE Id = :propertyId]
    .Deal__c;

    response.put('dealId', dealId);

    return response;
  }

  @AuraEnabled
  // @ added by Trivikram - To Calculate Total
  public static Map<String, Decimal> calculateTotal(String dealId) {
    Map<String, Decimal> calcutatedTotal = new Map<String, Decimal>();
    system.debug('dealId=>' + dealId);
    if (dealId != null) {
      Decimal purchasePrice = 0;
      Decimal BPOApp = 0;
      Decimal maxLTC = 0;
      Decimal maxLTV = 0;
      Decimal approvedAdv = 0;
      Decimal advanceFee = 0;
      Decimal BPOAppraisal = 0;
      Decimal docPrep = 0;
      Decimal netFunding = 0;
      Decimal renovationRes = 0;
      Decimal disbursementTotal = 0;
      for (Advance__c objAdvance : [
        SELECT
          id,
          Purchase_Price_Total__c,
          BPO_Appraisal_Value_Total__c,
          Max_LTC_Total__c,
          Max_LTV_Total__c,
          Approved_Advance_Amount_Total__c,
          Advance_Fee_Total__c,
          BPO_Appraisal_Fee_Total__c,
          Doc_Prep_Fee_Total__c,
          Net_Funding_Total__c,
          Renovation_Reserve_Total__c,
          Initial_Disbursement_Total__c
        FROM Advance__c
        WHERE Deal__c = :dealId AND Status__c = 'Completed'
      ]) {
        system.debug('objAdvance=>' + objAdvance);
        purchasePrice += objAdvance.Purchase_Price_Total__c;
        BPOApp += objAdvance.BPO_Appraisal_Value_Total__c;
        maxLTC += objAdvance.Max_LTC_Total__c;
        maxLTV += objAdvance.Max_LTV_Total__c;
        approvedAdv += objAdvance.Approved_Advance_Amount_Total__c;
        advanceFee += objAdvance.Advance_Fee_Total__c;
        BPOAppraisal += objAdvance.BPO_Appraisal_Fee_Total__c;
        docPrep += objAdvance.Doc_Prep_Fee_Total__c;
        netFunding += objAdvance.Net_Funding_Total__c;
        renovationRes += objAdvance.Renovation_Reserve_Total__c;
        disbursementTotal += objAdvance.Initial_Disbursement_Total__c;
      }
      calcutatedTotal.put('purchasePrice', purchasePrice);
      calcutatedTotal.put('BPOApp', BPOApp);
      calcutatedTotal.put('maxLTC', maxLTC);
      calcutatedTotal.put('maxLTV', maxLTV);
      calcutatedTotal.put('approvedAdv', approvedAdv);
      calcutatedTotal.put('advanceFee', advanceFee);
      calcutatedTotal.put('BPOAppraisal', BPOAppraisal);
      calcutatedTotal.put('docPrep', docPrep);
      calcutatedTotal.put('netFunding', netFunding);
      calcutatedTotal.put('renovationRes', renovationRes);
      calcutatedTotal.put('disbursementTotal', disbursementTotal);
      system.debug('calcutatedTotal=>' + calcutatedTotal);
    }
    return calcutatedTotal;
  }

  @AuraEnabled
  public static String reparentAttachment(
    String attachmentId,
    String parentId
  ) {
    Attachment a = [SELECT Name, Body FROM Attachment WHERE Id = :attachmentId];
    Attachment b = new Attachment(
      Name = a.Name,
      Body = a.Body,
      ParentId = parentId
    );
    insert b;
    delete a;

    return b.Id;
  }

  @AuraEnabled
  public static void attachFileToParent(
    String contentVersionId,
    String parentId
  ) {
    Appraisal__c appraisal = [
      SELECT Id, Property__r.Deal__c, Property__c, Deal__c
      FROM Appraisal__c
      WHERE Id = :parentId
    ];

    ContentVersion cv = [
      SELECT Id, ContentDocumentId, Title, PathOnClient, FileExtension
      FROM ContentVersion
      WHERE Id = :contentVersionId
    ];

    ContentDocumentLink link = new ContentDocumentLink();
    link.ContentDocumentId = cv.ContentDOcumentId;
    link.LinkedEntityId = parentId;
    link.ShareType = 'I';
    link.Visibility = 'AllUsers';
    insert link;

    List<Deal_Document__c> dealDocs = BorrowerChecklistController.createDealDocs(
      appraisal.Property__r.Deal__c,
      new List<String>{ cv.ContentDOcumentId },
      'Diligence Documents;Property Level Documents|Valuations',
      appraisal.Property__c,
      appraisal.Id
    );

    List<Deal_Document__c> needAppraisals = new List<Deal_Document__c>();
    for (Deal_Document__c doc : dealDocs) {
      if (cv.FileExtension == 'xml') {
        needAppraisals.add(doc);
      }
    }

    if (needAppraisals.size() > 0) {
      system.enqueueJob(new AppraisalParser(needAppraisals));
    }

    return;
  }

  @AuraEnabled
  public static String getSession() {
    Map<String, String> res = new Map<String, String>();
    if (!Test.isRunningTest()) {
      res.put('sessionId', util.getSessionIdFromVFPage(Page.fileUpload));
    } else {
      res.put('sessionId', '1231');
    }

    res.put(
      'endpoint',
      'https://' +
      ('.' + System.URL.getSalesforceBaseURL().getHost())
        .subStringBefore('.com')
        .replace('.salesforce', '')
        .replace('.force', '')
        .replace('.my', '')
        .replace('.visual', '')
        .subStringAfterLast('.') +
      '.salesforce.com'
    );
    if (
      res.get('endpoint').contains('colonyamericanfinance.salesforce') ||
      res.get('endpoint').contains('cvest.salesforce') ||
      res.get('endpoint').contains('corevest.salesforce')
    ) {
      res.put('endpoint', 'https://na54.salesforce.com');
    } else if (res.get('endpoint').contains('full')) {
      res.put('endpoint', 'https://cs215.salesforce.com');
    }

    return JSON.serialize(res);
  }

  @AuraEnabled
  public static String getRecord(String i) {
    return JSON.serialize(util.queryRecordAllFields(Id.valueOf(i)));
  }

  @AuraEnabled
  public static Integer getRelatedListCount(
    String parentId,
    String parentFieldName,
    String sobjectType,
    String whereClause
  ) {
    String queryString =
      'SELECT count(Id) cnt FROM ' +
      sobjectType +
      ' WHERE ' +
      parentFieldName +
      ' = \'' +
      parentId +
      '\'';
    if (String.isNotBlank(whereClause)) {
      queryString += ' AND ' + whereClause;
    }

    system.debug(queryString);
    AggregateResult ar = database.query(queryString);
    //system.debug(ar.get('cnt'));
    return (Integer) ar.get('cnt');
  }

  @AuraEnabled
  public static String getRecordTypeName(String i) {
    if (String.isNotBlank(i) && i instanceof Id) {
      String queryString =
        'SELECT Id, RecordType.DeveloperName FROM ' +
        String.valueOf(Id.ValueOf(i).getSObjectType()) +
        ' WHERE Id =\'' +
        i +
        '\' AND RecordTypeId != null LIMIT 1';
      List<sObject> sobjList = database.query(queryString);
      if (sobjList.size() > 0) {
        return (String) sobjList[0]
          .getsObject('RecordType')
          .get('DeveloperName');
      }
    }
    return 'Master';
  }

  @AuraEnabled
  public static List<sObject> getRecordList(
    String parentId,
    String parentFieldName,
    String sobjectType,
    List<String> fields,
    String sortCol,
    String sortDir,
    String whereClause,
    String orderBy
  ) {
    //Integer skipRecords = Integer.valueOf( ( page - 1 ) * pageSize );
    //Integer maxRecords = Integer.valueOf( pageSize );
    if (sobjectType.equalsIgnoreCase('Property__c')) {
      fields.add('recordTypeId');
    }

    String queryString = 'SELECT ';
    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM ' + sobjectType;

    queryString += ' WHERE '; //+  parentFieldName + ' = \'' + parentId + '\'';

    if (String.isNotBlank(parentFieldName) && String.isNotBlank(parentId)) {
      queryString += parentFieldName + ' = \'' + parentId + '\'';
      if (String.isNotBlank(whereClause)) {
        queryString += ' AND ';
      }
    }

    if (String.isNotBlank(whereClause)) {
      queryString += whereClause;
    }

    if (String.isNotBlank(orderBy)) {
      queryString += ' Order BY ' + orderBy;
    } else if (String.isNotBlank(sortCol)) {
      queryString += ' ORDER BY ' + sortCol + ' ' + sortDir;
    }

    //queryString += ' LIMIT ' + maxRecords;
    //queryString += ' OFFSET ' + skipRecords;

    system.debug(queryString);
    //List<sObject> objs = database.query(queryString);
    //system.debug(objs);
    //return JSON.serialize(database.query(queryString));
    //  return database.query(queryString);
    List<sObject> objs = new List<sObject>();
    objs = database.query(queryString);
    // System.debug('Possible_Duplicate__c 111----->');
    if (sobjectType.equalsIgnoreCase('Property__c')) {
      // System.debug('Possible_Duplicate__c----->');
      Map<string, String> propIds = new Map<string, String>();
      for (sObject sobj : objs) {
        propIds.put((String) sobj.get('id'), (String) sobj.get('recordTypeId'));
      }
      system.debug('--prop ids--');
      system.debug(propIds);
      Map<String, dupcheck__dc3Duplicate__c> duplicateCheckRecords = checkDuplicateFound(
        propIds
      );
      System.debug('duplicateCheckRecords----->' + duplicateCheckRecords);
      for (sObject sobj : objs) {
        if (
          duplicateCheckRecords.containsKey((String) sobj.get('id')) //&& (String)sobj.get('Status__c')=='Active')
        ) {
          sobj.put('Possible_Duplicate__c', true);
        } else {
          sobj.put('Possible_Duplicate__c', false);
        }
      }
    }
    //return database.query(queryString);
    return objs;
  }

  //CIP-2111 - Raj Sirivlu - 1/13/2022. Begin. Added new method getrecordList1 as a clone of getrecordList and changed how the ids are processed.
  @AuraEnabled
  public static List<sObject> getRecordListPropAdva(
    String parentId,
    String parentFieldName,
    String sobjectType,
    List<String> fields,
    String sortCol,
    String sortDir,
    String whereClause,
    String orderBy,
    Boolean showAdvancesDocs
  ) {
    if (sobjectType.equalsIgnoreCase('Property__c')) {
      fields.add('recordTypeId');
    }

    String queryString = 'SELECT ';

    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM ' + sobjectType;

    queryString += ' WHERE ';

    if (showAdvancesDocs == true) {
      parentFieldName = 'Advance__c'; //Override parent field name

      //Get documents for all the advances for the property.
      queryString +=
        parentFieldName +
        ' IN (select Advance__c FROM Property_Advance__c  WHERE Property__c  = \'' +
        parentId +
        '\')';
      if (String.isNotBlank(whereClause)) {
        queryString += ' AND ';
      }
    } else {
      if (String.isNotBlank(parentFieldName) && String.isNotBlank(parentId)) {
        queryString += parentFieldName + ' = \'' + parentId + '\'';
        if (String.isNotBlank(whereClause)) {
          queryString += ' AND ';
        }
      }
    }

    if (String.isNotBlank(whereClause)) {
      queryString += whereClause;
    }

    if (String.isNotBlank(orderBy)) {
      queryString += ' Order BY ' + orderBy;
    } else if (String.isNotBlank(sortCol)) {
      queryString += ' ORDER BY ' + sortCol + ' ' + sortDir;
    }

    system.debug('RS queryString :' + queryString);
    List<sObject> objs = new List<sObject>();
    objs = database.query(queryString);
    // System.debug('Possible_Duplicate__c 111----->');
    if (sobjectType.equalsIgnoreCase('Property__c')) {
      // System.debug('Possible_Duplicate__c----->');
      Map<string, String> propIds = new Map<string, String>();
      for (sObject sobj : objs) {
        propIds.put((String) sobj.get('id'), (String) sobj.get('recordTypeId'));
      }
      system.debug('--prop ids--');
      system.debug(propIds);
      Map<String, dupcheck__dc3Duplicate__c> duplicateCheckRecords = checkDuplicateFound(
        propIds
      );
      System.debug('duplicateCheckRecords----->' + duplicateCheckRecords);
      for (sObject sobj : objs) {
        if (
          duplicateCheckRecords.containsKey((String) sobj.get('id')) //&& (String)sobj.get('Status__c')=='Active')
        ) {
          sobj.put('Possible_Duplicate__c', true);
        } else {
          sobj.put('Possible_Duplicate__c', false);
        }
      }
    }

    return objs;
  }
  //CIP-2111 - Raj Sirivlu - 1/13/2022. End. Added new method getrecordList1 as a clone of getrecordList and changed how the ids are processed.

  @AuraEnabled
  public static List<sobject> getRecords(
    String parentId,
    String parentFieldName,
    String sobjectType,
    List<String> fields,
    Decimal page,
    Decimal pageSize,
    String sortCol,
    String sortDir,
    String whereClause,
    String orderBy
  ) {
    Integer skipRecords = Integer.valueOf((page - 1) * pageSize);
    Integer maxRecords = Integer.valueOf(pageSize);

    String queryString = 'SELECT ';
    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM ' + sobjectType;

    queryString += ' WHERE ' + parentFieldName + ' = \'' + parentId + '\'';
    if (String.isNotBlank(whereClause)) {
      queryString += ' AND ' + whereClause;
    }

    if (String.isNotBlank(orderBy)) {
      queryString += ' Order BY ' + orderBy;
    } else if (String.isNotBlank(sortCol)) {
      queryString += ' ORDER BY ' + sortCol + ' ' + sortDir;
    }

    queryString += ' LIMIT ' + maxRecords;
    queryString += ' OFFSET ' + skipRecords;

    //system.debug(queryString);
    //List<sObject> objs = database.query(queryString);
    //system.debug(objs);
    return database.query(queryString);
  }

  @AuraEnabled
  public static List<sObject> getRelatedList(
    String parentId,
    String parentFieldName,
    String sobjectType,
    String whereClause,
    String orderClause
  ) {
    String queryString = 'SELECT ';

    for (String field : util.getAllFieldNamesForObject(sobjectType)) {
      queryString += field + ', ';
    }
    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM ' + sobjectType;

    queryString += ' WHERE ' + parentFieldName + ' = \'' + parentId + '\'';
    if (String.isNotBlank(whereClause)) {
      queryString += ' AND ' + whereClause;
    }

    if (String.isNotBlank(orderClause)) {
      queryString += ' ORDER BY ' + orderClause;
    }
    system.debug('RS:' + queryString);
    //queryString += ' LIMIT ' + maxRecords;
    //queryString += ' OFFSET ' + skipRecords;

    //List<sObject> objs = database.query(queryString);

    return database.query(queryString);
  }
  /* @Trivikram
   Added for the DupCheck*/
  @AuraEnabled
  public static String getRelatedListPropertyForDupeCheck(
    String parentId,
    String parentFieldName,
    String sobjectType,
    String whereClause,
    String orderClause
  ) {
    String queryString = 'SELECT ';

    for (String field : util.getAllFieldNamesForObject(sobjectType)) {
      queryString += field + ', ';
    }
    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM ' + sobjectType;

    queryString += ' WHERE ' + parentFieldName + ' = \'' + parentId + '\'';
    if (String.isNotBlank(whereClause)) {
      queryString += ' AND ' + whereClause;
    }

    if (String.isNotBlank(orderClause)) {
      queryString += ' ORDER BY ' + orderClause;
    }
    system.debug(
      'queryString getRelatedListPropertyForDupeCheck' + queryString
    );
    //queryString += ' LIMIT ' + maxRecords;
    //queryString += ' OFFSET ' + skipRecords;

    //List<sObject> objs = database.query(queryString);
    System.debug('queryString Dupe check----> ' + queryString);
    List<sObject> objs = new List<sObject>();
    objs = database.query(queryString);
    List<propertyListWrapper> resultsData = new List<propertyListWrapper>();
    if (sobjectType.equalsIgnoreCase('Property__c')) {
      Map<string, String> propIds = new Map<string, String>();
      for (sObject sobj : objs) {
        propIds.put((String) sobj.get('id'), (String) sobj.get('recordTypeId'));
      }
      Map<String, dupcheck__dc3Duplicate__c> duplicateCheckRecords = checkDuplicateFound(
        propIds
      );

      // System.debug('duplicateCheckRecords----> '+duplicateCheckRecords);
      Set<String> dupeRecords = new Set<String>();

      Map<String, dupcheck__dc3Duplicate__c> matchRecords = new Map<String, dupcheck__dc3Duplicate__c>();

      for (dupcheck__dc3Duplicate__c dup : duplicateCheckRecords.values()) {
        dupeRecords.add(dup.dupcheck__MatchObject__c);
        // matchRecords.put(dup.dupcheck__SourceObject__c, dup);
      }

      Map<Id, property__c> dupRecords = new Map<ID, property__c>(
        [
          SELECT
            Id,
            Name,
            Property_Name__c,
            recordType.Name,
            deal__r.StageName,
            Status__c,
            City__c,
            State__c,
            ZipCode__c,
            Loan_Type__c,
            Servicer_Investor_Loan_Number__c,
            Servicer_Loan_Number__c,
            APN__c
          FROM property__c
          WHERE id IN :dupeRecords
        ]
      );
      System.debug('dupRecords----> ' + dupRecords);
      for (sObject sobj : objs) {
        if (
          duplicateCheckRecords.containsKey((String) sobj.get('id')) // && (String)sobj.get('Status__c')=='Active')
        ) {
          // resultsData.add(new propertyListWrapper(sobj, 'Yes', duplicateCheckRecords.get((String)sobj.get('id')).dupcheck__Score__c, dupRecords.get(duplicateCheckRecords.get((String)sobj.get('id')).dupcheck__SourceObject__c)));
          resultsData.add(
            new propertyListWrapper(
              sobj,
              'Yes',
              duplicateCheckRecords.get((String) sobj.get('id'))
                .dupcheck__Score__c,
              dupRecords.get(
                duplicateCheckRecords.get((String) sobj.get('id'))
                  .dupcheck__MatchObject__c
              )
            )
          );
        } /*else{    
resultsData.add(new propertyListWrapper(sobj, 'No', null, null));
}*/
      }
    }

    return Json.serialize(resultsData);
  }

  @AuraEnabled
  public static List<sObject> upsertRecords(List<sObject> records) {
    System.debug('records----->  ' + records);
    //List<sObject> toInsert = new List<sObject>();
    //List<sObject> toUpdate = new List<sObject>();

    //for( sObject s : records){
    //    if(s.Id != null){
    //        toUpdate.add(s);
    //    }else{
    //        toInsert.add(s);
    //    }
    //}

    //List<Database.SaveResult> resUpd = Database.update(toUpdate, false);
    //List<Database.SaveResult> resInsert = Database.insert(toInsert, false);

    //for( Database.SaveResult r : resUpd ){
    //    if( !r.isSuccess() ){
    //        system.debug(r.getErrors()[0].getMessage() );
    //        throw new AuraHandledException(r.getErrors()[0].getMessage());

    //    }
    //}

    //for( Database.SaveResult r : resInsert ){
    //    if( !r.isSuccess() ){
    //        system.debug(r.getErrors()[0].getMessage());
    //        throw new AuraHandledException(r.getErrors()[0].getMessage());
    //    }
    //}

    //Set<Id> ids = new Set<Id>();
    //for(sObject s : records){
    //    ids.add((Id)s.get('Id'));
    //}

    //return records;

    return lightning_Util.upsertRecords(records);
  }

  @AuraEnabled
  public static sObject upsertRecord(sObject record) {
    try {
      upsert record;
    } catch (DMLException e) {
      throw new AuraHandledException(e.getDmlMessage(0));
    }

    return record; //util.queryRecordAllFields((Id)record.get('Id'));
  }

  @AuraEnabled
  public static List<SObject> searchRecords(
    String searchTerm,
    String sObjectName,
    String whereClause,
    Integer lim
  ) {
    List<String> sObjectNames = new List<String>{ sobjectName };
    if (lim == null) {
      lim = 100;
    }
    String queryString =
      'FIND \'' +
      searchTerm +
      '*\' IN ALL FIELDS RETURNING ';
    for (String s : sObjectNames) {
      queryString += s + '(id,name';
      if (String.isNotBlank(whereClause)) {
        queryString += ' WHERE ' + whereClause;
      }
      queryString += ' LIMIT ' + lim + '),';
    }
    queryString = queryString.subStringBeforeLast(',');
    system.debug(queryString);
    List<sObject> results = new List<sObject>();
    for (List<SObject> s : search.query(queryString)) {
      results.addAll(s);
    }
    results.sort();
    //system.debug(results);
    return results;
  }

  @AuraEnabled
  public static String getUserId() {
    return UserInfo.getUserId();
  }

  @AuraEnabled
  public static Id saveAttachment(
    Id parentId,
    String fileName,
    String base64Data,
    String contentType
  ) {
    //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

    system.debug(parentId);
    system.debug(fileName);
    system.debug(contentType);

    Attachment a = new Attachment();
    a.parentId = parentId;

    a.Body = EncodingUtil.base64Decode(base64Data);
    a.Name = fileName;
    a.ContentType = contentType;

    insert a;
    return a.Id;

    // return null;
  }

  @AuraEnabled
  public static Id saveTheChunk(
    Id parentId,
    String fileName,
    String base64Data,
    String contentType,
    String fileId
  ) {
    if (fileId == '') {
      fileId = saveAttachment(parentId, fileName, base64Data, contentType);
    } else {
      appendToAttachment(fileId, base64Data);
    }

    return Id.valueOf(fileId);
  }

  private static void appendToAttachment(Id fileId, String base64Data) {
    Attachment attch = [SELECT Id, body FROM Attachment WHERE Id = :fileId];
    attch.Body = EncodingUtil.base64Decode(
      EncodingUtil.base64Encode(attch.Body) + base64Data
    );

    upsert attch;
  }

  @AuraEnabled
  public static Boolean deleteRecord(sObject record) {
    try {
      delete record;
    } catch (DmlException e) {
      throw new AuraHandledException('Failed to delete');
    }

    return true;
  }

  @AuraEnabled
  public static Boolean deleteRecords(List<sObject> records) {
    try {
      delete records;
    } catch (DmlException e) {
      throw new AuraHandledException('Failed to delete');
    }

    return true;
  }

  @AuraEnabled
  public static String saveDataTape(String data, String dealId) {
    dataTapeSaving = true;
    Opportunity op = [SELECT Id, StageName FROM Opportunity WHERE Id = :dealId];
    //try {
    Boolean datatapeChanged = false;
    List<Property__c> records = (List<Property__c>) JSON.deserialize(
      data,
      List<Property__c>.class
    );

    List<Property__c> toDelete = new List<Property__c>();
    for (Integer i = records.size() - 1; i >= 0; --i) {
      if (records[i].Id == null) {
        datatapeChanged = true;
      }

      if (records[i].Status__c == 'Inactive') {
        datatapeChanged = true;
      }

      if (records[i].IsDeleted) {
        toDelete.add(records.remove(i));
        datatapeChanged = true;
      }
    }

    if (toDelete.size() > 0) {
      delete toDelete;
    }

    Map<String, List<Property__c>> unitMap = new Map<String, List<Property__c>>();

    List<Property__c> properties = new List<Property__c>();
    for (Integer i = 0; i < records.size(); i++) {
      //if(records[i].Name == null || String.isBlank(records[i].Name])){

      //}

      if (
        records[i].Property_Type__c != '2-4 Unit' &&
        records[i].Property_Type__c != 'Multifamily' &&
        records[i].Property_Type__c != 'Mixed Use'
      ) {
        records[i].Is_Sub_Unit__c = false;
        records[i].Parent_Property__c = null;
      } else if (
        records[i].Name != records[i].Property_Name__c &&
        String.isNotBlank(records[i].Property_Name__c) &&
        records[i].Parent_Property__c == null
      ) {
        if (!unitMap.containsKey(records[i].Property_Name__c)) {
          unitMap.put(records[i].Property_Name__c, new List<Property__c>());
        }
        unitMap.get(records[i].Property_Name__c).add(records[i]);
      }

      if (
        records[i].Name != null &&
        String.isNotBlank(records[i].Name) &&
        records[i].Property_Type__c != 'Parent'
      ) {
        properties.add(records[i]);
      }
    }

    for (Property__c parentProperty : [
      SELECT Id, Name
      FROM Property__c
      WHERE
        Deal__c = :dealId
        AND Name IN :unitMap.keySet()
        AND Is_Parent__c = TRUE
    ]) {
      for (Property__c p : unitMap.get(parentProperty.Name)) {
        p.Parent_Property__c = parentProperty.Id;
        p.Is_Sub_Unit__c = true;
      }
      unitMap.remove(parentProperty.Name);
    }

    List<Property__c> parents = new List<Property__c>();
    for (String propertyName : unitMap.keySet()) {
      parents.add(
        new Property__c(
          Name = propertyName,
          Deal__c = dealId,
          Property_Name__c = propertyName,
          Status__c = 'Active',
          Is_Parent__c = true
        )
      );
    }

    if (parents.size() > 0) {
      parents = (List<Property__c>) lightning_Util.upsertRecords(parents);
    }
    for (Property__c parent : parents) {
      for (Property__c p : unitMap.get(parent.Name)) {
        p.Parent_Property__c = parent.Id;
        p.Is_Sub_Unit__c = true;
      }
    }

    List<Property__c> propInsert = new List<Property__c>();
    List<Property__c> propUpdate = new List<Property__c>();

    Map<String, Schema.SobjectField> propertyFieldMap = Schema.getGlobalDescribe()
      .get('Property__c')
      .getDescribe()
      .fields.getMap();

    for (Property__c p : properties) {
      if (p.Id == null) {
        Map<String, Object> fieldMap = p.getPopulatedFieldsAsMap();
        Property__c p2 = new Property__c();
        for (String field : fieldMap.keySet()) {
          if (
            fieldMap.get(field) != null &&
            propertyFieldMap.get(field).getDescribe().isCreateable()
          ) {
            p2.put(field, fieldMap.get(field));
          }
        }

        propInsert.add(p2);
      } else {
        propUpdate.add(p);
      }
    }

    List<Property__c> propertiesTemp = new List<Property__c>();
    // propInsert = (List<Property__c>)lightning_Util.upsertRecords(propInsert);
    for (Integer i = 0; i < propInsert.size(); i++) {
      propertiesTemp.add(propInsert[i]);

      if (propertiesTemp.size() == 200) {
        lightning_Util.upsertRecords(propertiesTemp);
        propertiesTemp.clear();
      }
    }

    if (propertiesTemp.size() > 0) {
      lightning_Util.upsertRecords(propertiesTemp);
    }

    propertiesTemp.clear();

    //propUpdate = (List<Property__c>)lightning_Util.upsertRecords(propUpdate);

    for (Integer i = 0; i < propUpdate.size(); i++) {
      propertiesTemp.add(propUpdate[i]);

      if (propertiesTemp.size() == 200) {
        lightning_Util.upsertRecords(propertiesTemp);
        propertiesTemp.clear();
      }
    }

    if (propertiesTemp.size() > 0) {
      lightning_Util.upsertRecords(propertiesTemp);
    }

    propUpdate.addAll(propInsert);

    Settings__mdt setting = [
      SELECT id, developername, Enable_Data_Tape_Change_Email__c
      FROM settings__mdt
      WHERE DeveloperName = 'Universal_Settings'
      LIMIT 1
    ];
    if (
      dataTapeChanged &&
      op.StageName == 'Underwriting' &&
      setting.Enable_Data_Tape_Change_Email__c
    ) {
      property_Helper.sendDataTapeNotification(dealId);
    }

    return JSON.serialize(propUpdate);
  }

  @AuraEnabled
  public static String getTemplate(String fileName) {
    System.debug(0);
    ContentDocument doc = [
      SELECT Id, Title
      FROM ContentDocument
      WHERE Title = :fileName
      LIMIT 1
    ];
    System.debug(1);
    ContentVersion cv = [
      SELECT id, versiondata, createddate
      FROM contentversion
      WHERE contentdocumentid = :doc.Id
      ORDER BY createddate DESC
      LIMIT 1
    ];

    return JSON.serialize(cv.versiondata);
  }

  @AuraEnabled
  public static String givePortalAccess(String recordId) {
    Set<Id> contactIds = new Set<Id>();
    for (Opportunity o : [
      SELECT
        Id,
        Contact__c,
        (
          SELECT Id, Contact__c
          FROM Deal_Contacts__r
          WHERE Contact__c != NULL AND Entity_Type__c = 'Portal Access'
        )
      FROM Opportunity
      WHERE Id = :recordId
    ]) {
      system.debug(o);
      contactIds.add(o.Contact__c);
      if (o.Deal_Contacts__r != null) {
        for (Deal_Contact__c c : o.Deal_Contacts__r) {
          contactIds.add(c.Contact__c);
        }
      }
    }

    system.debug(contactIds);

    List<User> portalUsers = new List<User>();
    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Customer Portal User'
      LIMIT 1
    ];

    for (User u : [
      SELECT Id, ContactId
      FROM User
      WHERE ContactId IN :contactIds
    ]) {
      contactIds.remove(u.ContactId);
    }

    for (Contact c : [
      SELECT Id, Email, FirstName, LastName
      FROM Contact
      WHERE Id IN :contactIds
    ]) {
      User u = new User(
        ContactId = c.Id,
        username = c.Email,
        firstName = c.FirstName,
        lastName = c.LastName,
        email = c.Email,
        communityNickName = c.LastName + '_' + c.FirstName,
        alias = string.valueof(
          c.FirstName.substring(0, 1) + c.LastName.substring(0, 1)
        ),
        profileid = p.Id,
        emailencodingkey = 'UTF-8',
        languagelocalekey = 'en_US',
        localesidkey = 'en_US',
        timezonesidkey = 'America/Los_Angeles'
      );

      portalUsers.add(u);
    }

    system.debug(portalUsers);

    Database.DMLOptions dlo = new Database.DMLOptions();
    dlo.EmailHeader.triggerUserEmail = true;

    List<Database.saveResult> sr = Database.Insert(portalUsers, dlo);

    return JSON.serialize(portalUsers);
  }

  @AuraEnabled
  public static Map<String, Object> getDocumentData(String contentVersionId) {
    Integer heapSize = Limits.getLimitHeapSize() - Limits.getHeapSize();
    system.debug(heapSize);
    List<ContentVersion> cv = [
      SELECT Id, VersionData, Title, ContentSize, PathOnClient
      FROM ContentVersion
      WHERE Id = :contentVersionId AND ContentSize < :heapSize
    ];
    Map<String, Object> resp = new Map<String, Object>();
    resp.put('data', null);

    if (cv.size() == 0) {
      cv = [
        SELECT Id, Title, ContentSize, PathOnClient
        FROM ContentVersion
        WHERE Id = :contentVersionId
      ];

      resp.put('error', 'deleted');
      resp.put('title', 'fake-path');
      resp.put('size', 0);
      if (cv.size() > 0) {
        resp.put('title', cv[0].PathOnClient);
        resp.put('size', cv[0].ContentSize);
        resp.put('error', 'error');
      }
    } else {
      resp.put('data', EncodingUtil.base64Encode(cv[0].VersionData));
      resp.put('title', cv[0].PathOnClient);
      resp.put('size', cv[0].ContentSize);
    }

    return resp;
  }

  @AuraEnabled
  public static String getDocuments(
    String recordId,
    String userType,
    String accountId,
    String accountType
  ) {
    String queryString = '';

    if (userType == 'internal') {
      queryString = 'SELECT Id, Deal__r.Name, Advance__r.Name, Deal__r.Deal_Loan_Number__c, Folder_String__c, ContentVersion_Id__c, Attachment_Id__c, ';
      queryString += 'Vendor_Type_Access__c, Property__r.Name, Property__r.Advance__r.Name, Property__c, Document_Type__c FROM Deal_Document__c ';
      queryString +=
        'WHERE Deal__c = \'' +
        recordId +
        '\' AND Attachment_Id__c != null AND ContentVersion_Id__c != null AND Is_Deleted__c = false';
    } else if (userType == 'vendor') {
      queryString = 'SELECT Id, Deal__r.Name, Advance__r.Name, Deal__r.Deal_Loan_Number__c, Folder_String__c, ContentVersion_Id__c, Attachment_Id__c, ';
      queryString += 'Vendor_Type_Access__c, Property__r.Name, Property__r.Advance__r.Name, Property__c, Document_Type__c FROM Deal_Document__c ';
      queryString +=
        'WHERE Deal__c = \'' +
        recordId +
        '\' AND Attachment_Id__c != null AND ContentVersion_Id__c != null AND Vendor_Access__c = true AND Is_Viewable__c = true AND Is_Deleted__C = false ';
    } else if (userType == 'borrower') {
      queryString = 'SELECT Id, Deal__r.Name, Advance__r.Name, Deal__r.Deal_Loan_Number__c, Folder_String__c, ContentVersion_Id__c, Attachment_Id__c, ';
      queryString += 'Vendor_Type_Access__c, Property__r.Name, Property__r.Advance__r.Name, Property__c, Document_Type__c FROM Deal_Document__c ';
      queryString +=
        'WHERE Deal__c = \'' +
        recordId +
        '\' AND Attachment_Id__c != null AND ContentVersion_Id__c != null AND Borrower_Access__c = true AND Is_Viewable__c = true AND Is_Deleted__c = false ';
    }

    List<Deal_Document__c> docs = (List<Deal_Document__c>) database.query(
      queryString
    );
    if (userType == 'vendor') {
      for (Integer i = docs.size() - 1; i >= 0; i--) {
        Boolean isVisible = true;
        if (String.isNotBlank(docs[i].Vendor_Type_Access__c)) {
          Set<String> filterSet = new Set<String>(
            docs[i].Vendor_Type_Access__c.split(';')
          );
          isVisible =
            filterSet.contains(accountId) || filterSet.contains(accountType);
        }

        if (!isVisible) {
          docs.remove(i);
        }
      }
    } else if (userType == 'borrower') {
    }

    Map<Id, Deal_Document__C> docMap = new Map<Id, Deal_Document__c>();
    for (Deal_Document__c doc : docs) {
      docMap.put(doc.ContentVersion_Id__c, doc);
    }

    for (ContentVersion cv : [
      SELECT Id, FileExtension
      FROM ContentVersion
      WHERE ID IN :docMap.keySet()
    ]) {
      if (cv.FileExtension == 'xml') {
        docMap.remove(cv.Id);
      }
    }

    return JSON.serialize(docMap.values());
  }

  //@AuraEnabled
  //public static List<sObject> getOpportunities(Id accountId){
  //    String qs = 'SELECT ';
  //    List<String> sl = new List<String>{
  //        'Initial Review',
  //        'Data Tape Received',
  //        'Term Sheet Issued',
  //        'Term Sheet Signed/Deposit Collected',
  //        'Underwriting',
  //        'Approved BY Committee',
  //        'Closed Won'
  //    };

  //    for(String field : util.getAllFieldNamesForObject('Opportunity')){
  //        qs += field + ', ';
  //    }
  //    qs += 'Underwriter__r.Name';

  //    qs += ' FROM Opportunity WHERE '
  //        + ' RecordType.Name = \'Term Loan\''
  //        + ' AND StageName IN :sl'
  //        + ' AND Anticipated_Closing_Date__c != null';

  //    System.debug(qs);

  //    return Database.query(qs);

  //}

  // public static

  /*@Trivikram
   For the Dupe Check*/

  public static Map<String, dupcheck__dc3Duplicate__c> checkDuplicateFound(
    Map<String, String> newList
  ) {
    String recordType = 'LOC_Loan';

    return checkDuplicateFoundByRecordType(newList, recordType);
  }

  @AuraEnabled
  public static Map<String, dupcheck__dc3Duplicate__c> checkDuplicateFoundByRecordType(
    Map<String, String> newList,
    String recordType
  ) {
    Decimal score = 65.00;
    Dupecheck_Setting__mdt[] settings = [
      SELECT MasterLabel, dupecheckscore__c
      FROM Dupecheck_Setting__mdt
      WHERE MasterLabel = 'Default'
    ];
    if (settings != null && !settings.isEmpty()) {
      score = settings[0].dupecheckscore__c;
    }
    Map<String, dupcheck__dc3Duplicate__c> duplicateCheckRecords = new Map<String, dupcheck__dc3Duplicate__c>();
    Map<String, List<dupcheck__dc3Duplicate__c>> dupMap = new Map<String, List<dupcheck__dc3Duplicate__c>>();
    Set<String> propIds = new Set<String>(newList.keySet());
    for (dupcheck__dc3Duplicate__c dup : [
      SELECT
        Id,
        dupcheck__Score__c,
        dupcheck__MatchObject__c,
        dupcheck__SourceObject__c,
        dupcheck__SourceRecordType__c,
        dupcheck__MatchRecordType__c
      FROM dupcheck__dc3Duplicate__c
      WHERE
        dupcheck__Score__c >= :score
        AND dupcheck__SourceObject__c IN :newList.keyset()
    ]) {
      if (!dupMap.containsKey(dup.dupcheck__MatchObject__c)) {
        dupMap.put(
          dup.dupcheck__MatchObject__c,
          new List<dupcheck__dc3Duplicate__c>()
        );
        propIds.remove(dup.dupcheck__SourceObject__c);
      }

      dupMap.get(dup.dupcheck__MatchObject__c).add(dup);
    }

    for (Property__c duplicateProperty : [
      SELECT Id, Deal_Record_Type__c
      FROM Property__c
      WHERE Id IN :dupMap.keySet()
    ]) {
      if (duplicateProperty.Deal_Record_Type__c == recordType) {
        for (dupcheck__dc3Duplicate__c dup : dupMap.get(duplicateProperty.Id)) {
          if (
            !duplicateCheckRecords.containsKey(dup.dupcheck__SourceObject__c)
          ) {
            duplicateCheckRecords.put(dup.dupcheck__SourceObject__c, dup);
          } else {
            if (
              dup.dupcheck__Score__c >
              duplicateCheckRecords.get(dup.dupcheck__SourceObject__c)
                .dupcheck__Score__c
            ) {
              duplicateCheckRecords.put(dup.dupcheck__SourceObject__c, dup);
            }
          }
        }
      }
    }

    if (propIds.size() > 0) {
      dupMap = new Map<String, List<dupcheck__dc3Duplicate__c>>();

      for (dupcheck__dc3Duplicate__c dup : [
        SELECT
          Id,
          dupcheck__Score__c,
          dupcheck__MatchObject__c,
          dupcheck__SourceObject__c,
          dupcheck__SourceRecordType__c,
          dupcheck__MatchRecordType__c
        FROM dupcheck__dc3Duplicate__c
        WHERE
          dupcheck__Score__c >= :score
          AND dupcheck__MatchObject__c IN :newList.keyset()
      ]) {
        if (!dupMap.containsKey(dup.dupcheck__SourceObject__c)) {
          dupMap.put(
            dup.dupcheck__SourceObject__c,
            new List<dupcheck__dc3Duplicate__c>()
          );
        }
        String temp1 = dup.dupcheck__SourceObject__c;
        dup.dupcheck__SourceObject__c = dup.dupcheck__MatchObject__c;
        dup.dupcheck__MatchObject__c = temp1;

        dupMap.get(temp1).add(dup);
      }

      for (Property__c duplicateProperty : [
        SELECT Id, Deal_Record_Type__c
        FROM Property__c
        WHERE Id IN :dupMap.keySet()
      ]) {
        if (duplicateProperty.Deal_Record_Type__c == recordType) {
          for (
            dupcheck__dc3Duplicate__c dup : dupMap.get(duplicateProperty.Id)
          ) {
            // String tem
            if (
              !duplicateCheckRecords.containsKey(dup.dupcheck__SourceObject__c)
            ) {
              duplicateCheckRecords.put(dup.dupcheck__SourceObject__c, dup);
            } else {
              if (
                dup.dupcheck__Score__c >
                duplicateCheckRecords.get(dup.dupcheck__SourceObject__c)
                  .dupcheck__Score__c
              ) {
                duplicateCheckRecords.put(dup.dupcheck__SourceObject__c, dup);
              }
            }
          }
        }
      }
    }

    return duplicateCheckRecords;
  }

  public class propertyListWrapper {
    public String propertyName { get; set; }
    public String propertyType { get; set; }
    public String propertyCity { get; set; }
    public String propertyState { get; set; }
    public String propertyZip { get; set; }

    public String possibleDuplicate { get; set; }
    public String recordType { get; set; }
    public String dealStage { get; set; }
    public Decimal score { get; set; }
    public String active { get; set; }
    public String propName { get; set; }
    public String address { get; set; }
    public String city { get; set; }
    public String state { get; set; }
    public String zip { get; set; }
    public String Status { get; set; }
    public String servicerInvestorLoanNumber { get; set; }
    public String APN { get; set; }
    public String servicerLoanNumber { get; set; }
    public String LoanType { get; set; }
    public propertyListWrapper(
      sObject property,
      String possibleDuplicate,
      Decimal score,
      Property__c prop
    ) {
      if (property != null) {
        this.propertyName = (String) property.get('Name');
        this.propertyType = (String) property.get('Property_Type__c');
        this.propertyCity = (String) property.get('City__c');
        this.propertyState = (String) property.get('State__c');
        this.propertyZip = (String) property.get('ZipCode__c');
      }

      this.possibleDuplicate = possibleDuplicate;
      this.score = score;
      if (prop != null) {
        this.recordType = prop.recordtype.Name;
        this.dealStage = prop.deal__r.StageName;
        this.propName = prop.Property_Name__c;
        this.address = prop.Name;
        this.city = prop.City__c;
        this.state = prop.State__c;
        this.zip = prop.zipCode__c;
        this.APN = prop.APN__c;
        this.Status = prop.Status__c;
        this.servicerInvestorLoanNumber = prop.Servicer_Investor_Loan_Number__c;
        this.servicerLoanNumber = prop.Servicer_Loan_Number__c;
        this.LoanType = prop.Loan_Type__c;
      }
    }
  }

  @AuraEnabled
  public static Settings__mdt queryUniversalSettings() {
    List<String> fieldNames = new List<String>{
      'Num_of_Days_to_Transfer_Lead__c',
      'Berkadia_CC_Emails__c',
      'Berkadia_To_Emails__c',
      'Disable_Advance_Trigger__c',
      'Disable_Deal_Contact_Trigger__c',
      'Disable_Deal_Document_Trigger__c',
      'Disable_Opportunity_Trigger__c',
      'Disable_Post_Close_Trigger__c',
      'Disable_Property_Advance_Trigger__c',
      'Disable_Property_Trigger__c',
      'Enable_Data_Tape_Change_Email__c',
      'Enable_SmartyStreets_API__c',
      'Require_Address_Valid_on_Pricing__c',
      'Require_Address_Val_on_UW_Submit__c',
      'Require_AVM_Sync_on_Pricing__c',
      'Require_AVM_Sync_on_UW_Submission__c',
      'Require_X_Author_Validation_on_Pricing__c',
      'Require_X_Author_Validation_on_UW_Submis__c',
      'Validated_Address_Threshold__c'
    };

    String queryString = 'SELECT ';
    for (String fieldName : fieldNames) {
      queryString += fieldName + ',';
    }

    queryString += ' Id FROM Settings__mdt';
    queryString += ' WHERE DeveloperName = \'Universal_Settings\'';

    return (Settings__mdt) database.query(queryString);
  }

  @AuraEnabled
  public static Boolean isXAuthorSaved(Id dealId) {
    List<Model_Save_Log__c> logs = [
      SELECT Id, Model_Type__c
      FROM Model_Save_Log__c
      WHERE Model_Type__c = :'Originations Model'
    ];

    return logs.size() > 0;
  }

  @AuraEnabled
  public static Decimal calculateSmartyStreetsVerified(Id dealId) {
    Decimal validatedPercentage = 0;
    List<Property__c> properties = [
      SELECT
        Id,
        (
          SELECT Id, Has_Same_Name__c
          FROM Validated_Property_Addresses__r
          WHERE Has_Same_Name__c = TRUE
        )
      FROM Property__c
      WHERE
        Deal__c = :dealId
        AND Status__c = 'Active'
        AND Is_Parent__c = FALSE
        AND Property_Type__c NOT IN ('Mixed Use', 'Multifamily')
    ];

    Decimal numOfProperties = properties.size();
    Decimal numOfValidatedProperties = 0;
    for (Property__c prop : properties) {
      if (prop.Validated_Property_Addresses__r.size() > 0) {
        numOfValidatedProperties++;
      }
    }

    if (numOfProperties > 0) {
      validatedPercentage = numOfValidatedProperties / numOfProperties;
    } else {
      return validatedPercentage = 1;
    }

    return validatedPercentage;
  }

  @AuraEnabled
  public static Boolean userHasPermission(String permissionSetName) {
    return lightning_Util.userHasPermission(permissionSetName);
  }

  @AuraEnabled
  public static User getUser() {
    return lightning_Util.getUser();
  }

  @AuraEnabled
  public static Map<String, List<dupcheck__dc3Duplicate__c>> compileAllDupes(
    Map<String, String> newList,
    String recordType
  ) {
    return DuplicateCheckJobHelper.checkDuplicateListFoundByRecordType(
      newList,
      recordType
    );
  }
}