({
    getFieldList: function(component, helper){
        var apexBridge = component.find("ETLC_ApexBridge");
        apexBridge.callApex({
            component: component,
            request: {
                controller: "Playout_Controller",
                method: "getFieldList",
                input:{
                    'sObjectName': component.get("v.sObjectName")
                },
                doesCallout: false
            },
            forceRefresh: true,
            pleaseWait: {
                type: "None",
            },
            callBackMethod: function (serverResponse) {
                component.find('utils').log('Playout:h.getFieldList:serverResponse:', serverResponse);

                component.set('v.availableFields', serverResponse.output.availableFields);
                component.set('v.userFields', serverResponse.output.userFields);

            },
            errorHandler: function (serverResponse) {
                component.find('utils').log('ERROR serverResponse:', serverResponse);
            }
        });
    }

})