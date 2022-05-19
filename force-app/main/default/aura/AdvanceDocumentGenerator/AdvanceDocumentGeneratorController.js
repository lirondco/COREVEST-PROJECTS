({	
	init : function(component, event, helper){
		console.log('doc generator init');
        //console.log("StaticResourceName Init==>"+component.get('v.StaticResourceName'));
	},

	generateDocx : function(component, event, helper){
		debugger;
		let params = event.getParam('arguments');
		//let queryString = `SELECT Id, SystemModStamp FROM StaticResource WHERE Name = '${component.get('v.StaticResourceName')}'`;
		let data = params.data;
		
        //console.log("StaticResourceName==>"+component.get('v.StaticResourceName'));
		component.find('util').getFileFromStaticResource(component.get('v.StaticResourceName'), params.fileName)
		.then($A.getCallback(response => {
            debugger;
			console.log(response);
			
			//let timestamp = new Date(response[0].SystemModstamp).getTime();

			//let url = `/resource/${timestamp}/${component.get('v.StaticResourceName')}/${params.fileName}`;
			//console.log(url);
			console.log(params);
			helper.loadFile(response, function(error, content){
				if (error) { throw error };
				var zip = new JSZip(content);
				var expressions= require('angular-expressions');
				
				// expressions.Parser.filter = {};
				//expressions.filters = {};
				console.log(expressions);
				console.log(zip);

				// expressions.filters.formatCurrency = function(input){
				// 	if(!input) return input;
				// 	return '$'+input;
				// }

				// expressions.filters.today = function(input){
				// 	return 'September 24, 2018'
				// }

				// expressions.Parser.$filter = expressions.filter;
				// expressions.filter.today(input){

				// }

				


				var angularParser = function(tag) {

					console.log(tag);

					return {
						get: tag === '.' ? function(s){ return s;} : function(s) {
							return expressions.compile(tag.replace(/(’|“|”)/g, "'"))(s);
						}
					};
				}



				var doc=new Docxtemplater().loadZip(zip).setOptions({parser: angularParser});
				console.log(data);
				doc.setData(data);

				try {
					// render the document (replace all occurences of {first_name} by John, {last_name} by Doe, ...)
					doc.render()
				}
				catch (error) {
					var e = {
						message: error.message,
						name: error.name,
						stack: error.stack,
						properties: error.properties,
					}
					console.log(JSON.stringify({error: e}));
					// The error thrown here contains additional information when logged with JSON.stringify (it contains a property object).
					throw error;
				}
				var out=doc.getZip().generate({
					type:"blob",
					mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
				}) //Output the document using Data-URI
                
                if(!component.get("v.isSendEmail")){
					 saveAs(out, params.fileName);
                }else{
                    console.log('File Generated-->'+out);
									helper.uploadHelper(component, event, out);
                }
               
			})

		}));
		
		

	},
        

})