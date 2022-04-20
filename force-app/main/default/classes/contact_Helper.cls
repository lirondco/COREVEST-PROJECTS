public class contact_Helper {
  public static Map<String, Schema.SObjectField> FIELD_MAP = Schema.SObjectType.Contact.fields.getMap();

  /**
   * @name beforeInsert
   * @description
   * @param
   **/
  public static void beforeInsert(List<Contact> newList) {
    for (Integer i = 0; i < newList.size(); i++) {
      if (String.isNotBlank(newList[i].Phone)) {
        newList[i].Phone = util.formatPhone(newList[i].Phone);
      }

      if (String.isNotBlank(newList[i].MobilePhone)) {
        newList[i].MobilePhone = util.formatPhone(newList[i].MobilePhone);
      }

      if (String.isNotBlank(newList[i].HomePhone)) {
        newList[i].HomePhone = util.formatPhone(newList[i].HomePhone);
      }

      if (String.isBlank(newList[i].Phone)) {
        if (String.isNotBlank(newList[i].MobilePhone)) {
          newList[i].Phone = newList[i].MobilePhone;
        } else if (String.isNotBlank(newList[i].HomePhone)) {
          newList[i].Phone = newList[i].HomePhone;
        }
      }
    }
  }

  /**
   * @name afterInsert
   * @description
   * @param
   **/
  //public static void afterInsert(List<Contact> newList){
  //    for ( Integer i=0;i<newList.size();i++ ){

  //    }
  //}

  /**
   * @name beforeUpdate
   * @description
   * @param
   **/
  public static void beforeUpdate(
    List<Contact> newList,
    List<Contact> oldList
  ) {
    for (Integer i = 0; i < newList.size(); i++) {
      if (newList[i].Phone != oldList[i].Phone) {
        if (String.isNotBlank(newList[i].Phone)) {
          newList[i].Phone = util.formatPhone(newList[i].Phone);
        }
      }

      if (newList[i].MobilePhone != oldList[i].MobilePhone) {
        if (String.isNotBlank(newList[i].MobilePhone)) {
          newList[i].MobilePhone = util.formatPhone(newList[i].MobilePhone);
        }

        if (String.isBlank(newList[i].Phone)) {
          newList[i].Phone = newList[i].MobilePhone;
        }
      }

      if (newList[i].HomePhone != oldList[i].HomePhone) {
        if (String.isNotBlank(newList[i].HomePhone)) {
          newList[i].HomePhone = util.formatPhone(newList[i].HomePhone);
        }
      }
    }
  }

  public static void afterUpdate(
    Map<Id, Contact> oldMap,
    List<Contact> newList
  ) {
    //Related account list
    list<id> myAcc = new List<id>();
    List<Contact> terminatedContacts = new List<Contact>();

    for (Contact con : newList) {
      if (con.In_Litigation__c == true) {
        myAcc.add(con.AccountId);
      }

      if (
        con.Status__c == 'Business Relationship Terminated' &&
        con.Status__c != oldMap.get(con.Id).Status__c
      ) {
        terminatedContacts.add(con);
      }
    }
    if (myAcc.size() > 0) {
      list<account> myAccs = new List<account>();
      list<account> accToUpdate = [
        SELECT Id, Do_Not_Lend__c
        FROM Account
        WHERE ID IN :myAcc
      ];
      for (account acc : accToUpdate) {
        acc.In_Litigation__c = true;
      }
      if (accToUpdate.size() > 0) {
        update accToUpdate;
      }
    }

    List<ContentDocumentLink> notes = new List<ContentDocumentLink>();

    if (terminatedContacts.size() > 0) {
      Map<Id, Contact> contactsMap = new Map<Id,Contact>([
        SELECT
          Id,
          Name,
          (
            SELECT Id, Title, CreatedDate, CreatedById,ContentDocumentId,ContentSize,FileExtension,FileType,LinkedEntityId,TextPreview
            FROM AttachedContentNotes
            WHERE
              CreatedDate > :DateTime.Now().addMinutes(-30)
              AND CreatedById = :UserInfo.getUserId()
            ORDER BY CreatedDate
          )
        FROM Contact
        WHERE Id IN :terminatedContacts
      ]);

      for (Contact c : terminatedContacts) {
        Contact fromMap = contactsMap.get(c.Id);
        if (
          fromMap.AttachedContentNotes != null &&
          fromMap.AttachedContentNotes.size() > 0
        ) {
          AttachedContentNote note = fromMap.AttachedContentNotes[0];
          ContentDocumentLink cdl = new ContentDocumentLink();
          cdl.LinkedEntityId = c.AccountId;
          cdl.ContentDocumentId = note.ContentDocumentId;
          cdl.Visibility = 'AllUsers';
          cdl.ShareType = 'I';
          notes.add(cdl);
        } else {
          c.addError('Please add a Note on the Notes & Files tab of this contact to explain why we have ended our business relationship with them.');
        }
      }
      if(notes.size() > 0) {
        Database.upsert(notes, false);
      }
    }
  }

  public static void isAfter(set<Id> parentIdsSet) {
    List<Account> accountListToUpdate = new List<Account>();
    List<Account> accountList = new List<Account>(
      [
        SELECT id, Name, Number_of_Contacts__c, (SELECT id, Name FROM Contacts)
        FROM Account
        WHERE id IN :parentIdsSet
      ]
    );
    for (Account acc : accountList) {
      List<Contact> contactList = acc.Contacts;
      acc.Number_of_Contacts__c = acc.Contacts.size();
      accountListToUpdate.add(acc);
    }
    system.debug('accountListToUpdate:::' + accountListToUpdate);
    try {
      if (accountListToUpdate != null && accountListToUpdate.size() > 0) {
        update accountListToUpdate;
      }
    } catch (System.Exception e) {
      system.debug('Exception::::::' + e.getLineNumber());
    }
  }

  /**
   * @name afterUpdate
   * @description
   * @param
   **/
  //public static void afterUpdate(List<Contact> newList, List<Contact> oldList){

  //   Map<Id, Id> contactOwnerMap = new Map<Id, Id>();

  //   for ( Integer i=0;i<newList.size();i++ ){

  //       if(newList[i].OwnerId != oldList[i].OwnerId){
  //           contactOwnerMap.put(newList[i].Id, newList[i].OwnerId);
  //       }
  //   }
  //   if(contactOwnerMap.values().size() > 0){
  //       updateLeadOwners(contactOwnerMap);
  //   }
  //}

  /**
   * @name beforeDelete
   * @description
   * @param
   **/
  //public static void beforeDelete(List<Contact> newList){
  //    for ( Integer i=0;i<newList.size();i++ ){

  //    }
  //}

  /**
   * @name afterDelete
   * @description
   * @param
   **/
  //public static void afterDelete(List<Contact> newList, List<Contact> oldList){
  //}

  /**
   * @name afterUndelete
   * @description
   * @param
   **/
  //public static void afterUndelete(List<Contact> oldList){
  //    for ( Integer i=0;i<oldList.size();i++ ){

  //    }
  //}

  //public static void updateLeadOwners(Map<Id, Id> contactOwnerMap){
  //    List<Lead> leads = new List<Lead>();
  //    for(Lead l : [SELECT Id, ConvertedContactId, OwnerId FROM Lead where ConvertedContactId IN : contactOwnerMap.keySet()]){
  //        l.ownerId = contactOwnerMap.get(l.ConvertedContactId);
  //       leads.add(l);
  //   }

  //   upsert leads;
  //}
}