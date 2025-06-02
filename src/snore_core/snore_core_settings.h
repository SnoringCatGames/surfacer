#ifndef SNORE_CORE_SETTINGS_H
#define SNORE_CORE_SETTINGS_H

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class SnoreCoreSettings : public Resource {
	GDCLASS(SnoreCoreSettings, Resource)

public:
	SnoreCoreSettings() = default;
	virtual ~SnoreCoreSettings() = default;

protected:
	static void _bind_methods() {}
};

} // namespace godot

#endif // SNORE_CORE_SETTINGS_H
