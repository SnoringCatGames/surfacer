#ifndef SNORE_CORE_MODULE_H
#define SNORE_CORE_MODULE_H

#include "snore_core/internal_utils.h"
#include "snore_core/snore_core_manifest.h"

#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/object.hpp>

namespace godot {

#define BIND_SNORE_CORE_MODULE_METHODS(m_class)                                \
	ADD_SIGNAL(MethodInfo("set_up_finished"));                                 \
	ClassDB::bind_method(                                                      \
			D_METHOD("set_up", "p_manifests"), &m_class::set_up_from_binding)

template <typename ManifestType> class SnoreCoreModule;

namespace SnoreCoreModuleInternal {
void set_up_main_module(const TypedArray<SnoreCoreManifest> &p_manifests);
void notify_main_module_of_module_set_up_finished(Object *p_module);
} // namespace SnoreCoreModuleInternal

template <typename ManifestType> class SnoreCoreModule : public Object {
	GDCLASS(SnoreCoreModule, Object)

	static_assert(
			std::is_base_of<SnoreCoreManifest, ManifestType>::value,
			"ManifestType must be derived from SnoreCoreManifest");

public:
	enum SET_UP_PHASE {
		NOT_STARTED,
		IN_PROGRESS,
		FINISHED,
	};

	SnoreCoreModule() = default;
	virtual ~SnoreCoreModule() = default;

	// This is called during game runtime, after manifest settings are loaded.
	virtual void set_up() = 0;

	// This is called during game runtime, before calling set_up.
	virtual void reset() = 0;

	// This resets some base state before calling reset().
	void reset_base() {
		set_up_phase = SET_UP_PHASE::NOT_STARTED;
		reset();
	}

	// This sets some tracking state before calling set_up().
	void set_up_base(const TypedArray<SnoreCoreManifest> &p_manifests) {
		ManifestType *manifest_ptr = get_manifest_from_list(p_manifests);
		CHECK(manifest_ptr,
			  "Cannot find manifest of type: " +
					  String(typeid(ManifestType).name()));
		manifest = Ref<ManifestType>(manifest_ptr);

		reset_base();
		set_up_phase = SET_UP_PHASE::IN_PROGRESS;
		set_up();
	}

	// Redirect the overall set_up flow to start with the main module.
	// This enables the client to call set_up() from any module.
	virtual void set_up_from_binding(
			const TypedArray<SnoreCoreManifest> &p_manifests) {
		SnoreCoreModuleInternal::set_up_main_module(p_manifests);
	}

	bool get_is_set_up_started() const {
		return set_up_phase == SET_UP_PHASE::IN_PROGRESS ||
				set_up_phase == SET_UP_PHASE::FINISHED;
	}

	bool get_is_set_up_finished() const {
		return set_up_phase == SET_UP_PHASE::FINISHED;
	}

	Ref<ManifestType> get_manifest() const { return manifest; }

protected:
	static void _bind_methods() {}

	bool are_types_registered = false;
	SET_UP_PHASE set_up_phase = SET_UP_PHASE::NOT_STARTED;

	Ref<ManifestType> manifest;

	void on_set_up_finished() {
		if (!ENSURE(set_up_phase == SET_UP_PHASE::IN_PROGRESS,
					"Cannot finish set_up when it is not in progress.")) {
			return;
		}

		set_up_phase = SET_UP_PHASE::FINISHED;
		emit_signal("set_up_finished");

		SnoreCoreModuleInternal::notify_main_module_of_module_set_up_finished(
				this);
	}

	ManifestType *get_manifest_from_list(
			TypedArray<SnoreCoreManifest> p_manifests) const {
		const char *type_name = typeid(ManifestType).name();
		for (int i = 0; i < p_manifests.size(); i++) {
			Object *object = p_manifests[i].get_validated_object();
			SnoreCoreManifest *manifest =
					Object::cast_to<SnoreCoreManifest>(object);
			CHECK_SIMPLE(manifest);
			if (manifest->is_class(type_name)) {
				return static_cast<ManifestType *>(manifest);
			}
		}
		return nullptr;
	}
};

} //namespace godot

#endif // SNORE_CORE_MODULE_H
