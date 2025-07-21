#ifndef TEST_SNORE_CORE_MODULE_H
#define TEST_SNORE_CORE_MODULE_H

#ifdef SC_TESTS_ENABLED

#include "snore_core/internal/ref_utils.h"
#include "snore_core/internal/string_utils.h"
#include "snore_core/internal/test_utils.h"
#include "snore_core/snore_core_module.h"
#include "snore_core/snore_core_settings.h"

#include "snore_core/internal/test_utils.h"
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#include <string>
#include <vector>

using namespace godot;

// Test settings class for testing SnoreCoreModule.
class FakeSnoreCoreSettings : public SnoreCoreSettings {
	GDCLASS(FakeSnoreCoreSettings, SnoreCoreSettings)

public:
	FakeSnoreCoreSettings() = default;
	virtual ~FakeSnoreCoreSettings() = default;

	bool get_test_flag() const { return test_flag; }
	void set_test_flag(bool p_value) { test_flag = p_value; }

protected:
	static void _bind_methods() {}

private:
	bool test_flag = false;
};

// Test module class for testing SnoreCoreModule template functionality.
class FakeSnoreCoreModule : public SnoreCoreModule<FakeSnoreCoreSettings> {
	GDCLASS(FakeSnoreCoreModule, SnoreCoreModule)

public:
	static const constexpr char *name = "TestModule";

	FakeSnoreCoreModule() = default;
	virtual ~FakeSnoreCoreModule() = default;

	virtual const StringName &get_name() const override {
		static const StringName string_name = StringName(name);
		return string_name;
	}

	virtual const StringName &get_settings_class_name() const override {
		return FakeSnoreCoreSettings::get_class_static();
	}

	virtual FakeSnoreCoreSettings *cast_to_settings(
			Object *p_object) const override {
		return Object::cast_to<FakeSnoreCoreSettings>(p_object);
	}

	virtual void set_settings(FakeSnoreCoreSettings *p_settings) override {
		settings = Ref<FakeSnoreCoreSettings>(p_settings);
	}

	virtual void set_up() override {
		set_up_called = true;
		on_set_up_finished();
	}

	virtual void reset() override {
		reset_called = true;
		set_up_called = false;
	}

	bool get_set_up_called() const { return set_up_called; }
	bool get_reset_called() const { return reset_called; }

	// Shadow the base method to prevent calling
	// SnoreCoreModuleInternal::notify_main_module_of_module_set_up_finished.
	void on_set_up_finished() {
		if (!ENSURE(set_up_phase == SET_UP_PHASE::IN_PROGRESS,
					"Cannot finish set_up when it is not in progress.")) {
			return;
		}

		set_up_phase = SET_UP_PHASE::FINISHED;
	}

protected:
	static void _bind_methods() {}

private:
	bool set_up_called = false;
	bool reset_called = false;
};

// Test fixtures for SnoreCore module testing.
class SnoreCoreModuleTest : public ::testing::Test {
protected:
	void SetUp() override {
		test_module = memnew(FakeSnoreCoreModule);
		test_settings.instantiate();
	}

	void TearDown() override {
		memdelete(test_module);
		test_module = nullptr;
		test_settings.unref();
	}

	FakeSnoreCoreModule *test_module;
	Ref<FakeSnoreCoreSettings> test_settings;
};

// Test cases for SnoreCoreModule functionality.
TEST_F(SnoreCoreModuleTest, InitialState) {
	EXPECT_EQ(
			SnoreCoreModule<FakeSnoreCoreSettings>::SET_UP_PHASE::NOT_STARTED,
			test_module->get_set_up_phase());
	EXPECT_FALSE(test_module->get_is_set_up_started());
	EXPECT_FALSE(test_module->get_is_set_up_finished());
	EXPECT_FALSE(test_module->get_set_up_called());
	EXPECT_FALSE(test_module->get_reset_called());
}

TEST_F(SnoreCoreModuleTest, GetName) {
	StringName expected_name = StringName("TestModule");
	EXPECT_EQ(expected_name, test_module->get_name());
}

TEST_F(SnoreCoreModuleTest, GetSettingsClassName) {
	StringName expected_class_name = FakeSnoreCoreSettings::get_class_static();
	EXPECT_EQ(expected_class_name, test_module->get_settings_class_name());
}

TEST_F(SnoreCoreModuleTest, SetUpBase) {
	test_settings->set_test_flag(true);

	test_module->set_up_base(test_settings.ptr());

	EXPECT_EQ(
			SnoreCoreModule<FakeSnoreCoreSettings>::SET_UP_PHASE::FINISHED,
			test_module->get_set_up_phase());
	EXPECT_TRUE(test_module->get_is_set_up_started());
	EXPECT_TRUE(test_module->get_is_set_up_finished());
	EXPECT_TRUE(test_module->get_set_up_called());
	EXPECT_TRUE(test_module->get_reset_called());

	Ref<FakeSnoreCoreSettings> retrieved_settings = test_module->get_settings();
	EXPECT_TRUE(retrieved_settings.is_valid());
	EXPECT_TRUE(retrieved_settings->get_test_flag());
}

TEST_F(SnoreCoreModuleTest, ResetBase) {
	// First set up the module.
	test_module->set_up_base(test_settings.ptr());
	EXPECT_TRUE(test_module->get_is_set_up_finished());

	// Reset should change state back to NOT_STARTED.
	test_module->reset_base();

	EXPECT_EQ(
			SnoreCoreModule<FakeSnoreCoreSettings>::SET_UP_PHASE::NOT_STARTED,
			test_module->get_set_up_phase());
	EXPECT_FALSE(test_module->get_is_set_up_started());
	EXPECT_FALSE(test_module->get_is_set_up_finished());
	EXPECT_FALSE(test_module->get_set_up_called());
	EXPECT_TRUE(test_module->get_reset_called());
}

TEST_F(SnoreCoreModuleTest, GetSettingsFromList) {
	TypedArray<SnoreCoreSettings> settings_list;
	settings_list.push_back(test_settings);

	FakeSnoreCoreSettings *found_settings =
			test_module->get_settings_from_list(settings_list);

	EXPECT_EQ(test_settings.ptr(), found_settings);
}

#endif // SC_TESTS_ENABLED

#endif // TEST_SNORE_CORE_MODULE_H
