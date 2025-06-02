#ifndef SNORE_CORE_MANIFEST_H
#define SNORE_CORE_MANIFEST_H

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class SnoreCoreManifest : public Resource {
	GDCLASS(SnoreCoreManifest, Resource)

public:
	SnoreCoreManifest() = default;
	virtual ~SnoreCoreManifest() = default;

protected:
	static void _bind_methods() {}
};

} // namespace godot

#endif // SNORE_CORE_MANIFEST_H
