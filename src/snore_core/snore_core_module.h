#ifndef SNORE_CORE_MODULE_H
#define SNORE_CORE_MODULE_H

#include "snore_core/internal/internal_debug_utils.h"
#include "snore_core/internal/internal_ref_utils.h"
#include "snore_core/snore_core_settings.h"

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

template <typename SettingsType> class SnoreCoreModule;

namespace SnoreCoreModuleInternal {
void notify_main_module_of_module_set_up_finished(const StringName &p_name);
} // namespace SnoreCoreModuleInternal

template <typename SettingsType> class SnoreCoreModule : public RefCounted {
	GDCLASS(SnoreCoreModule, RefCounted)

	static_assert(
			std::is_base_of<SnoreCoreSettings, SettingsType>::value,
			"SettingsType must be derived from SnoreCoreSettings");

public:
	enum SET_UP_PHASE {
		NOT_STARTED,
		IN_PROGRESS,
		FINISHED,
	};

	SnoreCoreModule() { settings = instantiate_ref<SettingsType>(); }
	virtual ~SnoreCoreModule() { settings.unref(); }

	virtual const StringName &get_name() const = 0;
	virtual const StringName &get_settings_class_name() const = 0;
	virtual SettingsType *cast_to_settings(Object *p_object) const = 0;
	virtual void set_settings(SettingsType *p_settings) = 0;

	// This is called during game runtime, after settings are loaded.
	virtual void set_up() = 0;

	// This is called during game runtime, before calling set_up.
	virtual void reset() = 0;

	// This resets some base state before calling reset().
	void reset_base() {
		settings.unref();
		set_up_phase = SET_UP_PHASE::NOT_STARTED;
		reset();
	}

	// This sets some tracking state before calling set_up().
	void set_up_base(SettingsType *p_settings) {
		reset_base();
		set_up_phase = SET_UP_PHASE::IN_PROGRESS;
		set_settings(p_settings);
		set_up();
	}

	SET_UP_PHASE get_set_up_phase() const { return set_up_phase; }

	bool get_is_set_up_started() const {
		return set_up_phase == SET_UP_PHASE::IN_PROGRESS ||
				set_up_phase == SET_UP_PHASE::FINISHED;
	}

	bool get_is_set_up_finished() const {
		return set_up_phase == SET_UP_PHASE::FINISHED;
	}

	Ref<SettingsType> get_settings() const { return settings; }

	SettingsType *get_settings_from_list(
			TypedArray<SnoreCoreSettings> p_all_settings) const {
		const StringName target_class_name = get_settings_class_name();

		for (int i = 0; i < p_all_settings.size(); i++) {
			Object *object = p_all_settings[i].get_validated_object();
			// NOTE: Godot's ClassDB fails to correctly handle generic types, so
			//       Object::cast_to<SettingsType>(object) won't work here (even
			//       though object->get_class() _will_ correctly return the
			//       subclass's name).
			SettingsType *settings_obj = cast_to_settings(object);
			if (settings_obj) {
				return settings_obj;
			}
		}

		ENSURE(false, "Cannot find settings of type: " + target_class_name);

		return nullptr;
	}

protected:
	static void _bind_methods() {}

	SET_UP_PHASE set_up_phase = SET_UP_PHASE::NOT_STARTED;

	Ref<SettingsType> settings;

	void on_set_up_finished() {
		if (!ENSURE(set_up_phase == SET_UP_PHASE::IN_PROGRESS,
					"Cannot finish set_up when it is not in progress.")) {
			return;
		}

		set_up_phase = SET_UP_PHASE::FINISHED;

		SnoreCoreModuleInternal::notify_main_module_of_module_set_up_finished(
				get_name());
	}
};

} //namespace godot

#endif // SNORE_CORE_MODULE_H
