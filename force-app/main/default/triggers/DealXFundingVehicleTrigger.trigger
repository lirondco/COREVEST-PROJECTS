trigger DealXFundingVehicleTrigger on Deal_x_Funding_Vehicle__c (after update, before insert) {
  if(Trigger.isAfter && Trigger.isUpdate) {
    DealXFundingVehicleHelper.afterUpdate(Trigger.oldMap, Trigger.new);
  }

  if(Trigger.isBefore && Trigger.isInsert) {
    DealXFundingVehicleHelper.beforeInsert(Trigger.new);
  }
}