({
    doInit : function(component, event, helper) {
        var action = component.get("c.getContactProductInfo");
        var caseRecID = component.get("v.recordId");
        //var contId = component.get("v.CaseRecord.ContactId");
        alert(caseRecID);
        action.setParams({
            "caseRecID":caseRecID
        });
        
        action.setCallback(this, function(data){
            component.set("v.productList",data.getReturnValue());
        });
        $A.enqueueAction(action);
    }
})