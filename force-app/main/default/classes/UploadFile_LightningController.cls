public class UploadFile_LightningController {
	// @AuraEnabled
	// public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
	//     base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
	// 	System.debug('this is the parentId');
	// 	System.debug(parentId);
	// 	ProcessInstanceWorkItem piw = [
	// 		SELECT ProcessInstance.TargetObjectId
	// 		FROM ProcessInstanceWorkItem
	// 		WHERE Id = :parentId
	// 		LIMIT 1
	// 	];
  //
	// 	ContentVersion cv = new ContentVersion(
	// 		VersionData = EncodingUtil.base64Decode(base64Data),
	// 		PathOnClient = fileName,
	// 		Title = fileName
	// 	);
  //
	//     insert cv;
  //
	// 	ContentVersion queryCv = [
	// 		SELECT ContentDocumentId
	// 		FROM ContentVersion
	// 		WHERE Id = :cv.Id
	// 		LIMIT 1
	// 	];
  //
	// 	Deal_Document__c dd = new Deal_Document__c(
	// 		File_Name__c = fileName,
	// 		ContentVersion_Id__c = queryCv.ContentDocumentId,
	// 		Attachment_Id__c = queryCv.ContentDocumentId,
	// 		Type__c = 'Approval Uploads',
	// 		Section__c = 'Approval Uploads',
	// 		Deal__c = piw.ProcessInstance.TargetObjectId
	// 	);
  //
	// 	insert dd;
  //
	// 	System.debug('this is the dd');
	// 	System.debug(dd);
  //
	// 	ContentDocumentLink cdl = new ContentDocumentLink(
	// 		ContentDocumentId = queryCv.ContentDocumentId,
	// 		LinkedEntityId = piw.ProcessInstance.TargetObjectId,
	// 		ShareType = 'V'
	// 	);
	// 	insert cdl;
  //
  //
	//     // Attachment a = new Attachment();
	//     // a.parentId = parentId;
	// 	//
	//     // a.Body = EncodingUtil.base64Decode(base64Data);
	//     // a.Name = fileName;
	//     // a.ContentType = contentType;
  //
	//     return cv.Id;
	// }

	// @AuraEnabled
	// public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
	//     if (fileId == '') {
	//         fileId = saveTheFile(parentId, fileName, base64Data, contentType);
	//     } else {
	//         appendToFile(fileId, base64Data);
	//     }
  //
	//     return Id.valueOf(fileId);
	// }

	// private static void appendToFile(Id fileId, String base64Data) {
	//     base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
  //
	//     // Attachment a = [
	//     //     SELECT Id, Body
	//     //     FROM Attachment
	//     //     WHERE Id = :fileId
	//     // ];
  //
	// 	ContentVersion cv = [
	// 		SELECT Id, VersionData
	// 		FROM ContentVersion
	// 		WHERE Id = :fileId
	// 	];
  //
	// 	String existingBody = EncodingUtil.base64Encode(cv.VersionData);
	//     cv.VersionData = EncodingUtil.base64Decode(existingBody + base64Data);
  //
	// 	// 	String existingBody = EncodingUtil.base64Encode(a.Body);
	//     // a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
  //
	//     update cv;
	// }
	

	@AuraEnabled
	public static String createDealDocuments(List<String> ids, String dealId){
		//system.debug(ids);

		List<Deal_Document__c> docs = new List<Deal_Document__c>();
		for(ContentDocument doc : [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id IN : ids]){

				Deal_Document__c dd = new Deal_Document__c(
				File_Name__c = doc.title,
				ContentVersion_Id__c = doc.LatestPublishedVersionId,
				Attachment_Id__c = doc.Id,
				Type__c = 'Approval Uploads',
				Section__c = 'Approval Uploads',
				Document_Type__c = 'Approval Documents',
				Document_Loaded__c = true,
				Added_By__c = userInfo.getUserId(),
				Other_Document_Type__c = 'Approval Documents',
				Deal__c = dealId
			);

			docs.add(dd);
		}

		if(docs.size() > 0){
			insert docs;
		}

		return 'true';
	}

}