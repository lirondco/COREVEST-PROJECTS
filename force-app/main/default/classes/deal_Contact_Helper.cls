public class deal_Contact_Helper {
  /*

    BridgeGuarantorList
    Loan Entities
    Loan Individuals

    */
  public static Map<String, Schema.SObjectField> FIELD_MAP = Schema.SObjectType.Deal_Contact__c.fields.getMap();

  public static void beforeUpdate(
    List<Deal_Contact__c> newList,
    List<Deal_Contact__c> oldList
  ) {
    setUserBasedOnContact(newList);
  }

  public static void beforeInsert(List<Deal_Contact__c> newList) {
    Set<String> nameSet = new Set<String>();
    Set<Date> dateEstablishedSet = new Set<Date>();
    Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
    Map<Id, List<Deal_Contact__c>> entityMap = new Map<Id, List<Deal_Contact__c>>();

    for (Integer i = 0; i < newList.size(); i++) {
      opportunityMap.put(newList[i].Deal__c, null);

      if (newList[i].Is_Guarantor__c == true) {
        newList[i].Entity_Type__c = 'Guarantor';
      }

      if (
        newList[i].Contact__c != null &&
        newList[i].Account_Entity__c == null
      ) {
        if (!entityMap.containsKey(newList[i].Deal__c)) {
          entityMap.put(newList[i].Deal__c, new List<Deal_Contact__c>());
        }
        entityMap.get(newList[i].Deal__c).add(newList[i]);
      }
      if (
        String.isNotBlank(newList[i].Company_Name__c) &&
        newList[i].Business_Entity__c == null
      ) {
        nameSet.add(newList[i].Company_Name__c);
        if (newList[i].Operating_Agreement_Date__c != null) {
          dateEstablishedSet.add(newList[i].Operating_Agreement_Date__c);
        }
      }
    }
    opportunityMap = new Map<Id, Opportunity>(
      [
        SELECT Id, AccountId
        FROM Opportunity
        WHERE Id IN :opportunityMap.keySet()
      ]
    );
    Map<String, Business_Entity__c> businessEntityMap = new Map<String, Business_Entity__c>();
    for (Business_Entity__c be : [
      SELECT Id, Operating_Agreement_Date__c, Name
      FROM Business_Entity__c
      WHERE
        Name IN :nameSet
        AND Operating_Agreement_Date__c IN :dateEstablishedSet
    ]) {
      businessEntityMap.put(be.Name + '|' + be.Operating_Agreement_Date__c, be);
    }
    for (Opportunity c : [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE ID IN :entityMap.keySet()
    ]) {
      opportunityMap.put(c.Id, c);
      for (Deal_Contact__c entity : entityMap.get(c.Id)) {
        entity.Account_Entity__c = c.AccountId;
      }
    }
    List<Business_Entity__c> businessEntityInserts = new List<Business_Entity__c>();
    List<Deal_Contact__c> newEntityList = new List<Deal_Contact__c>();
    for (Integer i = 0; i < newList.size(); i++) {
      if (String.isNotBlank(newList[i].Company_Name__c)) {
        if (
          businessEntityMap.containsKey(
            newList[i].Company_Name__c +
            '|' +
            newList[i].Operating_Agreement_Date__c
          )
        ) {
          newList[i].Business_Entity__c = businessEntityMap.get(
              newList[i].Company_Name__c +
              '|' +
              newList[i].Operating_Agreement_Date__c
            )
            .Id;
        } else {
          Opportunity o = opportunityMap.get(newList[i].Deal__c);
          Business_Entity__c be = new Business_Entity__c(
            Account__c = o.AccountId,
            Name = newList[i].Company_Name__c
          );
          if (newList[i].Operating_Agreement_Date__c != null) {
            be.Operating_Agreement_Date__c = newList[i]
              .Operating_Agreement_Date__c;
          }
          if (String.isNotBlank(newList[i].Company_Jurisdiction__c)) {
            be.Company_Jurisdiction__c = newList[i].Company_Jurisdiction__c;
          }
          if (String.isNotBlank(newList[i].Company_Type__c)) {
            be.Entity_Type__c = newList[i].Company_Type__c;
          }
          if (String.isNotBlank(newList[i].Business_Tax_ID_EIN__c)) {
            be.Business_Tax_ID_EIN__c = newList[i].Business_Tax_ID_EIN__c;
          }
          businessEntityInserts.add(be);
        }
      }
    }
    if (businessEntityInserts.size() > 0) {
      insert businessEntityInserts;
      for (Business_Entity__c be : businessEntityInserts) {
        String u = be.Name + '|' + be.Operating_Agreement_Date__c;
        businessEntityMap.put(u, be);
      }
      for (Integer i = 0; i < newList.size(); i++) {
        if (
          String.isNotBlank(newList[i].Company_Name__c) &&
          newList[i].Contact__c == null
        ) {
          String u =
            newList[i].Company_Name__c +
            '|' +
            newList[i].Operating_Agreement_Date__c;

          if (businessEntityMap.containsKey(u)) {
            newList[i].Business_Entity__c = businessEntityMap.get(u).Id;
          }
        }
      }
    }

    Map<Id, List<Deal_Contact__c>> contactPrepopulateMap = new Map<Id, List<Deal_Contact__c>>();

    for (Deal_Contact__c entity : newList) {
      if (entity.Contact__c != null) {
        if (
          entity.Contact__c != null &&
          !contactPrepopulateMap.containsKey(entity.Contact__c)
        ) {
          contactPrepopulateMap.put(
            entity.Contact__c,
            new List<Deal_Contact__c>()
          );
        }

        contactPrepopulateMap.get(entity.Contact__c).add(entity);
      }

      if (
        String.isNotBlank(entity.Entity_Type__c) &&
        entity.Entity_Type__c.contains(';')
      ) {
        List<String> entityList = entity.Entity_Type__c.split(';');
        entity.Entity_Type__c = entityList[0];
        for (Integer i = 1; i < entityList.size(); i++) {
          Deal_Contact__c clonedEntity = entity.clone(
            false,
            false,
            false,
            false
          );
          clonedEntity.Entity_Type__c = entityList[i];
          newEntityList.add(clonedEntity);
        }
      }
    }

    for (Contact c : [
      SELECT
        Id,
        Sponsor_Tier__c,
        Experience__c,
        Liquidity__c,
        Experian__c,
        TransUnion__c,
        Equifax__c,
        Years_of_Experience__c,
        Net_Worth__c,
        Rental_Units_Owned__c,
        Cash_Equivalent__c,
        Cash_Position__c,
        Legal_Name__c
      FROM Contact
      WHERE Id IN :contactPrepopulateMap.keySet()
    ]) {
      for (Deal_Contact__c entity : contactPrepopulateMap.get(c.Id)) {
        entity.Sponsor_Tier__c = c.Sponsor_Tier__c;
        entity.Experience__c = c.Experience__c;
        entity.Liquidity__c = c.Liquidity__c;
        entity.Experian__c = c.Experian__c;
        entity.TransUnion__c = c.TransUnion__c;
        entity.Equifax__c = c.Equifax__c;
        entity.Years_of_Experience1__c = c.Years_of_Experience__c;
        entity.Cash_Position__c = c.Cash_Position__c;
        entity.Cash_Equivalent__c = c.Cash_Equivalent__c;
        entity.Rental_Units_Owned__c = c.Rental_Units_Owned__c;
        entity.Net_Worth__c = c.Net_Worth__c;
        entity.Legal_Name__c = c.Legal_Name__c;
      }
    }

    if (newEntityList.size() > 0) {
      insert newEntityList;
    }

    setUserBasedOnContact(newList);
  }

  public static void afterInsert(List<Deal_Contact__c> newList) {
    List<Loan_Fee__c> loanFees = new List<Loan_Fee__c>();
    List<Deal_Contact__c> dealContacts = [
      SELECT
        Id,
        Deal_Contact_Type__c,
        Account__c,
        Account__r.Account_Status__c,
        Vendor_Type__c,
        Deal__c,
        Entity_Type__c
      FROM Deal_Contact__c
      WHERE ID IN :newList
    ];
    Map<Id, Opportunity> ops = new Map<Id, Opportunity>();

    Set<Id> sponsorIds = new Set<Id>();

    for (Deal_Contact__c dc : dealContacts) {
      if (dc.Entity_Type__c == 'Sponsor') {
        sponsorIds.add(dc.Id);
      }

      if (
        dc.Deal_Contact_Type__c == 'Vendor' &&
        dc.Account__r.Account_Status__c == 'Active CoreVest Vendor' &&
        (dc.Vendor_Type__c == 'Cash Management' ||
        dc.Vendor_Type__c == 'Valuation' ||
        dc.Vendor_Type__c == 'Lender Legal Counsel' ||
        dc.Vendor_Type__c == 'Insurance Review' ||
        //    || dc.Vendor_Type__c=='Flood Check'
        dc.Vendor_Type__c == 'Architect' ||
        dc.Vendor_Type__c == 'Contractor' ||
        dc.Vendor_Type__c == 'Engineer' ||
        dc.Vendor_Type__c == 'Escrow Agent' ||
        dc.Vendor_Type__c == 'Insurance' ||
        dc.Vendor_Type__c == 'Lease/Purchase Review' ||
        dc.Vendor_Type__c == 'Rent Deposit Bank' ||
        dc.Vendor_Type__c == 'Servicer' ||
        dc.Vendor_Type__c == 'Tax Verification' ||
        dc.Vendor_Type__c == 'Title and Escrow' ||
        //    || dc.Vendor_Type__c=='Title and Escrow 2'
        dc.Vendor_Type__c == 'Title Company' ||
        dc.Vendor_Type__c == 'PCA & ESA' ||
        dc.Vendor_Type__c == 'Reserves')
      ) {
        loanFees.add(
          new Loan_Fee__c(
            Deal__c = dc.Deal__c,
            Vendor__c = dc.Account__c,
            Vendor_Type__c = dc.Vendor_Type__c,
            Deal_Contact__c = dc.Id
          )
        );
      }

      if (
        dc.Vendor_Type__c != null &&
        dc.Account__c != null &&
        (dc.Vendor_Type__c == 'Title and Escrow' ||
        dc.Vendor_Type__c == '3rd Party Title' ||
        dc.Vendor_Type__c == 'Lender Legal Counsel' ||
        dc.Vendor_Type__c == 'Insurance Review')
      ) {
        if (!ops.containsKey(dc.Deal__c)) {
          ops.put(dc.Deal__c, new Opportunity(Id = dc.Deal__c));
        }
        if (dc.Vendor_Type__c == 'Title and Escrow') {
          ops.get(dc.Deal__c).Title__c = dc.Account__c;
        } else if (dc.Vendor_Type__c == '3rd Party Title') {
          ops.get(dc.Deal__c).Third_Party_Title__c = dc.Account__c;
        } else if (dc.Vendor_Type__c == 'Lender Legal Counsel') {
          ops.get(dc.Deal__c).Legal_Counsel__c = dc.Account__c;
        } else if (dc.Vendor_Type__c == 'Insurance Review') {
          ops.get(dc.Deal__c).Insurance__c = dc.Account__c;
        }
      }
    }

    if (ops.values().size() > 0) {
      update ops.values();
    }

    if (!loanFees.isEmpty()) {
      insert loanFees;
    }

    // if (sponsorIds.size() > 0) {
    //   ChecklistHelper.createChecklistSectionSponsor(sponsorIds);
    // }
  }

  public static void afterUpdate(
    Map<Id, Deal_Contact__c> newMap,
    Map<Id, Deal_Contact__c> oldMap
  ) {
    List<Deal_Contact__c> newList = newMap.values();
    List<Deal_Contact__c> oldList = oldMap.values();
    Map<Id, Opportunity> ops = new Map<Id, Opportunity>();
    for (Deal_Contact__c entity : newList) {
      system.debug(entity);
      if (
        entity.Vendor_Type__c != null &&
        entity.Account__c != null &&
        (entity.Vendor_Type__c == 'Title and Escrow' ||
        entity.Vendor_Type__c == '3rd Party Title' ||
        entity.Vendor_Type__c == 'Lender Legal Counsel' ||
        entity.Vendor_Type__c == 'Insurance Review')
      ) {
        if (!ops.containsKey(entity.Deal__c)) {
          ops.put(entity.Deal__c, new Opportunity(Id = entity.Deal__c));
        }
        if (entity.Vendor_Type__c == 'Title and Escrow') {
          ops.get(entity.Deal__c).Title__c = entity.Account__c;
        } else if (entity.Vendor_Type__c == '3rd Party Title') {
          ops.get(entity.Deal__c).Third_Party_Title__c = entity.Account__c;
        } else if (entity.Vendor_Type__c == 'Lender Legal Counsel') {
          ops.get(entity.Deal__c).Legal_Counsel__c = entity.Account__c;
        } else if (entity.Vendor_Type__c == 'Insurance Review') {
          ops.get(entity.Deal__c).Insurance__c = entity.Account__c;
        }
      }

      system.debug('do we hit this?');
      system.debug(ops);
    }
    //for(Deal_Contact__c busentity : newList){
    //if (busentity.Entity_Type__c!=null && busentity.Entity_Type__c.contains('Borrower') && busentity.Business_Entity__c != null) {
    //ops.get(busentity.Deal__c).Borrower_Entity__c = busentity.Business_Entity__r.Id;
    //}
    //}

    if (ops.values().size() > 0) {
      update ops.values();
    }

    List<Contact> contactsUpdate = new List<Contact>();
    Map<Id, Set<Id>> dealToContactIdMap = new Map<Id, Set<Id>>();
    Map<Id, Contact> contactMap = new Map<Id, Contact>();
    for (Integer i = 0; i < newList.size(); i++) {
      if (!contactMap.containsKey(newList[i].Contact__c)) {
        contactMap.put(newList[i].Contact__c, new Contact());
      }
      if (!dealToContactIdMap.containsKey(newList[i].Deal__c)) {
        dealToContactIdMap.put(newList[i].Deal__c, new Set<Id>());
      }
      if (newList[i].Net_Worth__c != oldList[i].Net_Worth__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Net_Worth__c = newList[i]
          .Net_Worth__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (
        newList[i].Rental_Units_Owned__c != oldList[i].Rental_Units_Owned__c
      ) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Rental_Units_Owned__c = newList[i]
          .Rental_Units_Owned__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Cash_Position__c != oldList[i].Cash_Position__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Cash_Position__c = newList[i]
          .Cash_Position__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Cash_Equivalent__c != oldList[i].Cash_Equivalent__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Cash_Equivalent__c = newList[i]
          .Cash_Equivalent__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Sponsor_Tier__c != oldList[i].Sponsor_Tier__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Sponsor_Tier__c = newList[i]
          .Sponsor_Tier__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Experience__c != oldList[i].Experience__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Experience__c = newList[i]
          .Experience__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Liquidity__c != oldList[i].Liquidity__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Liquidity__c = newList[i]
          .Liquidity__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Experian__c != oldList[i].Experian__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Experian__c = newList[i]
          .Experian__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].TransUnion__c != oldList[i].TransUnion__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).TransUnion__c = newList[i]
          .TransUnion__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Equifax__c != oldList[i].Equifax__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Equifax__c = newList[i]
          .Equifax__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (
        newList[i].Years_of_Experience1__c != oldList[i].Years_of_Experience1__c
      ) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Years_of_Experience__c = newList[
            i
          ]
          .Years_of_Experience1__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
      if (newList[i].Legal_Name__c != oldList[i].Legal_Name__c) {
        contactMap.get(newList[i].Contact__c).Id = newList[i].Contact__c;
        contactMap.get(newList[i].Contact__c).Legal_Name__c = newList[i]
          .Legal_Name__c;
        dealToContactIdMap.get(newList[i].Deal__c).add(newList[i].Contact__c);
      }
    }

    for (Contact c : contactMap.values()) {
      if (c.Id != null) {
        contactsupdate.add(c);
      }
    }

    if (contactsUpdate.size() > 0) {
      update contactsUpdate;

      Map<Id, Contact> contactMapExtra = new Map<Id, Contact>(contactsUpdate);
      // for(Contact : )

      List<Deal_Contact__c> dcToUpdate = new List<Deal_Contact__c>();
      for (Deal_Contact__c dealContact : [
        SELECT
          Id,
          Net_Worth__c,
          Rental_Units_Owned__c,
          Cash_Position__c,
          Cash_Equivalent__c,
          Sponsor_Tier__c,
          Experience__c,
          Liquidity__c,
          Experian__c,
          TransUnion__c,
          Equifax__c,
          Years_of_Experience1__c,
          Legal_Name__c,
          Contact__c,
          Deal__c
        FROM Deal_Contact__c
        WHERE
          Contact__c IN :contactMapExtra.keySet()
          AND Deal__c IN :dealToContactIdMap.keySet()
      ]) {
        Contact c = contactMapExtra.get(dealContact.Contact__C);

        if (c != null) {
          Boolean addToList = false;

          if (
            c.Net_Worth__c != null &&
            dealContact.Net_Worth__c != c.Net_Worth__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Net_Worth__c = c.Net_Worth__c;
            addToList = true;
          }

          if (
            c.Rental_Units_Owned__c != null &&
            dealContact.Rental_Units_Owned__c != c.Rental_Units_Owned__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Rental_Units_Owned__c = c.Rental_Units_Owned__c;
            addToList = true;
          }

          if (
            c.Cash_Position__c != null &&
            dealContact.Cash_Position__c != c.Cash_Position__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Cash_Position__c = c.Cash_Position__c;
            addToList = true;
          }

          if (
            c.Cash_Equivalent__c != null &&
            dealContact.Cash_Equivalent__c != c.Cash_Equivalent__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Cash_Equivalent__c = c.Cash_Equivalent__c;
            addToList = true;
          }

          if (
            c.Sponsor_Tier__c != null &&
            dealContact.Sponsor_Tier__c != c.Sponsor_Tier__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Sponsor_Tier__c = c.Sponsor_Tier__c;
            addToList = true;
          }

          if (
            c.Experience__c != null &&
            dealContact.Experience__c != c.Experience__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Experience__c = c.Experience__c;
            addToList = true;
          }

          if (
            c.Liquidity__c != null &&
            dealContact.Liquidity__c != c.Liquidity__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Liquidity__c = c.Liquidity__c;
            addToList = true;
          }

          if (
            c.Experian__c != null &&
            dealContact.Experian__c != c.Experian__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Experian__c = c.Experian__c;
            addToList = true;
          }

          if (
            c.TransUnion__c != null &&
            dealContact.TransUnion__c != c.TransUnion__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.TransUnion__c = c.TransUnion__c;
            addToList = true;
          }

          if (
            c.Equifax__c != null &&
            dealContact.Equifax__c != c.Equifax__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Equifax__c = c.Equifax__c;
            addToList = true;
          }

          if (
            c.Years_of_Experience__c != null &&
            dealContact.Years_of_Experience1__c != c.Years_of_Experience__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Years_of_Experience1__c = c.Years_of_Experience__c;
            addToList = true;
          }

          if (
            c.Legal_Name__c != null &&
            dealContact.Legal_Name__c != c.Legal_Name__c &&
            dealToContactIdMap.containsKey(dealContact.Deal__c)
          ) {
            dealContact.Legal_Name__c = c.Legal_Name__c;
            addToList = true;
          }

          if (addToList) {
            dcToUpdate.add(dealContact);
          }
        }
      }

      if (dcToUpdate.size() > 0) {
        update dcToUpdate;
      }
    }

    //New changes to update Loan Fee when deal contact is updated.
    updateLoanFeeRecord(newMap, oldMap);
  }

  public static void afterDelete(List<Deal_Contact__c> oldList) {
    Map<Id, Opportunity> ops = new Map<Id, Opportunity>();
    for (Deal_Contact__c dc : oldList) {
      if (
        dc.Vendor_Type__c != null &&
        dc.Account__c != null &&
        (dc.Vendor_Type__c == 'Title and Escrow' ||
        dc.Vendor_Type__c == '3rd Party Title' ||
        dc.Vendor_Type__c == 'Lender Legal Counsel' ||
        dc.Vendor_Type__c == 'Insurance Review')
      ) {
        if (!ops.containsKey(dc.Deal__c)) {
          ops.put(dc.Deal__c, new Opportunity(Id = dc.Deal__c));
        }
        if (
          dc.Vendor_Type__c == 'Title and Escrow' &&
          dc.Account__c == dc.Deal__r.Title__c
        ) {
          ops.get(dc.Deal__c).Title__c = null;
        } else if (
          dc.Vendor_Type__c == '3rd Party Title' &&
          dc.Account__c == dc.Deal__r.Third_Party_Title__c
        ) {
          ops.get(dc.Deal__c).Third_Party_Title__c = null;
        } else if (
          dc.Vendor_Type__c == 'Lender Legal Counsel' &&
          dc.Account__c == dc.Deal__r.Legal_Counsel__c
        ) {
          ops.get(dc.Deal__c).Legal_Counsel__c = null;
        } else if (
          dc.Vendor_Type__c == 'Insurance Review' &&
          dc.Account__c == dc.Deal__r.Insurance__c
        ) {
          ops.get(dc.Deal__c).Insurance__c = null;
        }
      }
    }

    if (ops.values().size() > 0) {
      update ops.values();
    }
  }

  public static void updateLoanFeeRecord(
    Map<Id, Deal_Contact__c> newMap,
    Map<Id, Deal_Contact__c> oldMap
  ) {
    List<Loan_Fee__c> loanFeesUpdate = new List<Loan_Fee__c>();
    List<Loan_Fee__c> loanFeesInsert = new List<Loan_Fee__c>();
    Map<String, String> dealContactFeesMap = new Map<String, String>();
    for (Loan_Fee__c l : [
      SELECT Id, Deal_Contact__c
      FROM Loan_Fee__c
      WHERE Deal_Contact__c IN :newMap.keySet()
    ]) {
      dealContactFeesMap.put(l.Deal_Contact__c, l.Id);
    }

    List<Deal_Contact__c> dealContacts = [
      SELECT
        Id,
        Deal_Contact_Type__c,
        Account__c,
        Account__r.Account_Status__c,
        Vendor_Type__c,
        Deal__c
      FROM Deal_Contact__c
      WHERE ID IN :newMap.keyset()
    ];
    for (Deal_Contact__c dc : dealContacts) {
      if (
        (dc.Vendor_Type__c != oldMap.get(dc.Id).Vendor_Type__c ||
        dc.Account__c != oldMap.get(dc.Id).Account__c) &&
        //	if(	(System.Label.LoanFeesInsertTriggerSwitch.equalsIgnoreCase('False') || (System.Label.LoanFeesInsertTriggerSwitch.equalsIgnoreCase('True') && (dc.Vendor_Type__c != oldMap.get(dc.Id).Vendor_Type__c || dc.Account__c != oldMap.get(dc.Id).Account__c)))
        dc.Deal_Contact_Type__c == 'Vendor' &&
        dc.Account__c != null &&
        dc.Account__r.Account_Status__c == 'Active CoreVest Vendor' &&
        (dc.Vendor_Type__c == 'Cash Management' ||
        // || dc.Vendor_Type__c=='3rd Party Title'
        dc.Vendor_Type__c == 'Valuation' ||
        //   || dc.Vendor_Type__c=='Flood Check'
        dc.Vendor_Type__c == 'Lender Legal Counsel' ||
        dc.Vendor_Type__c == 'Insurance Review' ||
        dc.Vendor_Type__c == 'Architect' ||
        dc.Vendor_Type__c == 'Contractor' ||
        dc.Vendor_Type__c == 'Engineer' ||
        dc.Vendor_Type__c == 'Escrow Agent' ||
        dc.Vendor_Type__c == 'Insurance' ||
        dc.Vendor_Type__c == 'Lease/Purchase Review' ||
        dc.Vendor_Type__c == 'Rent Deposit Bank' ||
        dc.Vendor_Type__c == 'Servicer' ||
        dc.Vendor_Type__c == 'Tax Verification' ||
        dc.Vendor_Type__c == 'Title and Escrow' ||
        dc.Vendor_Type__c == 'PCA & ESA' ||
        // || dc.Vendor_Type__c=='Title and Escrow 2'
        // || dc.Vendor_Type__c=='Title Company'
        dc.Vendor_Type__c == 'Reserves')
      ) {
        if (dealContactFeesMap.containsKey(dc.Id)) {
          loanFeesUpdate.add(
            new Loan_Fee__c(
              Id = dealContactFeesMap.get(dc.Id),
              Vendor__c = dc.Account__c,
              Vendor_Type__c = dc.Vendor_Type__c
            )
          );
        } else {
          loanFeesInsert.add(
            new Loan_Fee__c(
              Deal__c = dc.Deal__c,
              Vendor__c = dc.Account__c,
              Vendor_Type__c = dc.Vendor_Type__c,
              Deal_Contact__c = dc.Id
            )
          );
        }
      }
    }

    if (!loanFeesUpdate.isEmpty()) {
      update loanFeesUpdate;
    }
    if (!loanFeesInsert.isEmpty()) {
      insert loanFeesInsert;
    }
  }

  public static void setUserBasedOnContact(List<Deal_Contact__c> newList) {
    Set<Id> contactIds = new Set<Id>();
    for (Deal_Contact__c dc : newList) {
      if (dc.Contact__c != null) {
        contactIds.add(dc.Contact__c);
      }
    }
    Map<Id, Id> contactToUserMap = new Map<Id, Id>();
    for (User u : [
      SELECT Id, ContactId
      FROM User
      WHERE ContactId IN :contactIds
    ]) {
      contactToUserMap.put(u.ContactId, u.Id);
    }
    for (Deal_Contact__c dc : newList) {
      dc.User__c = contactToUserMap.get(dc.Contact__c);
    }
  }
}