class_name Specimen
extends Area2D

var pickupable := true


func _on_body_entered(body: Node2D) -> void:
	if body is TestPlayer and body.has_node("InventoryNode") and pickupable:
		var inventory_node: Node = body.get_node("InventoryNode")
		
		# Check if inventory is full
		if inventory_node.inventory.size() < inventory_node.MAX_INVENTORY_SIZE:
			var sample_clone = self.duplicate()
			sample_clone.set_meta('team', body.team)
			
			body.get_node("InventoryNode").pickup_sample(sample_clone)
			#turn_into_specimen_timer.stop()
			queue_free.call_deferred()
