global class LossMitigationSchedule implements Schedulable {
  global void execute(SchedulableContext SC) {
    Database.executeBatch(new LossMitigationBatch());
  }
}
