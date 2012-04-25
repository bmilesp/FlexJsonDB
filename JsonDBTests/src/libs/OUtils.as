package libs
{
	import flash.utils.describeType;
	import mx.utils.ObjectUtil;
	
	public class OUtils extends ObjectUtil
	{
		public function OUtils()
		{
			super();
		}
		
		public static function varExport(obj:Object = null, depth:Number = 0):String{
			//trace('obj: ');
			//trace(ObjectUtil.toString(obj));
			var tab:String = "";
			for (var i:Number=0; i<=depth ; i++){
				tab+= "\t";
			}
			var returnStr:String = "{";
			var returnItems:Array = new Array();
			for (var item:String in obj){
				var objtype:Object = ObjectUtil.getClassInfo(obj[item]);
				if(objtype.name == "Object" || objtype.name == 'Array'){
					returnItems.push(tab+item + ' : ' + varExport(obj[item], depth +1));
				}else{
					returnItems.push(tab+item+" : \""+obj[item]+"\"");
				}
			}
			if(returnItems.length > 0){
				returnItems.sort();
				returnStr += "\n"+returnItems.join(",\n");
			}
			returnStr += "}";
			return returnStr;
		}
		
		/*
		public static function compareFriendlyDates(obj:Object = null, passedObject = null, dateKeys:Array = ['created', 'modified']):Object{
			var returnObject:Object = {};
			for (var item:String in obj){
				var objtype:Object = ObjectUtil.getClassInfo(obj[item]);
				if(objtype.name == "Object"){
					obj[item] = compareFriendlyDates(obj[item]);
				}else{
					for each(var key in dateKeys){
						if(key == obj[item]){
							obj[item] = "\""+obj[item]+"\"";
						}
					}
				}
				returnObject[item] = obj[item];
			}
		}*/
	}
}