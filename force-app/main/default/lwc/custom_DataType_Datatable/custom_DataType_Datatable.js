import LightningDatatable from "lightning/datatable";
import customNameTemplate from "./customAccountName.html";

export default class Custom_DataType_Datatable extends LightningDatatable {
    static customTypes = {
        customName: {
          template: customNameTemplate,
          standardCellLayout: true,
          typeAttributes: {
            accountName:'',
            iconName:''
          }
        }
    };
}