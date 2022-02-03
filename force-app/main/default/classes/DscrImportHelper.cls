public without sharing class DscrImportHelper {
  public class ImportException extends Exception {
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

  // TODO: complete deal generation. Loan_Purpose__c is the next field to be added.

  public static final Map<String,Map<String, Data_Transformation__mdt>> DATA_TRANSFORMATION_MAP = getDataTransformationMetaMap();

  @AuraEnabled
  public static String getFileBody(String fileId) {
    try {
      ContentVersion cv = [
        SELECT id, ContentDocumentId, VersionData
        FROM Contentversion
        WHERE id = :fileId
      ];

      return EncodingUtil.base64Encode(cv.VersionData);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, String> getLastAttachment(String recordId) {
    try {
      Map<String, String> retVal = new Map<String, String>();

      List<ContentDocumentLink> docs = [
        SELECT
          ContentDocumentId,
          Id,
          ContentDocument.Title,
          contentdocument.fileextension,
          contentdocument.LatestPublishedVersionId
        FROM ContentDocumentLink
        WHERE
          LinkedEntityId = :recordId
          AND ContentDocument.FileType = 'EXCEL_X'
        ORDER BY contentdocument.ContentModifiedDate DESC
        LIMIT 1
      ];

      if (docs.size() > 0) {
        retVal.put(
          'name',
          docs[0].ContentDocument.Title +
          '.' +
          docs[0].ContentDocument.FileExtension
        );
        retVal.put(
          'contentVersionId',
          docs[0].contentdocument.LatestPublishedVersionId
        );
        retVal.put('documentId', docs[0].ContentDocumentId);
      } else {
        retVal.put('noResult', 'true');
      }

      return retVal;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<Map<String, String>> parseFileValues(
    String fileJson,
    Id recordId
  ) {
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

      List<Map<String, String>> cleanMapList = new List<Map<String, String>>();

      for (Map<String, String> m : mapToParse) {
        if (!m.containsKey('Loan ID')) {
          break;
        }

        Map<String, String> cleanMap = new Map<String, String>();
        String email = '';
        String accountName = '';

        for (String key : m.keySet()) {
          String newKey = key;

          if (key.contains('\n')) {
            newKey = key.substringBefore('\n');
          }

          if(key.contains('Loan Purpose')) {
            newKey = 'Loan Purpose';
          }

          if(key.contains('Program Type')) {
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
            'No Guarantor Email found for Line ' + cleanMap.get('Loan ID')
          );
        }
        if (String.isEmpty(accountName)) {
          throw new ImportException(
            'No Borrower Name found for Line ' + cleanMap.get('Loan ID')
          );
        }
        emailToAccount.put(email, accountName);
        cleanMapList.add(cleanMap);
      }

      Map<String, Contact> contactMap = generateContactsMap(
        emailToAccount,
        cleanMapList,
        ldRecord
      );

      return mapToParse;
    } catch (Exception e) {
      throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());
    }
  }

  public static Map<String, Contact> generateContactsMap(
    Map<String, String> emailToAccount,
    List<Map<String, String>> cleanMapList,
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

    for (Map<String, String> m : cleanMapList) {
      if (retMap.containsKey(m.get('Guarantor Email'))) {
        continue;
      }

      if (
        !m.containsKey('Guarantor Name') ||
        String.isEmpty(m.get('Guarantor Name'))
      ) {
        throw new ImportException(
          'No guarantor name found for Loan ID ' + m.get('Loan ID')
        );
      }

      Contact newContact = new Contact();
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

  public static Opportunity generateDeal(Map<String, String> m) {
    Opportunity deal = new Opportunity();

    Id dealRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Acquired Bridge Loan')
      .getRecordTypeId();

    deal.RecordTypeId = dealRecId;
    deal.Name = m.get('Borrower Name');
    deal.Deal_Intro_Source__c = 'Imported List';
    deal.StageName = 'Initial Review';

    if (String.isNotEmpty(m.get('Units')) && m.get('Units').isNumeric()) {
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
      m.get('Rehab Holdback').isNumeric()
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

    if(String.isNotEmpty(m.get('Interest Holdback')) && m.get('Interest Holdback').isNumeric()) {
      deal.Interest_Reserves__c = Decimal.valueOf(m.get('Interest Holdback'));
    }

    if(String.isNotEmpty(m.get('Total Loan Amount')) && m.get('Total Loan Amount').isNumeric()) {
      deal.LOC_Commitment__c = Decimal.valueOf(m.get('Total Loan Amount'));
    } else {
      throw new ImportException('No total loan amount found for ' + m.get('Loan Id'));
    }

    deal.Deal_Code__c = m.get('Loan ID');
    deal.Yardi_ID__c = m.get('Loan Id');
    
    if(String.isNotEmpty(m.get('Lender Name'))) {
      deal.Lender__c = m.get('Lender Name');
    }




    return deal;
  }

  public static Map<String,Map<String, Data_Transformation__mdt>> getDataTransformationMetaMap() {
    Map<String,Map<String, Data_Transformation__mdt>> retMap = new Map<String,Map<String, Data_Transformation__mdt>>();

    List<Data_Transformation__mdt> dtms = Data_Transformation__mdt.getAll().values();

    for(Data_Transformation__mdt dtm : dtms) {
      Map<String, Data_Transformation__mdt> dtmMap = new Map<String, Data_Transformation__mdt>();
      if(retMap.containsKey(dtm.Field_API_Name__c)) {
        dtmMap = retMap.get(dtm.Field_API_Name__c);
      }

      dtmMap.put(dtm.Incoming_Data__c, dtm);
      retMap.put(dtm.Field_API_Name__c, dtmMap);
    }

    return retMap;
  }
}
