#ifndef SURFACE_SIDE_H
#define SURFACE_SIDE_H

#include <godot_cpp/core/binder_common.hpp>

namespace godot {
enum SurfaceSide
{
    NONE,
    FLOOR,
    CEILING,
    LEFT_WALL,
    RIGHT_WALL,
};
}
VARIANT_ENUM_CAST(SurfaceSide);

#endif
