extends Resource
class_name CabinetItemCatalog

const CabinetItemDescriptor := preload("res://scripts/resources/cabinet_item_descriptor.gd")

@export var descriptors: Array = []

func get_descriptor(descriptor_id: StringName) -> CabinetItemDescriptor:
    for descriptor in descriptors:
        if descriptor == null:
            continue
        if descriptor.descriptor_id == descriptor_id:
            return descriptor
    return null

func get_descriptors() -> Array[CabinetItemDescriptor]:
    var results: Array[CabinetItemDescriptor] = []
    for descriptor in descriptors:
        if descriptor is CabinetItemDescriptor:
            results.append(descriptor)
    return results

func get_all_descriptor_ids() -> Array[StringName]:
    var ids: Array[StringName] = []
    for descriptor in descriptors:
        if descriptor == null:
            continue
        ids.append(descriptor.descriptor_id)
    return ids
