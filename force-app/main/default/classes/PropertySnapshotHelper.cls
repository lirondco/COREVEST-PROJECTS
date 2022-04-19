public without sharing class PropertySnapshotHelper {
  private static final Map<String, String> PROPERTY_GENERAL_FIELD_MAP = new Map<String, String>{
    'Current_UPB__c' => 'Current_UPB__c',
    'Appraised_Value_Amount__c' => 'Current_Valuation_Amount__c',
    'BPO_Appraisal_Date__c' => 'Current_Valuation_Date__c',
    'Payoff_Amount__c' => 'Payoff_Amount__c',
    'Payoff_Received_Date__c' => 'Payoff_Date__c'
  };

  private static final Map<String, String> DEAL_FIELD_MAP = new Map<String, String>{
    'Legal_Fee__c' => 'Legal_Fee__c',
    'Extension_Fee__c' => 'Extension_Fee__c',
    'Securitized__c' => 'Securitized_at_Time_of_Resolution__c'
  };

  private static final Map<String, String> SNAPSHOT_TO_PROP_MAP_ASSETPAIDOFF = new Map<String, String>{
    'Resolved_Date__c' => 'Payoff_Received_Date__c',
    'Start_Date__c' => 'Payoff_Received_Date__c',
    'Days_To_Resolve__c' => 'Days_To_Resolve__c'
  };

  private static final Map<String, String> SNAPSHOT_TO_SPEC_ASSET_RESOLVED = new Map<String, String>{
    'Start_Date__c' => 'CreatedDate',
    'Resolved_Date__c' => 'Resolved_Date__c',
    'Days_To_Resolve__c' => 'Days_To_Resolve__c',
    'REO_Sell_Date__c' => 'REO_Sell_Date__c',
    'REO_Date__c' => 'REO_Date__c',
    'Vintage_Year__c' => 'Vintage_Year__c',
    'Realized_Loss_Severity__c' => 'Realized_Loss_Severity__c',
    'Total_Broker_Commissions_Fees_Paid__c' => 'Total_Broker_Commissions_Fees_Paid__c',
    'Maturity_Default_Transfer__c' => 'Maturity_Default_Transfer__c',
    'Days_to_Resolve_REO_to_REO_Sold__c' => 'Days_to_Resolve_REO_to_REO_Sold__c'
  };

  private static final Map<String, String> SNAPSHOT_TO_EXT_COMPLETED = new Map<String, String>{
    'Start_Date__c' => 'CreatedDate',
    'Resolved_Date__c' => 'Extension_Date__c',
    'Days_To_Resolve__c' => 'Days_To_Resolve__c'
  };

  private static final String PROP_EVENT_NAME_PAID = 'Asset Paid Off';

  private static final String PROP_EVENT_NAME_SOLD = 'Asset Sold';

  private static final List<String> PROPERTY_EVENT_TYPES = new List<String>{
    PROP_EVENT_NAME_PAID,
    PROP_EVENT_NAME_SOLD
  };

  private static final String PROP_EXT_EVENT_NAME = 'Extension Completed';

  private static final String SPEC_ASSET_EVENT_NAME = 'Special Asset Resolved';

  private static final Map<String, Map<String, String>> FIELD_MAPPING_BY_EVENT = new Map<String, Map<String, String>>{
    PROP_EVENT_NAME_PAID => SNAPSHOT_TO_PROP_MAP_ASSETPAIDOFF,
    PROP_EXT_EVENT_NAME => SNAPSHOT_TO_EXT_COMPLETED,
    SPEC_ASSET_EVENT_NAME => SNAPSHOT_TO_SPEC_ASSET_RESOLVED
  };

  private static final Map<String, Schema.SObjectField> PROPERTY_FIELD_MAP = Schema.SObjectType.Property__c.fields.getMap();
  private static final Map<String, Schema.SObjectField> OPPORTUNITY_FIELD_MAP = Schema.SObjectType.Opportunity.fields.getMap();
  private static final Map<String, Schema.SObjectField> SNAPSHOT_FIELDMAP = Schema.SObjectType.Property_Snapshot__c.fields.getMap();


  public static void createPropertySnapshot(
    Map<String, Map<Id, sObject>> eventTypeMap
  ) {
    List<Property_Snapshot__c> propSnapshots = new List<Property_Snapshot__c>();
    Set<Id> dealIds = new Set<Id>();
    Set<Id> propIds = new Set<Id>();

    Map<Id, Property__c> propMap = new Map<Id, Property__c>();
    Map<Id, Opportunity> dealMap = new Map<Id, Opportunity>();

    for (String key : eventTypeMap.keySet()) {
      if (key == PROP_EXT_EVENT_NAME || key == SPEC_ASSET_EVENT_NAME) {
        for (sObject obj : eventTypeMap.get(key).values()) {
          if (obj.get('Property__c') != null) {
            propIds.add((Id) obj.get('Property__c'));
          }
        }
      } else {
        for (sObject obj : eventTypeMap.get(key).values()) {
          if (obj.get('Deal__c') != null) {
            dealIds.add((Id) obj.get('Deal__c'));
          }
        }
      }
    }

    if (dealIds.size() > 0) {
      String dealQuery =
        'SELECT Id,' +
        String.join(new List<String>(DEAL_FIELD_MAP.keySet()), ',') +
        ' FROM Opportunity WHERE Id IN :dealIds';
      dealMap = new Map<Id, Opportunity>(
        (List<Opportunity>) Database.query(dealQuery)
      );
    } else if (propIds.size() > 0) {
      String propQuery =
        'SELECT Id,' +
        String.join(
          new List<String>(PROPERTY_GENERAL_FIELD_MAP.keySet()),
          ','
        ) +
        ', Deal__r.' +
        String.join(
          new List<String>(DEAL_FIELD_MAP.keySet()),
          ', Deal__r.'
        ) +
        ' FROM Property__c WHERE Id IN :propIds';
      propMap = new Map<Id, Property__c>(
        (List<Property__c>) Database.query(propQuery)
      );
    }

    for (String key : eventTypeMap.keySet()) {
      Property_Snapshot__c propSnapshot = new Property_Snapshot__c(
        Event_Type__c = key
      );

      Map<String, String> fieldMapping = FIELD_MAPPING_BY_EVENT.get(key);

      for (sObject obj : eventTypeMap.get(key).values()) {
        if(PROP_EXT_EVENT_NAME == key) {
            propSnapshot.Property_Extension__c = (Id) obj.get('Id');
            propSnapshot.Property__c = (Id) obj.get('Property__c');
        } else if (SPEC_ASSET_EVENT_NAME == key) {
            propSnapshot.Special_Asset__c = (Id) obj.get('Id');
            propSnapshot.Property__c = (Id) obj.get('Property__c');
        } else {
            propSnapshot.Property__c = (Id) obj.get('Id');
        }
        for (String fld : fieldMapping.keySet()) {
          Schema.SObjectField field = SNAPSHOT_FIELDMAP.get(fld);   
          if(field != null) {
            if(fieldMapping.get(fld) == 'CreatedDate') {
                propSnapshot.put(field, date.valueOf((DateTime) obj.get('CreatedDate')));
            } else {
                propSnapshot.put(field, obj.get(fieldMapping.get(fld)));
            }
          }
        }

        if (
          key == SPEC_ASSET_EVENT_NAME &&
          obj.get('Special_Asset_Reason__c') != null &&
          obj.get('Special_Asset_Reason__c') == 'Bankruptcy'
        ) {
          propSnapshot.In_BK_at_Time_of_Resolution__c = true;
        }

        for (String propFld : PROPERTY_GENERAL_FIELD_MAP.keySet()) {
          Schema.SObjectField field = SNAPSHOT_FIELDMAP.get(PROPERTY_GENERAL_FIELD_MAP.get(propFld));   
          if (propMap.size() > 0) {
            Property__c prop = propMap.get((Id) obj.get('Property__c'));
            if (prop != null) {
              propSnapshot.put(field, prop.get(propFld));
            }
          } else {
            propSnapshot.put(field, obj.get(propFld));
          }
        }

        for(String dealFld : DEAL_FIELD_MAP.keySet()) {
         Schema.SObjectField field = SNAPSHOT_FIELDMAP.get(DEAL_FIELD_MAP.get(dealFld));   
          if (dealMap.size() > 0) {
            Opportunity deal = dealMap.get((Id) obj.get('Deal__c'));
            if (deal != null) {
              propSnapshot.put(field, deal.get(dealFld));
            }
          } else {
            Property__c prop = propMap.get((Id) obj.get('Property__c'));
            if (prop != null) {
              propSnapshot.put(field, prop.getSobject('Deal__r').get(dealFld));
            }
          }
        }
      }
      propSnapshots.add(propSnapshot);  
    }

    if(propSnapshots.size() > 0) {
      Database.insert(propSnapshots);
    }
  }
}
