public without sharing class util {
  public static Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();

  public static sObject queryOppAndChildren(
    String recordId,
    String sObjectName,
    String childName,
    String childrenName
  ) {
    String qs = 'SELECT RecordType.DeveloperName,Opportunity.Account.Referral_Source__c,Opportunity.Account.Referral_Source__r.Name,Opportunity.Account.Introduction_Subsource__c,';
    Id i = recordId;
    Map<String, Schema.SObjectField> parentMap = Schema.getGlobalDescribe()
      .get(sObjectName)
      .getDescribe()
      .fields.getMap();
    Map<String, Schema.SObjectField> childMap = Schema.getGlobalDescribe()
      .get(childName)
      .getDescribe()
      .fields.getMap();

    for (String f : parentMap.keySet()) {
      if (parentMap.get(f).getDescribe().isAccessible()) {
        qs += f + ',';
      }
    }

    qs += '(SELECT ';
    for (String c : childMap.keySet()) {
      if (childMap.get(c).getDescribe().isAccessible()) {
        qs += c + ',';
      }
    }

    qs = qs.substringBeforeLast(',');
    qs +=
      ' FROM ' +
      childrenName +
      ' WHERE Active__c = true ORDER BY Name ASC) FROM ' +
      sObjectName +
      ' WHERE Id = :recordId LIMIT 1';
    System.debug(qs);
    return Database.query(qs);
  }

  public static sObject queryRecordAndChildren(
    String recordId,
    String sObjectName,
    String childName,
    String childrenName
  ) {
    String qs = 'SELECT ';
    Id i = recordId;
    Map<String, Schema.SObjectField> parentMap = Schema.getGlobalDescribe()
      .get(sObjectName)
      .getDescribe()
      .fields.getMap();
    Map<String, Schema.SObjectField> childMap = Schema.getGlobalDescribe()
      .get(childName)
      .getDescribe()
      .fields.getMap();

    for (String f : parentMap.keySet()) {
      if (parentMap.get(f).getDescribe().isAccessible()) {
        qs += f + ',';
      }
    }

    qs += '(SELECT ';
    for (String c : childMap.keySet()) {
      if (childMap.get(c).getDescribe().isAccessible()) {
        qs += c + ',';
      }
    }

    qs = qs.substringBeforeLast(',');
    qs +=
      ' FROM ' +
      childrenName +
      ') FROM ' +
      sObjectName +
      ' WHERE Id = :recordId LIMIT 1';
    System.debug(qs);
    return Database.query(qs);
  }
  /**
   * @description Retrieves list of Field Names from a given sObject type.
   * @param objectName Name of object to get fields from
   */
  public static Set<String> getAllFieldNamesForObject(String objectName) {
    Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe()
      .get(objectName.toLowerCase())
      .getDescribe()
      .fields.getMap();
    Set<String> selectFields = new Set<String>();
    if (fMap != null) {
      for (Schema.SObjectField ft : fMap.values()) {
        selectFields.add(ft.getDescribe().getName());
      }
    }
    return selectFields;
  }

  public static Map<String, String> getFieldTypeMap(String objectName) {
    Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe()
      .get(objectName.toLowerCase())
      .getDescribe()
      .fields.getMap();
    //Set<String> selectFields = new Set<String>();
    Map<String, String> fieldTypeMap = new Map<String, String>();
    if (fMap != null) {
      for (Schema.SObjectField ft : fMap.values()) {
        fieldTypeMap.put(
          ft.getDescribe().getName(),
          String.valueOf(ft.getDescribe().getType())
        );
      }
    }
    return fieldTypeMap;
  }

  public static Map<String, Schema.DescribeFieldResult> getFieldDescribeMap(
    String objectName
  ) {
    Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe()
      .get(objectName.toLowerCase())
      .getDescribe()
      .fields.getMap();
    //Set<String> selectFields = new Set<String>();
    Map<String, Schema.DescribeFieldResult> fieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();
    if (fMap != null) {
      for (Schema.SObjectField ft : fMap.values()) {
        fieldDescribeMap.put(ft.getDescribe().getName(), ft.getDescribe());
      }
    }
    return fieldDescribeMap;
  }

  //public static Map<String,

  /**
   * @description Returns an objected with all mapped fields
   * @param objectName Name of object to get fields from
   * @param objectName Id of the record to get fields from
   */
  public static SObject getMappedObjectById(String objectName, Id objectId) {
    SObject record = Database.query(
      'SELECT ' +
      util.getActiveMappedSelectFields(objectName) +
      ' FROM ' +
      objectName +
      ' WHERE Id =:objectId LIMIT 1'
    );
    return record;
  }

  /**
   * @description Returns an objected with all mapped fields
   * @param objectName Name of object to get fields from
   * @param objectName Id of the record to get fields from
   */
  public static SObject getFullObjectById(String objectName, Id objectId) {
    String queryString = 'SELECT ';
    for (String s : util.getAllFieldNamesForObject(objectName)) {
      queryString += s + ', ';
    }
    queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM ' + objectName + ' WHERE Id = :objectId LIMIT 1';
    SObject record = Database.query(queryString);
    return record;
  }

  /**
   * @description Retrieves list of Active Mapped Field Names from a given sObject type.
   * @param objectName Name of object to get fields from
   */
  public static Set<String> getActiveMappedFieldNamesForObject(
    String objectName
  ) {
    Set<String> allFieldNames = getAllFieldNamesForObject(objectName);
    List<Integration_Mapping__c> mappingList = [
      SELECT
        Id,
        Active__c,
        Required__c,
        Salesforce_Field__c,
        Salesforce_Object__c,
        Integration_Field__c,
        Integration_Object__c,
        Key__c
      FROM Integration_Mapping__c
      WHERE
        Salesforce_Object__c = :objectName
        AND Salesforce_Field__c IN :allFieldNames
        AND Active__c = TRUE
      ORDER BY Salesforce_Field__c
    ];
    Set<String> selectFields = new Set<String>();
    for (Integration_Mapping__c mapping : mappingList) {
      selectFields.add(mapping.Salesforce_Field__c);
    }
    return selectFields;
  }

  /**
   * @description Retrieves list of Active Mapped Field Names from a given sObject type.
   * @param objectName Name of object to get fields from
   */
  public static Set<Integration_Mapping__c> getActiveMappingsForObject(
    String objectName
  ) {
    Set<String> allFieldNames = getAllFieldNamesForObject(objectName);
    List<Integration_Mapping__c> mappingList = [
      SELECT
        Id,
        Active__c,
        Required__c,
        Salesforce_Field__c,
        Salesforce_Object__c,
        Integration_Field__c,
        Integration_Object__c,
        Key__c
      FROM Integration_Mapping__c
      WHERE
        Salesforce_Object__c = :objectName
        AND Salesforce_Field__c IN :allFieldNames
        AND Active__c = TRUE
      ORDER BY Salesforce_Field__c
    ];
    Set<Integration_Mapping__c> mappings = new Set<Integration_Mapping__c>();
    for (Integration_Mapping__c mapping : mappingList) {
      mappings.add(mapping);
    }
    return mappings;
  }

  /**
   * @description Constructs list of select fields for querying.
   * @param objectName Name of object to get fields from
   */
  public static String getActiveMappedSelectFields(String objectName) {
    String result = '';
    Set<String> mappedFields = getActiveMappedFieldNamesForObject(objectName);
    Boolean isFirst = true;
    for (String s : mappedFields) {
      if (isFirst) {
        result += s;
        isFirst = false;
      } else {
        result += ', ' + s;
      }
    }
    return result;
  }

  /**
   *
   *
   **/
  public static List<sObject> queryRecords(String queryString) {
    return database.query(queryString);
  }

  /**
   *@description
   *@param
   */
  public static List<sObject> queryRecords(
    String sObjectName,
    String whereClause,
    String orderClause
  ) {
    String lim = ' LIMIT ';
    String queryString = 'SELECT ';
    Schema.SObjectType obj = GLOBAL_DESCRIBE.get(sObjectName);
    Map<String, Schema.SObjectField> fieldMap = obj.getDescribe()
      .fields.getMap();
    for (String f : fieldMap.keySet()) {
      if (
        fieldMap.get(f)
          .getDescribe()
          .isAccessible() /*&& fieldMap.get(f).getDescribe().isCreateable()*/ // && fieldMap.get(f).getDescribe().isUpdateable()
      ) {
        queryString += f + ',';
      }
    }
    queryString = queryString.subStringBeforeLast(',');
    queryString += ' FROM ' + sObjectName + ' WHERE ' + whereClause;
    queryString += ' ORDER BY ' + orderClause;
    String limitString = ' LIMIT 1000';
    if (queryString.contains(lim)) {
      limitString = lim + queryString.subStringAfter(lim);
      queryString = queryString.subStringBefore(lim);
    }
    queryString += limitString;
    system.debug(queryString);
    return database.query(queryString);
  }

  public static sObject queryRecordAllFields(Id i) {
    String queryString = 'SELECT ';
    for (
      String s : getAllFieldNamesForObject(String.valueOf(i.getSObjectType()))
    ) {
      queryString += s + ' , ';
    }

    queryString = queryString.subStringBeforeLast(',');
    queryString += ' FROM ' + String.valueOf(i.getSObjectType());
    queryString += ' WHERE Id = \'' + i + '\'';

    system.debug(queryString);

    return database.query(queryString);
  }

  public static List<sObject> queryRecordsAllFields(Set<Id> ids) {
    Id i = (new List<Id>(ids))[0];

    String queryString = 'SELECT ';
    for (
      String s : getAllFieldNamesForObject(String.valueOf(i.getSObjectType()))
    ) {
      queryString += s + ' , ';
    }

    queryString = queryString.subStringBeforeLast(',');
    queryString += ' FROM ' + String.valueOf(i.getSObjectType());
    queryString += ' WHERE Id IN ' + inClausify(ids);

    return database.query(queryString);
  }

  public static String inClausify(Set<Id> ids) {
    String inClause = String.format(
      '(\'\'{0}\'\')',
      new List<String>{ String.join(new List<Id>(ids), '\',\'') }
    );
    return inClause;
  }

  public static Map<String, RecordType> compileRecordTypeMap(
    String sObjectName
  ) {
    String s = sObjectName;
    Map<String, RecordType> results = new Map<String, RecordType>();
    for (RecordType rt : [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = :s
    ]) {
      results.put(rt.DeveloperName, rt);
    }
    return results;
  }

  public static Map<String, Product2> compileProductMap() {
    Map<String, Product2> results = new Map<String, Product2>();
    for (Product2 prod : [SELECT Id, Name, ProductCode FROM Product2]) {
      results.put(prod.Name, prod);
    }
    return results;
  }

  public static Map<String, PricebookEntry> compilePricebookEntryMap() {
    Map<String, PricebookEntry> results = new Map<String, PricebookEntry>();
    for (PricebookEntry pbe : [SELECT Id, Name FROM PricebookEntry]) {
      results.put(pbe.Name, pbe);
    }
    return results;
  }

  public static sObject idToSObject(Id recordId) {
    SObject record = recordId.getSobjectType().newSObject();
    record.Id = recordId;
    return record;
  }

  public static Decimal fixNull(Decimal d) {
    if (d == null) {
      d = 0;
    }
    return d;
  }

  public static String getSessionIdFromVFPage(PageReference visualforcePage) {
    String content = visualforcePage.getContent().toString();
    Integer s =
        content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
      e = content.indexOf('End_Of_Session_Id');
    system.debug(content);
    system.debug(s);
    system.debug(e);
    system.debug(content.length());
    return content.substring(s, e);
  }

  public static sObject queryRecord(Id i) {
    List<sObject> results = queryRecords(
      String.valueOf(i.getSObjectType()),
      'Id = \'' +
      i +
      '\'',
      'LastModifiedDate'
    );
    if (results.size() > 0) {
      return results[0];
    }
    return null;
  }

  public static String formatPhone(String phoneNumber) {
    phoneNumber = phoneNumber.replaceAll(' ', '');
    phoneNumber = phoneNumber.replaceAll('\\(', '');
    phoneNumber = phoneNumber.replaceAll('\\)', '');
    phoneNumber = phoneNumber.replaceAll('-', '');
    phoneNumber = phoneNumber.replaceAll('\\.', '');
    String ext = '';
    phoneNumber = phoneNumber.toLowerCase();

    if (phoneNumber.contains('ext.')) {
      ext = phoneNumber.substringAfter('ext.');
      phoneNumber = phoneNumber.substringBefore('ext.');
    }

    if (phoneNumber.contains('ext')) {
      ext = phoneNumber.substringAfter('ext');
      phoneNumber = phoneNumber.substringBefore('ext');
    }

    if (phoneNumber.contains('x')) {
      ext = phoneNumber.substringAfter('x');
      phoneNumber = phoneNumber.substringBefore('x');
    }

    if (phoneNumber.substring(0, 1) == '+') {
      phoneNumber = phoneNumber.substring(1, phoneNumber.length());
    }

    if (phoneNumber.length() == 11 && phoneNumber.substring(0, 1) == '+') {
      phoneNumber = phoneNumber.substring(1, phoneNumber.length());
    }

    if (phoneNumber.length() == 10) {
      phoneNumber =
        '(' +
        phoneNumber.substring(0, 3) +
        ') ' +
        phoneNumber.substring(3, 6) +
        '-' +
        phoneNumber.subString(6, 10);
    }

    if (String.isNotBlank(ext)) {
      // phoneNumber = '(' + phoneNumber.substring(0,3) + ') ' + phoneNumber.substring(3, 6) + '-' + phoneNumber.subString(6,10);
      phoneNumber += ' x' + ext;
    }

    return phoneNumber;
  }

  public static Map<String, Boolean> compileApprovalUnlockMap() {
    return new Map<String, Boolean>{
      'Submit_Term_Deal_to_UW_Approval' => true,
      'Submit_Bridge_Deal_to_UW_Approval' => true,
      'Term_Pricing_Review' => true,
      'Bridge_LOC_Pricing_Review' => true,
      'Custom_SAB_Pricing_Review' => true,
      'Standard_SAB_Pricing_Review' => true,
      'Term_Pricing_Review_Capital_Markets' => true,
      'Bridge_LOC_Pricing_Review_Capital_Market' => true,
      'Term_Confirmation_of_Terms' => true,
      'Term_Repricing_Review_Capital_Markets' => true,
      'Term_Repricing_Review' => true
    };
  }
}