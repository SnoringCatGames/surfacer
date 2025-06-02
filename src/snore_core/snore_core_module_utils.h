#ifndef SNORE_CORE_MODULE_UTILS_H
#define SNORE_CORE_MODULE_UTILS_H

#include <godot_cpp/classes/engine.hpp>

namespace godot {

namespace SnoreCoreModuleUtils_Internal {

void RegisterSnoreCoreMainModuleIfNotPresent();
void UnregisterSnoreCoreMainModuleIfNoModulesRemain();
void RegisterSnoreCoreModuleToSnoreCoreMainModule(
		const StringName &p_module_name);
void UnregisterSnoreCoreModuleFromSnoreCoreMainModule(
		const StringName &p_module_name);

} // namespace SnoreCoreModuleUtils_Internal

#define REGISTER_ENGINE_SINGLETON(m_class)                                     \
	do {                                                                       \
		Engine::get_singleton()->register_singleton(                           \
				#m_class, memnew(m_class));                                    \
	} while (0)

#define UNREGISTER_ENGINE_SINGLETON(m_class)                                   \
	do {                                                                       \
		Object *singleton = Engine::get_singleton()->get_singleton(#m_class);  \
		Engine::get_singleton()->unregister_singleton(#m_class);               \
		memdelete(singleton);                                                  \
	} while (0)

#define REGISTER_SNORE_CORE_MODULE(m_class)                                    \
	do {                                                                       \
		SnoreCoreModuleUtils_Internal::                                        \
				RegisterSnoreCoreMainModuleIfNotPresent();                     \
		REGISTER_ENGINE_SINGLETON(m_class);                                    \
		SnoreCoreModuleUtils_Internal::                                        \
				RegisterSnoreCoreModuleToSnoreCoreMainModule(#m_class);        \
	} while (0)

#define UNREGISTER_SNORE_CORE_MODULE(m_class)                                  \
	do {                                                                       \
		SnoreCoreModuleUtils_Internal::                                        \
				UnregisterSnoreCoreModuleFromSnoreCoreMainModule(#m_class);    \
		UNREGISTER_ENGINE_SINGLETON(m_class);                                  \
		SnoreCoreModuleUtils_Internal::                                        \
				UnregisterSnoreCoreMainModuleIfNoModulesRemain();              \
	} while (0)

} //namespace godot

#endif // SNORE_CORE_MODULE_UTILS_H
