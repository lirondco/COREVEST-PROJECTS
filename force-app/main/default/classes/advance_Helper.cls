public class advance_Helper {
  public static Map<String, Schema.SObjectField> FIELD_MAP = Schema.SObjectType.Advance__c.fields.getMap();
  public static Boolean isAdmin = false;
  static {
    for (PermissionSetAssignment psa : [
      SELECT PermissionSet.PermissionsModifyAllData
      FROM PermissionSetAssignment
      WHERE AssigneeId = :UserInfo.getUserId()
    ]) {
      isAdmin |= psa.PermissionSet.PermissionsModifyAllData;
    }
  }
  public static Map<String, Id> RECORDTYPE_MAP = compileRecordTypeMap();
  public static Map<String, Id> compileRecordTypeMap() {
    Map<String, Id> recordmap = new Map<String, Id>();
    for (RecordType r : [
      SELECT Id, Name
      FROM RecordType
      WHERE sobjecttype = 'Advance__c'
    ]) {
      recordmap.put(r.Name, r.Id);
    }
    return recordmap;
  }
  /**
   * @name beforeInsert
   * @description
   * @param
   **/

  public static void beforeInsert(List<Advance__c> newList) {
    Map<Id, List<Advance__c>> advanceMap = new Map<Id, List<Advance__c>>();
    Map<Id, List<Advance__c>> interestReserveMap = new Map<Id, List<Advance__c>>();
      System.Debug('RS999 - newList :' +newList);
      System.Debug('RS999 - newList :' +newList);
    for (Integer i = 0; i < newList.size(); i++) {
        System.Debug('RS999 - newList[i].RecordTypeId :' +newList[i].RecordTypeId);
      if (newList[i].RecordTypeId != RECORDTYPE_MAP.get('Interest Reserve')) {
        if (!advanceMap.containsKey(newList[i].Deal__c)) {
          advanceMap.put(newList[i].Deal__c, new List<Advance__c>());
        }
        advanceMap.get(newList[i].Deal__c).add(newList[i]);

        // if (
        //   newList[i].Property_Record_Type__c == 'Renovation' ||
        //   newList[i].Property_Record_Type__c == 'Single Asset w/ Renovation'
        // ) {
        //   newList[i].RecordTypeId = RECORDTYPE_MAP.get('Renovation');
        // } else if (
        //   newList[i].Property_Record_Type__c == 'Ground Up Construction'
        // ) {
        //   newList[i].RecordTypeID = RECORDTYPE_MAP.get(
        //     'Ground Up Construction'
        //   );
        // } else {
        //   newList[i].RecordTypeID = RECORDTYPE_MAP.get('Non Renovation');
        // }
        // } else if (
        //   newList[i].RecordTypeId == RECORDTYPE_MAP.get('Interest Reserve')
        // ) {
        //   if (!interestReserveMap.containsKey(newList[i].Deal__c)) {
        //     interestReserveMap.put(newList[i].Deal__c, new List<Advance__c>());
        //   }
        //   interestReserveMap.get(newList[i].Deal__c).add(newList[i]);
      }
    }

    for (
      Opportunity o : [
        SELECT
          Id,
          Aggregate_Funding__c,
          Aggregate_Payoffs__c,
          Aggregate_Value_PreAdvance__c,
          Aggregate_Advance_Fee_PreAdvance__c,
          Outstanding_Facility_Amount__c,
          Outstanding_Loan_Amount_PreAdvance__c,
          (
            SELECT Id, Name, Advance_Num__c
            FROM Advances__r
            // WHERE Advance_Num__c != NULL
            // ORDER BY Advance_Num__c DESC
            // LIMIT 1
          )
        FROM Opportunity
        WHERE Id IN :advanceMap.keySet()
      ]
    ) {
      for (Advance__c adv : advanceMap.get(o.Id)) {
        adv.Aggregate_Funding__c = o.Aggregate_Funding__c;
        adv.Aggregate_Payoffs__c = o.Aggregate_Payoffs__c;
        adv.Aggregate_Advance_Fee_PreAdvance__c = o.Aggregate_Advance_Fee_PreAdvance__c;
        adv.Aggregate_Value_PreAdvance__c = o.Aggregate_Value_PreAdvance__c;
        adv.Outstanding_Facility_Amount__c = o.Outstanding_Facility_Amount__c;

        adv.Outstanding_Loan_Amount_PreAdvance__c = o.Outstanding_Loan_Amount_PreAdvance__c;

        if (String.isBlank(adv.Name)) {
          adv.Advance_Num__c = o.Advances__r.size() + 1;
          adv.Name = 'Pending-' + String.valueOf(adv.Advance_Num__c);
          // if (o.Advances__r.size() > 0) {
          //   //adv.Advance_Num__c = o.Advances__r[0].Advance_Num__c + 1;
          //   adv.Name = 'Pending-' + String.valueOf(adv.Advance_Num__c);
          // } else {
          //   adv.Name = 'Pending-1';
          //   adv.Advance_Num__c = 1;
          // }
        }
      }
    }

    for (Opportunity o : [
      SELECT
        id,
        Aggregate_Funding__c,
        Aggregate_Payoffs__c,
        Aggregate_Value_PreAdvance__c,
        Aggregate_Advance_Fee_PreAdvance__c,
        Outstanding_Facility_Amount__c,
        Outstanding_Loan_Amount_PreAdvance__c,
        (
          SELECT id
          FROM Advances__r
          WHERE RecordTypeID = :RECORDTYPE_MAP.get('Interest Reserve')
        )
      FROM Opportunity
      WHERE id IN :interestReserveMap.keySet()
    ]) {
      for (Advance__c adv : interestReserveMap.get(o.Id)) {
        adv.Aggregate_Funding__c = o.Aggregate_Funding__c;
        adv.Aggregate_Payoffs__c = o.Aggregate_Payoffs__c;
        adv.Aggregate_Advance_Fee_PreAdvance__c = o.Aggregate_Advance_Fee_PreAdvance__c;
        adv.Aggregate_Value_PreAdvance__c = o.Aggregate_Value_PreAdvance__c;
        adv.Outstanding_Facility_Amount__c = o.Outstanding_Facility_Amount__c;

        adv.Outstanding_Loan_Amount_PreAdvance__c = o.Outstanding_Loan_Amount_PreAdvance__c;

        if (String.isBlank(adv.Name)) {
          if (o.Advances__r.size() > 0) {
            adv.Name = 'IR-' + o.Advances__r.size() + 1; //String.valueOf(o.Advances__r[0].Advance_Number__c + 1);
          } else {
            adv.name = 'IR-1';
          }
        }
       SYSTEM.DEBUG('RS999 - adv' + adv);
      }
    }

  }

  /**
   * @name afterInsert
   * @description
   * @param
   **/
  public static void afterInsert(List<Advance__c> newList) {
    List<Opportunity> interestReserveAdv = new List<Opportunity>();
    list<id> cloneList = new List<id>();

    List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>();
    for (Integer i = 0; i < newList.size(); i++) {
      OpportunityLineItem oli = new OpportunityLineItem();
      if (newList[i].RecordTypeId != RECORDTYPE_MAP.get('Interest Reserve')) {
        if (newList[i].Deal_RecordType__c == 'LOC_Loan') {
          oli.OpportunityId = newList[i].Deal__c;
          oli.Advance__c = newList[i].Id;
          oli.PricebookEntryId = '01u0a00000K75EAAAZ';
          // oli.Product2Id = '01t0a000005zHebAAE';
          oli.Quantity = 1;
          oli.UnitPrice = newList[i].Approved_Advance_Amount_Total__c;
          oli.ServiceDate = System.today();
          olisToInsert.add(oli);
        } else if (
          newList[i].Deal_RecordType__c == 'Single_Asset_Bridge_Loan'
        ) {
          oli.OpportunityId = newList[i].Deal__c;
          oli.Advance__c = newList[i].Id;
          oli.PricebookEntryId = '01u0a00000K75EFAAZ';
          // oli.Product2Id = '01t0a000005zHegAAE';
          oli.Quantity = 1;
          oli.UnitPrice = util.fixNull(
            newList[i].Approved_Advance_Amount_Total__c
          );
          oli.ServiceDate = System.today();
          olisToInsert.add(oli);
        } else if (
          newList[i].Deal_RecordType__c == 'Acquired_Bridge_Loan_Active' ||
          newList[i].Deal_RecordType__c == 'Acquired_Bridge_Loan'
        ) {
          oli.OpportunityId = newList[i].Deal__c;
          oli.Advance__c = newList[i].Id;
          oli.PricebookEntryId = '01u5b00000L8lMiAAJ';
          // oli.Product2Id = '01t0a000005zHegAAE';
          oli.Quantity = 1;
          oli.UnitPrice = util.fixNull(
            newList[i].Approved_Advance_Amount_Total__c
          );
          oli.ServiceDate = System.today();
          olisToInsert.add(oli);
        }
      }
    }

    if (olisToInsert.size() > 0) {
      try {
        insert olisToInsert;
      } catch (DmlException err) {
        System.debug(err);
      }
    }
  }

  /**
   * @name beforeUpdate
   * @description
   * @param
   **/
  public static void beforeUpdate(
    List<Advance__c> newList,
    List<Advance__c> oldList
  ) {
    List<Advance__c> advList = new List<Advance__c>();
    Set<Id> advanceIds = new Set<Id>();
    Set<Id> advanceIdsUncomplete = new Set<Id>();
    Map<Id, List<Advance__c>> advanceMap = new Map<Id, List<Advance__c>>();

    Map<Id, Advance__c> advMap = new Map<Id, Advance__c>();
    List<Id> advancesForCompletion = new List<Id>();

    for (Integer i = 0; i < newList.size(); i++) {
      if (
        newList[i].Status__c != oldList[i].Status__c &&
        newList[i].Status__c == 'Completed' &&
        newList[i].RecordTypeId != RECORDTYPE_MAP.get('Construction Advance')
      ) {
        advancesForCompletion.add(newList[i].Id);
        // validateCompletion(newList[i]);
      }
      if (newList[i].RecordTypeId != RECORDTYPE_MAP.get('Interest Reserve')) {
        if (
          newList[i].Status__c != oldList[i].Status__c &&
          newList[i].Status__c == 'Completed'
        ) {
          newList[i].Name = newList[i].Name.replace('Pending-', '');
          advanceIds.add(newList[i].Id);
          if (!advanceMap.containsKey(newList[i].Deal__c)) {
            advanceMap.put(newList[i].Deal__c, new List<Advance__c>());
          }
          advanceMap.get(newList[i].Deal__c).add(newList[i]);
        }

        if (
          newList[i].Status__c != oldList[i].Status__c &&
          oldList[i].Status__c == 'Completed'
        ) {
          advanceIdsUncomplete.add(newList[i].Id);
        }

        if (
          newList[i].Closing_Funds_Checklist__c !=
          oldList[i].Closing_Funds_Checklist__c
        ) {
          newList[i].Closing_Funds_Checked_By__c = newList[i]
              .Closing_Funds_Checklist__c
            ? UserInfo.getUserId()
            : null;

          newList[i].Closing_Funds_Checklist_Date__c = newList[i]
              .Closing_Funds_Checklist__c
            ? system.now()
            : null;
        }

        if (newList[i].Manager_Approved__c != oldList[i].Manager_Approved__c) {
          newList[i].Manager_Approved_By__c = newList[i].Manager_Approved__c
            ? UserInfo.getUserId()
            : null;
          newList[i].Manager_Approval_Date__c = newList[i].Manager_Approved__c
            ? system.now()
            : null;
        }

        if (
          newList[i].Evidence_of_Insurance_Approved__c !=
          oldList[i].Evidence_of_Insurance_Approved__c
        ) {
          newList[i].Evidence_of_Insurance_Approved_By__c = newList[i]
              .Evidence_of_Insurance_Approved__c
            ? UserInfo.getUserId()
            : null;
          newList[i].Evidence_of_Insurance_Approval_Date__c = newList[i]
              .Evidence_of_Insurance_Approved__c
            ? system.now()
            : null;
        }

        if (
          newList[i].Flood_Certificate_Approved__c !=
          oldList[i].Flood_Certificate_Approved__c
        ) {
          newList[i].Flood_Certificate_Approved_By__c = newList[i]
              .Flood_Certificate_Approved__c
            ? UserInfo.getUserId()
            : null;
          newList[i].Flood_Certificate_Approval_Date__c = newList[i]
              .Flood_Certificate_Approved__c
            ? system.now()
            : null;
        }

        //List<Property__c> properties = new List<Property__c>();
        // Map<Id, Property_Advance__c> propertyMap = new Map<Id, Property_Advance__c>();
        //for(Property_Advance__c p : [SELECT Id, Property__c, Advance__c, Approved_Advance_Amount__c FROM Property_Advance__c WHERE Advance__c IN : advanceIds]){
        //    propertyMap.put(p.Property__c, p);
        //}

        //for(Property__c p : [SELECT Id, Status__c, First_Funding_Date__c, Funding_Date__c, Approved_Advance_Amount__c, Approved_Advance_Amount_Remaining__c FROM Property__c WHERE Id IN : propertyMap.keySet()]){
        //    if(p.Approved_Advance_Amount_Remaining__c <= propertyMap.get(p.Id).Approved_Advance_Amount__c){
        //       p.Status__c = 'Active';
        //    }else{
        //        p.Status__c = 'In Process';
        //    }
        //    p.Advance__c = propertyMap.get(p.Id).Advance__c;
        //    if(p.First_Funding_Date__c != null){
        //        p.Funding_Date__c = advMap.get(p.Advance__c).Wire_Date__c;
        //    }else{
        //        p.First_Funding_Date__c = advMap.get(p.Advance__c).Wire_Date__c;
        //        p.Funding_Date__c = advMap.get(p.Advance__c).Wire_Date__c;
        //    }

        //    properties.add(p);
        //}

        //Map<Id, Id> propertyMap2 = new Map<Id, Id>();
        //for(Property_Advance__c p : [SELECT Id, Property__c, Advance__c FROM Property_Advance__c WHERE Advance__c IN : advanceIdsUncomplete]){
        //    propertyMap2.put(p.Property__c, p.Advance__c);
        //}

        //for(Property__c p : [SELECT Id, Status__c, Funding_Date__c, First_Funding_Date__c FROM Property__c WHERE Id IN : propertyMap2.keySet()]){
        //    p.Status__c = 'Pending';
        //    p.Funding_Date__c = null;
        //    if(p.Funding_Date__c != null){
        //        p.Funding_Date__c = null;
        //    }else{
        //        p.First_Funding_Date__c = null;
        //    }

        //    properties.add(p);
        //}

        //if(properties.size() > 0){
        //    update properties;
        //}
      }
    }

    List<Advance__c> advsToValidate = isCreditLine(advancesForCompletion);

    if (advsToValidate.size() > 0) {
      Map<Id, Boolean> completionMap = validateCompletions(advsToValidate);

      for (Integer i = 0; i < newList.size(); i++) {
        if (
          !isAdmin &&
          newList[i].Status__c != oldList[i].Status__c &&
          newList[i].Status__c == 'Completed' &&
          completionMap.containsKey(newList[i].Id) &&
          completionMap.get(newList[i].Id) != true
        ) {
          newList[i]
            .addError(
              'Cannot change this Advance Record\'s status to complete. Please make sure that everything has been uploaded and reviewed first in the Clear To Fund tab.'
            );
        }
      }
    }

    for (Opportunity o : [
      SELECT
        Id,
        Aggregate_Funding__c,
        Aggregate_Payoffs__c,
        Aggregate_Value_PreAdvance__c,
        Aggregate_Advance_Fee_PreAdvance__c,
        Outstanding_Facility_Amount__c,
        Outstanding_Loan_Amount_PreAdvance__c
      FROM Opportunity
      WHERE Id IN :advanceMap.keySet()
    ]) {
      for (Advance__c adv : advanceMap.get(o.Id)) {
        adv.Aggregate_Funding__c = o.Aggregate_Funding__c;
        adv.Aggregate_Payoffs__c = o.Aggregate_Payoffs__c;
        adv.Outstanding_Facility_Amount__c = o.Outstanding_Facility_Amount__c;
      }
    }
  }

  /**
   * @name afterUpdate
   * @description
   * @param
   **/
  public static void afterUpdate(
    List<Advance__c> newList,
    List<Advance__c> oldList
  ) {
    Set<Id> completedAdvanceIds = new Set<Id>();
    Set<Id> uncompletedAdvanceIds = new Set<Id>();
    Set<Id> updateRollups = new Set<Id>();
    Set<Id> updateBridgeProduct = new Set<Id>();

    Set<Id> opIds = new Set<Id>();
    Set<Id> advanceWireIds = new Set<Id>();

    Set<Id> advIds = new Set<Id>();

    list<id> myAdvanceList = new List<id>();

    //CIP-2149 - Raj Sirivolu. 1/20/2022.Begin.
    Set<id> advanceProjUpdatesIds = new Set<id>();
    //CIP-2149 - Raj Sirivolu. 1/20/2022.End.
    for (Integer i = 0; i < newList.size(); i++) {
      if (newList[i].RecordTypeId != RECORDTYPE_MAP.get('Interest Reserve')) {
        if (
          newList[i].Status__c != oldList[i].Status__c &&
          newList[i].Status__c == 'Completed'
        ) {
          completedAdvanceIds.add(newList[i].Id);
          opIds.add(newList[i].Deal__c);
          if (
            newList[i].Lender__c ==
            'CoreVest American Finance Lender LLC, a Delaware limited liability company'
          ) {
            myAdvanceList.add(newList[i].id);
          }
        }

        if (
          oldList[i].Wire_Date__c != newList[i].Wire_Date__c &&
          newList[i].Wire_Date__c != null
        ) {
          updateBridgeProduct.add(newList[i].Id);
        }

        if (
          oldList[i].Approved_Advance_Amount_Total__c !=
          newList[i].Approved_Advance_Amount_Total__c
        ) {
          updateBridgeProduct.add(newList[i].Id);
        }

        if (
          newList[i].Status__c != oldLIst[i].Status__c &&
          oldList[i].Status__c == 'Completed'
        ) {
          uncompletedAdvanceIds.add(newList[i].Id);
        }

        if (
          newList[i].Commission_Trigger__c !=
          oldList[i].Commission_Trigger__c &&
          newList[i].Commission_Trigger__c == true
        ) {
          myAdvanceList.add(newList[i].id);
        }

        if (
          newList[i].Advance_Fee_Adjustment__c !=
          oldList[i].Advance_Fee_Adjustment__c ||
          newList[i].BPO_Appraisal_Fee_Adjustment__c !=
          oldList[i].BPO_Appraisal_Fee_Adjustment__c ||
          newList[i].Origination_Fee_Adjustment__c !=
          oldList[i].Origination_Fee_Adjustment__c ||
          newList[i].BlackSquare_Fee_Adjustment__c !=
          oldList[i].BlackSquare_Fee_Adjustment__c ||
          //newList[i].Daily_Interest_Rate_Adjustment__c != oldList[i].Daily_Interest_Rate_Adjustment__c ||
          newList[i].Doc_Prep_Fee_Adjustment__c !=
          oldList[i].Doc_Prep_Fee_Adjustment__c
        ) {
          advanceWireIds.add(newList[i].Id);
        }

        if (newList[i].Wire_Date__c != oldList[i].Wire_Date__c) {
          updateRollups.add(newList[i].Id);
        }

        //CIP-2149 - Raj Sirivolu. 1/20/2022. Begin.
        if (
          newList[i].RecordTypeId ==
          RECORDTYPE_MAP.get('Non Renovation Initial') ||
          newList[i].RecordTypeId == RECORDTYPE_MAP.get('Renovation Initial')
        ) {
          if (
            (newList[i].Target_Advance_Date__c !=
            oldList[i].Target_Advance_Date__c &&
            newList[i].Target_Advance_Date__c != null) ||
            (newList[i].Underwriter__c != oldList[i].Underwriter__c &&
            newList[i].Target_Advance_Date__c != null)
          ) {
            advanceProjUpdatesIds.add(newList[i].id);
          }
        }
        //CIP-2149 - Raj Sirivolu. 1/20/2022. End.
      }

      //system.debug(wires);

      //List<Property__c> properties = new List<Property__c>();
      //Map<Id, Id> propertyMap = new Map<Id, Id>();
      //for(Property_Advance__c p : [SELECT Id, Property__c, Advance__c FROM Property_Advance__c WHERE Advance__c IN : advanceIds]){
      //    propertyMap.put(p.Property__c, p.Advance__c);
      //}

      //for(Property__c p : [SELECT Id, Status__c FROM Property__c WHERE Id IN : propertyMap.keySet()]){
      //    p.Status__c = 'Active';
      //    p.Advance__c = propertyMap.get(p.Id);
      //    properties.add(p);
      //}

      //if(properties.size() > 0){
      //    update properties;
      //}

      // if (
      //   newList[i].status__c ==
      //   'Completed' /*&& newList[i].Advance_and_Origination_Fee_Subtotal__c > 0*/ &&
      //   newList[i].status__c != oldList[i].status__c
      // ) {
      //   myAdvanceList.add(newList[i].id);
      // }
    }

    List<Wire__c> wires = new List<Wire__c>();
    for (Advance__c adv : [
      SELECT
        Id,
        Advance_Fee_Adjustment__c,
        BPO_Appraisal_Fee_Adjustment__c,
        Doc_Prep_Fee_Adjustment__c,
        BlackSquare_Fee_Adjustment__c,
        Origination_Fee_Adjustment__c,
        Daily_Interest_Rate_Adjustment__c,
        (
          SELECT id, wire_number__c
          FROM wires__r
          ORDER BY wire_number__c ASC, createddate ASC
          LIMIT 1
        )
      FROM Advance__c
      WHERE Id IN :advanceWireIds
    ]) {
      if (adv.Wires__r != null && adv.Wires__r.size() > 0) {
        Wire__c w = new Wire__c(Id = adv.Wires__r[0].Id);
        w.Advance_Fee_Adjustment__c = util.fixNull(
          adv.Advance_Fee_Adjustment__c
        );
        w.BPO_Appraisal_Fee_Adjustment__c = util.fixNull(
          adv.BPO_Appraisal_Fee_Adjustment__c
        );
        w.Doc_Prep_Fee_Adjustment__c = util.fixNull(
          adv.Doc_Prep_Fee_Adjustment__c
        );
        w.Origination_Fee_Adjustment__c = util.fixNull(
          adv.Origination_Fee_Adjustment__c
        );
        w.BlackSquare_Fee_Adjustment__c = util.fixNull(
          adv.BlackSquare_Fee_Adjustment__c
        );
        //w.Daily_Interest_Rate_Adjustment__c = util.fixNull(adv.Daily_Interest_Rate_Adjustment__c);

        wires.add(w);
      }
    }

    List<Advance__c> pendingUpdates = new List<Advance__c>();
    for (Opportunity op : [
      SELECT
        Id,
        Aggregate_Funding__c,
        Aggregate_Payoffs__c,
        Aggregate_Value_PreAdvance__c,
        Aggregate_Advance_Fee_PreAdvance__c,
        Outstanding_Facility_Amount__c,
        Outstanding_Loan_Amount_PreAdvance__c,
        (SELECT Id FROM Advances__r WHERE Status__c = 'Pending')
      FROM Opportunity
      WHERE Id IN :opIds
    ]) {
      if (op.Advances__r != null && op.Advances__r.size() > 0) {
        for (Advance__c adv : op.Advances__r) {
          adv.Aggregate_Funding__c = op.Aggregate_Funding__c;
          adv.Aggregate_Payoffs__c = op.Aggregate_Payoffs__c;
          adv.Aggregate_Advance_Fee_PreAdvance__c = op.Aggregate_Advance_Fee_PreAdvance__c;
          adv.Aggregate_Value_PreAdvance__c = op.Aggregate_Value_PreAdvance__c;
          adv.Outstanding_Facility_Amount__c = op.Outstanding_Facility_Amount__c;
          adv.Outstanding_Loan_Amount_PreAdvance__c = op.Outstanding_Loan_Amount_PreAdvance__c;

          pendingUpdates.add(adv);
        }
      }
    }

    if (updateBridgeProduct.size() > 0) {
      updateOppLineItems(updateBridgeProduct);
    }

    List<Property__c> properties = new List<Property__c>();
    Map<Id, Property_Advance__c> propertyMap = new Map<Id, Property_Advance__c>();
    Map<Id, Id> propertyMap2 = new Map<Id, Id>();
    for (
      Property_Advance__c pAdv : [
        SELECT
          Id,
          Property__c,
          Advance__c,
          Advance__r.Target_Advance_Date__c, //CIP-2149 - Raj Sirivolu. 1/20/2022.
          Advance__r.Underwriter__c, //CIP-2149 - Raj Sirivolu. 1/20/2022.
          Approved_Advance_Amount_Calc__c,
          Advance__r.Wire_Date__c,
          Property__r.Status__c,
          Property__r.First_Funding_Date__c,
          Property__r.Funding_Date__c,
          Property__r.Approved_Advance_Amount__c,
          Property__r.Approved_Advance_Amount_Remaining__c
        FROM Property_Advance__c
        WHERE
          Advance__c IN :completedAdvanceIds
          OR Advance__c IN :uncompletedAdvanceIds
          OR Advance__c IN :advanceProjUpdatesIds //CIP-2149 - Raj Sirivolu. 1/20/2022.
      ]
    ) {
      //propertyMap.put(p.Property__c, p);

      Property__c property = new Property__c(Id = pAdv.Property__c);

      if (completedAdvanceIds.contains(pAdv.Advance__c)) {
        //
        // if(pAdv.Property__r.Approved_Advance_Amount_Remaining__c <= pAdv.Approved_Advance_Amount_Calc__c){
        //    property.Status__c = 'Active';
        // }else{
        //     property.Status__c = 'In Process';
        // }
        property.Status__c = 'Active';
        // property.Advance__c = pAdv.Advance__c;
        if (pAdv.Property__r.First_Funding_Date__c != null) {
          property.Funding_Date__c = pAdv.Advance__r.Wire_Date__c;
        } else {
          property.First_Funding_Date__c = pAdv.Advance__r.Wire_Date__c;
          property.Funding_Date__c = pAdv.Advance__r.Wire_Date__c;
          property.Advance__c = pAdv.Advance__c;
        }
      } else if (uncompletedAdvanceIds.contains(pAdv.Advance__c)) {
        property.Status__c = 'Pending';
        //property.Funding_Date__c = null;
        if (property.Funding_Date__c != null) {
          property.Funding_Date__c = null;
        } else {
          property.First_Funding_Date__c = null;
        }
      }
      //CIP-2149 - Raj Sirivolu. 1/20/2022. Begin.
      if (advanceProjUpdatesIds.contains(pAdv.Advance__c)) {
        if (pAdv.Advance__r.Target_Advance_Date__c != null) {
          property.Requested_Funding_Date__c = pAdv.Advance__r.Target_Advance_Date__c;
        }
        if (pAdv.Advance__r.Underwriter__c != null) {
          property.Underwriter__c = pAdv.Advance__r.Underwriter__c;
        }
      }
      //CIP-2149 - Raj Sirivolu. 1/20/2022.End.

      properties.add(property);
    }

    if (wires.size() > 0) {
      update wires;
    }

    //this is for completed advances

    if (properties.size() > 0) {
      update properties;
    }

    if (pendingUpdates.size() > 0) {
      update pendingUpdates;
    }

    if (
      uncompletedAdvanceIds.size() > 0 ||
      completedAdvanceIds.size() > 0 ||
      updateRollups.size() > 0
    ) {
      update [
        SELECT id, Property__r.Status__c
        FROM Property_Advance__c
        WHERE
          Advance__c IN :uncompletedAdvanceIds
          OR Advance__c IN :completedAdvanceIds
          OR Advance__c IN :updateRollups
      ];
    }

    if (myAdvanceList.size() > 0) {
      system.debug('advance list size' + myAdvanceList.size());
      list<advance__c> myAdv = [
        SELECT
          Advance_and_Origination_Fee_Subtotal__c,
          Initial_Disbursement_Total__c,
          Deal__r.Internal_Referral__r.id,
          Deal__r.Internal_Referral__r.isActive,
          Deal__r.Internal_Referral_Fee__c,
          Deal__r.Internal_Referral__c,
          Deal__r.Commission_Type__c,
          Deal__r.Type,
          Deal__r.Account.Borrowed_on_Term_Loans__c,
          Deal__r.OwnerId,
          Deal__r.id,
          Loan_Type__c,
          Deal__r.CAF_YSP__c,
          Deal__c,
          Approved_Advance_Amount_Max_Total__c,
          Approved_Advance_Amount_Total__c,
          Deal__r.Calculated_Origination_Fee__c,
          Deal__r.Amount,
          Deal__r.Account.Borrowed_on_Bridge_Loans__c,
          Deal__r.CAF_Upfront_Fee__c
        FROM advance__c
        WHERE id IN :myAdvanceList
      ];
      list<commission__c> myCommsToAdd = new List<commission__c>();
      system.debug(myAdv.size());

      for (advance__c adv : myAdv) {
        system.debug('enter for loop');
        decimal originationPlusCaf;
        decimal above5Mill;
        decimal above5MillComm;
        decimal finComm;
        decimal finalCommAmount;
        decimal originationFeeTotal;
        decimal orgFee = adv.Deal__r.CAF_Upfront_Fee__c != null
          ? adv.Deal__r.CAF_Upfront_Fee__c / 100
          : 0;
        decimal rateBasedOnBorrowed;

        if (
          adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c -
          adv.Approved_Advance_Amount_Total__c <= 5000000
        ) {
          rateBasedOnBorrowed = 0.20;
          system.debug('under 5 mil and direct');
          if (
            adv.Deal__r.Internal_Referral__c != null &&
            adv.Deal__r.Internal_Referral__r.isActive == true &&
            adv.Deal__r.Internal_Referral_Fee__c != null &&
            adv.Deal__r.Internal_Referral_Fee__c != 'N/A'
          ) {
            system.debug('N/A?' + adv.Deal__r.Internal_Referral_Fee__c);
            // decimal internalFee = adv.Deal__r.Internal_Referral_Fee__c == '20%'
            //  ? .20
            //  : .50;

            decimal internalFee;

            if (adv.Deal__r.Internal_Referral_Fee__c == '10%') {
              internalFee = .10;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '20%') {
              internalFee = .20;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '30%') {
              internalFee = .30;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '50%') {
              internalFee = .50;
            }
            system.debug('referral?');
            system.debug('referral direct?');
            system.debug('referral fee' + adv.Deal__r.Internal_Referral_Fee__c);
            system.debug('referral user' + adv.Deal__r.Internal_Referral__c);

            Decimal commReferralUser =
              (adv.Advance_and_Origination_Fee_Subtotal__c *
              rateBasedOnBorrowed) * internalFee;
            Decimal commNonReferralUser =
              (adv.Advance_and_Origination_Fee_Subtotal__c *
              rateBasedOnBorrowed) - commReferralUser;

            Commission__c myCommission = new Commission__c();
            myCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            myCommission.Deal__c = adv.Deal__r.id;
            myCommission.Loan_Type__c = adv.Deal__r.type;
            myCommission.Advance__c = adv.Id;
            myCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            myCommission.Owner__c = adv.Deal__r.Internal_Referral__r.id;
            myCommission.OwnerId = adv.Deal__r.Internal_Referral__r.id;

            myCommission.Commission_Amount1__c = commReferralUser;
            myCommission.Origination_Fee__c = orgFee * 100;
            myCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            myCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(myCommission);

            Commission__c refCommission = new Commission__c();
            refCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            refCommission.Deal__c = adv.Deal__r.id;
            refCommission.Loan_Type__c = adv.Deal__r.type;
            refCommission.Advance__c = adv.Id;
            refCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            refCommission.Owner__c = adv.Deal__r.OwnerId;
            refCommission.OwnerId = adv.Deal__r.OwnerId;

            refCommission.Commission_Amount1__c = commNonReferralUser;
            refCommission.Origination_Fee__c = orgFee * 100;
            refCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            refCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            refCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            refCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(refCommission);
          } else {
            system.debug('no referral direct?');

            Commission__c myCommission = new Commission__c();
            myCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            myCommission.Deal__c = adv.Deal__r.id;
            myCommission.Loan_Type__c = adv.Deal__r.type;
            myCommission.Advance__c = adv.Id;
            myCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            myCommission.Owner__c = adv.Deal__r.OwnerId;
            myCommission.OwnerId = adv.Deal__r.OwnerId;

            myCommission.Commission_Amount1__c =
              (adv.Advance_and_Origination_Fee_Subtotal__c) *
              rateBasedOnBorrowed;
            myCommission.Origination_Fee__c = orgFee * 100;
            myCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            myCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(myCommission);
          }
        } else if (
          adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c -
          adv.Approved_Advance_Amount_Total__c > 5000000 &&
          adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c -
          adv.Approved_Advance_Amount_Total__c <= 75000000
        ) {
          system.debug('over 5 mil and direct');
          rateBasedOnBorrowed = 0.10;

          if (
            adv.Deal__r.Internal_Referral__c != null &&
            adv.Deal__r.Internal_Referral__r.isActive == true &&
            adv.Deal__r.Internal_Referral_Fee__c != null &&
            adv.Deal__r.Internal_Referral_Fee__c != 'N/A'
          ) {
            system.debug('N/A?' + adv.Deal__r.Internal_Referral_Fee__c);

            //decimal internalFee = adv.Deal__r.Internal_Referral_Fee__c == '20%'
            //? .20
            // : .50;

            decimal internalFee;

            if (adv.Deal__r.Internal_Referral_Fee__c == '10%') {
              internalFee = .10;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '20%') {
              internalFee = .20;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '30%') {
              internalFee = .30;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '50%') {
              internalFee = .50;
            }
            Decimal commReferralUser =
              (adv.Advance_and_Origination_Fee_Subtotal__c *
              rateBasedOnBorrowed) * internalFee;
            Decimal commNonReferralUser =
              (adv.Advance_and_Origination_Fee_Subtotal__c *
              rateBasedOnBorrowed) - commReferralUser;

            Commission__c myCommission = new Commission__c();
            myCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            myCommission.Deal__c = adv.Deal__r.id;
            myCommission.Loan_Type__c = adv.Deal__r.type;
            myCommission.Advance__c = adv.Id;
            myCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            myCommission.Owner__c = adv.Deal__r.Internal_Referral__r.id;
            myCommission.OwnerId = adv.Deal__r.Internal_Referral__r.id;

            myCommission.Commission_Amount1__c = commReferralUser;
            myCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Origination_Fee__c = orgFee * 100;
            myCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            myCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(myCommission);

            Commission__c refCommission = new Commission__c();
            refCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            refCommission.Deal__c = adv.Deal__r.id;
            refCommission.Loan_Type__c = adv.Deal__r.type;
            refCommission.Advance__c = adv.Id;
            refCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            refCommission.Owner__c = adv.Deal__r.OwnerId;
            refCommission.OwnerId = adv.Deal__r.OwnerId;

            refCommission.Commission_Amount1__c = commNonReferralUser;
            refCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            refCommission.Origination_Fee__c = orgFee * 100;
            refCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            refCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            refCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(refCommission);
          } else {
            Commission__c myCommission = new Commission__c();
            myCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            myCommission.Deal__c = adv.Deal__r.id;
            myCommission.Loan_Type__c = adv.Deal__r.type;
            myCommission.Advance__c = adv.Id;
            myCommission.Owner__c = adv.Deal__r.OwnerId;
            myCommission.OwnerId = adv.Deal__r.OwnerId;

            myCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            myCommission.Commission_Amount1__c =
              (adv.Advance_and_Origination_Fee_Subtotal__c) *
              rateBasedOnBorrowed;
            myCommission.Origination_Fee__c = orgFee * 100;
            myCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            myCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(myCommission);
          }
        } else if (
          adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c -
          adv.Approved_Advance_Amount_Total__c > 75000000
        ) {
          system.debug('over 20 mil and direct');
          rateBasedOnBorrowed = 0.04;

          if (
            adv.Deal__r.Internal_Referral__c != null &&
            adv.Deal__r.Internal_Referral__r.isActive == true &&
            adv.Deal__r.Internal_Referral_Fee__c != null &&
            adv.Deal__r.Internal_Referral_Fee__c != 'N/A'
          ) {
            system.debug('N/A?' + adv.Deal__r.Internal_Referral_Fee__c);

            // decimal internalFee = adv.Deal__r.Internal_Referral_Fee__c == '20%'
            //   ? .20
            //   : .50;

            decimal internalFee;

            if (adv.Deal__r.Internal_Referral_Fee__c == '10%') {
              internalFee = .10;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '20%') {
              internalFee = .20;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '30%') {
              internalFee = .30;
            } else if (adv.Deal__r.Internal_Referral_Fee__c == '50%') {
              internalFee = .50;
            }

            Decimal commReferralUser =
              (adv.Advance_and_Origination_Fee_Subtotal__c *
              rateBasedOnBorrowed) * internalFee;
            Decimal commNonReferralUser =
              (adv.Advance_and_Origination_Fee_Subtotal__c *
              rateBasedOnBorrowed) - commReferralUser;

            Commission__c myCommission = new Commission__c();
            myCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            myCommission.Deal__c = adv.Deal__r.id;
            myCommission.Loan_Type__c = adv.Deal__r.type;
            myCommission.Advance__c = adv.Id;
            myCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            myCommission.Owner__c = adv.Deal__r.Internal_Referral__r.id;
            myCommission.OwnerId = adv.Deal__r.Internal_Referral__r.id;

            myCommission.Commission_Amount1__c = commReferralUser;
            myCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Origination_Fee__c = orgFee * 100;
            myCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            myCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(myCommission);

            Commission__c refCommission = new Commission__c();
            refCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            refCommission.Deal__c = adv.Deal__r.id;
            refCommission.Loan_Type__c = adv.Deal__r.type;
            refCommission.Advance__c = adv.Id;
            refCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            refCommission.Owner__c = adv.Deal__r.OwnerId;
            refCommission.OwnerId = adv.Deal__r.OwnerId;

            refCommission.Commission_Amount1__c = commNonReferralUser;
            refCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            refCommission.Origination_Fee__c = orgFee * 100;
            refCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            refCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            refCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(refCommission);
          } else {
            Commission__c myCommission = new Commission__c();
            myCommission.CAF_YSP__c = adv.Deal__r.CAF_YSP__c;
            myCommission.Deal__c = adv.Deal__r.id;
            myCommission.Advance__c = adv.Id;
            myCommission.Loan_Type__c = adv.Deal__r.type;
            myCommission.Owner__c = adv.Deal__r.OwnerId;
            myCommission.OwnerId = adv.Deal__r.OwnerId;

            myCommission.Final_Loan_Amount_Trigger__c = adv.Approved_Advance_Amount_Max_Total__c;
            myCommission.Commission_Amount1__c =
              (adv.Advance_and_Origination_Fee_Subtotal__c) *
              rateBasedOnBorrowed;
            //myCommission.Origination_Fee__c = orgFee*100;
            myCommission.Commissionable_Amount__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Origination_Fee_Amt__c = adv.Advance_and_Origination_Fee_Subtotal__c;
            myCommission.Total_Borrowed_on_Term__c = adv.Deal__r.Account.Borrowed_on_Term_Loans__c;
            myCommission.Total_Borrowed_on_Bridge__c = adv.Deal__r.Account.Borrowed_on_Bridge_Loans__c;

            myCommsToAdd.add(myCommission);
          }
        }
      }

      if (myCommsToAdd.size() > 0) {
        insert myCommsToAdd;
      }
    }

    if (uncompletedAdvanceIds.size() > 0) {
      system.debug('uncompleted advance' + uncompletedAdvanceIds.size());
      List<Commission__c> myCommissionList = [
        SELECT
          id,
          Commission_Amount1__c,
          Commission_Total__r.id,
          Commission_Total__r.Total_Bridge_Commission__c
        FROM Commission__c
        WHERE Advance__c IN :uncompletedAdvanceIds
      ];
      //for(Commission__c comm: myCommissionList){
      //comm.Commission_Total__r.Total_Bridge_Commission__c = comm.Commission_Total__r.Total_Bridge_Commission__c - comm.Commission_Amount1__c;
      //myCommissionTotalsIds.add(comm.Commission_Total__r);

      //}

      if (myCommissionList.size() > 0) {
        delete myCommissionList;
      }
      // if(myCommissionTotalsIds.size()>0){
      //  update myCommissionTotalsIds;
      //}
    }
  }

  /**
   * @name beforeDelete
   * @description
   * @param
   **/
  public static void beforeDelete(List<Advance__c> newList) {
    List<Id> advIds = new List<Id>();
    Profile p = [
      SELECT id, Name
      FROM Profile
      WHERE id = :Userinfo.getProfileid()
    ];

    system.debug('New List: ' + newList);
    for (Integer i = 0; i < newList.size(); i++) {
      if (
        newList[i].Status__c == 'Completed' &&
        p.Name != 'System Administrator'
      ) {
        newList[i].addError('You cannot delete a completed advance.');
      } else {
        advIds.add(newList[i].Id);
      }
    }
    List<OpportunityLineItem> lstLineItems = [
      SELECT Id
      FROM OpportunityLineItem
      WHERE Advance__c IN :advIds
    ];
    system.debug('Product List: ' + lstLineItems);

    if (lstLineItems.size() > 0) {
      delete lstLineItems;
    }
    List<id> myCommissions = new List<id>();
    List<id> advId = new List<id>();

    for (Advance__c adv : newList) {
      advId.add(adv.id);
      system.debug('old adv id' + advId);
    }

    List<Commission__c> myCommissionList = [
      SELECT
        id,
        Commission_Amount1__c,
        Commission_Total__r.id,
        Commission_Total__r.Total_Bridge_Commission__c
      FROM Commission__c
      WHERE Advance__c IN :advId
    ];
    system.debug('del comm size' + myCommissionList.size());

    if (myCommissionList.size() > 0) {
      system.debug('Comm to Delete' + myCommissionList.size());
      delete myCommissionList;
    }
  }

  /**
   * @name afterDelete
   * @description
   * @param
   **/
  /*public static void afterDelete(
    List<Advance__c> newList,
    List<Advance__c> oldList
  ) {
    //    for ( Integer i=0;i<newList.size();i++ ){

    //    }
    //
    //
    List<id> myCommissions = new List<id>();
    List<id> advId = new List<id>();

    for (Advance__c adv : oldList) {
      advId.add(adv.id);
    }
    List<Commission__c> myCommissionList = [
      SELECT
        id,
        Commission_Amount1__c,
        Commission_Total__r.id,
        Commission_Total__r.Total_Bridge_Commission__c
      FROM Commission__c
      WHERE Advance__c IN :advId
    ];

    if (myCommissionList.size() > 0) {
      delete myCommissionList;
    }
  }*/

  /**
   * @name afterUndelete
   * @description
   * @param
   **/
  //public static void afterUndelete(List<Advance__c> oldList){
  //    for ( Integer i=0;i<oldList.size();i++ ){

  //    }
  //}

  public static List<Advance__c> isCreditLine(List<Id> advIds) {
    List<Advance__c> validAdvs = new List<Advance__c>();

    for (Advance__c adv : [
      SELECT
        Id,
        Deal__c,
        Deal__r.RecordType.Name,
        Deal__r.LOC_Loan_Type__c,
        Closing_Funds_Checklist__c,
        Manager_Approved__c,
        Evidence_of_Insurance_Approved__c,
        Flood_Certificate_Approved__c
      FROM Advance__c
      WHERE
        Id IN :advIds
        AND Deal__r.RecordType.DeveloperName = 'LOC_Loan'
        AND Deal__r.LOC_Loan_Type__c = 'Credit Line'
    ]) {
      validAdvs.add(adv);
    }

    return validAdvs;
  }

  public static Map<Id, Boolean> validateCompletions(
    List<Advance__c> advances
  ) {
    Map<Id, Boolean> verifiedAdvs = new Map<Id, Boolean>();

    for (Advance__c adv : advances) {
      if (
        adv.Closing_Funds_Checklist__c == true &&
        adv.Manager_Approved__c == true &&
        adv.Evidence_of_Insurance_Approved__c == true &&
        adv.Flood_Certificate_Approved__c == true
      ) {
        verifiedAdvs.put(adv.Id, true);
      } else {
        verifiedAdvs.put(adv.Id, false);
      }
    }

    List<String> docStructures = AdvanceClearToFundController.docStructures;

    Map<String, String> docStringMap = new Map<String, String>();
    for (Document_Structure__mdt docStructure : [
      SELECT Id, Folder_Structure_String__c, Document_Type__c, DeveloperName
      FROM Document_Structure__mdt
      WHERE sObject__c = 'Advance__c' AND DeveloperName IN :docStructures
    ]) {
      String docString =
        docStructure.Folder_Structure_String__c +
        '|' +
        docStructure.Document_Type__c;
      docStringMap.put(docString, docStructure.DeveloperName);
    }

    Map<Id, Set<String>> mapExistingDocStrings = new Map<Id, Set<String>>();

    for (Deal_Document__c dealDoc : [
      SELECT
        Id,
        Doc_String__c,
        Reviewed__c,
        Reviewed_By__r.Name,
        Reviewed_By__c,
        File_Name__c,
        Attachment_Id__c,
        Reviewed_On__c,
        Advance__c
      FROM Deal_Document__c
      WHERE Advance__c IN :advances AND Doc_String__C IN :docStringMap.keySet()
      ORDER BY CreatedDate DESC
    ]) {
      Boolean isValid = verifiedAdvs.get(dealDoc.Advance__c);

      if (isValid == false) {
        continue;
      }

      if (dealDoc.Reviewed__c != true) {
        verifiedAdvs.put(dealDoc.Advance__c, false);
        continue;
      }

      if (mapExistingDocStrings.containsKey(dealDoc.Advance__c)) {
        Set<String> existingDocStrings = mapExistingDocStrings.get(
          dealDoc.Advance__c
        );
        existingDocStrings.add(docStringMap.get(dealDoc.Doc_String__c));
        mapExistingDocStrings.put(dealDoc.Advance__c, existingDocStrings);
      } else {
        Set<String> newDocStringSet = new Set<String>();
        newDocStringSet.add(docStringMap.get(dealDoc.Doc_String__c));
        mapExistingDocStrings.put(dealDoc.Advance__c, newDocStringSet);
      }
    }

    List<String> optional = new List<String>{
      'Flood_Insurance_if_applicable',
      'HOA_Policy_if_applicable',
      'LOC_Renovation_Cert'
    };

    for (String docStructure : docStructures) {
      if (optional.contains(docStructure)) {
        continue;
      }

      for (Id key : mapExistingDocStrings.keySet()) {
        if (!mapExistingDocStrings.get(key).contains(docStructure)) {
          verifiedAdvs.put(key, false);
        }
      }
    }

    return verifiedAdvs;
  }

  public static void updateOppLineItems(Set<Id> updatedLineIds) {
    List<OpportunityLineItem> oliList = [
      SELECT
        Id,
        Advance__r.Wire_Date__c,
        Advance__r.Approved_Advance_Amount_Total__c
      FROM OpportunityLineItem
      WHERE Advance__c IN :updatedLineIds
      // AND ProductCode LIKE 'bridge%'
    ];

    for (OpportunityLineItem oli : oliList) {
      if (oli.Advance__r.Wire_Date__c != null) {
        oli.ServiceDate = oli.Advance__r.Wire_Date__c;
      }
      oli.UnitPrice = oli.Advance__r.Approved_Advance_Amount_Total__c != null
        ? oli.Advance__r.Approved_Advance_Amount_Total__c
        : 0;
    }

    update oliList;
  }

  // public static void validateCompletion(Advance__c advance) {
  //   List<Opportunity> deal = [
  //     SELECT Id, RecordType.Name, LOC_Loan_Type__c
  //     FROM Opportunity
  //     WHERE
  //       Id = :advance.Deal__c
  //       AND RecordType.DeveloperName = 'LOC_Loan'
  //       AND LOC_Loan_Type__c = 'Credit Line'
  //     LIMIT 1
  //   ];

  //   if (deal.size() == 0) {
  //     return;
  //   }

  //   List<String> docStructures = AdvanceClearToFundController.docStructures;
  //   Boolean shouldComplete = true;

  //   if (
  //     shouldComplete &&
  //     (advance.Closing_Funds_Checklist__c == false ||
  //     advance.Manager_Approved__c == false ||
  //     advance.Evidence_of_Insurance_Approved__c == false ||
  //     advance.Flood_Certificate_Approved__c == false)
  //   ) {
  //     shouldComplete = false;
  //   }

  //   if (shouldComplete) {
  //     Map<String, String> docStringMap = new Map<String, String>();
  //     for (Document_Structure__mdt docStructure : [
  //       SELECT Id, Folder_Structure_String__c, Document_Type__c, DeveloperName
  //       FROM Document_Structure__mdt
  //       WHERE sObject__c = 'Advance__c' AND DeveloperName IN :docStructures
  //     ]) {
  //       String docString =
  //         docStructure.Folder_Structure_String__c +
  //         '|' +
  //         docStructure.Document_Type__c;
  //       docStringMap.put(docString, docStructure.DeveloperName);
  //     }
  //     for (Deal_Document__c dealDoc : [
  //       SELECT
  //         Id,
  //         Doc_String__c,
  //         Reviewed__c,
  //         Reviewed_By__r.Name,
  //         Reviewed_By__c,
  //         File_Name__c,
  //         Attachment_Id__c,
  //         Reviewed_On__c
  //       FROM Deal_Document__c
  //       WHERE
  //         (id = :advance.Id
  //         OR deal__c = :advance.Deal__c)
  //         AND Doc_String__C IN :docStringMap.keySet()
  //       ORDER BY CreatedDate ASC
  //     ]) {
  //       if (shouldComplete == false) {
  //         break;
  //       }
  //       if (
  //         docStringMap.get(dealDoc.Doc_String__c) ==
  //         'Flood_Insurance_if_applicable' ||
  //         docStringMap.get(dealDoc.Doc_String__c) == 'LOC_Renovation_Cert' ||
  //         docStringMap.get(dealDoc.Doc_String__c) == 'HOA_Policy_if_applicable'
  //       ) {
  //         continue;
  //       } else {
  //         shouldComplete = dealDoc.Reviewed__c == true;
  //       }
  //     }
  //   }
  //   if (!shouldComplete) {
  //     advance.addError(
  //       'Cannot change this Advance Record\'s status to complete. Please make sure that everything has been uploaded and reviewed first in the Clear To Fund tab.'
  //     );
  //   }
  // }
}