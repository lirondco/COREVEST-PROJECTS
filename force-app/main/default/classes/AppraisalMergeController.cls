public with sharing class AppraisalMergeController {
  public static Map<String, String> MERGE_MAP = new Map<String, String>{
    'Property_Address__c' => 'Name',
    'City__c' => 'City__c',
    'State__c' => 'State__c',
    'Zip__c' => 'ZipCode__c',
    'County__c' => 'County__c',
    'Appraisal_Effective_Date__c' => 'BPO_Appraisal_Date__c',
    'Appraised_Value_Amount__c' => 'Appraised_Value_Amount__c',
    'Appraised_After_Repair_Value__c' => 'After_Repair_Value__c',
    'Appraisal_Form__c' => 'Appraisal_Form__c',
    'Valuation_Type__c' => 'Valuation_Type__c',
    'Valuation_Provider__c' => 'BPO_Appraisal_Firm__c',
    'APN_Assessor_s_Parcel__c' => 'APN__c',
    'Units__c' => 'Number_of_Units__c',
    'Bedrooms__c' => 'Number_of_Beds__c',
    'Baths__c' => 'Number_of_Bath__c',
    'Gross_Living_Area__c' => 'Square_Feet__c',
    'Year_Built__c' => 'Year_Built__c',
    'Condition__c' => 'Condition__c',
    'Condition_Description__c' => 'Condition_Description__c',
    'Pool__c' => 'Pool__c',
    'Lot_Area__c' => 'Lot_Area__c',
    'Cooling__c' => 'Air_Conditioning__c',
    'Age__c' => 'Age__c',
    'Car_Storage__c' => 'Car_Storage__c',
    'Garage_of_Cars__c' => 'Garage_num_of_Cars__c',
    'Design_Style__c' => 'Design_Style__c',
    'Legal_Description__c' => 'Legal_Description__c',
    'Conforms_to_Neighborhood__c' => 'Legally_Conforming__c',
    'Attachment_Type__c' => 'Attachment_Type__c',
    'Zoning_Classification__c' => 'Zoning_Classification__c',
    'Zoning_Compliance__c' => 'Zoning_Compliance__c',
    'Zoning_Description__c' => 'Zoning_Description__c',
    'HOA_Frequency__c' => 'HOA_Frequency__c',
    'CreatedDate' => '',
    'Flood_Zone__c' => '',
    'Status__c' => '',
    'Appraisal_Product_Ordered__c' => '',
    'Appraisal_Replacement_Cost_Value__c' => 'Appraisal_Replacement_Cost_Value__c',
    'No_of_Stories__c' => 'No_of_Stories__c'
  };

  public static Map<String, Schema.SObjectField> APPRAISAL_FIELD_MAP = Schema.SObjectType.Appraisal__c.fields.getMap();
  public static Map<String, Schema.SObjectField> PROPERTY_FIELD_MAP = Schema.SObjectType.Property__c.fields.getMap();

  // public static Map<String, List<Sobject>> BATCH_VAL = new Map<String, List<SObject>>{
  //   'Appraisals' => new List<SObject>(),
  //   'Comments' => new List<SObject>()
  // };

  @AuraEnabled
  public static List<List<MergeWrapper>> initMergeScreen(String recordId) {
    String queryString = compileQueryString(recordId);

    List<MergeWrapper> wrappers = new List<MergeWrapper>();
    for (
      Appraisal__c appraisal : (List<Appraisal__c>) database.query(queryString)
    ) {
      wrappers.add(new MergeWrapper(appraisal));
    }

    Map<Id, List<MergeWrapper>> mergeMap = new Map<Id, List<MergeWrapper>>();
    for (MergeWrapper wrapper : wrappers) {
      if (!mergeMap.containsKey(wrapper.propertyId)) {
        mergeMap.put(wrapper.propertyId, new List<MergeWrapper>());
      }
      mergeMap.get(wrapper.propertyId).add(wrapper);
    }
    return mergeMap.values();
  }

  public static string compileQueryString(String dealId) {
    String queryString = 'SELECT Id, ';
    for (String appraisalField : MERGE_MAP.keySet()) {
      queryString += appraisalField + ', ';
      if (String.isNotBlank(MERGE_MAP.get(appraisalField))) {
        queryString += 'Property__r.' + MERGE_MAP.get(appraisalField) + ', ';
      }
    }

    queryString += 'Property__c';
    //queryString = queryString.substringBeforeLast(',');
    queryString += ' FROM Appraisal__c WHERE Deal__c =\'' + dealId + '\'';
    //queryString += ' AND Property__r.Is_Parent__c = false';
    queryString += ' AND Property__c != null';
    queryString += ' AND Status__c =\'' + 'Complete-Delivered' + '\'';
    queryString += ' Order By CreatedDate DESC';
    return queryString;
  }

  public class MergeField {
    @AuraEnabled
    public String propertyFieldLabel;
    @AuraEnabled
    public String propertyAPIFieldName;
    @AuraEnabled
    public String propertyFieldType;
    @AuraEnabled
    public Object propertyValue;

    @AuraEnabled
    public String appraisalFieldLabel;
    @AuraEnabled
    public String appraisalAPIFieldName;
    @AuraEnabled
    public Object appraisalValue;
    @AuraEnabled
    public String appraisalFieldType;
  }

  public class MergeWrapper {
    @AuraEnabled
    public List<MergeField> fields;
    @AuraEnabled
    public Boolean checked;
    @AuraEnabled
    public String appraisalId;
    @AuraEnabled
    public String propertyId;
    @AuraEnabled
    public String productOrdered;
    @AuraEnabled
    public String formId;

    MergeWrapper(Appraisal__c appraisal) {
      appraisalId = appraisal.Id;
      propertyId = appraisal.Property__c;
      formId = appraisal.Appraisal_Form__c;
      productOrdered = appraisal.Appraisal_Product_Ordered__c;
      checked = false;
      fields = new List<MergeField>();

      for (String appraisalField : MERGE_MAP.keySet()) {
        MergeField field = new MergeField();

        Schema.DescribeFieldResult appraisalDFR = APPRAISAL_FIELD_MAP.get(
            appraisalField
          )
          .getDescribe();
        field.appraisalFieldType = appraisalDFR.getType().name();
        field.appraisalAPIFieldName = appraisalField;
        field.appraisalFieldLabel = appraisalDFR.getLabel();
        field.appraisalValue = appraisal.get(appraisalField);

        if (String.isNotBlank(MERGE_MAP.get(appraisalField))) {
          Schema.DescribeFieldResult propertyDFR = PROPERTY_FIELD_MAP.get(
              MERGE_MAP.get(appraisalField)
            )
            .getDescribe();
          field.propertyFieldType = propertyDFR.getType().name();
          field.propertyAPIFieldName = MERGE_MAP.get(appraisalField);
          field.propertyFieldLabel = propertyDFR.getLabel();
          field.propertyValue = appraisal.getSobject('Property__r')
            .get(MERGE_MAP.get(appraisalField));
        }

        if (field.appraisalFieldLabel == 'Created Date') {
          field.appraisalFieldLabel = 'Uploaded Date';
        }
        //system.debug(appraisalField);
        fields.add(field);
      }
    }
  }

  @AuraEnabled
  public static void submitOrder(Id propertyId, Map<String, Object> arguments) {
    //system.debug(arguments);
    String appraisalFirm = (String) arguments.get('appraisalFirm');
    String productType = (String) arguments.get('productType');
    if (appraisalFirm == 'Clear Capital') {
      String turnTime = (String) arguments.get('turnTime');
      // List<Object> addOns = (List<Object>) arguments.get('addOns');
      List<String> addOns = (List<String>) arguments.get('addOns');
      String vendorComments = (String) arguments.get('vendorComments');
      submitOrderClearCapital(
        propertyId,
        productType,
        turnTime,
        // addOns,
        vendorComments
      );
    } else if (appraisalFirm == 'Appraisal Nation') {
      String vendorComments = (String) arguments.get('vendorComments');
      String dueDate = (String) arguments.get('dueDate');
      Boolean rushOrder = (Boolean) arguments.get('rushOrder');
      String password = (String) arguments.get('anPassword');
      String username = (String) arguments.get('anUsername');
      submitOrderAppraisalNation(
        propertyId,
        productType,
        rushOrder,
        dueDate,
        vendorComments,
        username,
        password
      );
    } else if (appraisalFirm == 'Clarocity Valuation Services') {
      String vendorComments = (String) arguments.get('vendorComments');
      String password = (String) arguments.get('anPassword');
      String username = (String) arguments.get('anUsername');
      submitOrderClarocity(
        propertyId,
        productType,
        vendorComments,
        username,
        password
      );
    } else if (appraisalFirm == 'Valuation Services AMC') {
      String vendorComments = (String) arguments.get('vendorComments');
      String dueDate = (String) arguments.get('dueDate');
      Boolean rushOrder = (Boolean) arguments.get('rushOrder');
      String password = (String) arguments.get('anPassword');
      String username = (String) arguments.get('anUsername');
      submitOrderValuationServices(
        propertyId,
        productType,
        rushOrder,
        dueDate,
        vendorComments,
        username,
        password
      );
    } else if (appraisalFirm == 'US RES') {
      String vendorComments = (String) arguments.get('vendorComments');
      String dueDate = (String) arguments.get('dueDate');
      Boolean rushOrder = (Boolean) arguments.get('rushOrder');
      String password = (String) arguments.get('anPassword');
      String username = (String) arguments.get('anUsername');
      submitOrderUSRES(
        propertyId,
        productType,
        rushOrder,
        dueDate,
        vendorComments,
        username,
        password
      );
    }

    try {
      Property__c p = [
        SELECT Id, Deal__c
        FROM Property__c
        WHERE Id = :propertyId
        LIMIT 1
      ];

      List<Deal_Contact__c> vendorContacts = [
        SELECT Id, Account__c, Vendor_Type__c
        FROM Deal_Contact__c
        WHERE
          Account__r.Name = :appraisalFirm
          AND Vendor_Type__c = 'Valuation'
          AND Deal__c = :p.Deal__c
      ];

      if (vendorContacts.size() == 0) {
        Account vendor = [
          SELECT Id, Name
          FROM Account
          WHERE RecordType.Name = 'Vendor' AND Name = :appraisalFirm
          LIMIT 1
        ];

        insert new Deal_Contact__c(
          Account__c = vendor.Id,
          Vendor_Type__c = 'Valuation',
          Deal_Contact_Type__c = 'Vendor',
          Order_Date__c = system.today(),
          Deal__c = p.Deal__c
        );
      }
    } catch (DMLException e) {
    }
  }

  public static void submitOrderClearCapital(
    Id propertyId,
    String productType,
    String turnTime,
    // List<Object> addOns,
    String vendorComments
  ) {
    Property__c p = [
      SELECT
        id,
        Number_of_Units__c,
        Deal__r.RecordType.DeveloperName,
        Refinance_Acquisition__c,
        City__c,
        State__c,
        Name,
        zipcode__c,
        Property_Type__c,
        Deal__c,
        Interior_Access_POC__c,
        Interior_Access_POC_Phone__c,
        Interior_Access_POC_Email__c,
        Square_Feet__c,
        Asset_ID__c,
        Deal__r.Deal_Loan_Number__c,
        Deal__r.Name
      FROM property__c
      WHERE id = :propertyId
      LIMIT 1
    ];

    Appraisal__c appraisal = ClearCapitalAPI.createOrder(
      p,
      productType,
      turnTime,
      // addOns,
      vendorComments
    );

    // if(addOns.size() > 0) {
    //   String addonAsString = '';

    //   for(Object a : addOns) {
    //     addonAsString += String.valueOf(a) + ';';
    //   }

    //   addonAsString = addonAsString.substringBeforeLast(';');
    //   appraisal.Product_Type_Addons__c = addonAsString;
    // }

    appraisal.Deal__c = p.Deal__c;
    appraisal.Property__c = p.Id;
    appraisal.Vendor_Ordered_From__c = 'Clear Capital';
    appraisal.Appraisal_Product_Ordered__c = productType;
    appraisal.Delivery_Method__c = 'API';
    appraisal.Property_Asset_Id__c = p.Asset_Id__c;
    appraisal.Property_Address__c = p.Name;
    appraisal.City__c = p.City__c;
    appraisal.State__c = p.State__c;
    appraisal.Zip__c = p.ZipCode__c;
    appraisal.Valuation_Provider__c = 'Clear Capital';
    appraisal.Turn_Time__c = turnTime;
    appraisal.Comments_to_Vendor__c = vendorComments;
    insert appraisal;
    // return;

    p.BPO_Appraisal_Firm__c = 'Clear Capital';
    p.BPO_Appraisal_Order_Date__c = System.today();
    p.Valuation_Type__c = productType;
    update p;
  }

  public static void submitOrderAppraisalNation(
    Id propertyId,
    String productType,
    Boolean rushOrder,
    String dueDate,
    String vendorComments,
    String username,
    String password
  ) {
    Property__c p = [
      SELECT
        id,
        Name,
        City__c,
        State__c,
        ZipCode__c,
        County__c,
        Property_Type__c,
        Deal__r.RecordType.DeveloperName,
        Number_of_Units__c,
        Deal__r.Deal_Loan_Number__c,
        Acquisition_Price__c,
        Currently_Leased__c,
        Borrower_Name__c,
        Deal__r.Contact__r.FirstName,
        Refinance_Acquisition__c,
        RecordType.DeveloperName,
        Deal__r.Contact__r.LastName,
        Deal__r.Contact__r.Phone,
        Deal__r.Contact__r.HomePhone,
        Deal__r.Contact__r.MobilePhone,
        Deal__r.Contact__r.Email,
        Deal__r.Contact__r.MailingStreet,
        Deal__r.Name,
        Deal__r.Contact__r.MailingCity,
        Deal__r.Contact__r.MailingState,
        Deal__r.Contact__r.MailingPostalCode,
        Interior_Access_POC__c,
        Interior_Access_POC_Phone__c,
        Interior_Access_POC_Email__c,
        Asset_Id__c,
        Deal__r.Anticipated_Closing_Date__c
      FROM property__c
      WHERE id = :propertyId
      LIMIT 1
    ];

    Appraisal__c appraisal = AppraisalNationAPI.submitOrder(
      p,
      productType,
      vendorComments,
      rushOrder,
      dueDate,
      username,
      password
    );
    appraisal.Deal__c = p.Deal__c;
    appraisal.Property__c = p.Id;
    appraisal.Vendor_Ordered_From__c = 'Appraisal Nation';
    appraisal.Appraisal_Product_Ordered__c = productType;
    appraisal.Status__c = 'Ordered';
    appraisal.Delivery_Method__c = 'API';
    appraisal.Property_Asset_Id__c = p.Asset_Id__c;
    appraisal.Property_Address__c = p.Name;
    appraisal.City__c = p.City__c;
    appraisal.State__c = p.State__c;
    appraisal.Zip__c = p.ZipCode__c;
    appraisal.Valuation_Provider__c = 'Appraisal Nation';
    appraisal.Comments_to_Vendor__c = vendorComments;
    insert appraisal;

    update new User(
      Id = userInfo.getUserId(),
      Appraisal_Nation_Username__c = username,
      Appraisal_Nation_Password__c = password
    );

    p.BPO_Appraisal_Firm__c = 'Appraisal Nation';
    p.BPO_Appraisal_Order_Date__c = System.today();
    p.Valuation_Type__c = productType;
    update p;
  }

  public static void submitOrderValuationServices(
    Id propertyId,
    String productType,
    Boolean rushOrder,
    String dueDate,
    String vendorComments,
    String username,
    String password
  ) {
    Property__c p = [
      SELECT
        id,
        Name,
        City__c,
        State__c,
        ZipCode__c,
        County__c,
        Property_Type__c,
        Deal__r.RecordType.DeveloperName,
        Number_of_Units__c,
        Deal__r.Deal_Loan_Number__c,
        Acquisition_Price__c,
        Currently_Leased__c,
        Borrower_Name__c,
        Deal__r.Contact__r.FirstName,
        Refinance_Acquisition__c,
        RecordType.DeveloperName,
        Deal__r.Contact__r.LastName,
        Deal__r.Contact__r.Phone,
        Deal__r.Contact__r.HomePhone,
        Deal__r.Contact__r.MobilePhone,
        Deal__r.Contact__r.Email,
        Deal__r.Contact__r.MailingStreet,
        Deal__r.Name,
        Deal__r.Contact__r.MailingCity,
        Deal__r.Contact__r.MailingState,
        Deal__r.Contact__r.MailingPostalCode,
        Interior_Access_POC__c,
        Interior_Access_POC_Phone__c,
        Interior_Access_POC_Email__c,
        Asset_Id__c,
        Deal__r.Anticipated_Closing_Date__c
      FROM property__c
      WHERE id = :propertyId
      LIMIT 1
    ];

    Appraisal__c appraisal = ValuationServicesAPI.submitOrder(
      p,
      productType,
      vendorComments,
      rushOrder,
      dueDate,
      username,
      password
    );
    appraisal.Deal__c = p.Deal__c;
    appraisal.Property__c = p.Id;
    appraisal.Vendor_Ordered_From__c = 'Valuation Services AMC';
    appraisal.Appraisal_Product_Ordered__c = productType;
    appraisal.Status__c = 'Ordered';
    appraisal.Delivery_Method__c = 'API';
    appraisal.Property_Asset_Id__c = p.Asset_Id__c;
    appraisal.Property_Address__c = p.Name;
    appraisal.City__c = p.City__c;
    appraisal.State__c = p.State__c;
    appraisal.Zip__c = p.ZipCode__c;
    appraisal.Valuation_Provider__c = 'Valuation Services AMC';
    appraisal.Comments_to_Vendor__c = vendorComments;
    insert appraisal;

    update new User(
      Id = userInfo.getUserId(),
      Valuation_Services_Username__c = username,
      Valuation_Services_Password__c = password
    );

    p.BPO_Appraisal_Firm__c = 'Valuation Services AMC';
    p.BPO_Appraisal_Order_Date__c = System.today();
    p.Valuation_Type__c = productType;
    update p;
  }

  public static void submitOrderUSRES(
    Id propertyId,
    String productType,
    Boolean rushOrder,
    String dueDate,
    String vendorComments,
    String username,
    String password
  ) {
    Property__c p = [
      SELECT
        id,
        Name,
        City__c,
        State__c,
        ZipCode__c,
        County__c,
        Property_Type__c,
        Deal__r.RecordType.DeveloperName,
        Number_of_Units__c,
        Deal__r.Deal_Loan_Number__c,
        Acquisition_Price__c,
        Currently_Leased__c,
        Borrower_Name__c,
        Deal__r.Contact__r.FirstName,
        Refinance_Acquisition__c,
        RecordType.DeveloperName,
        Deal__r.Contact__r.LastName,
        Deal__r.Contact__r.Phone,
        Deal__r.Contact__r.HomePhone,
        Deal__r.Contact__r.MobilePhone,
        Deal__r.Contact__r.Email,
        Deal__r.Contact__r.MailingStreet,
        Deal__r.Name,
        Deal__r.Contact__r.MailingCity,
        Deal__r.Contact__r.MailingState,
        Deal__r.Contact__r.MailingPostalCode,
        Interior_Access_POC__c,
        Interior_Access_POC_Phone__c,
        Interior_Access_POC_Email__c,
        Asset_Id__c,
        Deal__r.Anticipated_Closing_Date__c
      FROM property__c
      WHERE id = :propertyId
      LIMIT 1
    ];

    Appraisal__c appraisal = USResAPI.submitOrder(
      p,
      productType,
      vendorComments,
      rushOrder,
      dueDate,
      username,
      password
    );
    appraisal.Deal__c = p.Deal__c;
    appraisal.Property__c = p.Id;
    appraisal.Vendor_Ordered_From__c = 'US RES';
    appraisal.Appraisal_Product_Ordered__c = productType;
    appraisal.Status__c = 'Ordered';
    appraisal.Delivery_Method__c = 'API';
    appraisal.Property_Asset_Id__c = p.Asset_Id__c;
    appraisal.Property_Address__c = p.Name;
    appraisal.City__c = p.City__c;
    appraisal.State__c = p.State__c;
    appraisal.Zip__c = p.ZipCode__c;
    appraisal.Valuation_Provider__c = 'US RES';
    appraisal.Comments_to_Vendor__c = vendorComments;
    insert appraisal;

    update new User(
      Id = userInfo.getUserId(),
      US_RES_Username__c = username,
      US_RES_Password__c = password
    );

    p.BPO_Appraisal_Firm__c = 'US RES';
    p.BPO_Appraisal_Order_Date__c = System.today();
    p.Valuation_Type__c = productType;
    update p;
  }

  public static void submitOrderClarocity(
    Id propertyId,
    String productType,
    String vendorComments,
    String username,
    String password
  ) {
    Property__c p = [
      SELECT
        id,
        Name,
        City__c,
        State__c,
        ZipCode__c,
        County__c,
        Property_Type__c,
        Deal__r.RecordType.DeveloperName,
        Number_of_Units__c,
        Deal__r.Deal_Loan_Number__c,
        Acquisition_Price__c,
        Currently_Leased__c,
        Borrower_Name__c,
        Deal__r.Contact__r.FirstName,
        Refinance_Acquisition__c,
        RecordType.DeveloperName,
        Deal__r.Contact__r.LastName,
        Deal__r.Contact__r.Phone,
        Deal__r.Contact__r.HomePhone,
        Deal__r.Contact__r.MobilePhone,
        Deal__r.Contact__r.Email,
        Deal__r.Contact__r.MailingStreet,
        Deal__r.Name,
        Deal__r.Contact__r.MailingCity,
        Deal__r.Contact__r.MailingState,
        Deal__r.Contact__r.MailingPostalCode,
        Interior_Access_POC__c,
        Interior_Access_POC_Phone__c,
        Interior_Access_POC_Email__c,
        Asset_Id__c,
        Deal__r.Anticipated_Closing_Date__c,
        Deal__r.Borrower_Entity__r.Name
      FROM property__c
      WHERE id = :propertyId
      LIMIT 1
    ];

    Appraisal__c appraisal = ClarocityAPI.submitOrder(
      p,
      productType,
      vendorComments,
      username,
      password
    );

    appraisal.Deal__c = p.Deal__c;
    appraisal.Property__c = p.Id;
    appraisal.Vendor_Ordered_From__c = 'Clarocity Valuation Services';
    appraisal.Appraisal_Product_Ordered__c = productType;
    appraisal.Delivery_Method__c = 'API';
    appraisal.Property_Asset_Id__c = p.Asset_Id__c;
    appraisal.Property_Address__c = p.Name;
    appraisal.City__c = p.City__c;
    appraisal.State__c = p.State__c;
    appraisal.Zip__c = p.ZipCode__c;
    appraisal.Valuation_Provider__c = 'Clarocity Valuation Services';
    appraisal.Comments_to_Vendor__c = vendorComments;

    if (appraisal.Status__c != 'Duplicate') {
      appraisal.Status__c = 'Ordered';
    }

    insert appraisal;

    update new User(
      Id = userInfo.getUserId(),
      Clarocity_Username__c = username,
      Clarocity_Password__c = password
    );

    p.BPO_Appraisal_Firm__c = 'Clarocity Valuation Services';
    p.BPO_Appraisal_Order_Date__c = System.today();
    p.Valuation_Type__c = productType;
    update p;
  }

  public static void refreshBatch(Id id) {
    checkStatus(id);
    List<Id> idList = new List<Id>{ id };
    refreshAppraisalStatus(idList);
  }

  
  // @future (callout=true)
  // public static Map<String, List<Sobject>> refreshBatch(List<Id> ids) {
  //   for(Id id : ids) {
  //     checkStatus(id);
  //   }
  //   refreshAppraisalStatus(ids);
  //   return BATCH_VAL;
  //   checkStatus(id);
  //   List<Id> idList = new List<Id>{ id };
  //   refreshAppraisalStatus(idList);
  // }

  @AuraEnabled
  public static void checkStatus(Id appraisalId) {
    String appraisalFirm = [
      SELECT Id, Vendor_Ordered_From__c
      FROM Appraisal__c
      WHERE Id = :appraisalId
      LIMIT 1
    ]
    .Vendor_Ordered_From__c;

    if (appraisalFirm == 'Clear Capital') {
      checkStatusClearCapital(appraisalId);
    } else if (appraisalFirm == 'Appraisal Nation') {
      checkStatusAppraisalNation(appraisalId);
    } else if (appraisalFirm == 'Clarocity Valuation Services') {
      checkStatusClarocity(appraisalId);
    } else if (appraisalFirm == 'Valuation Services AMC') {
      checkStatusValuationServices(appraisalId);
    } else if (appraisalFirm == 'US RES') {
      checkStatusUSRES(appraisalId);
    }
  }

  public static void checkStatusClearCapital(Id appraisalId) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        Deal__r.RecordType.DeveloperName,
        report_type__c,
        appraisal_firm_transaction_id__c,
        appraisal_product_ordered__c
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    if (String.isBlank(appraisal.Appraisal_Firm_Transaction_ID__c)) {
      return;
    }

    Map<String, Object> resp = ClearCapitalAPI.checkStatus(
      appraisal.Appraisal_Firm_Transaction_ID__c,
      appraisal.Deal__r.RecordType.DeveloperName
    );

    if (String.ValueOf(resp.get('cancelledDate')) != null) {
      appraisal.Cancellation_Date__c = DateTime.valueOf(
        String.valueOf(resp.get('cancelledDate'))
          .replace('T', ' ')
          .subStringBeforeLast('-')
      );
    }

    if (String.valueOf(resp.get('onHoldDate')) != null) {
      appraisal.Cancellation_Date__c = DateTime.valueOf(
        String.valueOf(resp.get('onHoldDate'))
          .replace('T', ' ')
          .subStringBeforeLast('-')
      );
    }

    if (String.valueOf(resp.get('completedDate')) != null) {
      appraisal.Appraisal_Completion_Date__c = DateTime.valueOf(
        String.valueOf(resp.get('completedDate'))
          .replace('T', ' ')
          .subStringBeforeLast('-')
      );
    }

    if (String.valueOf(resp.get('estimatedCompletedDate')) != null) {
      appraisal.Estimated_Completion_Date__c = DateTime.valueOf(
        String.valueOf(resp.get('estimatedCompletedDate'))
          .replace('T', ' ')
          .subStringBeforeLast('-')
      );
    }

    if (String.valueOf(resp.get('appraisalEffectiveDate')) != null) {
      appraisal.Appraisal_Effective_Date__c = Date.valueOf(
        String.valueOf(resp.get('appraisalEffectiveDate'))
          .replace('T', ' ')
          .subStringBeforeLast('-')
      );
    }

    appraisal.Status__c = String.valueOf(resp.get('status'));
    appraisal.Status_Description__c = String.valueOf(
      resp.get('statusDescription')
    );
    appraisal.Inspection_Complete__c = String.valueOf(
      resp.get('inspectionComplete')
    );
    appraisal.Appraised_Value_Amount__c = Integer.valueOf(
      resp.get('appraisedValue')
    );
    appraisal.Appraisal_Fee__c = Integer.valueOf(resp.get('appraisalFee'));
    appraisal.Property_Address__c = String.valueOf(resp.get('street'));
    appraisal.City__c = String.valueOf(resp.get('city'));
    appraisal.State__c = String.valueOf(resp.get('state'));
    appraisal.Zip__c = String.valueOf(resp.get('zip'));

    if (String.isNotEmpty(appraisal.Status__c) && appraisal.Status__c.toLowerCase() == 'complete-delivered') {
      //retrieveOrder(appraisalId);
      retrieveOrderClearCapital(appraisalId);
    }

    update appraisal;
    List<Appraisal_Order_Comment__c> comments = new List<Appraisal_Order_Comment__c>();

    for (
      Map<String, String> comment : (List<Map<String, String>>) resp.get(
        'comments'
      )
    ) {
      Appraisal_Order_Comment__c cmt = new Appraisal_Order_Comment__c();

      String commentDate = comment.get('date');
      String body = comment.get('body');
      if (String.isNotBlank(body)) {
        Integer lng = body.length() <= 182 ? body.length() : 182;

        cmt.Key__c =
          appraisalId +
          '|' +
          commentDate +
          '|' +
          body.substring(0, lng);

        cmt.Comment__c = body;
        cmt.Comment_Date__c = DateTime.valueOf(
          commentDate.replace('T', ' ').subStringBeforeLast('-')
        );
        cmt.Appraisal__c = appraisalId;
        comments.add(cmt);
      }
    }

    if (comments.size() > 0) {
      Database.upsert(comments, Appraisal_Order_Comment__c.Fields.Key__c);
    }

    system.debug(JSON.serialize(resp));

    return;
  }

  @AuraEnabled
  public static void refreshAppraisalStatus(List<Id> appraisalIds) {
    if (appraisalIds.size() == 0 || appraisalIds.isEmpty()) {
      return;
    }
    List<Appraisal__c> appraisals = new List<Appraisal__c>();
    List<Appraisal__c> queriedApps = [
      SELECT
        id,
        createddate,
        report_type__c,
        appraisal_firm_transaction_id__c,
        appraisal_product_ordered__c,
        property__r.deal__r.recordtype.developername,
        Vendor_Ordered_From__c
      FROM appraisal__c
      WHERE
        Id IN :appraisalIds
        AND appraisal_firm_transaction_id__c != NULL
        AND Vendor_Ordered_From__c = 'Appraisal Nation'
      ORDER BY createddate DESC
    ];

    if (queriedApps.size() == 0 || queriedApps.isEmpty()) {
      return;
    }

    for (Appraisal__c appraisal : queriedApps) {
      Map<String, Object> resp = AppraisalNationAPI.getAppraisalDetail(
        appraisal.Appraisal_Firm_Transaction_ID__c,
        appraisal.property__r.deal__r.recordtype.developername
      );

      if (resp == null || resp.isEmpty()) {
        continue;
      }

      System.debug('--refresh data --');
      System.debug(JSON.serializePretty(resp));

      if (
        resp.containsKey('due_amount') &&
        resp.get('due_amount') != 'N/A' &&
        resp.get('due_amount') != null
      ) {
        String dueAmount = String.valueOf(resp.get('due_amount'));

        if (!dueAmount.isNumeric()) {
          dueAmount = dueAmount.replaceAll('[^\\d.]', '');
        }
        appraisal.Appraisal_Fee__c = Decimal.valueOf(dueAmount);
      }
      if (
        resp.containsKey('inspection_date') &&
        resp.get('inspection_date') != 'N/A' &&
        resp.get('inspection_date') != null
      ) {
        appraisal.Inspection_Date__c = Date.valueOf(
          String.valueOf(resp.get('inspection_date') + ' 00:00:00')
        );
      }
      if (
        resp.containsKey('due_date') &&
        resp.get('due_date') != 'N/A' &&
        resp.get('due_date') != null
      ) {
        appraisal.Estimated_Completion_Date__c = Date.valueOf(
          String.valueOf(resp.get('due_date') + ' 00:00:00')
        );
      }

      System.debug('--new appraisal data --');
      System.debug(appraisal);
      appraisals.add(appraisal);
    }

    // if(System.isBatch()) {
    //   appraisals.addAll((List<Appraisal__c>)BATCH_VAL.get('Appraisals'));
    //   BATCH_VAL.put('Appraisals', appraisals);
    // } else {
      database.update(appraisals, false);
    // }
  }

  public static void checkStatusAppraisalNation(Id appraisalId) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        report_type__c,
        appraisal_firm_transaction_id__c,
        appraisal_product_ordered__c,
        property__r.deal__r.recordtype.developername
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    if (String.isBlank(appraisal.Appraisal_Firm_Transaction_ID__c)) {
      return;
    }

   Map<String, Object> resp = AppraisalNationAPI.checkOrder(
      appraisal.Appraisal_Firm_Transaction_ID__c,
      appraisal.property__r.deal__r.recordtype.developername
    );

    // system.debug('--resp--');
    // system.debug(JSON.serializePretty(resp));

    appraisal.Status__c = (String) resp.get('appraisal_status');
    //system.debug('--status--');
    //system.debug(appraisal.status__c);
    if (appraisal.Status__c == 'New') {
      appraisal.Status__c = 'Ordered';
    } else if (appraisal.Status__c == 'Completed') {
      appraisal.Status__c = 'Complete-Delivered';
      Map<String, String> retrieveResp = retrieveOrderAppraisalNation(
        appraisalId
      );
      if (retrieveResp != null) {
        appraisal.Status__c = 'Complete-Undelivered';
      }
    }
    // if(System.isBatch()) {
    //   List<Sobject> appVal = BATCH_VAL.get('Appraisals');
    //   appVal.add((SObject) appraisal);
    //   BATCH_VAL.put('Appraisals', appVal);
    // } else {
      update appraisal;
    // }

    List<Appraisal_Order_Comment__c> comments = new List<Appraisal_Order_Comment__c>();
    system.debug(resp.get('comments'));
    for (Object com : (List<Object>) resp.get('comments')) {
      Appraisal_Order_Comment__c cmt = new Appraisal_Order_Comment__c();
      Map<String, Object> comment = (Map<String, Object>) com;
      String commentDate = (String) comment.get('comment_date');
      String body = (String) comment.get('comment');
      if (String.isNotBlank(body)) {
        //Integer lng = body.length() <= 182 ? body.length() : 182;

        cmt.Key__c = (String) comment.get('comment_id');

        cmt.Comment__c = body;
        cmt.Comment_Date__c = DateTime.valueOf(commentDate);

        cmt.Appraisal__c = appraisalId;
        comments.add(cmt);
      }
    }

    if (appraisal.Status__c == 'Complete-Delivered') {
    }
    
    if (comments.size() > 0) {
      Database.upsert(comments, Appraisal_Order_Comment__c.Fields.Key__c);
    } 
    // if (comments.size() > 0 && !System.isBatch()) {
      // Database.upsert(comments, Appraisal_Order_Comment__c.Fields.Key__c);
    // } // else {
    //   comments.addAll((List<Appraisal_Order_Comment__c>) BATCH_VAL.get('Comments'));
    //   BATCH_VAL.put('Comments', comments);
    // }
  }

  public static void checkStatusValuationServices(Id appraisalId) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        report_type__c,
        appraisal_firm_transaction_id__c,
        appraisal_product_ordered__c,
        property__r.deal__r.recordtype.developername
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    if (String.isBlank(appraisal.Appraisal_Firm_Transaction_ID__c)) {
      return;
    }

    Map<String, Object> resp = ValuationServicesAPI.checkOrder(
      appraisal.Appraisal_Firm_Transaction_ID__c,
      appraisal.property__r.deal__r.recordtype.developername
    );

    // system.debug('--resp--');
    // system.debug(JSON.serializePretty(resp));

    Map<String, Object> results = (Map<String, Object>) resp.get('result');

    system.debug(results);

    appraisal.Status__c = (String) results.get('status');

    if (
      results.containsKey('due_amount') &&
      results.get('due_amount') != 'N/A' &&
      results.get('due_amount') != null
    ) {
      String dueAmount = String.valueOf(results.get('due_amount'));

      if (!dueAmount.isNumeric()) {
        dueAmount = dueAmount.replaceAll('[^\\d.]', '');
      }
      appraisal.Appraisal_Fee__c = Decimal.valueOf(dueAmount);
    }
    if (
      results.containsKey('inspection_date') &&
      results.get('inspection_date') != 'N/A' &&
      results.get('inspection_date') != null
    ) {
      appraisal.Inspection_Date__c = Date.valueOf(
        String.valueOf(results.get('inspection_date') + ' 00:00:00')
      );
    }
    if (
      results.containsKey('due_date') &&
      results.get('due_date') != 'N/A' &&
      results.get('due_date') != null
    ) {
      appraisal.Estimated_Completion_Date__c = Date.valueOf(
        String.valueOf(results.get('due_date') + ' 00:00:00')
      );
    }

    if (appraisal.Status__c == 'New') {
      appraisal.Status__c = 'Ordered';
    } else if (appraisal.Status__c == 'Completed') {
      appraisal.Status__c = 'Complete-Delivered';
      Map<String, String> retrieveResp = retrieveOrderValuationServices(
        appraisalId
      );
      if (retrieveResp != null) {
        appraisal.Status__c = 'Complete-Undelivered';
      }
    }

    // if(System.isBatch()) {
    //   List<Sobject> appVal = BATCH_VAL.get('Appraisals');
    //   appVal.add((SObject) appraisal);
    //   BATCH_VAL.put('Appraisals', appVal);
    // } else {
      update appraisal;
    // }

    List<Appraisal_Order_Comment__c> comments = new List<Appraisal_Order_Comment__c>();
    system.debug(resp.get('comments'));
    for (Object com : (List<Object>) resp.get('comments')) {
      Appraisal_Order_Comment__c cmt = new Appraisal_Order_Comment__c();
      Map<String, Object> comment = (Map<String, Object>) com;
      String commentDate = (String) comment.get('comment_date');
      String body = (String) comment.get('comment');
      if (String.isNotBlank(body)) {
        //Integer lng = body.length() <= 182 ? body.length() : 182;

        cmt.Key__c = (String) comment.get('comment_id');

        cmt.Comment__c = body;
        cmt.Comment_Date__c = DateTime.valueOf(commentDate);

        cmt.Appraisal__c = appraisalId;
        comments.add(cmt);
      }
    }

    if (appraisal.Status__c == 'Complete-Delivered') {
    }
    
    if (comments.size() > 0) {
      Database.upsert(comments, Appraisal_Order_Comment__c.Fields.Key__c);
    }
    // if (comments.size() > 0 && !System.isBatch()) {
    //   Database.upsert(comments, Appraisal_Order_Comment__c.Fields.Key__c);
    // } else {
    //   comments.addAll((List<Appraisal_Order_Comment__c>) BATCH_VAL.get('Comments'));
    //   BATCH_VAL.put('Comments', comments);
    // }
  }

  public static void checkStatusUSRES(Id appraisalId) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        report_type__c,
        appraisal_firm_transaction_id__c,
        appraisal_product_ordered__c,
        property__r.deal__r.recordtype.developername
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    if (String.isBlank(appraisal.Appraisal_Firm_Transaction_ID__c)) {
      return;
    }

    Map<String, Object> resp = USResAPI.checkOrder(
      appraisal.Appraisal_Firm_Transaction_ID__c,
      appraisal.property__r.deal__r.recordtype.developername
    );

    // system.debug('--resp--');
    // system.debug(JSON.serializePretty(resp));

    Map<String, Object> results = (Map<String, Object>) resp.get('result');

    system.debug(results);

    appraisal.Status__c = (String) results.get('status');

    if (
      results.containsKey('due_amount') &&
      results.get('due_amount') != 'N/A' &&
      results.get('due_amount') != null
    ) {
      String dueAmount = String.valueOf(results.get('due_amount'));

      if (!dueAmount.isNumeric()) {
        dueAmount = dueAmount.replaceAll('[^\\d.]', '');
      }
      appraisal.Appraisal_Fee__c = Decimal.valueOf(dueAmount);
    }
    if (
      results.containsKey('inspection_date') &&
      results.get('inspection_date') != 'N/A' &&
      results.get('inspection_date') != null
    ) {
      appraisal.Inspection_Date__c = Date.valueOf(
        String.valueOf(results.get('inspection_date') + ' 00:00:00')
      );
    }
    if (
      results.containsKey('due_date') &&
      results.get('due_date') != 'N/A' &&
      results.get('due_date') != null
    ) {
      appraisal.Estimated_Completion_Date__c = Date.valueOf(
        String.valueOf(results.get('due_date') + ' 00:00:00')
      );
    }

    if (appraisal.Status__c == 'New') {
      appraisal.Status__c = 'Ordered';
    } else if (appraisal.Status__c == 'Completed') {
      appraisal.Status__c = 'Complete-Delivered';
      Map<String, String> retrieveResp = retrieveOrderUSRES(
        appraisalId
      );
      if (retrieveResp != null) {
        appraisal.Status__c = 'Complete-Undelivered';
      }
    }

    // if(System.isBatch()) {
    //   List<Sobject> appVal = BATCH_VAL.get('Appraisals');
    //   appVal.add((SObject) appraisal);
    //   BATCH_VAL.put('Appraisals', appVal);
    // } else {
      update appraisal;
    // }

    List<Appraisal_Order_Comment__c> comments = new List<Appraisal_Order_Comment__c>();
    system.debug(resp.get('comments'));
    for (Object com : (List<Object>) resp.get('comments')) {
      Appraisal_Order_Comment__c cmt = new Appraisal_Order_Comment__c();
      Map<String, Object> comment = (Map<String, Object>) com;
      String commentDate = (String) comment.get('comment_date');
      String body = (String) comment.get('comment');
      if (String.isNotBlank(body)) {
        //Integer lng = body.length() <= 182 ? body.length() : 182;

        cmt.Key__c = (String) comment.get('comment_id');

        cmt.Comment__c = body;
        cmt.Comment_Date__c = DateTime.valueOf(commentDate);

        cmt.Appraisal__c = appraisalId;
        comments.add(cmt);
      }
    }

    if (appraisal.Status__c == 'Complete-Delivered') {
    }
    
    if (comments.size() > 0) {
      Database.upsert(comments, Appraisal_Order_Comment__c.Fields.Key__c);
    }
    // if (comments.size() > 0 && !System.isBatch()) {
    //   Database.upsert(comments, Appraisal_Order_Comment__c.Fields.Key__c);
    // } else {
    //   comments.addAll((List<Appraisal_Order_Comment__c>) BATCH_VAL.get('Comments'));
    //   BATCH_VAL.put('Comments', comments);
    // }
  }

  public static void checkStatusClarocity(Id appraisalId) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        Deal__r.RecordType.DeveloperName,
        report_type__c,
        appraisal_firm_transaction_id__c,
        appraisal_product_ordered__c
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    if (String.isBlank(appraisal.Appraisal_Firm_Transaction_ID__c)) {
      return;
    }

    Map<String, Object> resp = ClarocityAPI.checkOrder(
      appraisal.Appraisal_Firm_Transaction_ID__c,
      appraisal.Deal__r.RecordType.DeveloperName
    );

    appraisal.Status__c = (String) resp.get('description');

    Map<String, String> statusMap = new Map<String, String>{
      'Unassigned' => 'Ordered',
      'New' => 'Ordered',
      'In Progress' => 'Assigned',
      'QC Ready' => 'Ready for Review',
      'Completed' => 'Complete-Delivered',
      'Order Canceled' => 'Canceled',
      'Bulk Order Hold' => 'On Hold',
      'Duplicate' => 'Cancelled',
      'Manual Hold' => 'On Hold'
    };

    if (statusMap.containsKey(appraisal.Status__c)) {
      appraisal.Status__c = statusMap.get(appraisal.Status__c);
    }

    if (appraisal.Status__c == 'Complete-Delivered') {
      ClarocityAPI.retrieveOrderFuture(
        appraisalId,
        appraisal.Deal__r.RecordType.DeveloperName
      );
    }
    update appraisal;
  }
  /*
 @AuraEnabled
   public static void retrieveOrder(Id appraisalId){
      String appraisalFirm = [SELECT Id, Vendor_Ordered_From__c FROM Appraisal__c WHERE Id =: appraisalId LIMIT 1].Vendor_Ordered_From__c;
       if(appraisalFirm == 'Clear Capital'){
           retrieveOrderClearCapital(appraisalId);
       }else if(appraisalFirm == 'Appraisal Nation'){
           retrieveOrderAppraisalNation(appraisalId);
       }else if(appraisalFirm == 'Clarocity Valuation Services'){

       }
   }
   */

  public static void retrieveOrderClearCapital(Id appraisalId) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        Deal__r.RecordType.DeveloperName,
        report_type__c,
        appraisal_firm_transaction_id__c,
        Property_Address__c,
        Property__r.Deal__c,
        appraisal_product_ordered__c,
        Property__c,
        Property__r.Deal_Record_Type__C
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    String docString = '';
    if (appraisal.Property__r.Deal_Record_Type__c == 'LOC_Loan') {
      //
    }

    ClearCapitalAPI.retrieveOrderFuture(appraisalId, 'xml');
    ClearCapitalAPI.retrieveOrderFuture(appraisalId, 'pdf');

    // Map<String, String> results = ClearCapitalAPI.retrieveOrder(appraisal.Appraisal_Firm_Transaction_ID__c, 'xml', appraisal.Deal__r.RecordType.DeveloperName);

    // List<ContentVersion> cvs = new List<ContentVersion>();
    // String propertyAddress = appraisal.Property_Address__c;
    // String xmlFileId = '';
    // if(results.containsKey('file')){
    //     ContentVersion cv = new ContentVersion();
    //     cv.ContentLocation = 'S';
    //     //cv.ContentDocumentId = contentDocumentId;

    //     if(Test.isRunningTest()){
    //         StaticResource xml = [SELECT Id, Body FROM StaticResource WHERE Name = 'AppraisalXMLTest' LIMIT 1];
    //         cv.VersionData = xml.Body;
    //     }else{
    //         cv.VersionData = EncodingUtil.base64Decode(results.get('file'));
    //     }

    //     cv.Title = propertyAddress + '.xml';
    //     cv.PathOnClient = propertyAddress + '.xml';

    //     cvs.add(cv);

    // }//

    // results = ClearCapitalAPI.retrieveOrder(appraisal.Appraisal_Firm_Transaction_ID__c, 'pdf', appraisal.Deal__r.RecordType.DeveloperName);

    // if(results.containsKey('file')){
    //     ContentVersion cv = new ContentVersion();
    //     cv.ContentLocation = 'S';
    //     //cv.ContentDocumentId = contentDocumentId;
    //     cv.VersionData = EncodingUtil.base64Decode(results.get('file'));
    //     cv.Title = propertyAddress + '.pdf';
    //     cv.PathOnClient = propertyAddress + '.pdf';

    //     cvs.add(cv);

    // }

    // if(cvs.size() > 0){
    //     insert cvs;

    //     List<String> docIds = new List<String>();
    //     for(ContentVersion cv : [SELECT Id, ContentDocumentId, FileExtension FROM ContentVersion WHERE Id IN :cvs]){
    //         ContentDocumentLink link = new ContentDocumentLink();
    //         link.ShareType = 'I';
    //         link.LinkedEntityId = appraisalId;
    //         link.ContentDocumentId = cv.ContentDocumentId;
    //         link.Visibility = 'AllUsers';

    //         insert link;

    //         if(cv.FileExtension == 'xml'){
    //             xmlFIleId = link.ContentDocumentId;
    //         }

    //         docIds.add(link.ContentDocumentId);
    //     }

    //     List<Deal_Document__c> dealDocs = BorrowerChecklistController.createDealDocs(appraisal.Property__r.Deal__c, docIds, 'Diligence Documents;Property Level Documents|Valuations', appraisal.Property__c, appraisalId);
    //     List<Deal_Document__c> needAppraisals = new List<Deal_Document__c>();
    //     for(Deal_Document__c doc : dealDocs){
    //         if( doc.Attachment_Id__c == xmlFileId ){
    //             needAppraisals.add(doc);
    //         }
    //     }

    //         system.enqueueJob(new AppraisalParser(needAppraisals));
    // }

    //system.debug(results);
    return;
  }

  public static Map<String, String> retrieveOrderAppraisalNation(
    Id appraisalId
  ) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        report_type__c,
        appraisal_firm_transaction_id__c,
        Property_Address__c,
        Property__r.Deal__c,
        appraisal_product_ordered__c,
        Property__c,
        Property__r.Deal_Record_Type__C
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    return AppraisalNationAPI.retrieveOrder(
      appraisal.appraisal_firm_transaction_id__c,
      appraisalId
    );
  }

  public static Map<String, String> retrieveOrderValuationServices(
    Id appraisalId
  ) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        report_type__c,
        appraisal_firm_transaction_id__c,
        Property_Address__c,
        Property__r.Deal__c,
        appraisal_product_ordered__c,
        Property__c,
        Property__r.Deal_Record_Type__C
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    return ValuationServicesAPI.retrieveOrder(
      appraisal.appraisal_firm_transaction_id__c,
      appraisalId
    );
  }

  public static Map<String, String> retrieveOrderUSRES(
    Id appraisalId
  ) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        report_type__c,
        appraisal_firm_transaction_id__c,
        Property_Address__c,
        Property__r.Deal__c,
        appraisal_product_ordered__c,
        Property__c,
        Property__r.Deal_Record_Type__C
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    return USResAPI.retrieveOrder(
      appraisal.appraisal_firm_transaction_id__c,
      appraisalId
    );
  }

  public static void sendRetrievalErrorEmail(Id appraisalId, String fileUrl) {
    List<String> toAddresses = new List<String>{ 'bryon.harland@cvest.com' };
    List<String> bccAddresses = new List<String>{ 'bryon.harland@cvest.com' };

    String htmlBody = '<html><body>';
    htmlBody += 'Due to size limitations, the PDF and/or the XMl was not received through the API. ';
    htmlBody += fileURL;
    htmlBody += '<br/><br/>';
    htmlBody += 'Upload the XML to the following appraisal record ';
    htmlBody +=
      System.URL.getOrgDomainURL().toExternalForm() +
      '/lightning/r/Appraisal__c/' +
      appraisalId +
      '/view';

    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setSubject('Appraisal API Unable to Retrieve Files due to size limitation');
    email.setHtmlBody(htmlBody);
    email.setToAddresses(toAddresses);
    email.setBccAddresses(bccAddresses);

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
  }

  public static void sendRetrievalErrorEmail(
    Id appraisalId,
    List<String> fileUrls
  ) {
    Appraisal__c appraisal = [
      SELECT
        Id,
        Deal__r.Underwriter__r.Email,
        Deal__r.Name,
        Deal__r.Deal_Loan_Number__c,
        Deal__r.StageName,
        CreatedBy.Email,
        Property__c,
        Vendor_Ordered_From__c,
        Property__r.Name,
        Property__r.City__c,
        Property__r.State__c,
        Property__r.ZipCode__c,
        Property__r.BPO_Appraisal_Date__c,
        Property__r.Appraised_Value_Amount__c,
        Property__r.Status__c
      FROM Appraisal__c
      WHERE Id = :appraisalId
      LIMIT 1
    ];

    OrgWideEmailAddress fromAddress = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'integrations@cvest.com'
      LIMIT 1
    ];

    List<String> toAddresses = new List<String>{
      appraisal.Deal__r.Underwriter__r.Email,
      appraisal.CreatedBy.Email
    };
    List<String> bccAddresses = new List<String>{ 'bryon.harland@cvest.com' };

    String htmlBody = '<html><body>';
    htmlBody += 'Due to size limitations, the PDF and/or the XMl was not received through the API.  ';
    htmlBody +=
      '<p>Deal: ' +
      appraisal.Deal__r.Name +
      '(' +
      appraisal.Deal__r.Deal_Loan_Number__c +
      '<br/>Deal Stage: ' +
      appraisal.Deal__r.StageName +
      ')</p>';
    htmlBody +=
      '<p>Property Address: ' +
      appraisal.Property__r.Name +
      ', ' +
      appraisal.Property__r.City__c +
      ', ' +
      appraisal.Property__r.State__c +
      ' ' +
      appraisal.Property__r.ZipCode__c +
      '</p>';
    htmlBody +=
      '<p>Property Status: ' +
      appraisal.Property__r.Status__c +
      '</p>';
    htmlBody += '<br/>';
    for (String fileURL : fileUrls) {
      htmlBody += fileURL + '<br/>';
    }
    //htmlBody += fileURL;
    htmlBody += '<br/>';
    htmlBody += 'Upload the XML to the following Appraisal record <br/>';
    htmlBody +=
      System.URL.getOrgDomainURL().toExternalForm() +
      '/lightning/r/Appraisal__c/' +
      appraisalId +
      '/view';

    htmlBody += '<br/>';
    htmlBody += 'Upload the PDF to the following Property record <br/>';
    htmlBody +=
      System.URL.getOrgDomainURL().toExternalForm() +
      '/lightning/r/Property__c/' +
      appraisal.Property__c +
      '/view';

    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setSubject(
      appraisal.Vendor_Ordered_From__c + ' Appraisal API Unable to Retrieve Files due to size limitation'
    );
    email.setHtmlBody(htmlBody);
    email.setToAddresses(toAddresses);
    email.setOrgWideEmailAddressId(fromAddress.Id);
    email.setBccAddresses(bccAddresses);
    email.setUseSignature(false);

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
  }
}