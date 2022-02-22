public without sharing class SecuritizationHelper {
  public static final Map<String, Id> RT_MAP = queryRecordTypeMap();

  public static void beforeInsert(List<Securitization__c> newList) {
    // for (Securitization__c sec : newList) {
    //   Funding_Vehicle__c fv = new Funding_Vehicle__c();
    //   fv.Name = sec.Name;
    //   fv.Funding_Vehicle_Type__c = 'Securitization';
    //   fv.RecordTypeId = recordTypeMap.get('SecuritizatiupdateFundingVehicleCnx
    //   insert fv;
    // response.put('fvId', fv.Id);
    //   sec.Funding_Vehicle__c = fv.Id;
    //   update sec;
  }

  public static void afterInsert(List<Securitization__c> newList) {
    createRelatedFundingVehicles(newList);
  }

  public static void afterUpdate(
    Map<Id, Securitization__c> oldMap,
    List<Securitization__c> newList
  ) {
    Map<Id, Securitization__c> secMap = new Map<Id, Securitization__c>();

    for (Securitization__c sec : newList) {
      Securitization__c oldSec = oldMap.get(sec.Id);
      if (
        (oldSec.Status__c != sec.Status__c && (sec.Status__c == 'Redeemed' || sec.Status__c == 'Closed')) ||
        (oldSec.Close_Date__c != sec.Close_Date__c &&
        sec.Close_Date__c != null)
      ) {
        secMap.put(sec.Id, sec);
      }
    }

    if (secMap.size() > 0) {
      updateFundingVehicleCnx(secMap);
    }
  }

  public static void updateFundingVehicleCnx(
    Map<Id, Securitization__c> secMap
  ) {
    Map<Id, Securitization__c> dealsToUpdate = new Map<Id, Securitization__c>();
    List<Deal_x_Funding_Vehicle__c> dfvs = [
      SELECT Id, End_Date__c, Deal__c, Deal__r.Securitization__c, Deal__r.Warehouse_Line__c, Funding_Vehicle__r.Securitization__c
      FROM Deal_x_Funding_Vehicle__c
      WHERE Funding_Vehicle__r.Securitization__c IN :secMap.keySet()
    ];

    Map<Id, String> warehouseMap = new Map<Id, String>();

    for (Deal_x_Funding_Vehicle__c d : dfvs) {
      Securitization__c sec = secMap.get(
        d.Funding_Vehicle__r.Securitization__c
      );

      if (sec.Close_Date__c != null && String.isNotEmpty(d.Deal__r.Warehouse_Line__c)) {
        d.Start_Date__c = sec.Close_Date__c;
        warehouseMap.put(d.Deal__c, d.Deal__r.Warehouse_Line__c);
      }
      if (sec.Status__c == 'Redeemed' && d.Deal__r.Securitization__c != null) {
        d.End_Date__c = (Date) System.today();
        dealsToUpdate.put(d.Deal__c, sec);
      } else if (sec.Status__c == 'Closed' && d.Deal__r.Securitization__c != null) {
        d.Include_Yes_No__c = true;
        dealsToUpdate.put(d.Deal__c, sec);
      }
    }


    if(warehouseMap.size() > 0) {
      List<Deal_x_Funding_Vehicle__c> warehouseDfcxs = [
      SELECT Id, Deal__c, End_Date__c, Deal__r.Securitization__c, Deal__r.Warehouse_Line__c, Funding_Vehicle__r.Name
      FROM Deal_x_Funding_Vehicle__c
      WHERE Deal__c IN :warehouseMap.keySet()
      AND Funding_Vehicle__r.Name IN :warehouseMap.values()
    ];

    System.debug(JSON.serializePretty(warehouseDfcxs));
      
        for (Deal_x_Funding_Vehicle__c d : warehouseDfcxs) {
          Securitization__c sec = secMap.get(
            d.Deal__r.Securitization__c
          );
          if(sec != null) {
            d.End_Date__c = sec.Close_Date__c;
            dfvs.add(d);
  
          }
        }

    }

    try {
      update dfvs;
      updateDeals(dealsToUpdate);
    } catch (DmlException e) {
      System.debug(
        'Error updating Deal_x_Funding_Vehicle__c records: ' + e.getMessage()
      );
    }
  }

  public static void updateDeals(Map<Id, Securitization__c> dealSecMap) {
    List<Opportunity> updDeals = new List<Opportunity>();

    for (Id id : dealSecMap.keySet()) {
      Securitization__c sec = dealSecMap.get(id);
      Boolean securitised = sec.Status__c == 'Closed';
      updDeals.add(
        new Opportunity(
          Id = id,
          Securitized__c = securitised
        )
      );
    }

    update updDeals;
  }

  public static Map<String, Id> queryRecordTypeMap() {
    Map<String, Id> recordTypeMap = new Map<String, Id>();

    for (RecordType rt : [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE Sobjecttype = 'Funding_Vehicle__c'
    ]) {
      recordTypeMap.put(rt.DeveloperName, rt.Id);
    }

    return recordTypeMap;
  }

  public static void createRelatedFundingVehicles(
    List<Securitization__c> newList
  ) {
    List<Funding_Vehicle__c> fvList = new List<Funding_Vehicle__c>();

    for (Securitization__c sec : newList) {
      Funding_Vehicle__c fv = new Funding_Vehicle__c();
      fv.Name = sec.Name;
      fv.Funding_Vehicle_Type__c = 'Securitization';
      fv.RecordTypeId = RT_MAP.get('Securitization');
      fv.Securitization__c = sec.Id;
      fvList.add(fv);
    }

    insert fvList;
  }
}