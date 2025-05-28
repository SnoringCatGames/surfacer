#ifndef CANVAS_LAYER_CONFIG_H
#define CANVAS_LAYER_CONFIG_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class CanvasLayerConfig : public Resource {
	GDCLASS(CanvasLayerConfig, Resource)

public:
	CanvasLayerConfig();
	CanvasLayerConfig(const String &p_name, Node::ProcessMode p_process_mode);
	~CanvasLayerConfig() = default;

	String get_name() const { return name; }
	void set_name(const String &p_name) { name = p_name; }

	Node::ProcessMode get_process_mode() const { return process_mode; }
	void set_process_mode(Node::ProcessMode p_process_mode) {
		process_mode = p_process_mode;
	}

protected:
	static void _bind_methods();

private:
	String name;
	Node::ProcessMode process_mode = Node::PROCESS_MODE_INHERIT;
};

} // namespace godot

#endif // CANVAS_LAYER_CONFIG_H
