#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

class GDExample : public Sprite2D {
	GDCLASS(GDExample, Sprite2D)

private:
	double time_passed = 0.0;
	double time_emit = 0.0;
	double amplitude = 10.0;
	double speed = 1.0;

protected:
	static void _bind_methods();

public:
	GDExample();
	~GDExample();

	virtual void _process(double delta) override;

    void set_amplitude(double p_amplitude);
    double get_amplitude() const;

    void set_speed(double p_speed);
    double get_speed() const;
};

}

#endif
