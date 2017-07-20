({
    doInit: function(component, event, helper){
        helper.getFieldList(component, helper);
    },
    handleEvtUserFieldsChanged: function(component, event, helper){
        component.find('utils').log('Playout:c.Evt_UserFieldsChanged:Handling Evt_UserFieldsChanged');
        helper.getFieldList(component, helper);
    }
})