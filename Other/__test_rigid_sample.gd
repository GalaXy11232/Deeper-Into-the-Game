extends RigidBody2D


func _on_body_entered(body: Node2D) -> void:
	if body is TestPlayer and body.has_node("InventoryNode"):
		var inventory_node: Node = body.get_node("InventoryNode")
		
		# Check if inventory is full
		if inventory_node.inventory.size() < inventory_node.MAX_INVENTORY_SIZE:
			body.get_node("InventoryNode").pickup_sample()
			queue_free.call_deferred()
