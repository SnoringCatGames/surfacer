#ifndef SNORE_CORE_MODULE_UTILS_H
#define SNORE_CORE_MODULE_UTILS_H

#include <godot_cpp/classes/engine.hpp>

namespace godot {

namespace snore_core_module_utils_internal {

void register_snore_core_main_module_if_not_present();
void register_snore_core_module_to_snore_core_main_module(
		const StringName &p_module_name);
void unregister_snore_core_module_from_snore_core_main_module(
		const StringName &p_module_name);

} // namespace snore_core_module_utils_internal

#define REGISTER_ENGINE_SINGLETON(m_class)                                     \
	do {                                                                       \
		Engine::get_singleton()->register_singleton(                           \
				#m_class, memnew(m_class));                                    \
	} while (0)

void unregister_engine_singleton(const StringName &p_class_name);

#define REGISTER_SNORE_CORE_MODULE(m_class)                                    \
	do {                                                                       \
		snore_core_module_utils_internal::                                     \
				register_snore_core_main_module_if_not_present();              \
		REGISTER_ENGINE_SINGLETON(m_class);                                    \
		snore_core_module_utils_internal::                                     \
				register_snore_core_module_to_snore_core_main_module(          \
						#m_class);                                             \
	} while (0)

#define UNREGISTER_SNORE_CORE_MODULE(m_class)                                  \
	do {                                                                       \
		snore_core_module_utils_internal::                                     \
				unregister_snore_core_module_from_snore_core_main_module(      \
						#m_class);                                             \
		unregister_engine_singleton(#m_class);                                 \
	} while (0)

} //namespace godot

#endif // SNORE_CORE_MODULE_UTILS_H
