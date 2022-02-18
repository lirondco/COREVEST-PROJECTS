trigger property_Advance_Trigger on Property_Advance__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings');
  if (!settings.Disable_Property_Advance_Trigger__c) {
    if (Trigger.isBefore && Trigger.isInsert) {
      Property_Advance_Helper.beforeInsert(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
      Property_Advance_Helper.afterInsert(Trigger.New);
      PropertyTriggerExtensions.checkAdvancePropertyStatuses(Trigger.newMap);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
      Property_Advance_Helper.beforeUpdate(Trigger.New, Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
      Property_Advance_Helper.afterUpdate(Trigger.New, Trigger.Old);
    }
    if (Trigger.isBefore && Trigger.isDelete) {
      //	Property_Advance__c_Helper.beforeDelete(Trigger.New);

    }
    if (Trigger.isAfter && Trigger.isDelete) {
      Property_Advance_Helper.afterDelete(Trigger.New, Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isUndelete) {
      //	Property_Advance__c_Helper.afterUndelete(Trigger.Old);
    }
  }
}