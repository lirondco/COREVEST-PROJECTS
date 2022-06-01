({
	CHUNK_SIZE: 950 000,
    MAX_FILE_SIZE: 4 275 000,
    MAX_FILE_SIZE_API: 60 000 000, 

    readFiles : function(component, helper, arr, parentId){
        //console.log(arr);
        return arr.reduce(function(promise, file, index) {
            //var reader = new FileReader();
            //reader.onload = $A.getCallback()
            return promise.then($A.getCallback(function() {
                return helper.readFilePromise(component, helper, file, parentId, index).then($A.getCallback(function(res){
                    console.log('done in promise');
                    if(!$A.util.isEmpty(res)){
                        var files = component.get('v.files');
                        files.push(res);
                        component.set('v.files', files);
                    }
                    
                }));
            }));
        }, Promise.resolve());
    },
    readFilePromise : function(component, helper, file, parentId) {

        return new Promise((resolve, reject) => {
            var fr = new FileReader();
            fr.onload = $A.getCallback(function(event){
                var data = event.target.result;
                var fileContents = data.match(/,(.*)$/)[1];
                var fromPos = 0;
                var toPos = Math.min(fileContents.length, fromPos + helper.CHUNK_SIZE);

                if(file.size >= helper.MAX_FILE_SIZE_API){
                    resolve({attachmentId: '', size: file.size, name: file.name });
                }else if(file.size >= helper.MAX_FILE_SIZE && component.get('v.uploaderType') != 'portal'){
                    //resolve({attachmentId: '', size: file.size, name: file.name });
                    helper.forceTkUploadAttachment(component, helper, file, fileContents, parentId, resolve, reject, component.get('v.accountId'));
                }
                else{
                    helper.uploadChunkPromise(component, helper, file, fileContents, fromPos, toPos, '', parentId, resolve, reject);
                }
                
            })
            
            if(file.size >= helper.MAX_FILE_SIZE && file.size < helper.MAX_FILE_SIZE_API && component.get('v.uploaderType') == 'portal' ){
                // console.log(component.get('v.uploaderType'));
                // if(file.size < helper.MAX_FILE_SIZE_API && component.get('v.uploaderType') != 'portal'){
                //     helper.forceTkUpload(component, helper, file, null, parentId, resolve, reject);
                // }else if(file.size < helper.MAX_FILE_SIZE_API && component.get('v.uploaderType') == 'portal'){
                //     helper.forceTkUpload(component, helper, file, null, parentId, resolve, reject, component.get('v.accountId'));
                // }else{
                //     resolve({attachmentId: '', size: file.size, name: file.name });
                // }
                helper.forceTkUpload(component, helper, file, null, parentId, resolve, reject, component.get('v.accountId'));
            }else{
                fr.readAsDataURL(file);
            }
        });
    },

	readFile : function(component, helper, file, parentId) {
		var reader = new FileReader();
		
		reader.onload = $A.getCallback(function(event){
			var data = event.target.result;
			var fileContents = data.match(/,(.*)$/)[1];
			var fromPos = 0;
	        var toPos = Math.min(fileContents.length, fromPos + helper.CHUNK_SIZE);
	        helper.uploadChunk(component, helper, file, fileContents, fromPos, toPos, '', parentId);

		});

		reader.file = file;
		reader.readAsDataURL(file);
	},

    uploadChunk : function(component, helper, file, fileContents, fromPos, toPos, attachId, parentId) {
        var action = component.get("c.saveTheChunk");
        var chunk = fileContents.substring(fromPos, toPos);
        console.log('--parentId', parentId);
        action.setParams({
            parentId: component.get("v.parentId"),
            fileName: file.name,
            base64Data: chunk,
            contentType: file.type,
            fileId: attachId
        });

        var self = this;
        action.setCallback(this, function(response) {

            if(response.getState() === "ERROR"){
                var errors = response.getError();
                if( errors ){
                    if(errors[0] && errors[0].message){
                        console.log("Error message: " + errors[0].message);
                    }
                }
            }
            else if(response.getState() === 'SUCCESS'){
                attachId = response.getReturnValue();
                console.log('continue uploading' + file.name);

                //console.log(self);

                fromPos = toPos;
                toPos = Math.min(fileContents.length, fromPos + helper.CHUNK_SIZE);

                console.log(fromPos);
                console.log(toPos);

                if (fromPos < toPos) {
                	helper.uploadChunk(component,helper, file, fileContents, fromPos, toPos, attachId);
                }
                else{

                    var fileObj = {
					 	attachmentId : attachId,
					 	name : file.name,
					 	size : file.size,
					};

					var files = component.get('v.files');
					component.set('v.files', files.concat(fileObj));
                }

            }
        });

        $A.enqueueAction(action);
    },
    // helper.uploadChunkPromise(component, helper, file, fileContents, fromPos, toPos, '', parentId);
    uploadChunkPromise : function(component, helper, file, fileContents, fromPos, toPos, attachId, parentId, resolve, reject){
        // return new Promise(function(resolve, reject){

            var action = component.get("c.saveTheChunk");
            var chunk = fileContents.substring(fromPos, toPos);
            console.log('--parentId', parentId);
            action.setParams({
                parentId: component.get("v.parentId"),
                fileName: file.name,
                base64Data: chunk,
                contentType: file.type,
                fileId: attachId
            });

            var self = this;
            action.setCallback(this, function(response) {

                if(response.getState() === "ERROR"){
                    var errors = response.getError();
                    if( errors ){
                        if(errors[0] && errors[0].message){
                            console.log("Error message: " + errors[0].message);
                            reject(file);
                        }
                    }
                }
                else if(response.getState() === 'SUCCESS'){
                    attachId = response.getReturnValue();
                    console.log('continue uploading' + file.name);

                    //console.log(self);

                    fromPos = toPos;
                    toPos = Math.min(fileContents.length, fromPos + helper.CHUNK_SIZE);

                    console.log(fromPos);
                    console.log(toPos);

                    if (fromPos < toPos) {
                        helper.uploadChunkPromise(component,helper, file, fileContents, fromPos, toPos, attachId, parentId, resolve, reject);
                    }
                    else{
                        
                        var fileObj = {
                            attachmentId : attachId,
                            name : file.name,
                            size : file.size,
                        };
                        //return fileObj
                        resolve(fileObj);
                    }
                }
            });

            $A.enqueueAction(action);
        // });
    },

    forceTkUploadAttachment : function(component, helper, file, fileContents, parentId, resolve, reject, accountId){

        console.log('uploading attachment');

        var sessionId = component.get("v.sessionId");
        var sfInstanceUrl = component.get("v.sfInstanceUrl");
        console.log('sfInstanceUrl', sfInstanceUrl);
        var client = new forcetk.Client();
        //sfInstanceUrl = 'https://caf--partial.lightning.force.com';
        //sfInstanceUrl = 'https://caf--partial.cs62.my.salesforce.com';
        //
        if(sfInstanceUrl.includes('https://corevest.salesforce.com') || sfInstanceUrl.includes('https://cvest.salesforce.com')){
            sfInstanceUrl = 'https://na54.salesforce.com';
        }
        client.setSessionToken(sessionId ,'v36.0',sfInstanceUrl);
        client.proxyUrl = null;

        var attachmentParentId = parentId;
        if(!$A.util.isEmpty(accountId)){
            console.log('account id is not blank');
            attachmentParentId = accountId;
        }

        //console.log(attachmentParentId)

        try{

            client.create('Attachment', {
                                            'ParentId': attachmentParentId,
                                            'Name': file.name,
                                            'ContentType': file.type,
                                            'Body': fileContents,
                                            }, 

                     $A.getCallback(function(response)
                   {
                       if(response.id !== null)
                       {    
                            if($A.util.isEmpty(accountId)){
                                var fileObj = {
                                    attachmentId : response.id,
                                    name : file.name,
                                    size : file.size,
                                };

                                resolve(fileObj);
                            }else{
                                console.log('account id is not blank');

                                var attachment = {
                                    sobjectType : 'Attachment',
                                    Id : response.id,
                                    ParentId : parentId
                                }
                                console.log(attachment);

                                var action = component.get('c.reparentAttachment');
                                action.setParams({
                                    attachmentId : response.id,
                                    parentId : parentId
                                });
                                action.setCallback(this, function(response){
                                    var state = response.getState();

                                    if(state == 'SUCCESS'){
                                        var attachmentId = response.getReturnValue();
                                        var fileObj = {
                                            attachmentId : attachmentId,
                                            name : file.name,
                                            size : file.size,
                                        };

                                        resolve(fileObj);
                                    }else if(state === 'ERROR'){
                                        console.log('error');
                                        console.log(response.getError());

                                        var obj = {
                                            name : file.name,
                                            size : file.size,
                                            message : 'file to big'
                                        }
                                        resolve(obj);
                                    }
                                });
                                $A.enqueueAction(action);
                            }
                       }
                       else
                       {    
                            console.log(response.errors[0].message);
                            console.log('error');
                       }
                   }), 
                   function(request, status, response)
                   {
                       console.log('----46----',request);
                       console.log(status);
                       console.log(response);
                       //console.log(resespons.message);
                       resolve();
                    }
            );
        }catch(e){
            var obj = {
                name : file.name,
                size : file.size,
                message : 'file to big'
            }
            resolve(obj);
        }
    },

    forceTkUpload : function(component, helper, file, fileContents, parentId, resolve, reject, accountId) {
        var sessionId = component.get("v.sessionId");
        var sfInstanceUrl = component.get("v.sfInstanceUrl");
        
        var client = new forcetk.Client();
        //sfInstanceUrl = 'https://caf--partial.lightning.force.com';
        //sfInstanceUrl = 'https://caf--partial.cs62.my.salesforce.com';
        console.log('sfInstanceUrl', sfInstanceUrl);
        if(sfInstanceUrl.includes('https://corevest.salesforce.com') || sfInstanceUrl.includes('https://cvest.salesforce.com')){
            sfInstanceUrl = 'https://na54.salesforce.com';
        }
        
        client.setSessionToken(sessionId ,'v36.0',sfInstanceUrl);
        client.proxyUrl = null;

        var attachmentParentId = parentId;
        if(!$A.util.isEmpty(accountId)){
            console.log('account id is not blank');
            attachmentParentId = accountId;
        }

        console.log(attachmentParentId)

        try{

            client.createBlob('Attachment', {
                                            'ParentId': attachmentParentId,
                                            'Name': file.name,
                                            'ContentType': file.type,
                                            }, 
                   file.name, 'Body', file , $A.getCallback(function(response)
                   {
                       if(response.id !== null)
                       {    
                            if($A.util.isEmpty(accountId)){
                                var fileObj = {
                                    attachmentId : response.id,
                                    name : file.name,
                                    size : file.size,
                                };
                                resolve(fileObj);
                            }else{
                                console.log('account id is not blank');

                                var attachment = {
                                    sobjectType : 'Attachment',
                                    Id : response.id,
                                    ParentId : parentId
                                }
                                console.log(attachment);

                                var action = component.get('c.reparentAttachment');
                                action.setParams({
                                    attachmentId : response.id,
                                    parentId : parentId
                                });
                                action.setCallback(this, function(response){
                                    var state = response.getState();

                                    if(state == 'SUCCESS'){
                                        var attachmentId = response.getReturnValue();
                                        var fileObj = {
                                            attachmentId : attachmentId,
                                            name : file.name,
                                            size : file.size,
                                        };

                                        resolve(fileObj);
                                    }else if(state === 'ERROR'){
                                        console.log('error');
                                        console.log(response.getError());

                                        var obj = {
                                            name : file.name,
                                            size : file.size,
                                            message : 'file to big'
                                        }
                                        resolve(obj);
                                    }
                                });
                                $A.enqueueAction(action);
                            }
                       }
                       else
                       {    
                            console.log(response.errors[0].message);
                            console.log('error');
                       }
                   }), 
                   function(request, status, response)
                   {
                       console.log('----46----',request);
                       console.log(response);
                       //console.log(resespons.message);
                       resolve();
            });
        }catch(e){
            var obj = {
                name : file.name,
                size : file.size,
                message : 'file to big'
            }
            resolve(obj);
        }
    }
})