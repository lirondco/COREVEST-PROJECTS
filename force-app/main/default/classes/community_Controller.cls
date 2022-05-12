public without sharing class community_Controller {
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
  public static String getDealRecordTypeName(String i) {
    if (String.isNotBlank(i) && i instanceof Id) {
      String queryString =
        'SELECT Id, RecordType.DeveloperName, Deal__r.RecordType.DeveloperName FROM ' +
        String.valueOf(Id.ValueOf(i).getSObjectType()) +
        ' WHERE Id =\'' +
        i +
        '\' AND RecordTypeId != null LIMIT 1';
      List<sObject> sobjList = database.query(queryString);
      if (sobjList.size() > 0) {
        return (String) sobjList[0]
          .getSobject('Deal__r')
          .getsObject('RecordType')
          .get('DeveloperName');
      }
    }
    return 'Master';
  }

  @AuraEnabled
  public static String getRecordList(
    String parentId,
    String parentFieldName,
    String sobjectType,
    List<String> fields,
    String sortCol,
    String sortDir,
    String whereClause,
    String orderBy
  ) {
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

    system.debug(queryString);

    return JSON.serialize(database.query(queryString));
  }

  @AuraEnabled
  public static String getDocumentList(
    String parentId,
    String parentFieldName,
    String sobjectType,
    List<String> fields,
    String sortCol,
    String sortDir,
    String whereClause,
    String orderBy,
    String accountId,
    String vendorType,
    String userType
  ) {
    UserResource user = new UserResource(UserInfo.getUserId());

    if (!CommunityController.checkAccess(parentId)) {
      return null;
    }

    String queryString = 'SELECT ';
    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString += ', Vendor_Type_Access__c, Folder_String__c, Confidential__c, Deal__r.RecordType.DeveloperName';
    queryString += ' FROM ' + sobjectType;

    //if(String.isNotBlank(parentField)){
    //  queryString
    //}
    queryString +=
      ' WHERE ' +
      parentFieldName +
      ' = \'' +
      parentId +
      '\' AND Document_Loaded__c = true AND Is_Viewable__c = true ';
    //queryString += ' AND Confidential__c = false';
    if (String.isNotBlank(whereClause)) {
      queryString += ' AND ' + whereClause;
    }

    if (user.userType == 'borrower') {
      queryString += ' AND ' + 'Borrower_Access__c = true';
    } else if (user.userType == 'vendor') {
      queryString += ' AND ' + 'Vendor_Access__c = true';
    }

    if (String.isNotBlank(orderBy)) {
      queryString += ' Order BY ' + orderBy;
    } else if (String.isNotBlank(sortCol)) {
      queryString += ' ORDER BY ' + sortCol + ' ' + sortDir;
    }
    system.debug(queryString);
    List<Deal_Document__c> docs = (List<Deal_Document__c>) database.query(
      queryString
    );
    String recordType = '';
    if (docs.size() > 0) {
      recordType = docs[0].Deal__r.RecordType.DeveloperName;
    }
    system.debug('--record type--');
    system.debug(recordType);
    system.debug(docs);
    if (user.userType == 'vendor') {
      Map<String, Map<String, String>> docMetaDataMap = new Map<String, Map<String, String>>();
      for (Document_Structure__mdt docMetaData : [
        SELECT
          Id,
          Folder_Structure_String__c,
          Document_Type__c,
          Vendor_Type_Access__c
        FROM Document_Structure__mdt
        WHERE RecordType__c = :recordType
      ]) {
        system.debug(docMetaData);
        //docMetaDataMap.put(docMetaData.Folder_Structure_String__c, docMetaData.Vendor_Type_Access__c);
        if (
          !docMetaDataMap.containsKey(docMetaData.Folder_Structure_String__c)
        ) {
          docMetaDataMap.put(
            docMetaData.Folder_Structure_String__c,
            new Map<String, String>()
          );
        }
        docMetaDataMap.get(docMetaData.Folder_Structure_String__c)
          .put(docMetaData.Document_Type__c, docMetaData.Vendor_Type_Access__c);
      }

      for (Integer i = docs.size() - 1; i >= 0; i--) {
        Boolean isVisible = false;
        //if(String.isNotBlank(docs[i].Vendor_Type_Access__c)){
        //    Set<String> filterSet = new Set<String>(docs[i].Vendor_Type_Access__c.split(';'));
        //    isVisible = filterSet.contains(accountId) || filterSet.contains(vendorType);
        //}
        system.debug('--folder string--');
        system.debug(docs[i].Folder_String__c);
        Map<String, String> folderMap = docMetaDataMap.get(
          docs[i].Folder_String__c
        );
        system.debug(folderMap);
        if (folderMap != null) {
          system.debug(docs[i].Document_Type__c);
          String vendorTypeAccess = folderMap.get(docs[i].Document_Type__c);
          system.debug(vendorTypeAccess);
          if (String.isNotBlank(vendorTypeAccess)) {
            Set<String> filterSet = new Set<String>(
              vendorTypeAccess.split(';')
            );
            isVisible =
              filterSet.contains(user.accountId) ||
              filterSet.contains(user.accountType);
          }
        }

        if (!isVisible) {
          docs.remove(i);
        }
      }
    }
    // else if(user.userType == 'Borrower'){
    //     for(Integer i = docs.size() - 1; i >= 0; i--){
    //         if(docs[i].Confidential__c){
    //             docs.remove(i);
    //         }
    //     }
    // }

    return JSON.serialize(docs);

    //return JSON.serialize(database.query(queryString));
  }

  @AuraEnabled
  public static String queryRecord(String i, List<String> fieldList) {
    String queryString = 'SELECT Id, ';
    for (String fieldName : fieldList) {
      queryString += fieldName + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString +=
      ' FROM ' + Id.valueOf(i).getSObjectType().getDescribe().getName();
    queryString += ' WHERE Id=\'' + i + '\' LIMIT 1';

    return JSON.serialize(database.query(queryString));
  }

  @AuraEnabled
  public static String getFieldTypeMap(String sobjectName) {
    return JSON.serialize(util.getFieldTypeMap(sobjectName));
  }

  @AuraEnabled
  public static string getDeals(
    List<String> fields,
    String sortDir,
    String sortCol,
    String whereClause,
    Boolean showOnlyOpen,
    Boolean showOnlyTerm,
    Boolean showOnlyBridge
  ) {
    UserResource user = new UserResource(UserInfo.getUserId());

    if (user.userType == 'borrower') {
      return getBorrowerDeals(
        user.contactId,
        fields,
        sortDir,
        sortCol,
        whereClause,
        showOnlyOpen,
        showOnlyTerm,
        showOnlyBridge
      );
    } else if (user.userType == 'vendor') {
      return getVendorDeals(
        user.accountId,
        fields,
        sortDir,
        sortCol,
        whereClause,
        showOnlyOpen,
        showOnlyTerm,
        showOnlyBridge
      );
    } else {
      return null;
    }
  }

  @AuraEnabled
  public static String getVendorDeals(
    String accountId,
    List<String> fields,
    String sortDir,
    String sortCol,
    String whereClause,
    Boolean showOnlyOpen,
    Boolean showOnlyTerm,
    Boolean showOnlyBridge
  ) {
    system.debug(accountId);
    system.debug(fields);
    Set<Id> oppIds = new Set<Id>();
    for (Deal_Contact__c entity : [
      SELECT Id, Deal__c
      FROM Deal_Contact__c
      WHERE Account__c = :accountId
    ]) {
      oppIds.add(entity.Deal__c);
    }

    String queryString = 'SELECT ';
    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM Opportunity ';
    queryString += ' WHERE Id IN ('; //+ new List<Id>(oppIds);
    for (Id i : oppIds) {
      queryString += '\'' + i + '\', ';
    }
    if (oppIds.size() > 0) {
      queryString = queryString.substringBeforeLast(',');
    } else {
      queryString += '\'\'';
    }

    queryString += ')';

    //Set<String> stages = new Set<String>{'Submitted to Underwriting', 'Underwriting', 'Loan Processing', 'Approved by Committee', 'UW Hold', 'Closed Won', 'Term Sheet Issued', 'Term Sheet Signed/Deposit Collected', 'Matured', 'Expired'};
    //Set<String> closedStages = new Set<String>{'Closed Won', 'Matured', 'Expired'};

    Set<String> termStages = new Set<String>{
      'Term Sheet Issued',
      'Term Sheet Signed/Deposit Collected',
      'Submitted to Underwriting',
      'Underwriting',
      'Approved by Committee',
      'UW Hold',
      'Closed Won',
      'Paid Off',
      'Sold'
    };
    Set<String> termClosedStages = new Set<String>{
      'Closed Won',
      'Paid Off',
      'Sold'
    };

    Set<String> bridgeStages = new Set<String>{
      'Term Sheet Issued',
      'Term SHeet Signed/Deposit Collected',
      'Submitted to Underwriting',
      'Loan Processing',
      'Underwriting',
      'Approved by Committee',
      'UW Hold',
      'Closed Won',
      'Matured',
      'Expired',
      'Paid Off',
      'Sold'
    };
    Set<String> bridgeClosedStages = new Set<String>{
      'Matured',
      'Expired',
      'Paid Off',
      'Sold'
    };

    queryString += 'AND ((StageName IN : termStages AND RecordType__c =\'Term\') OR (StageName IN : bridgeStages AND RecordType__c =\'Bridge\'))';

    // // queryString += ' AND StageName IN : stages';
    if (showOnlyOpen != null && showOnlyOpen) {
      //queryString += ' AND (StageName = \'Underwriting\' OR StageName =\'Approved by Committee\' OR StageName =\'UW Hold\' OR StageName =\'Data Tape Received\' OR StageName =\'Term Sheet Issues\' OR StageName =\'Term Sheet Signed/Desposit Collected\'OR StageName =\'Initial Review\')';
      // queryString += ' AND StageName NOT IN : closedStages';
      queryString += ' AND ( (StageName NOT IN : termClosedStages AND RecordType__c =\'Term\') OR (StageName NOT IN : bridgeClosedStages AND RecordType__c =\'Bridge\') )';
    }

    if (showOnlyTerm != null && showOnlyTerm) {
      queryString += ' AND (RecordType__c =\'Term\')';
    }

    if (showOnlyTerm != null && showOnlyBridge) {
      queryString += ' AND (RecordType__c =\'Bridge\')';
    }

    if (String.isNotBlank(whereClause)) {
      queryString += ' AND (' + whereClause + ') ';
    }

    if (String.isNotBlank(sortCol)) {
      queryString += ' ORDER BY ' + sortCol + ' ' + sortDir;
    }
    system.debug(queryString);

    return JSON.serialize(database.query(queryString));
    //return queryString;
  }

  @AuraEnabled
  public static String getBorrowerDeals(
    String contactId,
    List<String> fields,
    String sortDir,
    String sortCol,
    String whereClause,
    Boolean showOnlyOpen,
    Boolean showOnlyTerm,
    Boolean showOnlyBridge
  ) {
    Set<Id> oppIds = new Set<Id>();
    for (Deal_Contact__c c : [
      SELECT Id, Deal__c
      FROM Deal_Contact__c
      WHERE Contact__c = :contactId AND Entity_Type__c = 'Portal Access'
    ]) {
      oppIds.add(c.Deal__c);
    }

    String queryString = 'SELECT ';
    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM Opportunity ';
    queryString += ' WHERE (Contact__c =\'' + contactId + '\'';
    queryString += ' OR Id IN : oppIds )';

    // Set<String> stages = new Set<String>{'Submitted to Underwriting', 'Underwriting', 'Loan Processing', 'Approved by Committee', 'UW Hold', 'Closed Won', 'Term Sheet Signed/Deposit Collected', 'Matured', 'Expired'};
    // Set<String> closedStages = new Set<String>{'Closed Won', 'Matured', 'Expired'};
    // queryString += ' AND StageName IN : stages';
    // if(showOnlyOpen != null && showOnlyOpen){
    //     //queryString += ' AND (StageName = \'Underwriting\' OR StageName =\'Approved by Committee\' OR StageName =\'UW Hold\' OR StageName =\'Data Tape Received\' OR StageName =\'Term Sheet Issues\' OR StageName =\'Term Sheet Signed/Desposit Collected\'OR StageName =\'Initial Review\')';
    //     queryString += ' AND StageName NOT IN : closedStages';
    // }

    // // if(showOnlyOpen != null && showOnlyOpen){
    // //  queryString += ' AND StageName IN (\'Underwriting\'';
    // // }

    // if(showOnlyTerm != null && showOnlyTerm){
    //     queryString += ' AND (RecordType__c =\'Term\')';
    // }

    // if(showOnlyTerm != null && showOnlyBridge){
    //     queryString += ' AND (RecordType__c =\'Bridge\')';
    // }

    Set<String> termStages = new Set<String>{
      'Term Sheet Issued',
      'Term Sheet Signed/Deposit Collected',
      'Submitted to Underwriting',
      'Underwriting',
      'Approved by Committee',
      'UW Hold',
      'Closed Won',
      'Withdrawn',
      'Rejected',
      'Paid Off',
      'Sold'
    };
    Set<String> termClosedStages = new Set<String>{
      'Closed Won',
      'Withdrawn',
      'Rejected',
      'Paid Off',
      'Sold'
    };

    Set<String> bridgeStages = new Set<String>{
      'Term Sheet Issued',
      'Term SHeet Signed/Deposit Collected',
      'Submitted to Underwriting',
      'Loan Processing',
      'Underwriting',
      'Approved by Committee',
      'UW Hold',
      'Closed Won',
      'Matured',
      'Expired',
      'Withdrawn',
      'Rejected',
      'Paid Off',
      'Sold'
    };
    Set<String> bridgeClosedStages = new Set<String>{
      'Matured',
      'Expired',
      'Withdrawn',
      'Rejected',
      'Paid Off',
      'Sold'
    };

    queryString += 'AND ((StageName IN : termStages AND RecordType__c =\'Term\') OR (StageName IN : bridgeStages AND RecordType__c =\'Bridge\'))';

    // // queryString += ' AND StageName IN : stages';
    if (showOnlyOpen != null && showOnlyOpen) {
      //queryString += ' AND (StageName = \'Underwriting\' OR StageName =\'Approved by Committee\' OR StageName =\'UW Hold\' OR StageName =\'Data Tape Received\' OR StageName =\'Term Sheet Issues\' OR StageName =\'Term Sheet Signed/Desposit Collected\'OR StageName =\'Initial Review\')';
      // queryString += ' AND StageName NOT IN : closedStages';
      queryString += ' AND ( (StageName NOT IN : termClosedStages AND RecordType__c =\'Term\') OR (StageName NOT IN : bridgeClosedStages AND RecordType__c =\'Bridge\') )';
    }

    if (showOnlyTerm != null && showOnlyTerm) {
      queryString += ' AND (RecordType__c =\'Term\')';
    }

    if (showOnlyTerm != null && showOnlyBridge) {
      queryString += ' AND (RecordType__c =\'Bridge\')';
    }

    if (String.isNotBlank(whereClause)) {
      queryString += ' AND (' + whereClause + ') ';
    }
    system.debug(queryString);
    return JSON.serialize(database.query(queryString));
  }

  @AuraEnabled
  public static String getPropertyDeal(
    String parentId,
    List<String> fields,
    String sortCol,
    String sortDir,
    String orderBy
  ) {
    if (CommunityController.checkAccess(parentId)) {
      return getRecordList(
        parentId,
        'Deal__c',
        'Property__c',
        fields,
        sortCol,
        sortDir,
        null,
        orderBy
      );
    } else {
      return null;
    }
  }

  @AuraEnabled
  public static String getProperties(
    String userType,
    String recordId,
    List<String> fields,
    String contactId,
    String accountId,
    String whereClause,
    Boolean showOnlyOpen,
    Boolean showOnlyTerm,
    Boolean showOnlyBridge
  ) {
    Set<Id> dealIds = new Set<Id>();
    List<Opportunity> deals;

    UserResource user = new UserResource(UserInfo.getUserId());

    if (user.userType == 'borrower') {
      deals = (List<Opportunity>) JSON.deserialize(
        getBorrowerDeals(
          user.contactId,
          new List<String>{ 'Id' },
          null,
          null,
          null,
          showOnlyOpen,
          showOnlyTerm,
          showOnlyBridge
        ),
        List<Opportunity>.class
      );
    } else if (user.userType == 'vendor') {
      deals = (List<Opportunity>) JSON.deserialize(
        getVendorDeals(
          user.accountId,
          new List<String>{ 'Id' },
          null,
          null,
          null,
          showOnlyOpen,
          showOnlyTerm,
          showOnlyBridge
        ),
        List<Opportunity>.class
      );
    } else {
      deals = new List<Opportunity>();
    }

    for (Opportunity op : deals) {
      dealIds.add(op.Id);
    }

    String queryString = 'SELECT ';
    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM Property__c';
    queryString += ' WHERE Deal__C IN : dealIds';

    if (String.isNotBlank(whereClause)) {
      queryString += ' AND (' + whereClause + ')';
    }

    queryString += ' LIMIT 2000';

    return JSON.serialize(database.query(queryString));
  }

  // @auraEnabled
  // public static String queryLayout(String sobjectName, String recordTypeName, String userType){

  //  List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(
  //                                      Metadata.MetadataType.Layout,
  //                                      new List<String>{'Opportunity-Single Asset Layout'}
  //                                    );

  //  return JSON.serialize(layouts);

  // }

  @AuraEnabled
  public static String getUser() {
    return JSON.serialize(new UserResource(UserInfo.getUserId()));
  }

  public class UserResource {
    @AuraEnabled
    public Id id { get; set; }
    @AuraEnabled
    public String userType { get; set; }
    @AuraEnabled
    public Id contactId { get; set; }
    @AuraEnabled
    public Id accountId { get; set; }
    @AuraEnabled
    public String accountType { get; set; }
    @AuraEnabled
    public String documentId { get; set; }
    public Boolean isInternal { get; set; }

    public UserResource(Id id) {
      this.id = id;
      this.isInternal = false;
      User u = [SELECT Id, ContactId FROM User WHERE Id = :id];
      if (String.isNotBlank(u.ContactId)) {
        this.contactId = u.ContactId;
        Contact c = [
          SELECT
            Id,
            AccountId,
            Is_Vendor__c,
            Account.Non_Borrower_Account_Type__c
          FROM Contact
          WHERE Id = :this.ContactId
        ];
        this.accountId = c.AccountId;
        this.accountType = c.Account.Non_Borrower_Account_Type__c;
        if (c.Is_Vendor__c) {
          this.userType = 'vendor';
        } else {
          this.userType = 'borrower';
        }
      } else {
        //this.userType = 'standard';
        this.accountId = '001j000000ttlreAAA';
        this.contactId = '003j000000EmrJVAAZ';
        this.userType = 'borrower';
        this.accountType = 'Title and Escrow';
        this.isInternal = true;
      }

      if (u.Id == '005j0000000bPgPAAU') {
        this.accountId = '001j000000ttlreAAA';
        this.contactId = '003j000000EmrJVAAZ';
        this.userType = 'borrower';
        this.accountType = 'Title and Escrow';
        this.isInternal = true;
      }

      List<Deal_Document__c> docs = [SELECT Id FROM Deal_Document__c LIMIT 1];
      if (docs.size() > 0) {
        this.documentId = docs[0].Id;
      }
    }
  }

  @AuraEnabled
  public static String getPropertyPicklists(String dealId) {
    List<Map<String, String>> picklists = new List<Map<String, String>>();
    List<Property__c> lp = new List<Property__c>();
    /* Added by Trivikram - start  */
    for (Property__c property : [
      SELECT Id, Active__c, Name
      FROM Property__c
      WHERE Deal__c = :dealId AND Active__c = TRUE
      ORDER BY Name ASC
    ]) {
      Map<String, String> picklist = new Map<String, String>();
      picklist.put('label', property.Name);
      picklist.put('value', property.Id);

      picklists.add(picklist);
    }
    /* Added by Trivikram - End  */
    return JSON.serialize(picklists);
  }

  @AuraEnabled
  public static List<sObject> upsertRecords(List<sObject> records) {
    return lightning_Controller.upsertRecords(records);
  }
}