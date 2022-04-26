public class lead_Helper {
  public static Boolean isRunOnce = true;

  public static Map<String, Schema.SObjectField> FIELD_MAP = Schema.SObjectType.Lead.fields.getMap();

  public static Map<String, RecordType> RECORDTYPE_MAP = util.compileRecordTypeMap(
    'Lead'
  );

  /**
   * @name beforeInsert
   * @description
   * @param
   **/
  public static void beforeInsert(List<Lead> newList) {
    Map<String, Lead> leadMap = new Map<String, Lead>();
    for (Lead l : newList) {
      if (l.Email != null && l.Run_Dupe_Check__c) {
        leadMap.put(l.Email, l);
      }

      if (String.isNotBlank(l.Phone)) {
        l.Phone = util.formatPhone(l.phone);
      }

      if (String.isNotBlank(l.MobilePhone)) {
        l.MobilePhone = util.formatPhone(l.MobilePhone);
      }

      if (
        l.Company == 'None' ||
        l.Company == 'na' ||
        l.Company == 'n/a' ||
        l.Company == 'not provided' ||
        l.Company == 'self' ||
        l.Company == 'no company' ||
        l.Company == 'company name' ||
        l.Company == 'no name' ||
        l.Company == 'investor' ||
        l.Company == 'unknown' ||
        l.Company == 'tbd' ||
        l.Company == '*' ||
        l.Company == 'to be determined' ||
        l.Company == 'investor' ||
        l.Company == null
      ) {
        l.Company = l.FirstName + ' ' + l.LastName;
      }

      if (l.Status == 'Unqualified' || l.Status == 'Unresponsive') {
        l.OwnerId = '0050a00000LMH2UAAX';
      }

      if (l.Applicant_Type__c == 'Borrower') {
        l.RecordTypeId = RECORDTYPE_MAP.get('Borrower_Lead').Id;
      } else if (l.Applicant_Type__c == 'Broker') {
        l.RecordTypeId = RECORDTYPE_MAP.get('Broker_Lead').Id;
      } else if (l.Applicant_Type__c == 'Lender') {
        l.RecordTypeId = RECORDTYPE_MAP.get('Lender_Lead').Id;
      }
    }

    if (leadMap.size() > 0) {
      for (Lead l : [
        SELECT Id, Email, IsConverted, OwnerId, Owner.IsActive
        FROM Lead
        WHERE Email IN :leadMap.keySet()
      ]) {
        if (!l.IsConverted && l.OwnerId != '0050a00000LMH2UAAX') {
          if (l.Owner.IsActive) {
            leadMap.get(l.Email).OwnerId = l.OwnerId;
            leadMap.get(l.Email).Is_Duplicate__c = true;
            leadMap.get(l.Email).Janati_RR__Round_Robin__c = 'No';
          }
        }

        leadMap.get(l.Email).Existing_Lead__c = l.Id;
      }

      for (Contact c : [
        SELECT Id, Email, OwnerId, Owner.IsActive, Owner.Full_Name__c
        FROM Contact
        WHERE Email IN :leadMap.keySet()
      ]) {
        if (c.Owner.IsActive && c.owner.Full_Name__c != 'House Account') {
          leadMap.get(c.Email).OwnerId = c.OwnerId;
          leadMap.get(c.Email).Is_Duplicate__c = true;
          leadMap.get(c.Email).Janati_RR__Round_Robin__c = 'No';
        }

        leadMap.get(c.Email).Existing_Contact__c = c.Id;
      }
    }

    // Map<String, Lead_Settings__c> settings = new Map<String, Lead_Settings__c>();
    // for (Integer i = 0; i < newList.size(); i++) {
    //   if (
    //     newList[i].Janati_RR__Round_Robin__c != 'Yes' &&
    //     !newList[i].Is_Hot_Lead__c &&
    //     newList[i].Introduction_Source__c != null &&
    //     String.isNotBlank(newList[i].Introduction_Source__c)
    //   ) {
    //     String leadSource = newList[i].Introduction_Source__c;
    //     if (leadSource == 'Website Contact Form') {
    //       leadSource = 'Website Application';
    //     }
    //     if (!settings.containsKey(leadSource)) {
    //       Lead_Settings__c setting = Lead_Settings__c.getInstance(leadSource);
    //       if (setting != null) {
    //         settings.put(leadSource, setting);
    //       }
    //     }
    //     if (settings.containsKey(leadSource)) {
    //       Lead_Settings__c setting = settings.get(leadSource);
    //       newList[i].Round_Robin_Value__c = setting.Round_Robin_Value__c;

    //       if (setting.Round_Robin_Value__c == setting.Round_Robin_Max__c) {
    //         setting.Round_Robin_Value__c = 1;
    //       } else {
    //         setting.Round_Robin_Value__c = setting.Round_Robin_Value__c + 1;
    //       }

    //       settings.put(leadSource, setting);
    //     }
    //   }

      //if(newList[i].Existing_Lead__c != null || newList[i].Existing_Contact__c != null){
      //    newList[i].Is_Hot_Lead__c = true;
      //}
      //if(newList[i].Introduction_Source__c = null newList[i].CTM_Ring_Time__c != null && String.isNotBlank(newList[i].CTM_Ring_Time__c)){
      //    newList[i].Introduction_Source__c = 'CAF Hotline';
      //}
    // }

    // if (settings.values().size() > 0) {
    //   update settings.values();
    // }
  }

  /**
   * @name afterInsert
   * @description
   * @param
   **/
  public static void afterInsert(List<Lead> newList) {
    List<Id> leadIdsForPortal = new List<Id>();
    for (Lead l : newList) {
      if (
        // l.Introduction_Source__c == 'Website' &&
        // l.Introduction_Subsource__c == 'Main Application'
        l.Introduction_Source__c == 'Pre-Prod' &&
        l.Introduction_Subsource__c == 'Pre-Prod Main Application'
      ) {
        leadIdsForPortal.add(l.Id);
      }
    }

    Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings');
    if (
      leadIdsForPortal.size() > 0 && settings.Enable_Portal_User_Creation__c
    ) {
      system.enqueueJob(new CreatePortalUserQueueable(leadIdsForPortal));
    }
  }

  /**
   * @name beforeUpdate
   * @description
   * @param
   **/
  public static void beforeUpdate(List<Lead> newList, List<Lead> oldList) {
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
      }

      if (newList[i].Status != oldList[i].Status) {
        if (
          (newList[i].Status == 'Unqualified' ||
          newList[i].Status == 'Unresponsive') &&
          newList[i].OwnerId != '0050a00000LMH2UAAX'
        ) {
          newList[i].OwnerId = '0050a00000LMH2UAAX';
        }
      }

      if (
        newList[i].Company == 'None' ||
        newList[i].Company == 'na' ||
        newList[i].Company == 'n/a' ||
        newList[i].Company == 'not provided' ||
        newList[i].Company == 'self' ||
        newList[i].Company == 'no company' ||
        newList[i].Company == 'company name' ||
        newList[i].Company == 'no name' ||
        newList[i].Company == 'investor' ||
        newList[i].Company == 'unknown' ||
        newList[i].Company == 'tbd' ||
        newList[i].Company == '*' ||
        newList[i].Company == 'to be determined' ||
        newList[i].Company == 'investor' ||
        newList[i].Company == null
      ) {
        newList[i].Company = newList[i].FirstName + ' ' + newList[i].LastName;
      }

      if (newList[i].Applicant_Type__c != oldList[i].Applicant_Type__c) {
        if (newList[i].Applicant_Type__c == 'Borrower') {
          newList[i].RecordTypeId = RECORDTYPE_MAP.get('Borrower_Lead').Id;
        } else if (newList[i].Applicant_Type__c == 'Broker') {
          newList[i].RecordTypeId = RECORDTYPE_MAP.get('Broker_Lead').Id;
        } else if (newList[i].Applicant_Type__c == 'Lender') {
          newList[i].RecordTypeId = RECORDTYPE_MAP.get('Lender_Lead').Id;
        }
      }

      if (newList[i].Status != oldList[i].Status) {
        newList[i].Status_Last_Changed__c = System.today();
      }
    }
  }
  public static void CreateSource(List<Lead> LeadList) {
    system.debug('LeadList::::' + LeadList);

    List<Source__c> SourceList = new List<Source__c>();
    List<Master_Source__c> msList = new List<Master_Source__c>();
    List<string> FnameList = new List<string>();
    List<string> LnameList = new List<string>();
    List<string> EmailList = new List<string>();
    List<string> PhoneList = new List<string>();
    for (Lead l : LeadList) {
      FnameList.add(l.FirstName);
      LnameList.add(l.LastName);
      EmailList.add(l.Email);
      PhoneList.add(l.Phone);
      Source__c sobj = new Source__c();
      sobj.lead__c = l.id;
      system.debug('===sobj.lead__c===' + sobj.lead__c);
      sobj.Lead_Name__c = l.FirstName + ' ' + l.LastName;
      sobj.Lead_First_Name__c = l.FirstName;
      sobj.Lead_Last_Name__c = l.LastName;
      sobj.Email__c = l.Email;
      system.debug('===sobj.Email__c===' + sobj.Email__c);
      sobj.Phone__c = l.Phone;
      sobj.Mobile__c = l.MobilePhone;
      sobj.Company__c = l.Company;
      sobj.Primary_Loan_Product__c = l.Loan_Product_s__c;
      sobj.Primary_Source__c = l.Introduction_Source__c;
      sobj.Primary_Subsource__c = l.Introduction_Subsource__c;
      sobj.Account_Converted_Into__c = l.Account_Converted_Into__c;
      sobj.Contact_Converted_Into__c = l.Contact_Converted_Into__c;
      sobj.Deal_Converted_Into__c = l.Deal_Converted_Into__c;
      sobj.Lead_Status__c = l.Status;
      sobj.Conference_Year__c = l.Conference_Year__c;
      sobj.Loan_Product_s_c__c = l.Loan_Product_s__c;
      sobj.Requested_Loan_Size__c = l.Requested_Loan_Size__c;
      sobj.first_Touch_checkbox__c = l.first_Touch_checkbox__c;
      sobj.last_Touch_checkbox__c = l.last_Touch_checkbox__c;
      sobj.True_source__c = l.True_source__c;
      sobj.lead_id__c = l.id;
      sobj.utm_Campaign_Name__c = l.utm_Campaign_Name__c;
      sobj.utm_Campaign_Content__c = l.utm_Campaign_Content__c;
      sobj.utm_Campaign_Medium__c = l.utm_Campaign_Medium__c;
      sobj.utm_Campaign_Source__c = l.utm_Campaign_Source__c;
      sobj.utm_Campaign_Term__c = l.utm_Campaign_Term__c;

      SourceList.add(sobj);
    }
    /*CIP2334.RS.4/11/22.Begin
    system.debug('sobj:::SourceList::::' + SourceList);
    list<Master_Source__c> masterlist = [
      SELECT First_Name__c, Last_Name__c, Mobile__c, Email__c
      FROM Master_Source__c
      WHERE
        (First_Name__c IN :FnameList
        AND Last_Name__c IN :LnameList
        AND Mobile__c IN :PhoneList)
        OR (First_Name__c IN :FnameList
        AND Last_Name__c IN :LnameList
        AND Email__c IN :EmailList)
    ];

    system.debug('===masterlist===' + masterlist);
    if (masterlist != null && masterlist.size() > 0) {
      system.debug('=== if masterlist===' + masterlist);
      for (Master_Source__c ml : masterlist) {
        for (Source__c sl : SourceList) {
          if (
            (sl.Lead_First_Name__c == ml.First_Name__c &&
            sl.Lead_Last_Name__c == ml.Last_Name__c &&
            sl.Mobile__c == ml.Mobile__c) ||
            (sl.Lead_First_Name__c == ml.First_Name__c &&
            sl.Lead_Last_Name__c == ml.Last_Name__c &&
            sl.Email__c == ml.Email__c)
          ) {
            sl.Master_Source__c = ml.id;
          }
        }
      }
    }
    system.debug('===  SourceList===' + SourceList);
    for (Source__c sl : SourceList) {
      if (sl.Master_Source__c == null) {
        Master_Source__c msobj = new Master_Source__c();
        msobj.First_Name__c = sl.Lead_First_Name__c;
        msobj.Last_Name__c = sl.Lead_Last_Name__c;
        msobj.Mobile__c = sl.Mobile__c;
        msobj.Email__c = sl.Email__c;
        msList.add(msobj);
      }
    }
    system.debug('===msList===' + msList);
    if (msList != null && msList.size() > 0) {
      insert msList;
      system.debug('=== if msList===' + msList);
      for (Master_Source__c ml : msList) {
        for (Source__c sl : SourceList) {
          if (
            (sl.Lead_First_Name__c == ml.First_Name__c &&
            sl.Lead_Last_Name__c == ml.Last_Name__c &&
            sl.Mobile__c == ml.Mobile__c) ||
            (sl.Lead_First_Name__c == ml.First_Name__c &&
            sl.Lead_Last_Name__c == ml.Last_Name__c &&
            sl.Email__c == ml.Email__c)
          ) {
            sl.Master_Source__c = ml.id;
          }
        }
      }
    } CIP2334.RS.4/11/22.End*/
    system.debug('===SourceList===' + SourceList);
    if (SourceList != null && SourceList.size() > 0) {
      insert SourceList;
    }
  }
  public static void updateSource(List<Lead> LeadList) {
    if (lead_Helper.isRunOnce || Test.isRunningTest()) {
      lead_Helper.isRunOnce = false;

      list<string> listId = new List<string>();
      system.debug('LeadList===update source' + LeadList);
      for (lead lobj : LeadList) {
        listId.add(lobj.id);
      }
      List<Source__c> SourceList = [
        SELECT
          id,
          CreatedDate,
          lead__c,
          Lead_Name__c,
          Lead_First_Name__c,
          Lead_Last_Name__c,
          Email__c,
          Phone__c,
          Mobile__c,
          IsDeleted__c,
          Company__c,
          Primary_Loan_Product__c,
          Account_Converted_Into__c,
          Primary_Source__c,
          lead_id__c,
          Contact_Converted_Into__c,
          Deal_Converted_Into__c,
          Lead_Status__c,
          Loan_Product_s_c__c,
          Requested_Loan_Size__c,
          Last_Modified_Datetime__c,
          True_source__c,
          first_Touch_checkbox__c,
          last_Touch_checkbox__c,
          IsConvertedLead__c
        FROM Source__c
        WHERE lead__c IN :listId
        ORDER BY CreatedDate ASC
      ];
      map<Lead, list<Source__c>> lsmap = new Map<lead, list<Source__c>>();
      for (lead lobj : LeadList) {
        List<Source__c> SList = new List<Source__c>();
        for (Source__c s : SourceList) {
          if (S.lead__c == lobj.Id) {
            SList.add(s);
          }
        }
        lsmap.put(lobj, SList);
      }
      system.debug('lsmap==' + lsmap);
      system.debug('SourceList==' + SourceList);

      for (Lead lobj : lsmap.keyset()) {
        List<Source__c> solist = lsmap.get(lobj);
        integer size = solist.size();
        system.debug('size==' + size);
        system.debug('solist::::' + solist);

        for (Source__c s : solist) {
          if (size >= 2) {
            system.debug('size==###');
            s.first_Touch_checkbox__c = false;
            s.last_Touch_checkbox__c = false;
          }
          if (s.lead__c == s.lead_id__c) {
            if (lobj.id == s.lead__c) {
              s.Lead_Name__c = lobj.FirstName + ' ' + lobj.LastName;
              s.Company__c = lobj.Company;
              s.Primary_Loan_Product__c = lobj.Loan_Product_s__c;
              s.Primary_Subsource__c = lobj.Introduction_Subsource__c;
              s.Account_Converted_Into__c = lobj.Account_Converted_Into__c;
              s.Contact_Converted_Into__c = lobj.Contact_Converted_Into__c;
              s.Deal_Converted_Into__c = lobj.Deal_Converted_Into__c;
              s.Lead_Status__c = lobj.Status;
              s.Loan_Product_s_c__c = lobj.Loan_Product_s__c;
              s.Requested_Loan_Size__c = lobj.Requested_Loan_Size__c;
              s.lead_id__c = lobj.id;
              s.Conference_Year__c = lobj.Conference_Year__c;
              //s.first_Touch_checkbox__c=lobj.first_Touch_checkbox__c;
              //s.last_Touch_checkbox__c=lobj.last_Touch_checkbox__c;
              s.True_source__c = lobj.True_source__c;
            }
            system.debug('updateSource::s::::' + s);
          } else {
            if (s.IsDeleted__c == true) {
              //sobj.IsDeleted__c=true;
              //s.last_Touch_checkbox__c=false;
              //s.first_Touch_checkbox__c=false;
              s.True_source__c = false;
            } else {
              s.IsDeleted__c = true;
            }
            system.debug('else=== source');
          }
        }

        if (size >= 2) {
          system.debug('size==###');
          solist[0].first_Touch_checkbox__c = true;
          solist[size - 1].last_Touch_checkbox__c = true;
        }

        system.debug('solist::after::' + solist);
      }

      List<Source__c> ls = new List<Source__c>();
      for (List<Source__c> grouping : lsmap.values())
        ls.addAll(grouping);
      //insert records;
      system.debug('ls==' + ls);
      update ls;
      system.debug('ls=after=' + ls);
    }
  }
  // public static void UpdateLeadTrueSource(List<Lead> LeadList) {
  //   system.debug('==UpdateLeadTrueSource::LeadList==' + LeadList);

  //   List<Source__c> SourceList = new List<Source__c>();
  //   Source__c sobj = new Source__c();
  //   List<string> FnameList = new List<string>();
  //   List<string> LnameList = new List<string>();
  //   List<string> EmailList = new List<string>();
  //   List<string> PhoneList = new List<string>();
  //   List<Lead> NewLeadList = new List<Lead>();
  //   Map<id, lead> finalOldleadmap = new Map<id, lead>();
  //   Map<id, lead> finalNewleadmap = new Map<id, lead>();
  //   for (Lead l : LeadList) {
  //     FnameList.add(l.FirstName);
  //     LnameList.add(l.LastName);
  //     EmailList.add(l.Email);
  //     PhoneList.add(l.Phone);
  //   }
  //   list<Lead> leaddatalist = [
  //     SELECT id, name, FirstName, LastName, Email, Phone
  //     FROM Lead
  //     WHERE
  //       (FirstName IN :FnameList
  //       AND LastName IN :LnameList
  //       AND Email IN :EmailList)
  //       OR (FirstName IN :FnameList
  //       AND LastName IN :LnameList
  //       AND Phone IN :PhoneList)
  //   ];
  //   system.debug('==leaddatalist===' + leaddatalist);
  //   system.debug('===SourceList===' + SourceList);
  //   system.debug('===LeadList===' + LeadList);
  //   if (
  //     LeadList != null &&
  //     LeadList.size() > 0 &&
  //     leaddatalist != null &&
  //     leaddatalist.size() > 0
  //   ) {
  //     for (Lead l : LeadList) {
  //       for (lead ldata : leaddatalist) {
  //         if (
  //           (l.FirstName == ldata.FirstName &&
  //           l.LastName == ldata.LastName &&
  //           l.Phone == ldata.Phone) ||
  //           (l.FirstName == ldata.FirstName &&
  //           l.LastName == ldata.LastName &&
  //           l.Email == ldata.Email)
  //         ) {
  //           l.True_source__c = true;
  //           finalOldleadmap.put(ldata.id, ldata);
  //           l.Last_touch_Checkbox__c = true;
  //         }
  //       }
  //     }

  //     system.debug('leadlist==' + LeadList);
  //     system.debug('===finalOldleadmap===' + finalOldleadmap);
  //     for (Lead l : finalOldleadmap.values()) {
  //       l.True_source__c = false;
  //       l.Last_touch_Checkbox__c = false;
  //     }
  //     system.debug('===UpdateLead===' + finalOldleadmap.values());
  //     update finalOldleadmap.values();
  //   } else {
  //     for (Lead l : LeadList) {
  //       system.debug('inside if leadlist===');
  //       l.first_Touch_checkbox__c = true;
  //       //change on 13-01-2021 if lead is new then last and first touch both true
  //       l.Last_touch_Checkbox__c = true;
  //     }
  //   }
  // }
  public static void sourceUpdateonleadConvert(List<lead> LeadIdConvertList) {
    if (lead_Helper.isRunOnce || Test.isRunningTest()) {
      lead_Helper.isRunOnce = false;
      Map<id, String> Emailmap = new Map<id, String>();
      list<string> listId = new List<string>();
      Map<id, contact> contactmap = new Map<id, contact>();
      list<id> userId = new List<id>();
      List<user> user = new List<user>();
      system.debug('===LeadIdConvertList===' + LeadIdConvertList);
      for (lead lobj : LeadIdConvertList) {
        // lobj.True_source__c = true;
        system.debug('lobj.ConvertedAccountId==' + lobj.ConvertedAccountId);
        system.debug('lobj.ConvertedContactId==' + lobj.ConvertedContactId);
        lobj.Account_Converted_Into__c = lobj.ConvertedAccountId;
        lobj.Contact_Converted_Into__c = lobj.ConvertedContactId;
        listId.add(lobj.id);
      }
      List<Source__c> SourceList = [
        SELECT
          id,
          lead__c,
          LastModifiedBy.id,
          lead_id__c,
          IsDeleted__c,
          IsConvertedLead__c,
          Contact_Converted_Into__c,
          Account_Converted_Into__c,
          Last_Modified_Datetime__c,
          first_Touch_checkbox__c, //CIP2334.RS.4/11/22.
          last_touch_Checkbox__c //CIP2334.RS.4/11/22.
        FROM Source__c
        WHERE lead__c IN :listId
      ];
      system.debug('--SourceList=====' + SourceList);

      for (lead lobj : LeadIdConvertList) {
        for (Source__c sr : SourceList) {
          if (sr.lead_id__c == sr.lead__c && sr.IsDeleted__c == false) {
            sr.IsConvertedLead__c = true;
            sr.Contact_Converted_Into__c = lobj.Contact_Converted_Into__c;
            sr.Account_Converted_Into__c = lobj.Account_Converted_Into__c;
            userId.add(lobj.OwnerId);
            system.debug('userId==' + userId);
          } else {
            sr.Contact_Converted_Into__c = lobj.Contact_Converted_Into__c;
            sr.Account_Converted_Into__c = lobj.Account_Converted_Into__c;
          }
        }
      }

      if (SourceList != null && SourceList.size() > 0) {
        update SourceList;
      }

    //   List<string> FnameList = new List<string>();
    //   List<string> LnameList = new List<string>();
    //   List<string> EmailList = new List<string>();
    //   List<string> PhoneList = new List<string>();
    //   List<string> IDList = new List<string>();
    //   system.debug('=== Update::LeadIdConvertList===' + LeadIdConvertList);

    //   for (Lead l : LeadIdConvertList) {
    //     FnameList.add(l.FirstName);
    //     LnameList.add(l.LastName);
    //     EmailList.add(l.Email);
    //     PhoneList.add(l.Phone);
    //     IDList.add(l.id);
    //   }
    //   system.debug('=== FnameList===' + FnameList);
    //   system.debug('=== LnameList===' + LnameList);
    //   system.debug('=== EmailList===' + EmailList);
    //   system.debug('=== PhoneList===' + PhoneList);
    //   system.debug('=== IDList===' + IDList);
    //   list<Lead> leaddatalist = [
    //     SELECT id, name, FirstName, LastName, Email, True_source__c, Phone
    //     FROM Lead
    //     WHERE
    //       ((FirstName IN :FnameList
    //       AND LastName IN :LnameList
    //       AND Email IN :EmailList)
    //       OR (FirstName IN :FnameList
    //       AND LastName IN :LnameList
    //       AND Phone IN :PhoneList))
    //       AND id NOT IN :IDList
    //   ];
    //   system.debug('=== Update::leaddatalist===' + leaddatalist);

    //   if (leaddatalist != null && leaddatalist.size() > 0) {
    //     for (Lead l : leaddatalist) {
    //       l.True_source__c = false;
    //     }
    //     update leaddatalist;
    //   }
    //   system.debug('===  IF Update::leaddatalist===' + leaddatalist);
    }
  }

  @future
  public static void updateleadonMarge(String leadString) {
    if (lead_Helper.isRunOnce || Test.isRunningTest()) {
      lead_Helper.isRunOnce = false;
      Map<id, String> Emailmap = new Map<id, String>();
      list<lead> oldlead = (List<lead>) JSON.deserialize(
        leadString,
        List<lead>.class
      );

      Map<id, lead> leadMap = new Map<id, lead>();
      if (oldlead != null && oldlead.size() > 0) {
        for (lead lobj : oldlead) {
          //lead templ = leadMap.get(lobj.MasterRecordId);
          if (leadMap.get(lobj.MasterRecordId) != null) {
            lead l = leadMap.get(lobj.MasterRecordId);
            if (lobj.CreatedDate > l.CreatedDate) {
              leadMap.put(lobj.MasterRecordId, lobj);
            }
          } else {
            leadMap.put(lobj.MasterRecordId, lobj);
          }
        }

        system.debug('leadMap==' + leadMap);
        list<lead> lList = [
          SELECT
            id,
            Introduction_Source__c,
            Introduction_Subsource__c,
            Owner.Email
          FROM lead
          WHERE id IN :leadMap.keyset()
        ];
        list<lead> lfinallist = new List<lead>();
        system.debug('lList####' + lList);
        for (lead l : lList) {
          lead lobj = leadMap.get(l.id);
          if (l.id == lobj.MasterRecordId) {
            Emailmap.put(l.id, l.Owner.Email);
            system.debug('inside if####');
            l.Introduction_Source__c = lobj.Introduction_Source__c;
            l.Introduction_Subsource__c = lobj.Introduction_Subsource__c;
            lfinallist.add(l);
          }
        }
        if (!lfinallist.isEmpty()) {
          system.debug('lfinallist==' + lfinallist);
          update lfinallist;
        }
      }
    }
  }
}