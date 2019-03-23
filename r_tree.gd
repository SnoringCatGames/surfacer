extends Reference
class_name RTree

# An R-tree implementation that stores AABBs.

# TODO: Replace this with a GDNative version (with C++ bindings) once Godot supports HTML5 export 
#       with GDNative (https://github.com/godotengine/godot/issues/12243).

# FIXME:
# - for loops
# - Array methods: length, push, pop, sort, ...
# - falsey/truthy conditionals
# - 

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
func subarray(array: Array, start: int, length: int):
    var result = range(length)
    for i in result:
        result[i] = array[start + i]
    return result

###################################################################################################
# Adapted from the rbush library
# https://github.com/mourner/rbush
#
# MIT License
#
# Copyright (c) 2016 Vladimir Agafonkin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
###################################################################################################

var root: Dictionary

var _minEntries: int
var _max_entries: int

func _init(maxEntries: int = 9) -> void:
    # max entries in a node is 9 by default; min node fill is 40% for best performance
    _max_entries = max(4, maxEntries or 9)
    _minEntries = max(2, ceil(_max_entries * 0.4))

    clear()

func all() -> Array:
    return _all(root, [])

func search(bbox: Dictionary) -> Array:
    var node := root
    var result := []

    if !intersects(bbox, node):
        return result

    var nodes_to_search := []
    var i: int
    var length: int
    var child: Dictionary
    var childBBox: Dictionary

    while node != null:
        for (i = 0, length = node.children.size(); i < length; i += 1):
            child = node.children[i]
            childBBox = child

            if intersects(bbox, childBBox):
                if node.is_leaf:
                    result.push_back(child)
                elif contains(bbox, childBBox):
                    _all(child, result)
                else:
                    nodes_to_search.push_back(child)
        node = nodes_to_search.pop_back()

    return result

func collides(bbox: Dictionary) -> bool:
    var node := root

    if !intersects(bbox, node):
        return false

    var nodes_to_search := []
    var i: int
    var length: int
    var child: Dictionary
    var childBBox: Dictionary

    while node != null:
        for (i = 0, length = node.children.size(); i < length; i += 1):
            child = node.children[i]
            childBBox = child

            if intersects(bbox, childBBox):
                if node.is_leaf or contains(bbox, childBBox):
                    return true
                nodes_to_search.push_back(child)
        node = nodes_to_search.pop_back()

    return false

func load(dataset: Array) -> RTree:
    if dataset == null or dataset.empty():
        return self

    if dataset.size() < _minEntries:
        for (var i = 0, length = dataset.size(); i < length; i += 1):
            insert(dataset[i])
        return self

    # recursively build the tree with the given data from scratch using OMT algorithm
    var node = _build(dataset, 0, dataset.size() - 1, 0)

    if root.children.empty():
        # save as is if tree is empty
        root = node

    elif root.height == node.height:
        # split root if trees have the same height
        _split_root(root, node)

    else:
        if root.height < node.height:
            # swap trees if inserted one is bigger
            var tmpNode := root
            root = node
            node = tmpNode

        # insert the small tree into the large tree at appropriate level
        _insert(node, root.height - node.height - 1, true)

    return self

func insert(item: Dictionary) -> RTree:
    if item != null:
        _insert(item, root.height - 1)
    return self

func clear() -> RTree:
    root = create_node([])
    return self

# FIXME: equals_fn
func remove(item: Dictionary, equals_fn) -> RTree:
    if item == null:
        return self

    var node := root
    var bbox := item
    var path := [],
    var indexes := [],
    var i: int
    var parent: Dictionary
    var index: int
    var going_up: bool

    # depth-first iterative tree traversal
    while node != null or path.size() > 0:
        if node == null:
            # go up
            node = path.pop_back()
            parent = path[path.length - 1]
            i = indexes.pop_back()
            going_up = true

        if node.is_leaf:
            # check current node
            index = find_item(item, node.children, equals_fn)

            if index != -1:
                # item found, remove the item and condense tree upwards
                node.children.remove(index)
                path.push_back(node)
                _condense(path)
                return self

        if !going_up and !node.is_leaf and contains(node, bbox):
            path.push_back(node)
            indexes.push_back(i)
            i = 0
            parent = node
            node = node.children[0]

        elif parent != null:
            # go right
            i += 1
            node = parent.children[i]
            going_up = false

        else:
            # nothing found
            node = null

    return self

func _all(node: Dictionary, result: Array) -> Array:
    var nodes_to_search := []
    while node != null:
        if node.is_leaf:
            result.push.apply(result, node.children)
        else:
            nodes_to_search.push.apply(nodes_to_search, node.children)

        node = nodes_to_search.pop_Back()
    return result

func _build(items: Array, left: int, right: int, height: int) -> Dictionary:
    var N := right - left + 1
    var M := _max_entries
    var node: Dictionary

    if N <= M:
        # reached leaf level; return leaf
        node = create_node(subarray(items, left, right + 1 - left))
        calc_bbox(node)
        return node

    if height > 0:
        # target height of the bulk-loaded tree
        height = ceil(log(N) / log(M))

        # target number of root entries to maximize storage utilization
        M = ceil(N / pow(M, height - 1))

    node = create_node([])
    node.is_leaf = false
    node.height = height

    # split the items into M mostly square tiles

    var N2 := ceil(N / M)
    var N1 := N2 * ceil(sqrt(M))
    var i: int
    var j: int
    var right2: int
    var right3: int

    multi_select_min_y(items, left, right, N1)

    for (i = left; i <= right; i += N1):
        right2 = min(i + N1 - 1, right)

        multi_select_min_y(items, i, right2, N2)

        for (j = i; j <= right2; j += N2):
            right3 = min(j + N2 - 1, right2)

            # pack each entry recursively
            node.children.push(_build(items, j, right3, height - 1))

    calc_bbox(node)

    return node

func _choose_subtree(bbox: Dictionary, node: Dictionary, level: int, path: Array) -> Dictionary:
    var i: int
    var length: int
    var child: Dictionary
    var target_node: Dictionary
    var area: float
    var enlargement: float
    var min_area: float
    var min_enlargement: float

    while true:
        path.push_back(node)

        if node.is_leaf or path.length - 1 == level:
            break

        min_area = INF
        min_enlargement = INF

        for (i = 0, length = node.children.length; i < length; i += 1):
            child = node.children[i]
            area = bbox_area(child)
            enlargement = enlarged_area(bbox, child) - area

            # choose entry with the least area enlargement
            if enlargement < min_enlargement:
                min_enlargement = enlargement
                min_area = area if area < min_area else min_area
                target_node = child

            elif enlargement == min_enlargement:
                # otherwise choose one with the smallest area
                if area < min_area:
                    min_area = area
                    target_node = child

        node = target_node if target_node != null else node.children[0]

    return node

func _insert(item: Dictionary, level: int, is_node: bool) -> void:
    var bbox := item
    var insert_path := []

    # find the best node for accommodating the item, saving all nodes along the path too
    var node := _choose_subtree(bbox, root, level, insert_path)

    # put the item into the node
    node.children.push(item)
    extend(node, bbox)

    # split on node overflow; propagate upwards if necessary
    while level >= 0:
        if insert_path[level].children.size() > _max_entries:
            _split(insert_path, level)
            level -= 1
        else:
            break

    # adjust bboxes along the insertion path
    _adjust_parent_bboxes(bbox, insert_path, level)

# split overflowed node into two
func _split(insert_path: Array, level: int) -> void:
    var node: Dictionary = insert_path[level]
    var M := node.children.size()
    var m := _minEntries

    _choose_split_axis(node, m, M)

    var split_index := _choose_split_index(node, m, M)

    var new_node := create_node(subarray(node.children, split_index, node.children.size() - split_index))
    new_node.height = node.height
    new_node.is_leaf = node.is_leaf

    calc_bbox(node)
    calc_bbox(new_node)

    if level != null:
        insert_path[level - 1].children.push(new_node)
    else:
        _split_root(node, new_node)

func _split_root(node: Dictionary, new_node: Dictionary) -> void:
    # split root node
    root = create_node([node, new_node])
    root.height = node.height + 1
    root.is_leaf = false
    calc_bbox(root)

func _choose_split_index(node: Dictionary, m: int, M: int) -> int:
    var i: int
    var bbox1: Dictionary
    var bbox2: Dictionary
    var overlap: float
    var area: float
    var min_overlap: float
    var min_area: float
    var index: int

    min_overlap = min_area = INF

    for (i = m; i <= M - m; i += 1):
        bbox1 = dist_bbox(node, 0, i)
        bbox2 = dist_bbox(node, i, M)

        overlap = intersection_area(bbox1, bbox2)
        area = bbox_area(bbox1) + bbox_area(bbox2)

        # choose distribution with minimum overlap
        if overlap < min_overlap:
            min_overlap = overlap
            index = i

            min_area = area if area < min_area else min_area

        elif overlap == min_overlap:
            # otherwise choose distribution with minimum area
            if area < min_area:
                min_area = area
                index = i

    return index

# sorts node children by the best axis for split
func _choose_split_axis(node: Dictionary, m: int, M: int) -> void:
    var x_margin := _all_dist_margin(node, m, M, _compare_min_x)
    var y_margin := _all_dist_margin(node, m, M, _compare_min_y)

    # if total distributions margin value is minimal for x, sort by min_x,
    # otherwise it's already sorted by min_y
    if x_margin < y_margin:
        node.children.sort(_compare_min_x)

# total margin of all possible split distributions where each node is at least m full
# FIXME: refactor compare
func _all_dist_margin(node: Dictionary, m: int, M: int, compare) -> float:
    node.children.sort(compare)

    var left_bbox := dist_bbox(node, 0, m)
    var right_bbox := dist_bbox(node, M - m, M)
    var margin := bbox_margin(left_bbox) + bbox_margin(right_bbox)
    var i: int
    var child: Dictionary

    for (i = m; i < M - m; i += 1):
        child = node.children[i]
        extend(left_bbox, child)
        margin += bbox_margin(left_bbox)

    for (i = M - m - 1; i >= m; i -= 1):
        child = node.children[i]
        extend(right_bbox, child)
        margin += bbox_margin(right_bbox)

    return margin

func _adjust_parent_bboxes(bbox: Dictionary, path: Array, level: int) -> void:
    # adjust bboxes along the given tree path
    for (var i = level; i >= 0; i -= 1):
        extend(path[i], bbox)

func _condense(path: Array) -> void:
    # go through the path, removing empty nodes and updating bboxes
    for (var i = path.size() - 1, siblings; i >= 0; i -= 1):
        if path[i].children.size() == 0:
            if i > 0:
                siblings = path[i - 1].children
                siblings.remove(siblings.find(path[i]))
            else:
                clear()
        else:
            calc_bbox(path[i])

# FIXME: refactor equals_fn
func find_item(item: Dictionary, items: Array, equals_fn) -> int:
    if equals_fn == null:
        return items.find(item)

    for (var i = 0; i < items.length; i += 1):
        if equals_fn(item, items[i]):
            return i
    return -1

# calculate node's bbox from bboxes of its children
func calc_bbox(node: Dictionary) -> Dictionary:
    dist_bbox(node, 0, node.children.size(), node)

# min bounding rectangle of node children from k to p-1
func dist_bbox(node: Dictionary, k: int, p: int, dest_node: Dictionary) -> Dictionary:
    if dest_node == null:
        dest_node = create_node(null)
    dest_node.min_x = INF
    dest_node.min_y = INF
    dest_node.max_x = -INF
    dest_node.max_y = -INF

    for (var i = k, child; i < p; i += 1):
        child = node.children[i]
        extend(dest_node, child)

    return dest_node

func extend(a: Dictionary, b: Dictionary) -> Dictionary:
    a.min_x = min(a.min_x, b.min_x)
    a.min_y = min(a.min_y, b.min_y)
    a.max_x = max(a.max_x, b.max_x)
    a.max_y = max(a.max_y, b.max_y)
    return a

func _compare_min_x(a: Dictionary, b: Dictionary) -> float:
    return a.min_x - b.min_x
func _compare_min_y(a: Dictionary, b: Dictionary) -> float:
    return a.min_y - b.min_y

func bbox_area(a: Dictionary) -> float:
    return (a.max_x - a.min_x) * (a.max_y - a.min_y)
func bbox_margin(a: Dictionary) -> float:
    return (a.max_x - a.min_x) + (a.max_y - a.min_y)

func enlarged_area(a: Dictionary, b: Dictionary) -> float:
    return (max(b.max_x, a.max_x) - min(b.min_x, a.min_x)) * \
           (max(b.max_y, a.max_y) - min(b.min_y, a.min_y))

func intersection_area(a: Dictionary, b: Dictionary) -> float:
    var min_x := max(a.min_x, b.min_x)
    var min_y := max(a.min_y, b.min_y)
    var max_x := min(a.max_x, b.max_x)
    var max_y := min(a.max_y, b.max_y)

    return max(0, max_x - min_x) * \
           max(0, max_y - min_y)

func contains(a: Dictionary, b: Dictionary) -> bool:
    return a.min_x <= b.min_x and \
           a.min_y <= b.min_y and \
           b.max_x <= a.max_x and \
           b.max_y <= a.max_y

func intersects(a: Dictionary, b: Dictionary) -> bool:
    return b.min_x <= a.max_x and \
           b.min_y <= a.max_y and \
           b.max_x >= a.min_x and \
           b.max_y >= a.min_y

func create_node(children: Array) -> Dictionary:
    return {
        children: children,
        height: 1,
        is_leaf: true,
        min_x: INF,
        min_y: INF,
        max_x: -INF,
        max_y: -INF
    }

# sort an array so that items come in groups of n unsorted items, with groups sorted between each other
# combines selection algorithm with binary divide & conquer approach

func multi_select_min_x(arr: Array, left: int, right: int, n: int) -> void:
    var stack := [left, right]
    var mid: int

    while !stack.empty():
        right = stack.pop()
        left = stack.pop()

        if right - left <= n:
            continue

        mid = left + ceil((right - left) / n / 2) * n
        quickselect_min_x(arr, mid, left, right)

        stack.push(left, mid, mid, right)

func multi_select_min_y(arr: Array, left: int, right: int, n: int) -> void:
    var stack := [left, right]
    var mid: int

    while !stack.empty():
        right = stack.pop()
        left = stack.pop()

        if right - left <= n:
            continue

        mid = left + ceil((right - left) / n / 2) * n
        quickselect_min_y(arr, mid, left, right)

        stack.push(left, mid, mid, right)

###################################################################################################
# Adapted from the rbush-knn library
# https://github.com/mourner/rbush-knn
#
# ISC License
#
# Copyright (c) 2016, Vladimir Agafonkin
#
# Permission to use, copy, modify, and/or distribute this software for any purpose
# with or without fee is hereby granted, provided that the above copyright notice
# and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
# THIS SOFTWARE.
###################################################################################################

# FIXME: refactor predicate
func knn(tree, x: float, y: float, n: int, predicate, max_distance: float) -> Array:
    var node: Dictionary = tree.root
    var result: Array = []
    var i: int
    var child: Variant
    var dist: float
    var candidate: Variant

    var queue = PriorityQueue.new(null)

    while node != null:
        for (i = 0; i < node.children.length; i += 1):
            child = node.children[i]
            dist = boxDist(x, y, child)
            if max_distance == 0 or dist <= max_distance:
                queue.push({
                    node: child,
                    is_item: node.is_leaf,
                    dist: dist
                })

        while queue.length > 0 and queue.peek().is_item:
            candidate = queue.pop().node
            if predicate == null or predicate(candidate):
                result.push_back(candidate)
            if n > 0 and result.size() == n:
                return result

        node = queue.pop()
        if node != null:
            node = node.node

    return result

func compare_dist(a: float, b: float) -> float:
    return a.dist - b.dist

# FIXME: box type
func boxDist(x: float, y: float, box) -> float:
    var dx = axis_dist(x, box.min_x, box.max_x)
    var dy = axis_dist(y, box.min_y, box.max_y)
    return dx * dx + dy * dy

func axis_dist(k: float, min_value: float, max_value: float) -> float:
    return min_value - k if k < min_value else \
            (0 if k <= max_value else k - max_value)

###################################################################################################
# Adapted from the quickselect library
# https://github.com/mourner/quickselect
#
# ISC License
#
# Copyright (c) 2018, Vladimir Agafonkin
#
# Permission to use, copy, modify, and/or distribute this software for any purpose
# with or without fee is hereby granted, provided that the above copyright notice
# and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
# THIS SOFTWARE.
###################################################################################################

func quickselect_min_x(arr: Array, k: int, left: int, right: int) -> void:
    while right > left:
        if right - left > 600:
            var n := right - left + 1
            var m := k - left + 1
            var z := log(n)
            var s := 0.5 * exp(2 * z / 3)
            var sd := 0.5 * sqrt(z * s * (n - s) / n) * (-1 if m - n / 2 < 0 else 1)
            var new_left := max(left, floor(k - m * s / n + sd))
            var new_right := min(right, floor(k + (n - m) * s / n + sd))
            quickselect_min_x(arr, k, new_left, new_right)

        var t := arr[k]
        var i := left
        var j := right

        _swap(arr, left, k)
        if _compare_min_x(arr[right], t) > 0:
            _swap(arr, left, right)

        while i < j:
            _swap(arr, i, j)
            i += 1
            j -= 1
            while _compare_min_x(arr[i], t) < 0:
                i += 1
            while _compare_min_x(arr[j], t) > 0:
                j -= 1

        if _compare_min_x(arr[left], t) == 0:
            _swap(arr, left, j)
        else:
            j += 1
            _swap(arr, j, right)

        if j <= k:
            left = j + 1
        if k <= j:
            right = j - 1

func quickselect_min_y(arr: Array, k: int, left: int, right: int) -> void:
    while right > left:
        if right - left > 600:
            var n := right - left + 1
            var m := k - left + 1
            var z := log(n)
            var s := 0.5 * exp(2 * z / 3)
            var sd := 0.5 * sqrt(z * s * (n - s) / n) * (-1 if m - n / 2 < 0 else 1)
            var new_left := max(left, floor(k - m * s / n + sd))
            var new_right := min(right, floor(k + (n - m) * s / n + sd))
            quickselect_min_y(arr, k, new_left, new_right)

        var t := arr[k]
        var i := left
        var j := right

        _swap(arr, left, k)
        if _compare_min_y(arr[right], t) > 0:
            _swap(arr, left, right)

        while i < j:
            _swap(arr, i, j)
            i += 1
            j -= 1
            while _compare_min_y(arr[i], t) < 0:
                i += 1
            while _compare_min_y(arr[j], t) > 0:
                j -= 1

        if _compare_min_y(arr[left], t) == 0:
            _swap(arr, left, j)
        else:
            j += 1
            _swap(arr, j, right)

        if j <= k:
            left = j + 1
        if k <= j:
            right = j - 1

func _swap(arr: Array, i: int, j: int) -> void:
    var tmp: Variant = arr[i]
    arr[i] = arr[j]
    arr[j] = tmp

###################################################################################################
# Adapted from the tinyqueue library
# https://github.com/mourner/tinyqueue
#
# ISC License
# 
# Copyright (c) 2017, Vladimir Agafonkin
#
# Permission to use, copy, modify, and/or distribute this software for any purpose
# with or without fee is hereby granted, provided that the above copyright notice
# and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
# THIS SOFTWARE.
###################################################################################################

class PriorityQueue extends Reference:
    class_name PriorityQueue
    
    var items: Array
    var length: int
    
    func _init(items: Array = []) -> void:
        self.items = items
        length = items.size()

        if length > 0:
            for (var i = (length >> 1) - 1; i >= 0; i -= 1):
                _down(i)

    func push(item: Variant) -> void:
        items.push_back(item)
        length += 1
        _up(length - 1)

    func pop() -> Variant:
        if length == 0:
            return null

        var top: Variant = items[0]
        var bottom: Variant = items.pop_back()
        length -= 1

        if length > 0:
            items[0] = bottom
            _down(0)

        return top

    func peek() -> Variant:
        return items[0]

    func _up(pos: int) -> void:
        var item = items[pos]

        while pos > 0:
            var parent := (pos - 1) >> 1
            var current: Variant = items[parent]
            
            if compare_dist(item, current) >= 0:
                break
                
            items[pos] = current
            pos = parent

        items[pos] = item

    func _down(pos: int) -> void:
        var half_length := length >> 1
        var item: Variant = items[pos]

        while pos < half_length:
            var left := (pos << 1) + 1
            var best: Variant = items[left]
            var right := left + 1

            if right < length and compare_dist(items[right], best) < 0:
                left = right
                best = items[right]
            if compare_dist(best, item) >= 0:
                break

            items[pos] = best
            pos = left

        items[pos] = item
