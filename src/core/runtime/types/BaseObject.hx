package core.runtime.types;

import core.AST;
import haxe.DynamicAccess;

// class TemObject extends TemValue<ObjectType> {
  // override function to_haxe() {
  //   var dynamic_object: DynamicAccess<Dynamic> = {};
  //   var selector = dynamic_object;

  //   var i = 0;
  //   var object_value_arr: ObjectType = value;
  //   var object_value = object_value_arr[i];

  //   while(object_value != null) {
  //     var key = object_value.key;
  //     var value = object_value.value;

  //     if(value == null) {
  //       trace("wut");
  //     }

  //     if(value.type.match(VObject)) {
  //       var next_selector = {};
  //       selector.set(key, next_selector);

  //       i = 0;
  //       object_value_arr = value.value;
  //       selector = next_selector;
  //     } else {
  //       i++;
  //       selector.set(key, value.value);
  //     }

  //     object_value = object_value_arr[i];
  //   }

  //   return dynamic_object;
  // }
// }
