public without sharing class lightning_Util {
  @AuraEnabled
  public static List<sObject> upsertRecords(List<sObject> records) {
    try {
      List<sObject> toInsert = new List<sObject>();
      List<sObject> toUpdate = new List<sObject>();

      for (sObject s : records) {
        if (s.Id != null) {
          toUpdate.add(s);
        } else {
          toInsert.add(s);
        }
      }

      List<Database.SaveResult> resUpd = Database.update(toUpdate, false);
      List<Database.SaveResult> resInsert = Database.insert(toInsert, false);

      String errorMessage = '';

      for (Database.SaveResult r : resUpd) {
        if (!r.isSuccess()) {
          for (Database.Error error : r.getErrors()) {
            if (error instanceof Database.DuplicateError) {
              Datacloud.DuplicateResult duplicateResult = ((Database.DuplicateError) error)
                .getDuplicateResult();

              List<Datacloud.MatchResult> matchResults = duplicateResult.getMatchResults();
              Datacloud.MatchRecord[] matchRecords = matchResults[0]
                .getMatchRecords();

              //Datacloud.FieldDiff field = matchRecords[0].getFieldDiffs()[0];

              errorMessage += error.getMessage() + ' ';
              errorMessage += matchRecords[0].getRecord().get('Name');
              //if(String.isNotBlank((String)matchRecords[0].getRecord().get('Deal_Name__c'))){
              //    errorMessage += ' on Deal ' + matchRecords[0].getRecord().get('Deal_Name__c');
              //}

              //matchRecords[0].getRecord().get('Name');
            } else {
              errorMessage += error.getMessage();
            }
          }

          //system.debug(r.getErrors()[0].getMessage() );
          //throw new AuraHandledException(r.getErrors()[0].getMessage());
        }
      }

      for (Database.SaveResult r : resInsert) {
        if (!r.isSuccess()) {
          for (Database.Error error : r.getErrors()) {
            if (error instanceof Database.DuplicateError) {
              Datacloud.DuplicateResult duplicateResult = ((Database.DuplicateError) error)
                .getDuplicateResult();

              List<Datacloud.MatchResult> matchResults = duplicateResult.getMatchResults();
              Datacloud.MatchRecord[] matchRecords = matchResults[0]
                .getMatchRecords();

              errorMessage += error.getMessage() + ' ';
              errorMessage += matchRecords[0].getRecord().get('Name');

              system.debug('--- stuff -- ');
              system.debug(JSON.serialize(matchRecords[0].getRecord()));

              //if(String.isNotBlank((String)matchRecords[0].getRecord().get('Deal_Name__c'))){
              //    errorMessage += ' found on Deal ' + matchRecords[0].getRecord().get('Deal_Name__c');
              //}
            } else {
              errorMessage += error.getMessage();
            }
          }
        }
      }

      if (String.isNotBlank(errorMessage)) {
        system.debug(errorMessage);
        throw new AuraHandledException(errorMessage);
      }

      return records;
    } catch (DmlException e) {
      //system.debug(e.get)
      throw new AuraHandledException('testdaf');
    }
  }
  @AuraEnabled
  public static void deleteRecords(List<sObject> records) {
    system.debug(records);

    try {
      delete records;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getDmlMessage(0));
    }

    return;
  }

  @AuraEnabled
  public static List<sObject> query(String queryString) {
    system.debug(queryString);
    return database.query(queryString);
  }

  @AuraEnabled
  public static String queryJSON(String queryString) {
    return JSON.serialize(database.query(queryString));
  }

  @AuraEnabled
  public static List<sObject> queryRecords(
    String sobjectType,
    String whereClause,
    String orderBy,
    String lim,
    List<String> fields
  ) {
    String queryString = 'SELECT ';
    for (String field : fields) {
      queryString += field + ', ';
    }

    queryString = queryString.subStringBeforeLast(',');
    queryString += ' FROM ' + sobjectType;

    if (String.isNotBlank(whereClause)) {
      queryString += ' ' + whereClause;
    }

    if (String.isNotBlank(orderBy)) {
      queryString += ' ' + orderBy;
    }

    if (String.isNotBlank(lim)) {
      queryString += ' ' + lim;
    }

    return database.query(queryString);
  }

  @AuraEnabled
  public static String getUserId() {
    return UserInfo.getUserId();
  }

  @AuraEnabled(cacheable=true)
  public static User getUser() {
    return [
      SELECT
        Id,
        FirstName,
        LastName,
        Profile.Name,
        Appraisal_Nation_Username__c,
        Appraisal_Nation_Password__c,
        Clarocity_Password__c,
        Clarocity_Username__c,
        Valuation_Services_Username__c,
        Valuation_Services_Password__c,
        US_RES_Username__c,
        US_RES_Password__c,
        Email
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];
  }

  // **********************************************************************************************************************************
  // ********** GetDependentOptions ***************************************************************************************************
  // **********************************************************************************************************************************
  // Map<String,List<String>> GetDependentOptions (String pObjName, String pControllingFieldName, String pDependentFieldName)
  // Returns: Map of "pControllingFieldName" picklist values and their corresponding "pDependentFieldName" dependent option values.
  // **********************************************************************************************************************************

  // Converts a base64 string into a list of integers representing the encoded bytes
  public static List<Integer> B64ToBytes(String sIn) {
    Map<Integer, Integer> base64 = new Map<Integer, Integer>{
      65 => 0,
      66 => 1,
      67 => 2,
      68 => 3,
      69 => 4,
      70 => 5,
      71 => 6,
      72 => 7,
      73 => 8,
      74 => 9,
      75 => 10,
      76 => 11,
      77 => 12,
      78 => 13,
      79 => 14,
      80 => 15,
      81 => 16,
      82 => 17,
      83 => 18,
      84 => 19,
      85 => 20,
      86 => 21,
      87 => 22,
      88 => 23,
      89 => 24,
      90 => 25,
      97 => 26,
      98 => 27,
      99 => 28,
      100 => 29,
      101 => 30,
      102 => 31,
      103 => 32,
      104 => 33,
      105 => 34,
      106 => 35,
      107 => 36,
      108 => 37,
      109 => 38,
      110 => 39,
      111 => 40,
      112 => 41,
      113 => 42,
      114 => 43,
      115 => 44,
      116 => 45,
      117 => 46,
      118 => 47,
      119 => 48,
      120 => 49,
      121 => 50,
      122 => 51,
      48 => 52,
      49 => 53,
      50 => 54,
      51 => 55,
      52 => 56,
      53 => 57,
      54 => 58,
      55 => 59,
      56 => 60,
      57 => 61,
      43 => 62,
      47 => 63
    };

    List<Integer> lstOut = new List<Integer>();
    if (sIn == null || sIn == '')
      return lstOut;

    sIn += '='.repeat(4 - Math.mod(sIn.length(), 4));

    for (Integer idx = 0; idx < sIn.length(); idx += 4) {
      if (base64.get(sIn.charAt(idx + 1)) != null)
        lstOut.add(
          (base64.get(sIn.charAt(idx)) << 2) |
          (base64.get(sIn.charAt(idx + 1)) >>> 4)
        );
      if (base64.get(sIn.charAt(idx + 2)) != null)
        lstOut.add(
          ((base64.get(sIn.charAt(idx + 1)) & 15) << 4) |
          (base64.get(sIn.charAt(idx + 2)) >>> 2)
        );
      if (base64.get(sIn.charAt(idx + 3)) != null)
        lstOut.add(
          ((base64.get(sIn.charAt(idx + 2)) & 3) << 6) |
          base64.get(sIn.charAt(idx + 3))
        );
    }

    //System.Debug('B64ToBytes: [' + sIn + '] = ' + lstOut);
    return lstOut;
  } //B64ToBytes
  public static List<Integer> BlobToBytes(Blob input) {
    return B64ToBytes(EncodingUtil.base64Encode(input));
  } //BlobToBytes

  // Converts a base64 string into a list of integers indicating at which position the bits are on
  public static List<Integer> cnvBits(String b64Str) {
    List<Integer> lstOut = new List<Integer>();
    if (b64Str == null || b64Str == '')
      return lstOut;

    List<Integer> lstBytes = B64ToBytes(b64Str);

    Integer i, b, v;
    for (i = 0; i < lstBytes.size(); i++) {
      v = lstBytes[i];
      //System.debug ( 'i['+i+'] v['+v+']' );
      for (b = 1; b <= 8; b++) {
        //System.debug ( 'i['+i+'] b['+b+'] v['+v+'] = ['+(v & 128)+']' );
        if ((v & 128) == 128)
          lstOut.add((i * 8) + b);
        v <<= 1;
      }
    }

    //System.Debug('cnvBits: [' + b64Str + '] = ' + lstOut);
    return lstOut;
  } //cnvBits

  public class TPicklistEntry {
    public string active { get; set; }
    public string defaultValue { get; set; }
    public string label { get; set; }
    public string value { get; set; }
    public string validFor { get; set; }
    public TPicklistEntry() {
    }
  } //TPicklistEntry

  @AuraEnabled
  public static Map<String, List<String>> GetDependentOptions(
    String pObjName,
    String pControllingFieldName,
    String pDependentFieldName
  ) {
    Map<String, List<String>> mapResults = new Map<String, List<String>>();

    //verify/get object schema
    Schema.SObjectType pType = Schema.getGlobalDescribe().get(pObjName);
    if (pType == null)
      return mapResults;
    Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe()
      .fields.getMap();

    //verify field names
    if (
      !objFieldMap.containsKey(pControllingFieldName) ||
      !objFieldMap.containsKey(pDependentFieldName)
    )
      return mapResults;

    //get the control & dependent values
    List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName)
      .getDescribe()
      .getPicklistValues();
    List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName)
      .getDescribe()
      .getPicklistValues();

    //clear heap
    objFieldMap = null;

    //initialize results mapping
    for (
      Integer pControllingIndex = 0;
      pControllingIndex < ctrl_ple.size();
      pControllingIndex++
    ) {
      mapResults.put(
        ctrl_ple[pControllingIndex].getLabel(),
        new List<String>()
      );
    }
    //cater for null and empty
    mapResults.put('', new List<String>());
    mapResults.put(null, new List<String>());

    //serialize dep entries
    List<TPicklistEntry> objDS_Entries = new List<TPicklistEntry>();
    objDS_Entries = (List<TPicklistEntry>) JSON.deserialize(
      JSON.serialize(dep_ple),
      List<TPicklistEntry>.class
    );

    List<Integer> validIndexes;
    for (TPicklistEntry objDepPLE : objDS_Entries) {
      validIndexes = cnvBits(objDepPLE.validFor);
      //System.Debug('cnvBits: [' + objDepPLE.label + '] = ' + validIndexes);

      for (Integer validIndex : validIndexes) {
        mapResults.get(ctrl_ple[validIndex - 1].getLabel())
          .add(objDepPLE.label);
      }
    }

    //clear heap
    objDS_Entries = null;

    return mapResults;
  } //GetDependentOptions

  @AuraEnabled
  public static String insertFileAndLink(String request) {
    Map<String, Object> req = (Map<String, Object>) JSON.deserializeUntyped(
      request
    );

    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode((String) req.get('data'));
    cv.Title = (String) req.get('fileName');
    cv.pathOnClient = (String) req.get('fileName');
    cv.Type__c = (String) req.get('fileType');

    insert cv;

    Id contentDocumentId = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
    ]
    .ContentDocumentId;

    insert new ContentDocumentLink(
      LinkedEntityId = (String) req.get('parentId'),
      ContentDocumentId = contentDocumentId,
      ShareType = 'I',
      Visibility = 'AllUsers'
    );

    return contentDocumentId;
  }

  @AuraEnabled(cacheable=true)
  public static List<String> getPicklistValues(
    String sobjectType,
    String fieldName
  ) {
    system.debug(sobjectType);
    system.debug(fieldName);

    List<String> lstPickvals = new List<String>();
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sobjectType); //From the Object Api name retrieving the SObject
    Sobject Object_name = targetType.newSObject();

    Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
    Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
    Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
    List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName)
      .getDescribe()
      .getPickListValues(); //grab the list of picklist values for the passed field on the sobject
    for (Schema.PicklistEntry a : pick_list_values) {
      //for all values in the picklist list
      lstPickvals.add(a.getValue()); //add the value  to our final list
    }

    // return JSON.serialize(lstPickvals);
    return lstPickvals;
  }

  @AuraEnabled
  public static string getFileFromStaticResource(
    String staticResourceName,
    String fileName
  ) {
    StaticResource static_resource = [
      SELECT Id, SystemModStamp, Name
      FROM StaticResource
      WHERE Name = :staticResourceName
      LIMIT 1
    ];

    String url_file_ref =
      '/resource/' +
      String.valueOf(
        ((DateTime) static_resource.get('SystemModStamp')).getTime()
      ) +
      '/' +
      static_resource.get('Name') +
      '/' +
      EncodingUtil.urlEncode(fileName, 'UTF-8');

    PageReference file_ref = new PageReference(url_file_ref);
    //String res_json_body =
    return url_file_ref;
  }

  @AuraEnabled(Cacheable=true)
  public static List<List<sObject>> search(String searchQuery) {
    return search.query(searchQuery);
  }

  @AuraEnabled(Cacheable=true)
  public static String compileEmailTemplate(
    Id templateId,
    Id whoId,
    Id whatId
  ) {
    return JSON.serialize(
      Messaging.renderStoredEmailTemplate(templateId, whoId, whatId)
    );
  }

  // @AuraEnabled(Cacheable=true)
  // public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {

  //     searchTerm += '*';

  //     List<List<SObject>> searchResults = [FIND :searchTerm IN ALL Fields RETURNING
  //         Account (Id, Name, BillingCity WHERE RecordType.DeveloperName = 'Vendor')
  //         LIMIT : 5];

  //     List<LookupSearchResult> results = new List<LookupSearchResult>();

  //     String accountIcon = 'standard:account';
  //     Account [] accounts = ((List<Account>) searchResults[0]);
  //     for (Account account : accounts) {
  //         results.add(new LookupSearchResult(account.Id, 'Account', accountIcon, account.Name, 'Account • '+ account.BillingCity));
  //     }

  //     return results;

  // }

  //   public class LookupSearchResult {
  //     private Id id;
  //     private String sObjectType;
  //     private String icon;
  //     private String title;
  //     private String subtitle;

  //     public LookupSearchResult(
  //       Id id,
  //       String sObjectType,
  //       String icon,
  //       String title,
  //       String subtitle
  //     ) {
  //       this.id = id;
  //       this.sObjectType = sObjectType;
  //       this.icon = icon;
  //       this.title = title;
  //       this.subtitle = subtitle;
  //     }

  //     @AuraEnabled
  //     public Id getId() {
  //       return id;
  //     }

  //     @AuraEnabled
  //     public String getSObjectType() {
  //       return sObjectType;
  //     }

  //     @AuraEnabled
  //     public String getIcon() {
  //       return icon;
  //     }

  //     @AuraEnabled
  //     public String getTitle() {
  //       return title;
  //     }

  //     @AuraEnabled
  //     public String getSubtitle() {
  //       return subtitle;
  //     }
  //   }

  @AuraEnabled(cacheable=true)
  public static Map<String, Map<String, Boolean>> compileFieldPermissions(
    String sObjectName,
    List<String> fields
  ) {
    Map<String, Map<String, Boolean>> fieldPermissions = new Map<String, Map<String, Boolean>>();
    DescribeSObjectResult sObjectDescribe = Schema.getGlobalDescribe()
      .get(sObjectName)
      .getDescribe();

    Map<String, SObjectField> fieldDescribeMap = sObjectDescribe.fields.getMap();

    fieldPermissions.put('sobject', new Map<String, Boolean>());
    fieldPermissions.get('sobject')
      .put('isAccessible', sObjectDescribe.isAccessible());
    fieldPermissions.get('sobject')
      .put('isUpdateable', sObjectDescribe.isUpdateable());
    fieldPermissions.get('sobject')
      .put('isCreateable', sObjectDescribe.isCreateable());

    fieldPermissions.get('sobject')
      .put('isDeletable', sObjectDescribe.isDeletable());

    for (String field : fields) {
      // SObjectField fieldToken = fields.get(field);
      DescribeFieldResult fieldDescribe = fieldDescribeMap.get(field)
        .getDescribe();

      fieldPermissions.put(field, new Map<String, Boolean>());
      fieldPermissions.get(field)
        .put('isAccessible', fieldDescribe.isAccessible());
      fieldPermissions.get(field)
        .put('isUpdateable', fieldDescribe.isUpdateable());
      fieldPermissions.get(field)
        .put('isCreateable', fieldDescribe.isCreateable());
    }

    return fieldPermissions;
  }

  @AuraEnabled
  public static Boolean userHasPermission(String permissionSetName) {
    system.debug('check permission');
    User u = [
      SELECT
        id,
        (
          SELECT id
          FROM PermissionSetAssignments
          WHERE permissionset.name = :permissionSetName
        )
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    return u.permissionsetassignments.size() > 0;
  }
  @AuraEnabled
  public static String getAppName() {
    UserAppInfo userAppInfo = [
      SELECT Id, AppDefinitionId
      FROM UserAppInfo
      WHERE UserId = :UserInfo.getUserId()
      LIMIT 1
    ];
    AppDefinition appDefinition = [
      SELECT DurableId, Label
      FROM AppDefinition
      WHERE DurableId = :userAppInfo.AppDefinitionId
      LIMIT 1
    ];
    system.debug('app name==' + appDefinition.Label);
    return appDefinition.Label;
  }
  @AuraEnabled
  public static String getType(String recordId) {
    system.debug('recordid==' + recordId);
    opportunity opp = [
      SELECT Id, type
      FROM opportunity
      WHERE id = :recordId
      LIMIT 1
    ];
    system.debug('opp==' + opp.type);

    return opp.type;
  }
}