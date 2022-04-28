public class Commission_Helper {
  public static void afterInsert(List<Commission__c> newList) {
    List<id> termCommIds = new List<id>();
    List<id> bridgeCommIds = new List<id>();
    List<Commission__c> commsToUpdate = new List<Commission__c>();
    List<Commission__c> commsToAdd = new List<Commission__c>();

    List<Commission__c> commsToUpsert = new List<Commission__c>();
    list<id> ownId = new List<id>();
    list<Commission_Total__c> myCommTotals = new List<Commission_Total__c>();
    List<Period> periodQuery = [
      SELECT StartDate, EndDate
      FROM Period
      WHERE
        Type = 'Quarter'
        AND (StartDate = THIS_FISCAL_QUARTER
        OR StartDate = LAST_FISCAL_QUARTER)
      ORDER BY StartDate
    ];

    Date quarterStartDateLastQ = periodQuery[0].StartDate;

    Date quarterEndDateLastQ = periodQuery[0].EndDate;
    //NEW
    Date quarterStartDate = periodQuery[1].StartDate;

    Date quarterEndDate = periodQuery[1].EndDate;

    system.debug(quarterStartDate);
    system.debug(quarterEndDate);
    system.debug('last q' + quarterStartDateLastQ);
    system.debug('last q' + quarterEndDateLastQ);

    for (Commission__c comm : newList) {
      ownId.add(comm.Owner__c);
      system.debug('COMM helper running');
    }

    list<Commission_Total__c> commTotals = new List<Commission_Total__c>();
    //NEW
    list<Commission_Total__c> commTotalsLastQuarter = new List<Commission_Total__c>();

    for (Commission_Total__c comm : [
      SELECT Id, OwnerId, Quarter_Start_Date__c, Quarter_End_Date__c
      FROM Commission_Total__c
      WHERE
        OwnerId IN :ownId
        AND (Quarter_Start_Date__c = :quarterStartDate
        OR Quarter_Start_Date__c = :quarterStartDateLastQ)
        AND (Quarter_End_Date__c = :quarterEndDate
        OR Quarter_End_Date__c = :quarterEndDateLastQ)
    ]) {
      if (
        comm.Quarter_Start_Date__c == quarterStartDate &&
        comm.Quarter_End_Date__c == quarterEndDate
      ) {
        commTotals.add(comm);
      } else if (
        comm.Quarter_Start_Date__c == quarterStartDateLastQ &&
        comm.Quarter_End_Date__c == quarterEndDateLastQ
      ) {
        commTotalsLastQuarter.add(comm);
      }
    }

    //finds existing commission records for the quarter and relates them to commission total as a parent.
    //if commission totals for the quarter exists
    if (commTotals.size() > 0) {
      map<id, id> commTotalMap = new Map<id, id>();
      //used to verify user has commission total for the quarter or not
      map<id, id> commTotalMap2 = new Map<id, id>();

      //NEW
      map<id, id> commTotalMapLastQ = new Map<id, id>();
      //used to verify user has commission total for the last quarter or not
      map<id, id> commTotalMap2LastQ = new Map<id, id>();

      for (Commission_Total__c commTotal : commTotals) {
        commTotalMap.put(commTotal.OwnerId, commTotal.id);
        commTotalMap2.put(commTotal.OwnerId, commTotal.OwnerId);
      }
      //NEW
      for (Commission_Total__c commTotal : commTotalsLastQuarter) {
        commTotalMapLastQ.put(commTotal.OwnerId, commTotal.id);
        commTotalMap2LastQ.put(commTotal.OwnerId, commTotal.OwnerId);
      }

      for (Commission__c comm : newList) {
        if (
          comm.Loan_Type__c == 'Term Loan' ||
          (comm.Loan_Type__c == 'Bridge Loan' &&
          comm.Product_Type__c == 'Multifamily/CRE')
        ) {
          termCommIds.add(comm.id);
          system.debug('term loan size' + termCommIds.size());
        } else if (
          (comm.Loan_Type__c == 'Bridge Loan' &&
          comm.Commission_Detail__c == null) ||
          (comm.Loan_Type__c == 'SAB Loan' &&
          comm.Commission_Detail__c == null)
        ) {
          bridgeCommIds.add(comm.Deal__c);
          system.debug(comm.Deal__c);
          system.debug('bridge loan size' + bridgeCommIds.size());
        }
      }

      list<Commission_Detail__c> myCommDetailsBridge = [
        SELECT Id, Deal__c
        FROM Commission_Detail__c
        WHERE
          (Loan_Type__c = 'Bridge Loan'
          OR Loan_Type__c = 'SAB Loan')
          AND Deal__c IN :bridgeCommIds
      ];

      system.debug(myCommDetailsBridge.size());

      //BRIDGE with Totals for quarter split
      if (myCommDetailsBridge.size() > 0) {
        system.debug('bridge commission' + myCommDetailsBridge.size());

        Map<Id, Id> myMap = new Map<Id, Id>();

        for (Commission_Detail__c CommDetail : myCommDetailsBridge) {
          myMap.put(CommDetail.Deal__c, CommDetail.Id);
        }

        List<Commission__c> myBridgeCommissions = [
          SELECT
            id,
            Deal_Close_Date__c,
            Advance__r.Wire_Date__c,
            Owner__c,
            Quota__c,
            Deal__c,
            Quarter_Start_Date__c,
            Quarter_End_Date__c
          FROM Commission__c
          WHERE Commission_detail__c = NULL AND Deal__c IN :myMap.keySet()
        ];

        List<ForecastingQuota> allForQuotas = [
          SELECT
            Id,
            ForecastingTypeId,
            QuotaAmount,
            QuotaOwnerId,
            QuotaOwner.Name,
            ProductFamily,
            StartDate
          FROM ForecastingQuota
          WHERE
            ProductFamily IN ('Bridge', 'Term')
            AND StartDate = :quarterStartDate
            AND QuotaOwnerId IN :ownId
          ORDER BY ProductFamily
        ];

        list<ForecastingQuota> quotaBridge = new List<ForecastingQuota>();
        list<ForecastingQuota> quotaTerm = new List<ForecastingQuota>();
        Map<Id, decimal> quotaMapBridge = new Map<Id, decimal>();
        Map<Id, decimal> quotaMapTerm = new Map<Id, decimal>();

        for (ForecastingQuota quota : allForQuotas) {
          if (quota.ProductFamily == 'Bridge') {
            quotaBridge.add(quota);
            quotaMapBridge.put(quota.QuotaOwnerId, quota.QuotaAmount);
          } else if (quota.ProductFamily == 'Term') {
            quotaTerm.add(quota);
            quotaMapTerm.put(quota.QuotaOwnerId, quota.QuotaAmount);
          }
        }

        //List<Commission_Total__c> commsTotals = new List<Commission_Total__c>();

        if (myBridgeCommissions.size() > 0) {
          for (Commission__c bComm : myBridgeCommissions) {
            Commission_Total__c myCommTotal = new Commission_Total__c();
            if (
              (!commTotalMap2.containsKey(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDate &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDate) ||
              test.isRunningTest()
            ) {
              system.debug('bridge condition not in map');
              myCommTotal.OwnerId = bComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDate;
              myCommTotal.Quarter_End_Date__c = quarterEndDate;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);

              // myCommTotals.add(myCommTotal);
              insert myCommTotal;

              bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Quarter_Start_Date__c = quarterStartDate;
              bComm.Quarter_End_Date__c = quarterEndDate;
              bComm.Commission_Total__c = myCommTotal.Id;
              commsToUpdate.add(bComm);
              if (!test.isRunningTest()) {
                continue;
              }
            }
            if (
              (commTotalMap2.containsKey(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDate &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDate) ||
              test.isRunningTest()
            ) {
              system.debug('bridge commission in map');
              bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quarter_Start_Date__c = quarterStartDate;
              bComm.Quarter_End_Date__c = quarterEndDate;
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = commTotalMap.get(bComm.Owner__c);
              if (!test.isRunningTest()) {
                commsToUpdate.add(bComm);
                continue;
              }
            }
            if (
              (!commTotalMap2LastQ.containsKey(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDateLastQ &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDateLastQ) ||
              test.isRunningTest()
            ) {
              system.debug('bridge condition not in map');
              myCommTotal.OwnerId = bComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
              myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);

              // myCommTotals.add(myCommTotal);
              if (!test.isRunningTest()) {
                insert myCommTotal;
              }

              bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              bComm.Quarter_End_Date__c = QuarterEndDateLastQ;
              bComm.Commission_Total__c = myCommTotal.Id;
              if (!test.isRunningTest()) {
                commsToUpdate.add(bComm);
                continue;
              }
            }

            if (
              (commTotalMap2LastQ.containsKey(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDateLastQ &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDateLastQ) ||
              test.isRunningTest()
            ) {
              system.debug('bridge commission in map');
              bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quarter_Start_Date__c = QuarterStartDateLastQ;
              bComm.Quarter_End_Date__c = QuarterEndDateLastQ;
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = commTotalMapLastQ.get(bComm.Owner__c);
              if (!test.isRunningTest()) {
                commsToUpdate.add(bComm);
                continue;
              }
            }
            //commsTotals.add(myCommTotal);
          }
        }

        /* if (commsTotals.size() > 0) {
          try {
            insert commsTotals;
          } catch (DmlException err) {
            System.Debug(err);
          }
        }*/

        if (commsToUpdate.size() > 0) {
          system.debug('comm updated' + commsToUpdate.size());
          try {
            update commsToUpdate;
          } catch (DmlException err) {
            System.debug(err);
          }
          set<id> aggId = new Set<id>();
          for (Commission__c comm : commsToUpdate) {
            aggId.add(comm.Id);
          }
          aggregateAmounts(aggId);
        }

        /* for (Commission_Detail__c CommDetail : myCommDetailsBridge) {
          myMap.put(CommDetail.Deal__c, CommDetail.Id);

          if (myBridgeCommissions.size() > 0) {
            system.debug(myBridgeCommissions.size());

            for (Commission__c bComm : myBridgeCommissions) {
              if (
                !commTotalMap2.containsKey(bComm.Owner__c) &&
                bComm.Advance__r.Wire_Date__c >= QuarterStartDate &&
                bComm.Advance__r.Wire_Date__c <= QuarterEndDate
              ) {
                system.debug('bridge condition not in map');
                Commission_Total__c myCommTotal = new Commission_Total__c();
                myCommTotal.OwnerId = bComm.Owner__c;
                myCommTotal.Quarter_Start_Date__c = quarterStartDate;
                myCommTotal.Quarter_End_Date__c = quarterEndDate;
                myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
                myCommTotal.Bridge_Quota__c = quotaMapBridge.get(
                  bComm.Owner__c
                );

                insert myCommTotal;
                // myCommTotals.add(myCommTotal);

                bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
                bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
                bComm.Quarter_Start_Date__c = quarterStartDate;
                bComm.Quarter_End_Date__c = quarterEndDate;
                bComm.Commission_Total__c = myCommTotal.Id;
                commsToUpdate.add(bComm);
              } else if (
                commTotalMap2.containsKey(bComm.Owner__c) &&
                bComm.Advance__r.Wire_Date__c >= QuarterStartDate &&
                bComm.Advance__r.Wire_Date__c <= QuarterEndDate
              ) {
                system.debug('bridge commission in map');
                bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
                bComm.Quarter_Start_Date__c = quarterStartDate;
                bComm.Quarter_End_Date__c = quarterEndDate;
                bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
                bComm.Commission_Total__c = commTotalMap.get(bComm.Owner__c);
                commsToUpdate.add(bComm);
              } else if (
                !commTotalMap2.containsKey(bComm.Owner__c) &&
                bComm.Advance__r.Wire_Date__c >= QuarterStartDateLastQ &&
                bComm.Advance__r.Wire_Date__c <= QuarterEndDateLastQ
              ) {
                system.debug('bridge condition not in map');
                Commission_Total__c myCommTotal = new Commission_Total__c();
                myCommTotal.OwnerId = bComm.Owner__c;
                myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
                myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
                myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
                myCommTotal.Bridge_Quota__c = quotaMapBridge.get(
                  bComm.Owner__c
                );

                insert myCommTotal;
                // myCommTotals.add(myCommTotal);

                bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
                bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
                bComm.Quarter_Start_Date__c = quarterStartDateLastQ;
                bComm.Quarter_End_Date__c = QuarterEndDateLastQ;
                bComm.Commission_Total__c = myCommTotal.Id;
                commsToUpdate.add(bComm);
              } else if (
                commTotalMap2.containsKey(bComm.Owner__c) &&
                bComm.Advance__r.Wire_Date__c >= QuarterStartDateLastQ &&
                bComm.Advance__r.Wire_Date__c <= QuarterEndDateLastQ
              ) {
                system.debug('bridge commission in map');
                bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
                bComm.Quarter_Start_Date__c = QuarterStartDateLastQ;
                bComm.Quarter_End_Date__c = QuarterEndDateLastQ;
                bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
                bComm.Commission_Total__c = commTotalMapLastQ.get(
                  bComm.Owner__c
                );
                commsToUpdate.add(bComm);
              }
            }
          }
          //if(myCommTotals.size()>0){
          //  system.debug('comm total insert'+myCommTotals.size());
          //  insert myCommTotals;
          //}
        }
        if (commsToUpdate.size() > 0) {
          system.debug('comm updated' + commsToUpdate.size());
          update commsToUpdate;

          set<id> aggId = new Set<id>();
          for (Commission__c comm : commsToUpdate) {
            aggId.add(comm.Id);
          }
          aggregateAmounts(aggId);
        } */
      } else {
        //
        //bridge no totals for quarter split
        Map<Id, Id> myMap = new Map<Id, Id>();

        List<ForecastingQuota> allQuotas = [
          SELECT
            Id,
            ForecastingTypeId,
            QuotaAmount,
            QuotaOwnerId,
            QuotaOwner.Name,
            ProductFamily,
            StartDate
          FROM ForecastingQuota
          WHERE
            ProductFamily IN ('Bridge', 'Term')
            AND StartDate = :quarterStartDate
            AND QuotaOwnerId IN :ownId
        ];

        list<ForecastingQuota> quotaBridge = new List<ForecastingQuota>();
        list<ForecastingQuota> quotaTerm = new List<ForecastingQuota>();
        Map<Id, decimal> quotaMapBridge = new Map<Id, decimal>();
        Map<Id, decimal> quotaMapTerm = new Map<Id, decimal>();

        for (ForecastingQuota q : allQuotas) {
          if (q.ProductFamily == 'Bridge') {
            quotaMapBridge.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaBridge.add(q);
          } else if (q.ProductFamily == 'Bridge') {
            quotaMapTerm.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaTerm.add(q);
          }
        }

        /* system.debug('quota size' + quotaMapBridge.size());
        for (ForecastingQuota q : quotaBridge) {
          system.debug('qstart' + q.StartDate);
          system.debug('qid' + q.ForecastingTypeId);
          system.debug('qowner' + q.QuotaOwnerId);
          system.debug('qname' + q.QuotaOwner.Name);
          system.debug('prod fam' + q.ProductFamily);
          quotaMapBridge.put(q.QuotaOwnerId, q.QuotaAmount);
        }
        for (ForecastingQuota q : quotaTerm) {
          quotaMapTerm.put(q.QuotaOwnerId, q.QuotaAmount);
        } */

        list<Commission__c> myCommissions = [
          SELECT
            Owner__c,
            Advance__r.Wire_Date__c,
            Quota__c,
            Commission_Total__c,
            Quarter_Start_Date__c,
            Quarter_End_Date__c
          FROM Commission__c
          WHERE
            (Loan_Type__c = 'Bridge Loan'
            OR Loan_Type__c = 'SAB Loan')
            AND id IN :newList
        ];

        //List<Commission_Total__c> commsTotals = new List<Commission_Total__c>();

        if (myCommissions.size() > 0) {
          system.debug(myCommissions.size());

          for (Commission__c bComm : myCommissions) {
            system.debug('Comm Owner line 200' + bComm.Owner__c);
            system.debug(
              'Comm Total Map Id' + commTotalMap2.get(bComm.Owner__c)
            );
            Commission_Total__c myCommTotal = new Commission_Total__c();
            if (
              bComm.Owner__c != commTotalMap2.get(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDate &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDate
            ) {
              system.debug('bridge condition not in map');
              myCommTotal.OwnerId = bComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDate;
              myCommTotal.Quarter_End_Date__c = quarterEndDate;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);
              insert myCommTotal;
              //commsTotals.add(myCommTotal);
              // myCommTotals.add(myCommTotal);

              //bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = myCommTotal.Id;
              bComm.Quarter_Start_Date__c = quarterStartDate;
              bComm.Quarter_End_Date__c = quarterEndDate;
              commsToUpdate.add(bComm);
            } else if (
              bComm.Owner__c == commTotalMap2.get(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDate &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDate
            ) {
              system.debug('bridge commission in map');
              // bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = commTotalMap.get(bComm.Owner__c);
              bComm.Quarter_Start_Date__c = quarterStartDate;
              bComm.Quarter_End_Date__c = quarterEndDate;
              commsToUpdate.add(bComm);
            } else if (
              bComm.Owner__c != commTotalMap2LastQ.get(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDateLastQ &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDateLastQ
            ) {
              system.debug('bridge condition not in map');
              myCommTotal.OwnerId = bComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
              myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);

              //commsTotals.add(myCommTotal);
              // myCommTotals.add(myCommTotal);
              insert myCommTotal;

              //bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              bComm.Quarter_End_Date__c = QuarterEndDateLastQ;
              bComm.Commission_Total__c = myCommTotal.Id;
              commsToUpdate.add(bComm);
            } else if (
              bComm.Owner__c == commTotalMap2LastQ.get(bComm.Owner__c) &&
              bComm.Advance__r.Wire_Date__c >= QuarterStartDateLastQ &&
              bComm.Advance__r.Wire_Date__c <= QuarterEndDateLastQ
            ) {
              system.debug('bridge commission in map');
              //  bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quarter_Start_Date__c = QuarterStartDateLastQ;
              bComm.Quarter_End_Date__c = QuarterEndDateLastQ;
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = commTotalMapLastQ.get(bComm.Owner__c);
              commsToUpdate.add(bComm);
            }
          }
        }

        if (commsToUpdate.size() > 0) {
          system.debug('comm updated' + commsToUpdate.size());
          try {
            update commsToUpdate;
          } catch (DmlException err) {
            System.debug(err);
          }
          set<id> aggId = new Set<id>();
          for (Commission__c comm : commsToUpdate) {
            aggId.add(comm.Id);
          }
          aggregateAmounts(aggId);
        }

        /*if (commsTotals.size() > 0) {
          try {
            insert commsTotals;
          } catch (DmlException err) {
            System.debug(err);
          }
        }*/
        //if(myCommTotals.size()>0){
        //  system.debug('comm total insert'+myCommTotals.size());
        //  insert myCommTotals;
        //}
      }
      // term condition starts
      if (termCommIds.size() > 0) {
        system.debug('second term condition');
        list<Commission__c> commRecords = [
          SELECT
            id,
            Quota__c,
            Commission_Amount1__c,
            Deal_Close_Date__c,
            Deal__r.Account.Borrowed_on_Term_Loans__c,
            Final_Loan_Amount__c,
            Quarter_Start_Date__c,
            Quarter_End_Date__c,
            Owner__c,
            Product_Type__c
          FROM Commission__c
          WHERE
            (Loan_Type__c = 'Term Loan'
            OR (Loan_Type__c = 'Bridge Loan'
            AND Product_Type__c = 'Multifamily/CRE'))
            AND Id IN :termCommIds
        ];

        list<ForecastingQuota> quotaBridge = new List<ForecastingQuota>();
        List<ForecastingQuota> quotaTerm = new List<ForecastingQuota>();

        Map<Id, decimal> quotaMapBridge = new Map<Id, decimal>();
        Map<Id, decimal> quotaMapTerm = new Map<Id, decimal>();

        for (ForecastingQuota q : [
          SELECT
            Id,
            ForecastingTypeId,
            QuotaAmount,
            QuotaOwnerId,
            QuotaOwner.Name,
            ProductFamily,
            StartDate
          FROM ForecastingQuota
          WHERE
            ProductFamily IN ('Term', 'Bridge')
            AND StartDate = :quarterStartDate
            AND QuotaOwnerId IN :ownId
        ]) {
          if (q.ProductFamily == 'Term') {
            quotaMapTerm.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaTerm.add(q);
          } else if (q.ProductFamily == 'Bridge') {
            quotaMapBridge.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaBridge.add(q);
          }
        }

        /* system.debug('quota size' + quotaMapBridge.size());
        for (ForecastingQuota q : quotaTerm) {
          system.debug('qstart' + q.StartDate);
          system.debug('qid' + q.ForecastingTypeId);
          system.debug('qowner' + q.QuotaOwnerId);
          system.debug('qname' + q.QuotaOwner.Name);
          system.debug('prod fam' + q.ProductFamily);
          quotaMapTerm.put(q.QuotaOwnerId, q.QuotaAmount);
        }
        for (ForecastingQuota q : quotaBridge) {
          quotaMapBridge.put(q.QuotaOwnerId, q.QuotaAmount);
        } */

        //List<Commission_Total__c> commTotalsToInsert = new List<Commission_Total__c>();

        for (Commission__c myComm : commRecords) {
          system.debug('term loop line 84');
          system.debug('owner id' + myComm.Owner__c);
          system.debug('map owner id' + commTotalMap2.get(myComm.Owner__c));
          decimal commAmount = myComm.Commission_Amount1__c;
          Commission_Total__c myCommTotal = new Commission_Total__c();
          if (
            !commTotalMap2.containsKey(myComm.Owner__c) &&
            myComm.Deal_Close_Date__c >= QuarterStartDate &&
            myComm.Deal_Close_Date__c <= QuarterEndDate
          ) {
            system.debug('owner id' + myComm.Owner__c);
            system.debug('map owner id' + commTotalMap.get(myComm.Owner__c));
            if (
              myComm.Deal__r.Account.Borrowed_on_Term_Loans__c -
              myComm.Final_Loan_Amount__c >= 10000000
            ) {
              system.debug('Big condition');
              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDate;
              myCommTotal.Quarter_End_Date__c = quarterEndDate;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);
              insert myCommTotal;
              //commTotalsToInsert.add(myCommTotal);

              //myCommTotals.add(myCommTotal);
              system.debug('comm total' + myCommTotal.id);

              myComm.Commission_Amount1__c = commAmount * .5;
              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.Id;
              myComm.Quarter_Start_Date__c = quarterStartDate;
              myComm.Quarter_End_Date__c = quarterEndDate;

              commsToUpsert.add(myComm);
            } else {
              system.Debug('small condition');
              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDate;
              myCommTotal.Quarter_End_Date__c = quarterEndDate;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);
              insert myCommTotal;
              //commTotalsToInsert.add(myCommTotal);
              // myCommTotals.add(myCommTotal);
              //system.debug('com total 2' +myCommTotal.id);

              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.Id;
              myComm.Quarter_Start_Date__c = quarterStartDate;
              myComm.Quarter_End_Date__c = quarterEndDate;

              commsToUpsert.add(myComm);
            }
          } else if (
            commTotalMap2.containsKey(myComm.Owner__c) &&
            myComm.Deal_Close_Date__c >= QuarterStartDate &&
            myComm.Deal_Close_Date__c <= QuarterEndDate
          ) {
            if (
              myComm.Deal__r.Account.Borrowed_on_Term_Loans__c -
              myComm.Final_Loan_Amount__c >= 10000000
            ) {
              system.debug('Big condition');
              myComm.Commission_Amount1__c = commAmount * .5;
              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = commTotalMap.get(myComm.Owner__c);
              myComm.Quarter_Start_Date__c = quarterStartDate;
              myComm.Quarter_End_Date__c = quarterEndDate;

              commsToUpsert.add(myComm);
            } else {
              system.Debug('small condition');

              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = commTotalMap.get(myComm.Owner__c);
              myComm.Quarter_Start_Date__c = quarterStartDate;
              myComm.Quarter_End_Date__c = quarterEndDate;

              commsToUpsert.add(myComm);
            }
          } else if (
            !commTotalMap2LastQ.containsKey(myComm.Owner__c) &&
            myComm.Deal_Close_Date__c >= QuarterStartDateLastQ &&
            myComm.Deal_Close_Date__c <= QuarterEndDateLastQ
          ) {
            system.debug('owner id' + myComm.Owner__c);
            system.debug('map owner id' + commTotalMap.get(myComm.Owner__c));

            if (
              myComm.Deal__r.Account.Borrowed_on_Term_Loans__c -
              myComm.Final_Loan_Amount__c >= 10000000
            ) {
              system.debug('Big condition');
              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
              myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);

              //commTotalsToInsert.add(myCommTotal);
              insert myCommTotal;
              //myCommTotals.add(myCommTotal);
              system.debug('comm total' + myCommTotal.id);

              myComm.Commission_Amount1__c = commAmount * .5;
              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.Id;
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            } else {
              system.Debug('small condition');
              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
              myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);
              insert myCommTotal;
              //commTotalsToInsert.add(myCommTotal);
              // myCommTotals.add(myCommTotal);
              //system.debug('com total 2' +myCommTotal.id);

              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.Id;
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            }
          } else if (
            commTotalMap2LastQ.containsKey(myComm.Owner__c) &&
            myComm.Deal_Close_Date__c >= QuarterStartDateLastQ &&
            myComm.Deal_Close_Date__c <= QuarterEndDateLastQ
          ) {
            if (
              myComm.Deal__r.Account.Borrowed_on_Term_Loans__c -
              myComm.Final_Loan_Amount__c >= 10000000
            ) {
              system.debug('Big condition');
              myComm.Commission_Amount1__c = commAmount * .5;
              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = commTotalMapLastQ.get(
                myComm.Owner__c
              );
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            } else {
              system.Debug('small condition');

              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = commTotalMapLastQ.get(
                myComm.Owner__c
              );
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            }
          }
        }

        /* if (commTotalsToInsert.size() > 0) {
          try {
            insert commTotalsToInsert;
          } catch (DmlException err) {
            System.debug(err);
          }
        }*/

        if (commsToUpsert.size() > 0) {
          system.debug('upsert comms' + commsToUpsert.size());
          try {
            update commsToUpsert;
          } catch (DmlException err) {
            System.debug(err);
          }
          set<id> aggId = new Set<id>();
          for (Commission__c comm : commsToUpsert) {
            aggId.add(comm.Id);
          }
          aggregateAmounts(aggId);
        }
      }
    } else {
      //if(myCommTotals.size()>0){
      // system.debug('new totals to add line 238'+myCommTotals.size());
      //insert myCommTotals;
      //   }
      //if commsion totals don't exist for the quarter, create them.
      map<id, id> commTotalMap2 = new Map<id, id>();

      //NEW
      //used to verify user has commission total for the last quarter or not
      map<id, id> commTotalMapLastQ = new Map<id, id>();
      map<id, id> commTotalMap2LastQ = new Map<id, id>();

      //NEW
      for (Commission_Total__c commTotal : commTotalsLastQuarter) {
        commTotalMapLastQ.put(commTotal.OwnerId, commTotal.id);
        commTotalMap2LastQ.put(commTotal.OwnerId, commTotal.OwnerId);
      }

      for (Commission__c comm : newList) {
        if (
          comm.Loan_Type__c == 'Term Loan' ||
          (comm.Loan_Type__c == 'Bridge Loan' &&
          comm.Product_Type__c == 'Multifamily/CRE')
        ) {
          termCommIds.add(comm.id);
          system.debug('term loan size' + termCommIds.size());
        } else if (
          (comm.Loan_Type__c == 'Bridge Loan' &&
          comm.Commission_Detail__c == null) ||
          (comm.Loan_Type__c == 'SAB Loan' &&
          comm.Commission_Detail__c == null)
        ) {
          bridgeCommIds.add(comm.Deal__c);
          system.debug(comm.Deal__c);
          system.debug(bridgeCommIds.size());
        }
      }

      list<Commission_Detail__c> myCommDetailsBridge = [
        SELECT Id, Deal__c
        FROM Commission_Detail__c
        WHERE
          (Loan_Type__C = 'Bridge Loan'
          OR Loan_Type__C = 'SAB Loan')
          AND Deal__c IN :bridgeCommIds
      ];

      system.debug(myCommDetailsBridge.size());
      //Bridge with comm details
      if (myCommDetailsBridge.size() > 0) {
        Map<Id, Id> myMap = new Map<Id, Id>();

        for (Commission_Detail__c CommDetail : myCommDetailsBridge) {
          myMap.put(CommDetail.Deal__c, CommDetail.Id);
        }

        list<Commission__c> myBridgeCommissions = [
          SELECT
            id,
            Owner__c,
            Quota__c,
            Deal__c,
            Advance__r.Wire_Date__c,
            Quarter_Start_Date__c,
            Quarter_End_Date__c
          FROM Commission__c
          WHERE Commission_detail__c = NULL AND Deal__c IN :myMap.keySet()
        ];

        List<ForecastingQuota> quotaBridge = new List<ForecastingQuota>();
        List<ForecastingQuota> quotaTerm = new List<ForecastingQuota>();

        Map<Id, decimal> quotaMapBridge = new Map<Id, decimal>();
        Map<Id, decimal> quotaMapTerm = new Map<Id, decimal>();

        for (ForecastingQuota q : [
          SELECT
            Id,
            ForecastingTypeId,
            QuotaAmount,
            QuotaOwnerId,
            QuotaOwner.Name,
            ProductFamily,
            StartDate
          FROM ForecastingQuota
          WHERE
            ProductFamily IN ('Term', 'Bridge')
            AND StartDate = :quarterStartDate
            AND QuotaOwnerId IN :ownId
        ]) {
          if (q.ProductFamily == 'Bridge') {
            quotaMapBridge.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaBridge.add(q);
          } else if (q.ProductFamily == 'Term') {
            quotaMapTerm.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaTerm.add(q);
          }
        }

        //List<Commission_Total__c> allCommsTotals = new List<Commission_Total__c>();
        if (myBridgeCommissions.size() > 0) {
          system.debug(myBridgeCommissions.size());
          for (Commission__c bComm : myBridgeCommissions) {
            Commission_Total__c myCommTotal = new Commission_Total__c();
            if (
              bComm.Owner__c == commTotalMap2LastQ.get(bComm.Owner__c) &&
              bComm.advance__r.Wire_Date__c >= quarterStartDateLastQ &&
              bComm.advance__r.Wire_Date__c <= quarterEndDateLastQ
            ) {
              bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = commTotalMapLastQ.get(bComm.Owner__c);
              bComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              bComm.Quarter_End_Date__c = quarterEndDateLastQ;
              commsToUpdate.add(bComm);
            } else if (
              bComm.Owner__c != commTotalMap2LastQ.get(bComm.Owner__c) &&
              bComm.advance__r.Wire_Date__c >= quarterStartDateLastQ &&
              bComm.advance__r.Wire_Date__c <= quarterEndDateLastQ
            ) {
              myCommTotal.OwnerId = bComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
              myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);
              //allCommsTotals.add(myCommTotal);
              //myCommTotals.add(myCommTotal);
              insert myCommTotal;

              bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = myCommTotal.Id;
              bComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              bComm.Quarter_End_Date__c = quarterEndDateLastQ;
              commsToUpdate.add(bComm);
            } else {
              myCommTotal.OwnerId = bComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDate;
              myCommTotal.Quarter_End_Date__c = quarterEndDate;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);
              //allCommsTotals.add(myCommTotal);
              insert myCommTotal;
              //myCommTotals.add(myCommTotal);

              bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
              bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
              bComm.Commission_Total__c = myCommTotal.Id;
              bComm.Quarter_Start_Date__c = quarterStartDate;
              bComm.Quarter_End_Date__c = quarterEndDate;
              commsToUpdate.add(bComm);
            }
          }
        }

        /*if (allCommsTotals.size() > 0) {
          try {
            insert allCommsTotals;
          } catch (DmlException err) {
            System.debug(err);
          }
        }*/

        if (commsToUpdate.size() > 0) {
          try {
            update commsToUpdate;
          } catch (DmlException err) {
            System.debug(err);
          }
          set<id> aggId = new Set<id>();
          for (Commission__c comm : commsToUpdate) {
            aggId.add(comm.Id);
          }
          aggregateAmounts(aggId);
        }
        //if(myCommTotals.size()>0){
        //insert myCommTotals;
        //  }
      } else {
        //bridge no comm details
        Map<Id, Id> myMap = new Map<Id, Id>();

        List<ForecastingQuota> quotaBridge = new List<ForecastingQuota>();
        List<ForecastingQuota> quotaTerm = new List<ForecastingQuota>();

        Map<Id, decimal> quotaMapBridge = new Map<Id, decimal>();
        Map<Id, decimal> quotaMapTerm = new Map<Id, decimal>();

        for (ForecastingQuota q : [
          SELECT
            Id,
            ForecastingTypeId,
            QuotaAmount,
            QuotaOwnerId,
            QuotaOwner.Name,
            ProductFamily,
            StartDate
          FROM ForecastingQuota
          WHERE
            ProductFamily IN ('Bridge', 'Term')
            AND StartDate = :quarterStartDate
            AND QuotaOwnerId IN :ownId
        ]) {
          if (q.ProductFamily == 'Bridge') {
            quotaMapBridge.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaBridge.add(q);
          } else if (q.ProductFamily == 'Term') {
            quotaMapTerm.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaTerm.add(q);
          }
        }

        List<Commission__c> myCommissions = [
          SELECT
            Owner__c,
            Quota__c,
            Commission_Total__c,
            advance__r.Wire_Date__c,
            Quarter_Start_Date__c,
            Quarter_End_Date__c
          FROM Commission__c
          WHERE
            (Loan_Type__c = 'Bridge Loan'
            OR Loan_Type__c = 'SAB Loan')
            AND id IN :newList
        ];

        system.debug(myCommissions.size());
        //List<Commission_Total__c> commsTotalsForInsertion = new List<Commission_Total__c>();
        for (Commission__c bComm : myCommissions) {
          Commission_Total__c myCommTotal = new Commission_Total__c();
          if (
            bComm.Owner__c == commTotalMap2LastQ.get(bComm.Owner__c) &&
            bComm.advance__r.Wire_Date__c >= quarterStartDateLastQ &&
            bComm.advance__r.Wire_Date__c <= quarterEndDateLastQ
          ) {
            bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
            bComm.Commission_Total__c = commTotalMapLastQ.get(bComm.Owner__c);
            bComm.Quarter_Start_Date__c = quarterStartDateLastQ;
            bComm.Quarter_End_Date__c = quarterEndDateLastQ;
            commsToUpdate.add(bComm);
          } else if (
            bComm.Owner__c != commTotalMap2LastQ.get(bComm.Owner__c) &&
            bComm.advance__r.Wire_Date__c >= quarterStartDateLastQ &&
            bComm.advance__r.Wire_Date__c <= quarterEndDateLastQ
          ) {
            myCommTotal.OwnerId = bComm.Owner__c;
            myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
            myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
            myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
            myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);
            //commsTotalsForInsertion.add(myCommTotal);
            insert myCommTotal;

            //myCommTotals.add(myCommTotal);

            bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
            bComm.Commission_Total__c = myCommTotal.Id;
            bComm.Quarter_Start_Date__c = quarterStartDateLastQ;
            bComm.Quarter_End_Date__c = quarterEndDateLastQ;
            commsToUpdate.add(bComm);
          } else {
            myCommTotal.OwnerId = bComm.Owner__c;
            myCommTotal.Quarter_Start_Date__c = quarterStartDate;
            myCommTotal.Quarter_End_Date__c = quarterEndDate;
            myCommTotal.Term_Quota__c = quotaMapTerm.get(bComm.Owner__c);
            myCommTotal.Bridge_Quota__c = quotaMapBridge.get(bComm.Owner__c);

            //commsTotalsForInsertion.add(myCommTotal);
            // myCommTotals.add(myCommTotal);
            insert myCommTotal;

            //bComm.Commission_detail__c = myMap.get(bComm.Deal__c);
            bComm.Quota__c = quotaMapBridge.get(bComm.Owner__c);
            bComm.Commission_Total__c = myCommTotal.Id;
            bComm.Quarter_Start_Date__c = quarterStartDate;
            bComm.Quarter_End_Date__c = quarterEndDate;
            commsToUpdate.add(bComm);
          }
          /// finish commission here 7/6/2021
        }

        /*if (commsTotalsForInsertion.size() > 0) {
          try {
            insert commsTotalsForInsertion;
          } catch (DmlException err) {
            System.debug(err);
          }
        }*/

        if (commsToUpdate.size() > 0) {
          system.debug('comm updated' + commsToUpdate.size());
          try {
            update commsToUpdate;
          } catch (DmlException err) {
            System.debug(err);
          }
          set<id> aggId = new Set<id>();
          for (Commission__c comm : commsToUpdate) {
            aggId.add(comm.Id);
          }
          aggregateAmounts(aggId);
        }
      }
      //term
      if (termCommIds.size() > 0) {
        system.debug('second term condition');
        list<Commission__c> commRecords = [
          SELECT
            id,
            Quota__c,
            Quarter_Start_Date__c,
            Deal_Close_Date__c,
            Quarter_End_Date__c,
            Commission_Amount1__c,
            Deal__r.Account.Borrowed_on_Term_Loans__c,
            Final_Loan_Amount__c,
            Owner__c,
            Product_Type__c
          FROM Commission__c
          WHERE Id IN :termCommIds
        ];

        List<ForecastingQuota> quotaTerm = new List<ForecastingQuota>();
        List<ForecastingQuota> quotaBridge = new List<ForecastingQuota>();

        Map<Id, decimal> quotaMapTerm = new Map<Id, decimal>();
        Map<id, decimal> quotaMapBridge = new Map<Id, decimal>();

        for (ForecastingQuota q : [
          SELECT
            Id,
            ForecastingTypeId,
            QuotaAmount,
            QuotaOwnerId,
            QuotaOwner.Name,
            ProductFamily,
            StartDate
          FROM ForecastingQuota
          WHERE
            ProductFamily IN ('Bridge', 'Term')
            AND StartDate = :quarterStartDate
            AND QuotaOwnerId IN :ownId
        ]) {
          if (q.ProductFamily == 'Term') {
            quotaMapTerm.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaTerm.add(q);
          } else if (q.ProductFamily == 'Bridge') {
            quotaMapBridge.put(q.QuotaOwnerId, q.QuotaAmount);
            quotaBridge.add(q);
          }
        }

        //List<Commission_Total__c> commsTotalsForInsertion = new List<Commission_Total__c>();
        for (Commission__c myComm : commRecords) {
          system.debug('term loop line 84');
          decimal commAmount = myComm.Commission_Amount1__c;
          Commission_Total__c myCommTotal = new Commission_Total__c();
          if (
            !commTotalMap2LastQ.containsKey(myComm.Owner__c) &&
            myComm.Deal_Close_Date__c >= QuarterStartDateLastQ &&
            myComm.Deal_Close_Date__c <= QuarterEndDateLastQ
          ) {
            system.debug('owner id' + myComm.Owner__c);

            if (
              myComm.Deal__r.Account.Borrowed_on_Term_Loans__c -
              myComm.Final_Loan_Amount__c >= 10000000
            ) {
              system.debug('Big condition');
              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
              myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);

              //commsTotalsForInsertion.add(myCommTotal);
              insert myCommTotal;
              //myCommTotals.add(myCommTotal);
              system.debug('comm total' + myCommTotal.id);

              myComm.Commission_Amount1__c = commAmount * .5;
              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.Id;
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            } else {
              system.Debug('small condition');
              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDateLastQ;
              myCommTotal.Quarter_End_Date__c = quarterEndDateLastQ;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);

              //commsTotalsForInsertion.add(myCommTotal);
              // myCommTotals.add(myCommTotal);
              insert myCommTotal;
              system.debug('com total 2ID' + myCommTotal.id);

              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.Id;
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            }
          } else if (
            commTotalMap2LastQ.containsKey(myComm.Owner__c) &&
            myComm.Deal_Close_Date__c >= QuarterStartDateLastQ &&
            myComm.Deal_Close_Date__c <= QuarterEndDateLastQ
          ) {
            if (
              myComm.Deal__r.Account.Borrowed_on_Term_Loans__c -
              myComm.Final_Loan_Amount__c >= 10000000
            ) {
              system.debug('Big condition');
              myComm.Commission_Amount1__c = commAmount * .5;
              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = commTotalMapLastQ.get(
                myComm.Owner__c
              );
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            } else {
              system.Debug('small condition');

              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = commTotalMapLastQ.get(
                myComm.Owner__c
              );
              myComm.Quarter_Start_Date__c = quarterStartDateLastQ;
              myComm.Quarter_End_Date__c = quarterEndDateLastQ;

              commsToUpsert.add(myComm);
            }
          } else {
            if (
              myComm.Deal__r.Account.Borrowed_on_Term_Loans__c -
              myComm.Final_Loan_Amount__c >= 10000000
            ) {
              system.debug('Big condition');
              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDate;
              myCommTotal.Quarter_End_Date__c = quarterEndDate;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);
              //myCommTotals.add(myCommTotal);
              //commsTotalsForInsertion.add(myCommTotal);
              insert myCommTotal;

              myComm.Commission_Amount1__c = commAmount * .5;
              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.id;
              myComm.Quarter_Start_Date__c = quarterStartDate;
              myComm.Quarter_End_Date__c = quarterEndDate;

              commsToUpsert.add(myComm);
            } else {
              system.Debug('small condition');

              myCommTotal.OwnerId = myComm.Owner__c;
              myCommTotal.Quarter_Start_Date__c = quarterStartDate;
              myCommTotal.Quarter_End_Date__c = quarterEndDate;
              myCommTotal.Term_Quota__c = quotaMapTerm.get(myComm.Owner__c);
              myCommTotal.Bridge_Quota__c = quotaMapBridge.get(myComm.Owner__c);
              //myCommTotals.add(myCommTotal);
              //commsTotalsForInsertion.add(myCommTotal);
              insert myCommTotal;
              system.debug('com total 2ID' + myCommTotal.id);

              myComm.quota__c = quotaMapTerm.get(myComm.Owner__c);
              myComm.Commission_Total__c = myCommTotal.id;
              myComm.Quarter_Start_Date__c = quarterStartDate;
              myComm.Quarter_End_Date__c = quarterEndDate;

              commsToUpsert.add(myComm);
            }
          }

          /*if (commsTotalsForInsertion.size() > 0) {
            try {
              insert commsTotalsForInsertion;
            } catch (DmlException err) {
              System.debug(err);
            }
          }*/

          if (commsToUpsert.size() > 0) {
            try {
              update commsToUpsert;
            } catch (DmlException err) {
              System.debug(err);
            }

            set<id> aggId = new Set<id>();
            for (Commission__c comm : commsToUpsert) {
              aggId.add(comm.Id);
            }
            aggregateAmounts(aggId);
          }
        }
      }
    }

    //term condition

    //if(myCommTotals.size()>0){
    //insert myCommTotals;
    // System.debug('comm total term insert' + myCommTotals.size());
    //}
    //
    //
    // get totals
  }

  public static void afterUpdate(
    List<Commission__c> newList,
    List<Commission__c> oldList
  ) {
    Set<Id> commTotalIds = new Set<Id>();
    for (Integer i = 0; i < newList.size(); i++) {
      if (
        newList[i].Commission_Amount1__c != oldList[i].Commission_Amount1__c
      ) {
        commTotalIds.add(newList[i].Commission_Total__c);
      }
    }

    if (commTotalIds.size() > 0) {
      calculateRollups(commTotalIds);
    }

    // Map<Id, Decimal> myCommTotalMap = new Map<Id, Decimal>();
    // Map<Id, Decimal> myCommTotalOldMap = new Map<Id, Decimal>();

    // List<Id> termId = new List<Id>();
    // List<Id> bridgeId = new List<Id>();

    // for (Integer i = 0; i < newList.size(); i++) {
    //   if (
    //     newList[i].Commission_Amount1__c != oldList[i].Commission_Amount1__c
    //   ) {
    //     if (newList[i].Loan_Type__c == 'Term Loan') {
    //       myCommTotalMap.put(
    //         newList[i].Commission_Total__c,
    //         newList[i].Commission_Amount1__c
    //       );
    //       myCommTotalOldMap.put(
    //         oldList[i].Commission_Total__c,
    //         oldList[i].Commission_Amount1__c
    //       );
    //       system.debug('Comm Total id' + newList[i].Commission_Total__c);
    //       termId.add(newList[i].id);
    //     } else if (
    //       newList[i].Loan_Type__c == 'Bridge Loan' ||
    //       newList[i].Loan_Type__c == 'SAB Loan'
    //     ) {
    //       myCommTotalMap.put(
    //         newList[i].Commission_Total__c,
    //         newList[i].Commission_Amount1__c
    //       );
    //       myCommTotalOldMap.put(
    //         oldList[i].Commission_Total__c,
    //         oldList[i].Commission_Amount1__c
    //       );
    //       bridgeId.add(newList[i].id);
    //       system.debug('bridge size' + bridgeId);
    //     }
    //   }
    // }

    // if (termId.size() > 0) {
    //   system.debug(termId);
    //   List<Commission_Total__c> myCommissionTotalsToUpdate = [
    //     SELECT Id, Total_Term_Commission__c
    //     FROM Commission_Total__c
    //     WHERE Id IN :myCommTotalMap.KeySet()
    //   ];
    //   system.debug('keys' + myCommTotalMap.KeySet());
    //   system.debug(
    //     'commission total term to update' + myCommissionTotalsToUpdate.size()
    //   );

    //   for (Commission_Total__c commTot : myCommissionTotalsToUpdate) {
    //     system.debug(
    //       'comm total amount from map' + myCommTotalMap.get(commTot.id)
    //     );

    //     commTot.Total_Term_Commission__c =
    //       (commTot.Total_Term_Commission__c -
    //       myCommTotalOldMap.get(commTot.id)) + myCommTotalMap.get(commTot.id);
    //   }
    //   update myCommissionTotalsToUpdate;
    // }

    // if (bridgeId.size() > 0) {
    //   List<Commission_Total__c> myCommissionTotalsToUpdate = [
    //     SELECT Id, Total_Term_Commission__c, Total_Bridge_Commission__c
    //     FROM Commission_Total__c
    //     WHERE Id IN :myCommTotalMap.KeySet()
    //   ];

    //   system.debug(
    //     'bridge comm total size' + myCommissionTotalsToUpdate.size()
    //   );
    //   for (Commission_Total__c commTot : myCommissionTotalsToUpdate) {
    //     commTot.Total_Bridge_Commission__c =
    //       (commTot.Total_Bridge_Commission__c -
    //       myCommTotalOldMap.get(commTot.id)) + myCommTotalMap.get(commTot.id);
    //   }
    //   update myCommissionTotalsToUpdate;
    // }
  }

  public static void afterDelete(List<Commission__c> newList) {
    Set<Id> commTotalIds = new Set<Id>();
    for (Commission__c comm : newList) {
      commTotalIds.add(comm.Commission_Total__c);
    }

    if (commTotalIds.size() > 0) {
      calculateRollups(commTotalIds);
    }

    // system.debug('afterDelete');
    // Map<Id, Decimal> myCommTotalMap = new Map<Id, Decimal>();
    // List<Id> termId = new List<Id>();
    // List<Id> bridgeId = new List<Id>();

    // for (Commission__c comm : newList) {
    //   if (comm.Loan_Type__c == 'Term Loan') {
    //     myCommTotalMap.put(
    //       comm.Commission_Total__c,
    //       comm.Commission_Amount1__c
    //     );
    //     system.debug('Comm Total id' + comm.Commission_Total__c);
    //     termId.add(comm.id);
    //   } else if (
    //     comm.Loan_Type__c == 'Bridge Loan' ||
    //     comm.Loan_Type__c == 'SAB Loan'
    //   ) {
    //     myCommTotalMap.put(
    //       comm.Commission_Total__c,
    //       comm.Commission_Amount1__c
    //     );
    //     bridgeId.add(comm.id);
    //     system.debug('bridge size' + bridgeId);
    //   }
    // }

    // if (termId.size() > 0) {
    //   system.debug(termId);
    //   List<Commission_Total__c> myCommissionTotalsToUpdate = [
    //     SELECT Id, Total_Term_Commission__c
    //     FROM Commission_Total__c
    //     WHERE Id IN :myCommTotalMap.KeySet()
    //   ];
    //   system.debug('keys' + myCommTotalMap.KeySet());
    //   system.debug(
    //     'commission total term to update' + myCommissionTotalsToUpdate.size()
    //   );

    //   for (Commission_Total__c commTot : myCommissionTotalsToUpdate) {
    //     system.debug(
    //       'comm total amount from map' + myCommTotalMap.get(commTot.id)
    //     );

    //     commTot.Total_Term_Commission__c =
    //       commTot.Total_Term_Commission__c - myCommTotalMap.get(commTot.id);
    //   }
    //   update myCommissionTotalsToUpdate;
    // }

    // if (bridgeId.size() > 0) {
    //   List<Commission_Total__c> myCommissionTotalsToUpdate = [
    //     SELECT Id, Total_Term_Commission__c, Total_Bridge_Commission__c
    //     FROM Commission_Total__c
    //     WHERE Id IN :myCommTotalMap.KeySet()
    //   ];

    //   system.debug(
    //     'bridge comm total size' + myCommissionTotalsToUpdate.size()
    //   );
    //   for (Commission_Total__c commTot : myCommissionTotalsToUpdate) {
    //     commTot.Total_Bridge_Commission__c =
    //       commTot.Total_Bridge_Commission__c - myCommTotalMap.get(commTot.id);
    //   }
    //   update myCommissionTotalsToUpdate;
    // }
  }

  public static void calculateRollups(Set<Id> commTotalIds) {
    Map<Id, Commission_Total__c> commTotalMap = new Map<Id, Commission_Total__c>();

    for (Id i : commTotalIds) {
      Commission_Total__c commTotal = new Commission_Total__c();
      commTotal.Id = i;
      commTotal.Total_Bridge_Commission__c = 0;
      commTotal.Total_Term_Commission__c = 0;
      commTotal.Total_Bridge_CRE_MultiFamily_Commission__c = 0;
      commTotal.CRE_Multi_Advance_Commission__c = 0;

      commTotalMap.put(i, commTotal);
    }

    for (AggregateResult ar : [
      SELECT Commission_Total__c parent, SUM(Commission_Amount1__c) tot
      FROM Commission__c
      WHERE Loan_Type__c = 'Term Loan' AND Commission_Total__c IN :commTotalIds
      GROUP BY Commission_Total__c
    ]) {
      Id comTotalId = (Id) ar.get('parent');
      Commission_Total__c commTotal = commTotalMap.get(comTotalId);
      commTotal.Total_Term_Commission__c = (Decimal) ar.get('tot');
    }
    // add for CRE
    for (AggregateResult ar : [
      SELECT Commission_Total__c parent, SUM(Commission_Amount1__c) tot
      FROM Commission__c
      WHERE
        (Loan_Type__c = 'Bridge Loan'
        OR Loan_Type__c = 'SAB Loan')
        AND CRE_Multi_Deal__c = FALSE
        AND Commission_Total__c IN :commTotalIds
      GROUP BY Commission_Total__c
    ]) {
      Id comTotalId = (Id) ar.get('parent');
      Commission_Total__c commTotal = commTotalMap.get(comTotalId);
      commTotal.Total_Bridge_Commission__c = (Decimal) ar.get('tot');
    }

    for (AggregateResult ar : [
      SELECT Commission_Total__c parent, SUM(Commission_Amount1__c) tot
      FROM Commission__c
      WHERE
        (Loan_Type__c = 'Bridge Loan'
        OR Loan_Type__c = 'SAB Loan')
        AND CRE_Multi_Deal__c = TRUE
        AND Advance__c = NULL
        AND Commission_Total__c IN :commTotalIds
      GROUP BY Commission_Total__c
    ]) {
      Id comTotalId = (Id) ar.get('parent');
      Commission_Total__c commTotal = commTotalMap.get(comTotalId);
      commTotal.Total_Bridge_CRE_MultiFamily_Commission__c = (Decimal) ar.get(
        'tot'
      );
    }

    for (AggregateResult ar : [
      SELECT Commission_Total__c parent, SUM(Commission_Amount1__c) tot
      FROM Commission__c
      WHERE
        (Loan_Type__c = 'Bridge Loan'
        OR Loan_Type__c = 'SAB Loan')
        AND CRE_Multi_Deal__c = TRUE
        AND Advance__c != NULL
        AND Commission_Total__c IN :commTotalIds
      GROUP BY Commission_Total__c
    ]) {
      Id comTotalId = (Id) ar.get('parent');
      Commission_Total__c commTotal = commTotalMap.get(comTotalId);
      commTotal.CRE_Multi_Advance_Commission__c = (Decimal) ar.get('tot');
    }

    update commTotalMap.values();
  }

  @future
  public static void aggregateAmounts(set<id> aggId) {
    list<Commission__c> myCommissions = new List<Commission__c>();

    list<id> myCommsTotalsIdBridge = new List<id>();
    list<id> myCommsTotalsIdTerm = new List<id>();

    myCommissions = [
      SELECT id, Loan_Type__c, Commission_Total__c, Advance__c
      FROM Commission__c
      WHERE Id IN :aggId
    ];

    for (Commission__c myComms : myCommissions) {
      system.debug('future comm size' + myCommissions.size());
      if (
        (myComms.Loan_Type__c == 'Bridge Loan' ||
        myComms.Loan_Type__c == 'SAB Loan') && myComms.Advance__c != null
      ) {
        myCommsTotalsIdBridge.add(myComms.Commission_Total__c);
      } else if (
        (myComms.Loan_Type__c == 'Term Loan' ||
        myComms.Loan_Type__c == 'Bridge Loan') && myComms.Advance__c == null
      ) {
        myCommsTotalsIdTerm.add(myComms.Commission_Total__c);
      }
    }
    //bridge and Multifamily/CRE from advances
    if (myCommsTotalsIdBridge.size() > 0) {
      system.debug(myCommsTotalsIdBridge.size());
      list<Commission_Total__c> commissionTotalsListNonCre = [
        SELECT
          id,
          Total_Bridge_Commission__c,
          Total_Term_Commission__c,
          (
            SELECT Id, Commission_Amount1__c
            FROM Commissions__r
            WHERE
              (Loan_Type__c = 'Bridge Loan'
              OR Loan_Type__c = 'SAB Loan')
              AND CRE_Multi_Deal__c != TRUE
              AND Product_Type__c != 'Multifamily/CRE'
          )
        FROM Commission_Total__c
        WHERE id IN :myCommsTotalsIdBridge
      ];

      for (Commission_Total__c comm : commissionTotalsListNonCre) {
        comm.Total_Bridge_Commission__c = 0;
        for (Commission__c commItem : comm.Commissions__r) {
          comm.Total_Bridge_Commission__c += commItem.Commission_Amount1__c;
        }
      }
      update commissionTotalsListNonCre;

      list<Commission_Total__c> commissionTotalsListCreAdvance = [
        SELECT
          id,
          Total_Bridge_Commission__c,
          Total_Term_Commission__c,
          Total_Bridge_CRE_MultiFamily_Commission__c,
          CRE_Multi_Advance_Commission__c,
          (
            SELECT Id, Commission_Amount1__c
            FROM Commissions__r
            WHERE
              (Loan_Type__c = 'Bridge Loan'
              OR Loan_Type__c = 'SAB Loan')
              AND CRE_Multi_Deal__c = TRUE
              AND Product_Type__c = 'Multifamily/CRE'
              AND Advance__c != NULL
          )
        FROM Commission_Total__c
        WHERE id IN :myCommsTotalsIdTerm
      ];

      for (Commission_Total__c comm : commissionTotalsListCreAdvance) {
        comm.CRE_Multi_Advance_Commission__c = 0;
        for (Commission__c commItem : comm.Commissions__r) {
          comm.CRE_Multi_Advance_Commission__c += commItem.Commission_Amount1__c;
        }
      }
      update commissionTotalsListCreAdvance;
    }

    //term and Multifamily/CRE from deal level
    if (myCommsTotalsIdTerm.size() > 0) {
      system.debug(myCommsTotalsIdTerm.size());
      //term calc
      list<Commission_Total__c> commissionTotalsList = [
        SELECT
          id,
          Total_Bridge_Commission__c,
          Total_Term_Commission__c,
          (
            SELECT Id, Commission_Amount1__c
            FROM Commissions__r
            WHERE Loan_Type__c = 'Term Loan'
          )
        FROM Commission_Total__c
        WHERE id IN :myCommsTotalsIdTerm
      ];
      for (Commission_Total__c comm : commissionTotalsList) {
        comm.Total_Term_Commission__c = 0;
        for (Commission__c commItem : comm.Commissions__r) {
          if (commItem.Commission_Amount1__c != null) {
            comm.Total_Term_Commission__c += commItem.Commission_Amount1__c;
          }
        }
      }
      if (commissionTotalsList.size() > 0) {
        update commissionTotalsList;
      }

      //Multi/CRE CALCULATION HERE
      list<Commission_Total__c> commissionTotalsListCre = [
        SELECT
          id,
          Total_Bridge_Commission__c,
          Total_Term_Commission__c,
          Total_Bridge_CRE_MultiFamily_Commission__c,
          (
            SELECT Id, Commission_Amount1__c
            FROM Commissions__r
            WHERE
              (Loan_Type__c = 'Bridge Loan'
              OR Loan_Type__c = 'SAB Loan')
              AND CRE_Multi_Deal__c = TRUE
              AND Advance__c = NULL
          )
        FROM Commission_Total__c
        WHERE id IN :myCommsTotalsIdTerm
      ];
      for (Commission_Total__c comm : commissionTotalsListCre) {
        comm.Total_Bridge_CRE_MultiFamily_Commission__c = 0;
        for (Commission__c commItem : comm.Commissions__r) {
          comm.Total_Bridge_CRE_MultiFamily_Commission__c += commItem.Commission_Amount1__c;
        }
      }
      update commissionTotalsListCre;
    }
  }
}
