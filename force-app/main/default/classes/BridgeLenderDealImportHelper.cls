public without sharing class BridgeLenderDealImportHelper {
    public class ImportException extends Exception {
    }
  
  
    // field reference from the JS file is commented at the bottom of this file.
  
    public static final Id HOUSE_ACCOUNT_USER = retrieveHouseAccountUserId();
    public static final Map<String, Map<String, Data_Transformation__mdt>> DATA_TRANSFORMATION_MAP = getDataTransformationMetaMap();
    public static final Id DEAL_RECID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Acquired Bridge Loan')
      .getRecordTypeId();
  
    public static final Map<String, Id> PROP_RECIDMAP = new Map<String, Id>{
      'Bridge Renovation' => Schema.SObjectType.Property__c.getRecordTypeInfosByName()
        .get('Bridge Renovation')
        .getRecordTypeId(),
      'Bridge No Renovation' => Schema.SObjectType.Property__c.getRecordTypeInfosByName()
        .get('Bridge No Renovation')
        .getRecordTypeId()
    };
  
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
  
        Map<String, Map<String,String>> cleanMapMain = new Map<String, Map<String,String>>();
  
        for (Map<String, String> m : mapToParse) {
          if (!m.containsKey('Loan ID')) {
            break;
          }
  
          if (cleanMapMain.containsKey(m.get('Loan ID'))) {
            continue;
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
  
            if (key.contains('Program Type')) {
              newKey = 'Program Type';
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
              cleanMap.get('Loan ID')
            );
          }
          if (String.isEmpty(accountName)) {
            throw new ImportException(
              'Unable to finish import due to: No Borrower Name found for Line ' +
              cleanMap.get('Loan ID')
            );
          }
          emailToAccount.put(email, accountName);
          cleanMapMain.put(cleanMap.get('Loan ID'), cleanMap);
        }

        if(cleanMapMain.size() == 0) {
          throw new ImportException('This does not seem to be a valid excel file.');
        }
  
        Map<String, Contact> contactMap = generateContactsMap(
          emailToAccount,
          cleanMapMain,
          ldRecord
        );
  
        Map<String, Opportunity> newDeals = createDeals(
          cleanMapMain,
          contactMap,
          ldRecord
        );
  
        List<Property__c> newProps = createNewPropertiesFromDeals(
          newDeals,
          cleanMapMain
        );
  
        List<Deal_Contact__c> dealContacts = createDealContacts(
          newDeals,
          contactMap,
          cleanMapMain
        );
  
        List<Lender_Deal_to_Deal__c> newLdds = new List<Lender_Deal_to_Deal__c>();
  
        for(Map<String, String> m : cleanMapMain.values()) {
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
        System.debug(e.getMessage());
        throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());
      }
    }
  
    public static Map<String, Opportunity> createDeals(
      Map<String, Map<String, String>> cleanMapMain,
      Map<String, Contact> contactMap,
      Lender_Deal__c ldRecord
    ) {
      Map<String, Opportunity> newDeals = new Map<String, Opportunity>();
      Map<String, Id> existingDeals = generateExistingDealsMap(cleanMapMain.keySet());
  
      for (Map<String, String> cm : cleanMapMain.values()) {
        String uniqueId = cm.get('Loan ID');
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
      Map<String, Map<String, String>> cleanMapMain
    ) {
      List<Property__c> newProps = new List<Property__c>();
  
      for (Map<String, String> cm : cleanMapMain.values()) {
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
      Map<String, Map<String, String>> cleanMapMain
    ) {
      List<Deal_Contact__c> dealContacts = new List<Deal_Contact__c>();
  
      for (Map<String, String> cm : cleanMapMain.values()) {
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
      Map<String, Map<String, String>> cleanMapMain,
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
  
      for (Map<String, String> m : cleanMapMain.values()) {
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
  
      if (String.isNotEmpty(m.get('Units')) && (m.get('Units').replaceAll('\\.', '')).isNumeric()) {
        Decimal units = Decimal.valueOf(m.get('Units'));
  
        if (units >= 1 && units <= 4) {
          deal.LOC_Loan_Type__c = 'Single Asset (1-4 Unit)';
        } else if (units >= 5 && units <= 10) {
          deal.LOC_Loan_Type__c = 'Single Asset (5-10 Unit)';
        } else if (units > 10) {
          deal.LOC_Loan_Type__c = 'Multifamily/CRE';
        }
      }
  
      if (
        String.isNotEmpty(m.get('Rehab Holdback')) &&
        (m.get('Rehab Holdback').replaceAll('\\.', '')).isNumeric()
      ) {
        Boolean isDutch = false;
  
        if (String.isNotEmpty(m.get('Dutch/Non-Dutch'))) {
          isDutch = Boolean.valueOf(m.get('Dutch/Non-Dutch'));
        }
  
        Decimal rehabHoldback = Decimal.valueOf(m.get('Rehab Holdback'));
        if (rehabHoldback > 0) {
          deal.Product_Sub_Type__c = 'Renovation';
          deal.Renovation_Funding__c = 'Yes';
          deal.Reno_Funding_Type__c = isDutch ? 'Reserves' : 'Advances';
        } else {
          deal.Product_Sub_Type__c = 'No Renovation';
          deal.Renovation_Funding__c = 'No';
        }
      } else {
        deal.Product_Sub_Type__c = 'No Renovation';
        deal.Renovation_Funding__c = 'No';
      }
  
      if (
        String.isNotEmpty(m.get('Interest Holdback')) &&
        (m.get('Interest Holdback').replaceAll('\\.', '')).isNumeric()
      ) {
        deal.Interest_Reserves__c = Decimal.valueOf(m.get('Interest Holdback'));
      }
  
      if (
        String.isNotEmpty(m.get('Total Loan Amount')) &&
        (m.get('Total Loan Amount').replaceAll('\\.', '')).isNumeric()
      ) {
        Decimal totalLoanAmount = Decimal.valueOf(m.get('Total Loan Amount'));
        deal.Original_UPB_Svc__c = totalLoanAmount;
        deal.LOC_Commitment__c = totalLoanAmount;
      } else if (deal.Id == null) {
        throw new ImportException(
          'Unable to finish import due to: No total loan amount found for ' +
          m.get('Loan ID')
        );
      }
  
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
      }
  
      if (
        String.isNotEmpty(m.get('Program Type')) &&
        DATA_TRANSFORMATION_MAP.containsKey('Project_Strategy__c')
      ) {
        Map<String, Data_Transformation__mdt> dtMap = DATA_TRANSFORMATION_MAP.get(
          'Project_Strategy__c'
        );
        if (dtMap.containsKey(m.get('Program Type').trim())) {
          deal.Project_Strategy__c = dtMap.get(m.get('Program Type'))
            .Updated_Data__c;
        }
      }
      String test = 'sdf';
  
      if (String.isNotEmpty(m.get('Origination Date'))) {
        Date originationDate = Date.valueOf(m.get('Origination Date'));
        deal.Origination_Date__c = originationDate;
      }
  
      deal.CloseDate = (System.today()).addDays(3);
  
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
      }
  
      if (
        String.isNotEmpty(m.get('Current UPB')) &&
        (m.get('Current UPB').replaceAll('\\.', '')).isNumeric()
      ) {
        Decimal currentUPB = Decimal.valueOf(m.get('Current UPB'));
        deal.Current_UPB__c = currentUPB;
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
  
      if (String.isNotEmpty(m.get('ARLTV')) && (m.get('ARLTV').replaceAll('\\.', '')).isNumeric()) {
        Decimal arltv = Decimal.valueOf(m.get('ARLTV')) * 100;
        deal.Total_ARV_LTV__c = arltv;
      }
  
      if (String.isNotEmpty(m.get('Date of 1st Payment'))) {
        Date dateOfFirstPayment = Date.valueOf(m.get('Date of 1st Payment'));
        deal.First_Payment_Date__c = dateOfFirstPayment;
      }
  
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
      p.Status__c = 'Closing';
      Decimal rehabHoldback = null;
  
      if(String.isNotEmpty(m.get('Rehab Holdback')) && (m.get('Rehab Holdback').replaceAll('\\.', '')).isNumeric()) {
        rehabHoldback = Decimal.valueOf(m.get('Rehab Holdback'));
        p.Override_Reno_Advance_Amount__c = rehabHoldback;
      }
  
      if(rehabHoldback > 0 || rehabHoldback != null) {
        p.RecordTypeId = PROP_RECIDMAP.get('Bridge Renovation');
      } else {
        p.RecordTypeId = PROP_RECIDMAP.get('Bridge No Renovation');
      }
  
      if(String.isNotEmpty(m.get('Property Type')) && 
      DATA_TRANSFORMATION_MAP.containsKey('Property_Type__c')) {
        Map<String, Data_Transformation__mdt> dtMap = DATA_TRANSFORMATION_MAP.get(
          'Property_Type__c'
        );
        if (dtMap.containsKey(m.get('Property Type').trim())) {
          p.Property_Type__c = dtMap.get(m.get('Property Type')).Updated_Data__c;
        }
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
  
      if(String.isNotEmpty(m.get('Initial Draw')) && (m.get('Initial Draw').replaceAll('\\.', '')).isNumeric()) {
        p.Override_Initial_Disbursement__c = Decimal.valueOf(m.get('Initial Draw'));
      }
  
      if(rehabHoldback != null) {
        Decimal currHoldbackBalance = 0;
  
        if(String.isNotEmpty(m.get('Current Holdback Balance')) && m.get('Current Holdback Balance').replaceAll('\\.', '').isNumeric()) {
          currHoldbackBalance = Decimal.valueOf(m.get('Current Holdback Balance'));
        }
  
        p.Reno_Advance_Amount__c = rehabHoldback - currHoldbackBalance;
      }
  
      if(String.isNotEmpty(m.get('Construction Budget')) && (m.get('Construction Budget').replaceAll('\\.', '')).isNumeric()) {
        p.Rehab_Budget__c = Decimal.valueOf(m.get('Construction Budget'));
      }
  
      if(String.isNotEmpty(m.get('Property Purchase Price')) && (m.get('Property Purchase Price').replaceAll('\\.', '')).isNumeric()) {
        p.Acquisition_Price__c = Decimal.valueOf(m.get('Property Purchase Price'));
      }
  
      if(deal.First_Payment_Date__c != null) {
        p.First_Payment_Date__c = deal.First_Payment_Date__c;
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
  
      if(String.isNotEmpty(m.get('3rd Party ARV')) && (m.get('3rd Party ARV').replaceAll('\\.', '')).isNumeric()) {
        p.After_Repair_Value__c = Decimal.valueOf(m.get('3rd Party ARV'));
      }
  
      if(String.isNotEmpty(m.get('3rd Party Valuation Provider'))) {
        p.BPO_Appraisal_Firm__c = m.get('3rd Party Valuation Provider');
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
      "Loan ID": "12345",
      "Lender Name": "Lender ABC",
      "Address": "123 Test St",
      "City": "Costa Mesa",
      "State": "CA",
      "Zip": "92627",
      "Property Type": "Single Family",
      "Units": "1",
      "Sqft": "1200",
      "Loan Purpose (Refi, Purchase, Cash out Ref)": "Refi",
      "Program Type (Fix and Flip, Aggregation, GUC, BTR)": "Fix and Flip",
      "Origination Date": "44562",
      "Maturity Date": "45658",
      "Note Rate (%)": "0.02",
      " Total Loan Amount ": "1000000",
      " Current UPB ": "1000000",
      " Initial Draw ": "500000",
      " Rehab Holdback ": "500000",
      " Current Holdback Balance ": "400000",
      " Interest Holdback ": "90000",
      "Dutch/Non-Dutch \r\n(True/ False)": "false",
      " Construction Budget ": "70000",
      " Property Purchase Price ": "100000",
      " AIV ": "150000",
      " ARV ": "200000",
      "LTC": "0.75",
      "Total LTC": "0.9",
      "AILTV": "0.9",
      "ARLTV": "0.9",
      "Borrower Name": "The Borrower LLC",
      "Experience": "7",
      "FICO": "800",
      "Guarantor Name": "Bill Guarantor",
      "Guarantor Email": "bigg@guarantor.com",
      "Date of 1st Payment": "44593",
      "3rd Party Valuation Date": "44542",
      "3rd Party Valuation Type": "Interior",
      " 3rd Party AIV ": "150000",
      " 3rd Party ARV ": "200000",
      "3rd Party Valuation Provider": "Appraisal Nation"
  }
    */