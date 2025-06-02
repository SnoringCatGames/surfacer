#ifndef SNORE_CORE_MODULE_H
#define SNORE_CORE_MODULE_H

#include "snore_core/internal_utils.h"
#include "snore_core/snore_core_settings.h"

#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/object.hpp>

namespace godot {

#define BIND_SNORE_CORE_MODULE_METHODS(m_class)                                \
	ADD_SIGNAL(MethodInfo("set_up_finished"));                                 \
	ClassDB::bind_method(                                                      \
			D_METHOD("set_up", "p_settings"), &m_class::set_up_from_binding)

template <typename SettingsType> class SnoreCoreModule;

namespace SnoreCoreModuleInternal {
void set_up_main_module(const TypedArray<SnoreCoreSettings> &p_settings);
void notify_main_module_of_module_set_up_finished(Object *p_module);
} // namespace SnoreCoreModuleInternal

template <typename SettingsType> class SnoreCoreModule : public Object {
	GDCLASS(SnoreCoreModule, Object)

	static_assert(
			std::is_base_of<SnoreCoreSettings, SettingsType>::value,
			"SettingsType must be derived from SnoreCoreSettings");

public:
	enum SET_UP_PHASE {
		NOT_STARTED,
		IN_PROGRESS,
		FINISHED,
	};

	SnoreCoreModule() = default;
	virtual ~SnoreCoreModule() = default;

	// This is called during game runtime, after settings are loaded.
	virtual void set_up() = 0;

	// This is called during game runtime, before calling set_up.
	virtual void reset() = 0;

	// This resets some base state before calling reset().
	void reset_base() {
		set_up_phase = SET_UP_PHASE::NOT_STARTED;
		reset();
	}

	// This sets some tracking state before calling set_up().
	void set_up_base(const TypedArray<SnoreCoreSettings> &p_settings) {
		SettingsType *settings_ptr = get_settings_from_list(p_settings);
		CHECK(settings_ptr,
			  "Cannot find settings of type: " +
					  String(typeid(SettingsType).name()));
		settings = Ref<SettingsType>(settings_ptr);

		reset_base();
		set_up_phase = SET_UP_PHASE::IN_PROGRESS;
		set_up();
	}

	// Redirect the overall set_up flow to start with the main module.
	// This enables the client to call set_up() from any module.
	virtual void set_up_from_binding(
			const TypedArray<SnoreCoreSettings> &p_settings) {
		SnoreCoreModuleInternal::set_up_main_module(p_settings);
	}

	bool get_is_set_up_started() const {
		return set_up_phase == SET_UP_PHASE::IN_PROGRESS ||
				set_up_phase == SET_UP_PHASE::FINISHED;
	}

	bool get_is_set_up_finished() const {
		return set_up_phase == SET_UP_PHASE::FINISHED;
	}

	Ref<SettingsType> get_settings() const { return settings; }

protected:
	static void _bind_methods() {}

	bool are_types_registered = false;
	SET_UP_PHASE set_up_phase = SET_UP_PHASE::NOT_STARTED;

	Ref<SettingsType> settings;

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

	SettingsType *get_settings_from_list(
			TypedArray<SnoreCoreSettings> p_settings) const {
		const char *type_name = typeid(SettingsType).name();
		for (int i = 0; i < p_settings.size(); i++) {
			Object *object = p_settings[i].get_validated_object();
			SnoreCoreSettings *settings_obj =
					Object::cast_to<SnoreCoreSettings>(object);
			CHECK_SIMPLE(settings_obj);
			if (settings_obj->is_class(type_name)) {
				return static_cast<SettingsType *>(settings_obj);
			}
		}
		return nullptr;
	}
};

} //namespace godot

#endif // SNORE_CORE_MODULE_H
