// RUN: %target-swift-frontend -emit-silgen -sdk %S/Inputs -I %S/Inputs -enable-source-import %s | %FileCheck %s

// REQUIRES: objc_interop

import Foundation

// FIXME: Should go into the standard library.
public extension _ObjectiveCBridgeable {
  static func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectiveCType?)
      -> Self {
    var result: Self?
    _forceBridgeFromObjectiveC(source!, result: &result)
    return result!
  }
}

class BridgedObjC : NSObject { }

func == (x: BridgedObjC, y: BridgedObjC) -> Bool { return true }

struct BridgedSwift : Hashable, _ObjectiveCBridgeable {
  var hashValue: Int { return 0 }

  func _bridgeToObjectiveC() -> BridgedObjC {
    return BridgedObjC()
  }

  static func _forceBridgeFromObjectiveC(
    _ x: BridgedObjC,
    result: inout BridgedSwift?
  ) {
  }
  static func _conditionallyBridgeFromObjectiveC(
    _ x: BridgedObjC,
    result: inout BridgedSwift?
  ) -> Bool {
    return true
  }
}

func == (x: BridgedSwift, y: BridgedSwift) -> Bool { return true }

// CHECK-LABEL: sil hidden @_TF19collection_downcast17testArrayDowncast
// CHECK: bb0([[ARRAY:%[0-9]+]] : $Array<AnyObject>):
func testArrayDowncast(_ array: [AnyObject]) -> [BridgedObjC] {
  // CHECK: [[ARRAY_COPY:%.*]] = copy_value [[ARRAY]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs15_arrayForceCast
  // CHECK: apply [[DOWNCAST_FN]]<AnyObject, BridgedObjC>([[ARRAY_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1> (@owned Array<τ_0_0>) -> @owned Array<τ_0_1>
  // CHECK: destroy_value [[ARRAY]]
  return array as! [BridgedObjC]
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast27testArrayDowncastFromObject
// CHECK: bb0([[OBJ:%[0-9]+]] : $AnyObject):
func testArrayDowncastFromObject(_ obj: AnyObject) -> [BridgedObjC] {
  // CHECK: unconditional_checked_cast_addr take_always AnyObject in [[OBJECT_ALLOC:%[0-9]+]] : $*AnyObject to Array<BridgedObjC> in [[VALUE_ALLOC:%[0-9]+]] : $*Array<BridgedObjC>
  return obj as! [BridgedObjC]
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast28testArrayDowncastFromNSArray
// CHECK: bb0([[NSARRAY_OBJ:%[0-9]+]] : $NSArray):
func testArrayDowncastFromNSArray(_ obj: NSArray) -> [BridgedObjC] {
  // CHECK: unconditional_checked_cast_addr take_always NSArray in [[OBJECT_ALLOC:%[0-9]+]] : $*NSArray to Array<BridgedObjC> in [[VALUE_ALLOC:%[0-9]+]] : $*Array<BridgedObjC>
  return obj as! [BridgedObjC]
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast28testArrayDowncastConditional
// CHECK: bb0([[ARRAY:%[0-9]+]] : $Array<AnyObject>):
func testArrayDowncastConditional(_ array: [AnyObject]) -> [BridgedObjC]? {
  // CHECK: [[ARRAY_COPY:%.*]] = copy_value [[ARRAY]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs21_arrayConditionalCast
  // CHECK: apply [[DOWNCAST_FN]]<AnyObject, BridgedObjC>([[ARRAY_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1> (@owned Array<τ_0_0>) -> @owned Optional<Array<τ_0_1>>
  // CHECK: destroy_value [[ARRAY]]
  return array as? [BridgedObjC]
}
// CHECK: } // end sil function '_TF19collection_downcast28testArrayDowncastConditional{{.*}}'

// CHECK-LABEL: sil hidden @_TF19collection_downcast12testArrayIsa
// CHECK: bb0([[ARRAY:%[0-9]+]] : $Array<AnyObject>)
func testArrayIsa(_ array: [AnyObject]) -> Bool {
  // CHECK: [[ARRAY_COPY:%.*]] = copy_value [[ARRAY]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs21_arrayConditionalCast
  // CHECK: apply [[DOWNCAST_FN]]<AnyObject, BridgedObjC>([[ARRAY_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1> (@owned Array<τ_0_0>) -> @owned Optional<Array<τ_0_1>>
  // CHECK: destroy_value [[ARRAY]]
  return array is [BridgedObjC] ? true : false
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast24testArrayDowncastBridged
// CHECK: bb0([[ARRAY:%[0-9]+]] : $Array<AnyObject>):
func testArrayDowncastBridged(_ array: [AnyObject]) -> [BridgedSwift] {
  // CHECK: [[ARRAY_COPY:%.*]] = copy_value [[ARRAY]]
  // CHECK: [[BRIDGE_FN:%[0-9]+]] = function_ref @_TFs15_arrayForceCast
  // CHECK: apply [[BRIDGE_FN]]<AnyObject, BridgedSwift>([[ARRAY_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1> (@owned Array<τ_0_0>) -> @owned Array<τ_0_1>
  // CHECK: destroy_value [[ARRAY]]
  return array as! [BridgedSwift]
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast35testArrayDowncastBridgedConditional
// CHECK: bb0([[ARRAY:%[0-9]+]] : $Array<AnyObject>):
func testArrayDowncastBridgedConditional(_ array: [AnyObject]) -> [BridgedSwift]?{
  // CHECK: [[ARRAY_COPY:%.*]] = copy_value [[ARRAY]]
  // CHECK: [[BRIDGE_FN:%[0-9]+]] = function_ref @_TFs21_arrayConditionalCast
  // CHECK: apply [[BRIDGE_FN]]<AnyObject, BridgedSwift>([[ARRAY_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1> (@owned Array<τ_0_0>) -> @owned Optional<Array<τ_0_1>>
  // CHECK: destroy_value [[ARRAY]]
  return array as? [BridgedSwift]
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast19testArrayIsaBridged
// CHECK: bb0([[ARRAY:%[0-9]+]] : $Array<AnyObject>)
func testArrayIsaBridged(_ array: [AnyObject]) -> Bool {
  // CHECK: [[ARRAY_COPY:%.*]] = copy_value [[ARRAY]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs21_arrayConditionalCast
  // CHECK: apply [[DOWNCAST_FN]]<AnyObject, BridgedSwift>([[ARRAY_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1> (@owned Array<τ_0_0>) -> @owned Optional<Array<τ_0_1>>
  // CHECK: destroy_value [[ARRAY]]
  return array is [BridgedSwift] ? true : false
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast32testDictionaryDowncastFromObject
// CHECK: bb0([[OBJ:%[0-9]+]] : $AnyObject):
func testDictionaryDowncastFromObject(_ obj: AnyObject) 
       -> Dictionary<BridgedObjC, BridgedObjC> {
  // CHECK: unconditional_checked_cast_addr take_always AnyObject in [[OBJECT_ALLOC:%[0-9]+]] : $*AnyObject to Dictionary<BridgedObjC, BridgedObjC> in [[VALUE_ALLOC:%[0-9]+]] : $*Dictionary<BridgedObjC, BridgedObjC>
  return obj as! Dictionary<BridgedObjC, BridgedObjC>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast22testDictionaryDowncast
// CHECK: bb0([[DICT:%[0-9]+]] : $Dictionary<NSObject, AnyObject>)
func testDictionaryDowncast(_ dict: Dictionary<NSObject, AnyObject>) 
       -> Dictionary<BridgedObjC, BridgedObjC> {
  // CHECK: [[DICT_COPY:%.*]] = copy_value [[DICT]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs19_dictionaryDownCast
  // CHECK: apply [[DOWNCAST_FN]]<NSObject, AnyObject, BridgedObjC, BridgedObjC>([[DICT_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1, τ_0_2, τ_0_3 where τ_0_0 : Hashable, τ_0_2 : Hashable> (@owned Dictionary<τ_0_0, τ_0_1>) -> @owned Dictionary<τ_0_2, τ_0_3>
  // CHECK: destroy_value [[DICT]]
  return dict as! Dictionary<BridgedObjC, BridgedObjC>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast33testDictionaryDowncastConditional
// CHECK: bb0([[DICT:%[0-9]+]] : $Dictionary<NSObject, AnyObject>)
func testDictionaryDowncastConditional(_ dict: Dictionary<NSObject, AnyObject>) 
       -> Dictionary<BridgedObjC, BridgedObjC>? {
  // CHECK: [[DICT_COPY:%.*]] = copy_value [[DICT]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs30_dictionaryDownCastConditional
  // CHECK: apply [[DOWNCAST_FN]]<NSObject, AnyObject, BridgedObjC, BridgedObjC>([[DICT_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1, τ_0_2, τ_0_3 where τ_0_0 : Hashable, τ_0_2 : Hashable> (@owned Dictionary<τ_0_0, τ_0_1>) -> @owned Optional<Dictionary<τ_0_2, τ_0_3>>
  // CHECK: destroy_value [[DICT]]
  return dict as? Dictionary<BridgedObjC, BridgedObjC>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast41testDictionaryDowncastBridgedVConditional
// CHECK: bb0([[DICT:%[0-9]+]] : $Dictionary<NSObject, AnyObject>)
func testDictionaryDowncastBridgedVConditional(_ dict: Dictionary<NSObject, AnyObject>) 
       -> Dictionary<BridgedObjC, BridgedSwift>? {
  // CHECK: [[DICT_COPY:%.*]] = copy_value [[DICT]]
  // CHECK: [[BRIDGE_FN:%[0-9]+]] = function_ref @_TFs30_dictionaryDownCastConditional
  // CHECK: apply [[BRIDGE_FN]]<NSObject, AnyObject, BridgedObjC, BridgedSwift>([[DICT_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1, τ_0_2, τ_0_3 where τ_0_0 : Hashable, τ_0_2 : Hashable> (@owned Dictionary<τ_0_0, τ_0_1>) -> @owned Optional<Dictionary<τ_0_2, τ_0_3>>{{.*}}
  // CHECK: destroy_value [[DICT]]
  return dict as? Dictionary<BridgedObjC, BridgedSwift>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast41testDictionaryDowncastBridgedKConditional
// CHECK: bb0([[DICT:%[0-9]+]] : $Dictionary<NSObject, AnyObject>)
func testDictionaryDowncastBridgedKConditional(_ dict: Dictionary<NSObject, AnyObject>) 
       -> Dictionary<BridgedSwift, BridgedObjC>? {
  // CHECK: [[DICT_COPY:%.*]] = copy_value [[DICT]]
  // CHECK: [[BRIDGE_FN:%[0-9]+]] = function_ref @_TFs30_dictionaryDownCastConditional
  // CHECK: apply [[BRIDGE_FN]]<NSObject, AnyObject, BridgedSwift, BridgedObjC>([[DICT_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1, τ_0_2, τ_0_3 where τ_0_0 : Hashable, τ_0_2 : Hashable> (@owned Dictionary<τ_0_0, τ_0_1>) -> @owned Optional<Dictionary<τ_0_2, τ_0_3>>
  // CHECK: destroy_value [[DICT]]
  return dict as? Dictionary<BridgedSwift, BridgedObjC>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast31testDictionaryDowncastBridgedKV
// CHECK: bb0([[DICT:%[0-9]+]] : $Dictionary<NSObject, AnyObject>)
func testDictionaryDowncastBridgedKV(_ dict: Dictionary<NSObject, AnyObject>) 
-> Dictionary<BridgedSwift, BridgedSwift> {
  // CHECK: [[DICT_COPY:%.*]] = copy_value [[DICT]]
  // CHECK: [[BRIDGE_FN:%[0-9]+]] = function_ref @_TFs19_dictionaryDownCast
  // CHECK: apply [[BRIDGE_FN]]<NSObject, AnyObject, BridgedSwift, BridgedSwift>([[DICT_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1, τ_0_2, τ_0_3 where τ_0_0 : Hashable, τ_0_2 : Hashable> (@owned Dictionary<τ_0_0, τ_0_1>) -> @owned Dictionary<τ_0_2, τ_0_3>
  // CHECK: destroy_value [[DICT]]
  return dict as! Dictionary<BridgedSwift, BridgedSwift>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast42testDictionaryDowncastBridgedKVConditional
// CHECK: bb0([[DICT:%[0-9]+]] : $Dictionary<NSObject, AnyObject>)
func testDictionaryDowncastBridgedKVConditional(_ dict: Dictionary<NSObject, AnyObject>) 
       -> Dictionary<BridgedSwift, BridgedSwift>? {
  // CHECK: [[DICT_COPY:%.*]] = copy_value [[DICT]]
  // CHECK: [[BRIDGE_FN:%[0-9]+]] = function_ref @_TFs30_dictionaryDownCastConditional
  // CHECK: apply [[BRIDGE_FN]]<NSObject, AnyObject, BridgedSwift, BridgedSwift>([[DICT_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1, τ_0_2, τ_0_3 where τ_0_0 : Hashable, τ_0_2 : Hashable> (@owned Dictionary<τ_0_0, τ_0_1>) -> @owned Optional<Dictionary<τ_0_2, τ_0_3>>
  // CHECK: destroy_value [[DICT]]
  return dict as? Dictionary<BridgedSwift, BridgedSwift>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast25testSetDowncastFromObject
// CHECK: bb0([[OBJ:%[0-9]+]] : $AnyObject):
func testSetDowncastFromObject(_ obj: AnyObject) 
       -> Set<BridgedObjC> {
  // CHECK: unconditional_checked_cast_addr take_always AnyObject in [[OBJECT_ALLOC:%[0-9]+]] : $*AnyObject to Set<BridgedObjC> in [[VALUE_ALLOC:%[0-9]+]] : $*Set<BridgedObjC>
  return obj as! Set<BridgedObjC>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast15testSetDowncast
// CHECK: bb0([[SET:%[0-9]+]] : $Set<NSObject>)
func testSetDowncast(_ dict: Set<NSObject>) 
       -> Set<BridgedObjC> {
  // CHECK: [[SET_COPY:%.*]] = copy_value [[SET]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs12_setDownCast
  // CHECK: apply [[DOWNCAST_FN]]<NSObject, BridgedObjC>([[SET_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1 where τ_0_0 : Hashable, τ_0_1 : Hashable> (@owned Set<τ_0_0>) -> @owned Set<τ_0_1>
  // CHECK: destroy_value [[SET]]
  return dict as! Set<BridgedObjC>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast26testSetDowncastConditional
// CHECK: bb0([[SET:%[0-9]+]] : $Set<NSObject>)
func testSetDowncastConditional(_ dict: Set<NSObject>) 
       -> Set<BridgedObjC>? {
  // CHECK: [[SET_COPY:%.*]] = copy_value [[SET]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs23_setDownCastConditional
  // CHECK: apply [[DOWNCAST_FN]]<NSObject, BridgedObjC>([[SET_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1 where τ_0_0 : Hashable, τ_0_1 : Hashable> (@owned Set<τ_0_0>) -> @owned Optional<Set<τ_0_1>>
  // CHECK: destroy_value [[SET]]
  return dict as? Set<BridgedObjC>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast22testSetDowncastBridged
// CHECK: bb0([[SET:%[0-9]+]] : $Set<NSObject>)
func testSetDowncastBridged(_ dict: Set<NSObject>) 
       -> Set<BridgedSwift> {
  // CHECK: [[SET_COPY:%.*]] = copy_value [[SET]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs12_setDownCast
  // CHECK: apply [[DOWNCAST_FN]]<NSObject, BridgedSwift>([[SET_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1 where τ_0_0 : Hashable, τ_0_1 : Hashable> (@owned Set<τ_0_0>) -> @owned Set<τ_0_1>
  // CHECK: destroy_value [[SET]]
  return dict as! Set<BridgedSwift>
}

// CHECK-LABEL: sil hidden @_TF19collection_downcast33testSetDowncastBridgedConditional
// CHECK: bb0([[SET:%[0-9]+]] : $Set<NSObject>)
func testSetDowncastBridgedConditional(_ dict: Set<NSObject>) 
       -> Set<BridgedSwift>? {
  // CHECK: [[SET_COPY:%.*]] = copy_value [[SET]]
  // CHECK: [[DOWNCAST_FN:%[0-9]+]] = function_ref @_TFs23_setDownCastConditional
  // CHECK: apply [[DOWNCAST_FN]]<NSObject, BridgedSwift>([[SET_COPY]]) : $@convention(thin) <τ_0_0, τ_0_1 where τ_0_0 : Hashable, τ_0_1 : Hashable> (@owned Set<τ_0_0>) -> @owned Optional<Set<τ_0_1>>
  // CHECK: destroy_value [[SET]]
  return dict as? Set<BridgedSwift>
}
