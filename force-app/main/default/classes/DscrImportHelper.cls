public without sharing class DscrImportHelper {
  public class ImportException extends Exception {
  }


  // field reference from the JS file is commented at the bottom of this file.

  public static final Id HOUSE_ACCOUNT_USER = retrieveHouseAccountUserId();
  public static final Map<String, Map<String, Data_Transformation__mdt>> DATA_TRANSFORMATION_MAP = getDataTransformationMetaMap();
  public static final Id DEAL_RECID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
    .get('Investor DSCR')
    .getRecordTypeId();

  public static final Id PROP_RECID = Schema.SObjectType.Property__c.getRecordTypeInfosByName()
    .get('Single Rental Loan')
    .getRecordTypeId();


  public static Id retrieveHouseAccountUserId() {
    List<User> contacts = [SELECT Id FROM USer WHERE Name = 'House Account'];

    return contacts.size() > 0 ? contacts[0].Id : UserInfo.getUserId();
  }

  @AuraEnabled
  public static List<Lender_Deal_to_Deal__c> parseFileValues(
    String fileJson,
    Id recordId
  ) {
    Savepoint sp = Database.setSavepoint();

    try {
      Lender_Deal__c ldRecord = [
        SELECT Lender__r.Name, Lender__c
        FROM Lender_Deal__c
        WHERE Id = :recordId
      ];

      Integer sheetNo = 0;
      System.debug('entering parseFileValues');
      List<Map<String, String>> mapToParse = new List<Map<String, String>>();
      Map<String, String> fileRecords = (Map<String, String>) JSON.deserialize(
        fileJson,
        Map<String, String>.class
      );
      System.debug(fileRecords);

      for (String k : fileRecords.keySet()) {
        // take the first sheet only assuming the name is not known. We can extend this to support multiple sheets.
        if (sheetNo > 0) {
          break;
        }
        sheetNo++;
        mapToParse = (List<Map<String, String>>) JSON.deserialize(
          fileRecords.get(k),
          List<Map<String, String>>.class
        );
      }

      Map<String, String> emailToAccount = new Map<String, String>();

      List<Map<String,String>> cleanedMapList = new List<Map<String,String>>();
      Set<String> loanIdSet = new Set<String>();

      for (Map<String, String> m : mapToParse) {
        if (!m.containsKey('Loan ID')) {
          break;
        } else {
          loanIdSet.add(m.get('Loan ID').trim());
        }

        Map<String, String> cleanMap = new Map<String, String>();
        String email = '';
        String accountName = '';

        for (String key : m.keySet()) {
          String newKey = key;

          if (key.contains('\n')) {
            newKey = key.substringBefore('\n');
          }

          if (key.contains('Loan Purpose')) {
            newKey = 'Loan Purpose';
          }

          if(key.contains('Amortization Type')) {
            newKey = 'Amortization Type';
          }

          newKey = newKey.trim();

          cleanMap.put(newKey, m.get(key).trim());

          if (newKey == 'Guarantor Email') {
            email = m.get(key);
          }

          if (newKey == 'Borrower Name') {
            accountName = m.get(key);
          }
        }

        if (String.isEmpty(email)) {
          throw new ImportException(
            'Unable to finish import due to: No Guarantor Email found for Line ' +
            (cleanedMapList.size() + 1)
          );
        }
        if (String.isEmpty(accountName)) {
          throw new ImportException(
            'Unable to finish import due to: No Borrower Name found for Line ' +
            (cleanedMapList.size() + 1)
          );
        }
        emailToAccount.put(email, accountName);
        cleanedMapList.add(cleanMap);
      }

      if(cleanedMapList.size() == 0) {
        throw new ImportException('This does not seem to be a valid excel file.');
      }

      Map<String, Contact> contactMap = generateContactsMap(
        emailToAccount,
        cleanedMapList,
        ldRecord
      );

      Map<String, Opportunity> newDeals = createDeals(
        cleanedMapList,
        contactMap,
        ldRecord,
        loanIdSet
      );

      List<Property__c> newProps = createNewPropertiesFromDeals(
        newDeals,
        cleanedMapList
      );

      List<Deal_Contact__c> dealContacts = createDealContacts(
        newDeals,
        contactMap,
        cleanedMapList
      );

      List<Lender_Deal_to_Deal__c> newLdds = new List<Lender_Deal_to_Deal__c>();

      for(Map<String, String> m : cleanedMapList) {
        String uniqueId = m.get('Loan ID');
        Opportunity deal = newDeals.get(uniqueId);
        Lender_Deal_to_Deal__c ldd = new Lender_Deal_to_Deal__c();
        ldd.Deal__c = deal.Id;
        ldd.Lender_Deal__c = recordId;
        ldd.Status__c = 'Decision Pending';
        newLdds.add(ldd);
      }

      insert newLdds;

      return newLdds;
    } catch (Exception e) {
      Database.rollback(sp);
      System.debug(e.getLineNumber() + ' : ' + e.getMessage());
      throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());
    }
  }

  public static Map<String, Opportunity> createDeals(
    List<Map<String, String>> cleanedMapList,
    Map<String, Contact> contactMap,
    Lender_Deal__c ldRecord,
    Set<String> loanIDs
  ) {

    Map<String, Opportunity> newDeals = new Map<String, Opportunity>();
    Map<String, Id> existingDeals = generateExistingDealsMap(loanIDs);

    for (Map<String, String> cm : cleanedMapList) {
      String uniqueId = cm.get('Loan ID');
      if(newDeals.containsKey(uniqueId)) {
        continue;
      }
      Opportunity existingDeal = new Opportunity();
      if(existingDeals.containsKey(uniqueId)) {
        existingDeal.Id = existingDeals.get(uniqueId);
      }

      Opportunity newDeal = generateDeal(cm, existingDeal);
      newDeal.Deal_Intro_Sub_Source__c = ldRecord.Lender__c != null
        ? ldRecord.Lender__r.Name
        : null;
      newDeal.Approved_Third_Party_Originators__c = ldRecord.Lender__c;
      newDeal.AccountId = contactMap.get(cm.get('Guarantor Email')).AccountId;

      newDeals.put(uniqueId, newDeal);
    }

    upsert newDeals.values();

    return newDeals;
  }

  public static Map<String, Id> generateExistingDealsMap(Set<String> loanIds) {
    Map<String, Id> retMap = new Map<String, Id>();
    List<Opportunity> existingDeals = [
      SELECT Id, Deal_Code__c
      FROM Opportunity
      WHERE Deal_Code__c IN :loanIds
    ];

    for (Opportunity deal : existingDeals) {
      retMap.put(deal.Deal_Code__c, deal.Id);
    }

    return retMap;
  }

  public static List<Property__c> createNewPropertiesFromDeals(
    Map<String, Opportunity> newDeals,
    List<Map<String, String>> cleanedMapList
  ) {
    List<Property__c> newProps = new List<Property__c>();

    for (Map<String, String> cm : cleanedMapList) {
      String uniqueId = cm.get('Loan ID');
      Opportunity newDeal = newDeals.get(uniqueId);
      Property__c newProp = generateProperty(cm, newDeal);
      newProps.add(newProp);
    }

    insert newProps;

    return newProps;
  }

  public static List<Deal_Contact__c> createDealContacts(
    Map<String, Opportunity> newDeals,
    Map<String, Contact> contactMap,
    List<Map<String, String>> cleanedMapList
  ) {
    List<Deal_Contact__c> dealContacts = new List<Deal_Contact__c>();

    for (Map<String, String> cm : cleanedMapList) {
      String uniqueId = cm.get('Loan ID');
      Opportunity newDeal = newDeals.get(uniqueId);
      Contact newContact = contactMap.get(cm.get('Guarantor Email'));
      List<Deal_Contact__c> newDealContacts = generateDealContacts(
        newDeal,
        newContact,
        cm
      );
      dealContacts.addAll(newDealContacts);
    }

    insert dealContacts;

    return dealContacts;
  }

  public static Map<String, Contact> generateContactsMap(
    Map<String, String> emailToAccount,
    List<Map<String, String>> cleanedMapList,
    Lender_Deal__c ld
  ) {
    Map<String, Contact> retMap = new Map<String, Contact>();
    Map<String, Account> accountMap = generateAccountMap(
      emailToAccount.values(),
      ld
    );

    List<Contact> contacts = [
      SELECT Id, Name, Email, AccountId
      FROM Contact
      WHERE
        Email IN :emailToAccount.keySet()
        AND RecordType.DeveloperName = 'Borrower'
    ];

    for (Contact c : contacts) {
      retMap.put(c.Email, c);
    }

    List<Contact> newContacts = new List<Contact>();
    Id ctcRecId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
      .get('Borrower')
      .getRecordTypeId();

    for (Map<String, String> m : cleanedMapList) {
      if (retMap.containsKey(m.get('Guarantor Email'))) {
        continue;
      }

      if (
        !m.containsKey('Guarantor Name') ||
        String.isEmpty(m.get('Guarantor Name'))
      ) {
        throw new ImportException(
          'Unable to finish import due to: No guarantor name found for Loan ID ' +
          m.get('Loan ID')
        );
      }

      Contact newContact = new Contact();
      newContact.OwnerId = HOUSE_ACCOUNT_USER;
      newContact.FirstName = m.get('Guarantor Name').substringBefore(' ');
      newContact.LastName = m.get('Guarantor Name').substringAfter(' ');
      newContact.Email = m.get('Guarantor Email');
      newContact.RecordTypeId = ctcRecId;
      newContact.Introduction_Source__c = 'Imported List';
      if (ld.Lender__r != null) {
        newContact.Introduction_Subsource__c = ld.Lender__r.Name;
      }
      newContact.AccountId = accountMap.get(m.get('Borrower Name')).Id;
      newContacts.add(newContact);
    }

    if (newContacts.size() > 0) {
      insert newContacts;

      for (Contact c : newContacts) {
        retMap.put(c.Email, c);
      }
    }

    return retMap;
  }

  public static Map<String, Account> generateAccountMap(
    List<String> accountNames,
    Lender_Deal__c ld
  ) {
    Map<String, Account> accountMap = new Map<String, Account>();
    Set<String> accountNamesSet = new Set<String>();
    accountNamesSet.addAll(accountNames);

    List<Account> accounts = [
      SELECT Id, Name
      FROM Account
      WHERE Name IN :accountNamesSet AND RecordType.DeveloperName = 'Borrower'
    ];

    for (Account account : accounts) {
      accountMap.put(account.Name, account);
      accountNamesSet.remove(account.Name);
    }

    if (accountNamesSet.size() > 0) {
      List<Account> newAccounts = new List<Account>();
      Id accRecId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Borrower')
        .getRecordTypeId();

      for (String n : accountNamesSet) {
        Account newAccount = new Account();
        newAccount.OwnerId = HOUSE_ACCOUNT_USER;
        newAccount.Name = n;
        newAccount.Introductions_Source__c = 'Imported List';
        if (ld.Lender__r != null) {
          newAccount.Introduction_Subsource__c = ld.Lender__r.Name;
        }
        if (accRecId != null) {
          newAccount.RecordTypeId = accRecId;
        }
        newAccounts.add(newAccount);
      }

      try {
        insert newAccounts;

        for (Account a : newAccounts) {
          accountMap.put(a.Name, a);
        }
      } catch (Exception e) {
        throw e;
      }
    }

    return accountMap;
  }

  public static Opportunity generateDeal(Map<String, String> m, Opportunity opp) {
    Opportunity deal = opp;

    deal.RecordTypeId = DEAL_RECID;
    deal.Name = m.get('Borrower Name');
    deal.Deal_Intro_Source__c = 'Imported List';
    deal.StageName = 'Initial Review';
    deal.LOC_Loan_Type__c = 'Investor DSCR';
    
    //deal.Renovation_Funding__c ??? waiting for response

    deal.Deal_Code__c = m.get('Loan ID');
    deal.Yardi_ID__c = m.get('Loan ID');

    if (String.isNotEmpty(m.get('Lender Name'))) {
      deal.Lender__c = m.get('Lender Name');
    }

    // DATA_TRANSFORMATION_MAP
    if (
      String.isNotEmpty(m.get('Loan Purpose')) &&
      DATA_TRANSFORMATION_MAP.containsKey('Loan_Purpose__c')
    ) {
      Map<String, Data_Transformation__mdt> dtMap = DATA_TRANSFORMATION_MAP.get(
        'Loan_Purpose__c'
      );
      if (dtMap.containsKey(m.get('Loan Purpose').trim())) {
        deal.Loan_Purpose__c = dtMap.get(m.get('Loan Purpose')).Updated_Data__c;
      }
    } else if (
      String.isNotEmpty(m.get('Loan Purpose')) &&
      !DATA_TRANSFORMATION_MAP.containsKey('Loan_Purpose__c')
    ) {
      deal.Loan_Purpose__c = m.get('Loan Purpose');
    }

    if (String.isNotEmpty(m.get('Origination Date'))) {
      Date originationDate = Date.valueOf(m.get('Origination Date'));
      deal.Origination_Date__c = originationDate;
    }

    deal.CloseDate = (System.today()).addDays(5);

    if (String.isNotEmpty(m.get('Maturity Date'))) {
      Date maturityDate = Date.valueOf(m.get('Maturity Date'));
      deal.Stated_Maturity_Date__c = maturityDate;
      deal.Updated_Loan_Maturity_Date__c = maturityDate;
    }

    if (
      String.isNotEmpty(m.get('Note Rate (%)')) &&
      (m.get('Note Rate (%)').replaceAll('\\.', '')).isNumeric()
    ) {
      Decimal noteRate = Decimal.valueOf(m.get('Note Rate (%)')) * 100;
      deal.Rate__c = noteRate;
      deal.Final_Spread__c = noteRate;
    }

    if (
      String.isNotEmpty(m.get('Total Loan Amount')) &&
      (m.get('Total Loan Amount').replaceAll('\\.', '')).isNumeric()
    ) {
      Decimal tla = Decimal.valueOf(m.get('Total Loan Amount'));
      deal.Original_UPB_Svc__c = tla;
      deal.Final_Loan_Amount__c = tla;
    }

    if (String.isNotEmpty(m.get('LTC')) && (m.get('LTC').replaceAll('\\.', '')).isNumeric()) {
      Decimal ltc = Decimal.valueOf(m.get('LTC')) * 100;
      deal.LTC__c = ltc;
    }

    if (
      String.isNotEmpty(m.get('Total LTC')) && (m.get('Total LTC').replaceAll('\\.', '')).isNumeric()
    ) {
      Decimal totalLTC = Decimal.valueOf(m.get('Total LTC')) * 100;
      deal.Total_Loan_LTC__c = totalLTC;
    }

    if (String.isNotEmpty(m.get('LTV')) && (m.get('LTV').replaceAll('\\.', '')).isNumeric()) {
      Decimal ltv = Decimal.valueOf(m.get('LTV')) * 100;
      deal.Closing_LTV__c = ltv;
    }

    if (String.isNotEmpty(m.get('Date of 1st Payment'))) {
      Date dateOfFirstPayment = Date.valueOf(m.get('Date of 1st Payment'));
      deal.First_Payment_Date__c = dateOfFirstPayment;
    }
    
    if(String.isNotEmpty(m.get('Prepayment Type'))) {
      deal.Stepdown_Prepayment_Period__c = m.get('Prepayment Type').replaceAll('/', ',');
    }

    deal.Foreign_National__c = String.isNotEmpty(m.get('Foreign National (Y/N)')) ? m.get('Foreign National (Y/N)') == 'Y' : false;

    if (
      String.isNotEmpty(m.get('IO Term')) &&
      DATA_TRANSFORMATION_MAP.containsKey('IO_Term__c')
    ) {
      Map<String, Data_Transformation__mdt> dtMap = DATA_TRANSFORMATION_MAP.get(
        'IO_Term__c'
      );
      if (dtMap.containsKey(m.get('IO Term').trim())) {
        deal.IO_Term__c = dtMap.get(m.get('IO Term')).Updated_Data__c;
      }
    } else if (
      String.isNotEmpty(m.get('IO Term')) &&
      !DATA_TRANSFORMATION_MAP.containsKey('IO_Term__c')
    ) {
      deal.IO_Term__c = m.get('IO Term');
    }

    if(String.isNotEmpty(m.get('Amortization Type'))) {
      deal.Interest_Rate_Type__c = m.get('Amortization Type');
    }

    deal.Term_Loan_Type__c = '30 Year';

    return deal;
  }

  public static Map<String, Map<String, Data_Transformation__mdt>> getDataTransformationMetaMap() {
    Map<String, Map<String, Data_Transformation__mdt>> retMap = new Map<String, Map<String, Data_Transformation__mdt>>();

    List<Data_Transformation__mdt> dtms = Data_Transformation__mdt.getAll()
      .values();

    for (Data_Transformation__mdt dtm : dtms) {
      Map<String, Data_Transformation__mdt> dtmMap = new Map<String, Data_Transformation__mdt>();
      if (retMap.containsKey(dtm.Field_API_Name__c)) {
        dtmMap = retMap.get(dtm.Field_API_Name__c);
      }

      dtmMap.put(dtm.Incoming_Data__c, dtm);
      retMap.put(dtm.Field_API_Name__c, dtmMap);
    }

    return retMap;
  }

  public static Property__c generateProperty(
    Map<String, String> m,
    Opportunity deal
  ) {
    Property__c p = new Property__c();

    p.Deal__c = deal.Id;
    p.Status__c = 'Active';
    if(String.isNotEmpty(PROP_RECID)) {
      p.RecordTypeId = PROP_RECID;
    }

    if(String.isNotEmpty(m.get('Property Type')) && 
    DATA_TRANSFORMATION_MAP.containsKey('Property_Type__c')) {
      Map<String, Data_Transformation__mdt> dtMap = DATA_TRANSFORMATION_MAP.get(
        'Property_Type__c'
      );
      if (dtMap.containsKey(m.get('Property Type').trim())) {
        p.Property_Type__c = dtMap.get(m.get('Property Type')).Updated_Data__c;
      }
    } else if (
      String.isNotEmpty(m.get('Property Type')) &&
      !DATA_TRANSFORMATION_MAP.containsKey('Property_Type__c')
    ) {
      p.Property_Type__c = m.get('Property Type');
    }

    if(String.isNotEmpty(m.get('Address'))) {
      p.Name = m.get('Address');
      p.Property_Name__c = m.get('Address');
    } else {
      throw new ImportException('Unable to finish import due to: Address is missing for Loan ID: ' + m.get('Loan ID'));
    }

    if(String.isNotEmpty(m.get('City'))) {
      p.City__c = m.get('City');
    } else {
      throw new ImportException('Unable to finish import due to: City is missing for Loan ID: ' + m.get('Loan ID'));
    }

    if(String.isNotEmpty(m.get('State'))) {
      String state = m.get('State').trim();
      if(state.length() != 2) {
        throw new ImportException('Unable to finish import due to: State value (' + state + ') is invalid for Loan ID: ' + m.get('Loan ID') + '.\n State must be a 2 character abbreviation.');
      }
      p.State__c = state;
    } else {
      throw new ImportException('Unable to finish import due to: State is missing for Loan ID: ' + m.get('Loan ID'));
    }

    if(String.isNotEmpty(m.get('Zip'))) {
      p.ZipCode__c = m.get('Zip');
    }

    if(String.isNotEmpty(m.get('Units')) && (m.get('Units').replaceAll('\\.', '')).isNumeric()) {
      p.Number_of_Units__c = Decimal.valueOf(m.get('Units'));
    }

    if(String.isNotEmpty(m.get('Sqft'))) {
      String sqft = m.get('Sqft').replaceAll('[^0-9.]', '');
      p.Square_Feet__c = sqft;
    }

    if(String.isNotEmpty(m.get('Purchase Price')) && (m.get('Purchase Price').replaceAll('\\.', '')).isNumeric()) {
      p.Acquisition_Price__c = Decimal.valueOf(m.get('Purchase Price'));
    }

    if(String.isNotEmpty(m.get('Date of 1st Payment'))) {
      Date firstPayDate = Date.valueOf(m.get('Date of 1st Payment'));
      if(firstPayDate != null) {
        p.First_Payment_Date__c = firstPayDate;
      }
    }

    if(String.isNotEmpty(m.get('3rd Party Valuation Date'))) {
      Date thirdPvd = Date.valueOf(m.get('3rd Party Valuation Date'));
      if(thirdPvd != null) {
        p.BPO_Appraisal_Date__c = thirdPvd;
      }
    }

    if(String.isNotEmpty(m.get('3rd Party Valuation Type'))) {
      p.Valuation_Type__c = m.get('3rd Party Valuation Type');
    }

    if(String.isNotEmpty(m.get('3rd Party AIV')) && (m.get('3rd Party AIV').replaceAll('\\.', '')).isNumeric()) {
      p.Appraised_Value_Amount__c = Decimal.valueOf(m.get('3rd Party AIV'));
    }

    if(String.isNotEmpty(m.get('3rd Party Valuation Provider')) && 
    DATA_TRANSFORMATION_MAP.containsKey('BPO_Appraisal_Firm__c')) {
      Map<String, Data_Transformation__mdt> dtMap = DATA_TRANSFORMATION_MAP.get(
        'BPO_Appraisal_Firm__c'
      );
      if (dtMap.containsKey(m.get('3rd Party Valuation Provider').trim())) {
        p.BPO_Appraisal_Firm__c = dtMap.get(m.get('3rd Party Valuation Provider')).Updated_Data__c;
      }
    } else if (
      String.isNotEmpty(m.get('3rd Party Valuation Provider')) &&
      !DATA_TRANSFORMATION_MAP.containsKey('BPO_Appraisal_Firm__c')
    ) {
      p.BPO_Appraisal_Firm__c = m.get('3rd Party Valuation Provider');
    }

    if (
      String.isNotEmpty(m.get('Loan Purpose')) &&
      DATA_TRANSFORMATION_MAP.containsKey('Refinance_Acquisition__c')
    ) {
      Map<String, Data_Transformation__mdt> dtMap = DATA_TRANSFORMATION_MAP.get(
        'Refinance_Acquisition__c'
      );
      if (dtMap.containsKey(m.get('Loan Purpose').trim())) {
        p.Refinance_Acquisition__c = dtMap.get(m.get('Loan Purpose')).Updated_Data__c;
      }
    } else if (
      String.isNotEmpty(m.get('Loan Purpose')) &&
      !DATA_TRANSFORMATION_MAP.containsKey('Refinance_Acquisition__c')
    ) {
      p.Refinance_Acquisition__c = m.get('Loan Purpose');
    }

    if(String.isNotEmpty(m.get('Leased (Y/N)'))) {
      p.Currently_Leased__c = m.get('Leased (Y/N');
    }

    if(String.isNotEmpty(m.get('Occupancy Status/Type'))) {
      p.Occupancy_Status__c = m.get('Occupancy Status/Type');
    }

    return p;
  }

  public static List<Deal_Contact__c> generateDealContacts(Opportunity deal, Contact contact, Map<String,String> m) {
    List<Deal_Contact__c> generatedDealContacts = new List<Deal_Contact__c>();

    Deal_Contact__c entityDc = new Deal_Contact__c();
    Deal_Contact__c guarantorDc = new Deal_Contact__c();

    entityDc.Deal__c = deal.Id;
    entityDc.Deal_Contact_Type__c = 'Entity';
    entityDc.Entity_Type__c = 'Borrower';

    if(String.isNotEmpty(m.get('Borrower Name'))) {
      String borrowerName = m.get('Borrower Name');
      entityDc.Company_Name__c = borrowerName;

      if(borrowerName.containsIgnoreCase('llc')) {
        entityDc.Company_Type__c = 'Limited Liability Company';
      }
    }

    generatedDealContacts.add(entityDc);

    guarantorDc.Deal__c = deal.Id;
    guarantorDc.Deal_Contact_Type__c = 'Individual';
    guarantorDc.Entity_Type__c = 'Guarantor';
    guarantorDc.Contact__c = contact.Id;

    if(String.isNotEmpty(m.get('Experience')) && (m.get('Experience').replaceAll('\\.', '')).isNumeric()) {
      guarantorDc.Years_of_Experience1__c = Decimal.valueOf(m.get('Experience'));
    }

    if(String.isNotEmpty(m.get('FICO')) && (m.get('FICO').replaceAll('\\.', '')).isNumeric()) {
      Decimal fico = Decimal.valueOf(m.get('FICO'));
      guarantorDc.Experian__c = fico;
      guarantorDc.TransUnion__c = fico;
      guarantorDc.Equifax__c = fico;
    }

    generatedDealContacts.add(guarantorDc);

    return generatedDealContacts;
  }
}

/* A SINGLE DATA COMES IN FROM JAVASCRIPT LIKE THIS:
{
    "Loan ID": 3243424,
    "Lender Name": "ChurChill",
    "Address": "456 Another St",
    "City": "Costa Mesa",
    "State": "CA",
    "Zip": "92627",
    "Property Type": "SFR",
    "Units": 1,
    "Sqft": 1100,
    "Origination Date": "2021-12-01T08:00:00.000Z",
    "Maturity Date": "2024-01-01T08:00:00.000Z",
    "Amortization Type (Fixed, IO, ADJ)": "IO",
    "IO Term": 120,
    "Note Rate (%)": 0.02,
    "Rate Type": "Fixed",
    " Total Loan Amount ": 800000,
    " 3rd Party AIV ": 50000,
    " Purchase Price ": 60000,
    " Total LTC ": 0.8,
    " LTV ": 0.85,
    " Leased (Y/N) ": "Y",
    " Occupancy Status/Type ": "Occupied/Short Term Rental",
    "DSCR Value": 5.56,
    "Borrower Name": "456 Some Place Inc",
    "Guarantor Name": "Blaire Clutters",
    "Guarantor Email": "cluutersbl@gmailf.com",
    "Experience": 2,
    "FICO": 750,
    "Loan Purpose (Acquisition,Refi, or Cash out Refi)": "Refi",
    "Date of 1st Payment": "2022-02-02T08:00:00.000Z",
    "3rd Party Valuation Date": "2021-12-01T08:00:00.000Z",
    "3rd Party Valuation Type": "Exterior Appraisal",
    "3rd Party Valuation Provider": "AN",
    "Prepayment Type": "5/4/3/2/1",
    "Foreign National (Y/N)": "N"
}
*/ 