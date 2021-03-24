class_name PriorityQueue
extends Reference

###################################################################################################
# By Hamfist McMutton
# https://hamfistedgamedev.blogspot.com/p/godot-priorityqueue.html
# 
# License: CC0 1.0 Universal
#
# Statement of Purpose
# The laws of most jurisdictions throughout the world automatically confer exclusive Copyright and Related Rights (defined below) upon the creator and subsequent owner(s) (each and all, an "owner") of an original work of authorship and/or a database (each, a "Work").
# 
# Certain owners wish to permanently relinquish those rights to a Work for the purpose of contributing to a commons of creative, cultural and scientific works ("Commons") that the public can reliably and without fear of later claims of infringement build upon, modify, incorporate in other works, reuse and redistribute as freely as possible in any form whatsoever and for any purposes, including without limitation commercial purposes. These owners may contribute to the Commons to promote the ideal of a free culture and the further production of creative, cultural and scientific works, or to gain reputation or greater distribution for their Work in part through the use and efforts of others.
# 
# For these and/or other purposes and motivations, and without any expectation of additional consideration or compensation, the person associating CC0 with a Work (the "Affirmer"), to the extent that he or she is an owner of Copyright and Related Rights in the Work, voluntarily elects to apply CC0 to the Work and publicly distribute the Work under its terms, with knowledge of his or her Copyright and Related Rights in the Work and the meaning and intended legal effect of CC0 on those rights.
# 
# 1. Copyright and Related Rights. A Work made available under CC0 may be protected by copyright and related or neighboring rights ("Copyright and Related Rights"). Copyright and Related Rights include, but are not limited to, the following:
# 
#   i. the right to reproduce, adapt, distribute, perform, display, communicate, and translate a Work;
#   ii. moral rights retained by the original author(s) and/or performer(s);
#   iii. publicity and privacy rights pertaining to a person's image or likeness depicted in a Work;
#   iv. rights protecting against unfair competition in regards to a Work, subject to the limitations in paragraph 4(a), below;
#   v. rights protecting the extraction, dissemination, use and reuse of data in a Work;
#   vi. database rights (such as those arising under Directive 96/9/EC of the European Parliament and of the Council of 11 March 1996 on the legal protection of databases, and under any national implementation thereof, including any amended or successor version of such directive); and
#   vii. other similar, equivalent or corresponding rights throughout the world based on applicable law or treaty, and any national implementations thereof.
# 
# 2. Waiver. To the greatest extent permitted by, but not in contravention of, applicable law, Affirmer hereby overtly, fully, permanently, irrevocably and unconditionally waives, abandons, and surrenders all of Affirmer's Copyright and Related Rights and associated claims and causes of action, whether now known or unknown (including existing as well as future claims and causes of action), in the Work (i) in all territories worldwide, (ii) for the maximum duration provided by applicable law or treaty (including future time extensions), (iii) in any current or future medium and for any number of copies, and (iv) for any purpose whatsoever, including without limitation commercial, advertising or promotional purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each member of the public at large and to the detriment of Affirmer's heirs and successors, fully intending that such Waiver shall not be subject to revocation, rescission, cancellation, termination, or any other legal or equitable action to disrupt the quiet enjoyment of the Work by the public as contemplated by Affirmer's express Statement of Purpose.
# 
# 3. Public License Fallback. Should any part of the Waiver for any reason be judged legally invalid or ineffective under applicable law, then the Waiver shall be preserved to the maximum extent permitted taking into account Affirmer's express Statement of Purpose. In addition, to the extent the Waiver is so judged Affirmer hereby grants to each affected person a royalty-free, non transferable, non sublicensable, non exclusive, irrevocable and unconditional license to exercise Affirmer's Copyright and Related Rights in the Work (i) in all territories worldwide, (ii) for the maximum duration provided by applicable law or treaty (including future time extensions), (iii) in any current or future medium and for any number of copies, and (iv) for any purpose whatsoever, including without limitation commercial, advertising or promotional purposes (the "License"). The License shall be deemed effective as of the date CC0 was applied by Affirmer to the Work. Should any part of the License for any reason be judged legally invalid or ineffective under applicable law, such partial invalidity or ineffectiveness shall not invalidate the remainder of the License, and in such case Affirmer hereby affirms that he or she will not (i) exercise any of his or her remaining Copyright and Related Rights in the Work or (ii) assert any associated claims and causes of action with respect to the Work, in either case contrary to Affirmer's express Statement of Purpose.
# 
# 4. Limitations and Disclaimers.
# 
#   a. No trademark or patent rights held by Affirmer are waived, abandoned, surrendered, licensed or otherwise affected by this document.
#   b. Affirmer offers the Work as-is and makes no representations or warranties of any kind concerning the Work, express, implied, statutory or otherwise, including without limitation warranties of title, merchantability, fitness for a particular purpose, non infringement, or the absence of latent or other defects, accuracy, or the present or absence of errors, whether or not discoverable, all to the greatest extent permissible under applicable law.
#   c. Affirmer disclaims responsibility for clearing rights of other persons that may apply to the Work or any use thereof, including without limitation any person's Copyright and Related Rights in the Work. Further, Affirmer disclaims responsibility for obtaining any necessary consents, permissions or other rights required for any use of the Work.
#   d. Affirmer understands and acknowledges that Creative Commons is not a party to this document and has no duty or obligation with respect to this CC0 or use of the Work.
# 
###################################################################################################

var Self = get_script()

# Holds an arbitrary number of values sorted by a weight assigned to set values.
# 
# Structure is a balanced BST.
# 
# In order to compare non-int values, the input is in the form of an array of size 2:
#  - 0: Priority value in form of int or float.
#  - 1: Value to store.

const LOG2_BASE_E = 0.69314718056

var is_empty := true
# Number of elements in heap.
var current_size: int = 0
# The array holding the values.
# Array<[int|float, any]>
var items := [null]
var maintain_min: bool
var last_power_of_two := 0

func _init( \
        items := [], \
        set_maintain_min := true) -> void:
    # Determines whether the smallest or largest value is maintained at the top.
    maintain_min = set_maintain_min
    
    if items.size() > 0:
        last_power_of_two = ceil(log(items.size()) / LOG2_BASE_E)
        self.items.resize(pow(2, last_power_of_two) + 1)
        current_size = items.size()
        
        # Randomly populate the array.
        var i := 0
        while i < items.size():
            self.items[i + 1] = items[i]
            i += 1
        
        _build_heap()
    else:
        current_size = 0
        is_empty = true

# true means the root node is the one with lowest value.
# false means the queue will sort the highest value to the front.
func get_maintain_min() -> bool:
    return maintain_min

# Returns the smallest / biggest item ( = root) without deleting it.
func get_root_item():
    if !is_empty:
        return items[1]
    return null

# Returns the value of the smallest / biggest item ( = root) without deleting it.
func get_root_value():
    if !is_empty:
        return items[1][1]
    return null

# Returns the priority of root object.
func get_root_priority():
    if is_empty:
        return -1
    return items[1][0]

func get_item_priority(index: int):
    if index + 1 > current_size or index < 0:
        print( \
                str(OS.get_ticks_msec()) + \
                ": PRIORITY QUEUE (" + \
                str(get_instance_id()) + \
                "): get_item_priority(index) out of bounds! index = " + \
                str(index) + \
                ", current_size = " + \
                str(current_size))
        return false
    return items[index + 1][0]

func get_item_value(index: int):
    if index + 1 > current_size or index < 0:
        print( \
                str(OS.get_ticks_msec()) + \
                ": PRIORITY QUEUE (" + \
                str(get_instance_id()) + \
                "): get_item_priority(index) out of bounds! index = " + \
                str(index) + \
                ", current_size = " + \
                str(current_size))
        return false
    return items[index + 1][1]

# Returns the number of 'tiers' with at least one element in it.
func get_height() -> int:
    return ceil(log(items.size() - 1) / LOG2_BASE_E) as int

# Returns number of elements in the queue.
func get_size() -> int:
    return current_size

# Allows duplicates of priorities.
# - Insert new element into heap at the next available slot. Calling that "hole".
# - Then percolate the element up in the heap while heap-order property is not satisfied.
func insert(priority, value) -> bool:
    # Check validity of input.
    if typeof(priority) != TYPE_INT and typeof(priority) != TYPE_REAL:
        print( \
                str(OS.get_ticks_msec()) + \
                ": PRIORITY QUEUE (" + \
                str(get_instance_id()) + \
                "): Priority of incorrect type (" + \
                str(typeof(priority)) + \
                ") (should be float or int)! Aborting insert()")
        return false
    
    # Check for space left in array. If filled, open up a new layer.
    if current_size == items.size() - 1:
        items.resize(items.size() * 2)
        last_power_of_two += 1
    
    # Percolate up. Starting hole at the last free index of the array, move the hole downwards
    # until the parent node is smaller than the priority we want to sort in.
    current_size += 1
    is_empty = current_size < 0
    items[current_size] = [priority, value]
    _percolate_up(current_size)
    
    # Successfully inserted.
    return true

# Deletes minimum element.
# - Minimum element is always at the root.
# - Heap decreases by one in size.
# - Move last element into hole at root.
# - Percolate down while heap-order not satisfied.
func remove_root(return_array := false):
    if is_empty:
        print( \
                str(OS.get_ticks_msec()) + \
                ": PRIORITY QUEUE (" + \
                str(get_instance_id()) + \
                "): Can't delete root in empty heap! is_empty = true, current_size = " + \
                str(current_size))
        return null
    
    var rootItem = items[1] if return_array else items[1][1]
    
    # Place last element in front.
    items[1] = items[current_size]
    # Reduce size.
    current_size -= 1
    # Let last element ripple down to reestablish heap order.
    _percolate_down(1)
    is_empty = current_size < 1
    
    # Resize array (remove_root() is the only function to remove any items, since remove() calls
    # this).
    if current_size == pow(2, last_power_of_two - 1):
        last_power_of_two -= 1
        items.resize(pow(2, last_power_of_two) + 1)
    
    return rootItem

# - First, promote item to the top.
# - Then remove_min.
# - This removes the item from the tree.
# - Priority must be higher than the one at root.
func remove(index: int):
    if index + 1 > current_size or index < 0:
        print( \
                str(OS.get_ticks_msec()) + \
                ": PRIORITY QUEUE (" + \
                str(get_instance_id()) + \
                "): remove(index) out of bounds! index = " + \
                str(index) + \
                ", current_size = " + \
                str(current_size))
        return null
    
    var priority
    if maintain_min:
        # All cases except integer underflow caught.
        priority = get_root_priority() - 1
    else:
        # All cases except integer overflow.
        priority = get_root_priority() + 1
    
    _change_priority(index, priority)
    return remove_root()

# Put items of both queues into a new list.
# 
# Create new queue with those items and return that queue.
func merge_with( \
        priority_queue: PriorityQueue, \
        set_maintain_min = true) -> PriorityQueue:
    var list: = []
    var own_queue: = _get_queue()
    var other_queue: = priority_queue._get_queue()
    
    # Loop through own entries.
    var length_own: = own_queue.size() - 1
    var length_other: = other_queue.size() - 1
    var i: int = max(length_own, length_other)
    while i >= 0:
        if i < length_own:
            if (own_queue[i] != null):
                list.append(own_queue[i])
        if i < length_other:
            if (other_queue[i] != null):
                list.append(other_queue[i])
        i -= 1
    
    return Self.new(list, set_maintain_min)

# Establishes heap order property from an arbitrary arrangement of items.
# 
# Runs in linear time.
func _build_heap() -> void:
    # Start with lowest, rightmost internal node.
    var i := current_size / 2
    while i > 0:
        _percolate_down(i)
        i -= 1
    is_empty = current_size < 1

# Returns the complete queue without first (empty) entry as simple array.
func _get_queue() -> Array:
    var list := []
    var i := 0
    while i < items.size():
        if items[i] != null:
            list.append(items[i][1])
        i += 1
    return list

# Internal method to percolate down in the heap.
# hole is the index at which the percolate begins.
func _percolate_down(hole: int) -> void:
    var child: int
    var tmp: Array = items[hole]
    
    while hole * 2 <= current_size:
        if maintain_min:
            # Sort so smallest value is root.
            # hole * 2 is left child, child + 1 is the right child.
            child = hole * 2
            if child != current_size and items[child + 1][0] < items[child][0]:
                child += 1
            
            if items[child][0] < tmp[0]:
                # Pick child to swap with.
                items[hole] = items[child]
            else:
                break
            
            hole = child
        else:
            # Sort so biggest value is root.
            # hole * 2 is left child, child + 1 is the right child.
            child = hole * 2
            if child != current_size and items[child + 1][0] > items[child][0]:
                child += 1
            
            if items[child][0] > tmp[0]:
                # Pick child to swap with.
                items[hole] = items[child]
            else:
                break
            
            hole = child
    
    items[hole] = tmp

func _percolate_up(hole) -> void:
    var tmp: Array = items[hole]
    if maintain_min:
        # Sort smallest value towards root.
        while hole > 1 and tmp[0] < items[hole / 2][0]:
            # Get parent node and push it below.
            items[hole] = items[hole / 2]
            hole /= 2
    else:
        # Sort biggest value towards root.
        while hole > 1 and tmp[0] > items[hole / 2][0]:
            # Get parent node and push it below.
            items[hole] = items[hole / 2]
            hole /= 2
    
    items[hole] = tmp

# Changes priority of the item at index to new_priority.
# 
# - If the new priority value is higher, this means the item was demoted, so we need to percolate
#   down.
# - If the new priority value is lower, the item has been promoted and needs to percolate up.
func _change_priority(index: int, new_priority) -> bool:
    if index < 0 or index + 1 > current_size:
        # Invalid index for array. Abort.
        print( \
                str(OS.get_ticks_msec()) + \
                ": PRIORITY QUEUE (" + \
                str(get_instance_id()) + \
                "): Can't access array at index '" + \
                str(index) + \
                "', out of bounds!")
        return false
    
    if typeof(new_priority) != TYPE_INT and typeof(new_priority) != TYPE_REAL:
        # Invalid priority parameter. Abort.
        print( \
                str(OS.get_ticks_msec()) + \
                ": PRIORITY QUEUE (" + \
                str(get_instance_id()) + \
                "): Can't assign priority '" + \
                str(new_priority) + \
                "', NaN!")
        return false
            
    var node = items[index + 1]
    if maintain_min:
        # Sort smallest value towards root.
        if new_priority < node[0]:
            # Item was promoted, move it ahead in the queue.
            node[0] = new_priority
            _percolate_up(index + 1)
            return true
        elif new_priority > node[0]:
            # Item was demoted, move it back in the queue.
            node[0] = new_priority
            _percolate_down(index + 1)
            return true
    else:
        # Sort highest value towards root.
        if new_priority > node[0]:
            # Item was promoted, move it ahead in the queue.
            node[0] = new_priority
            _percolate_up(index + 1)
            return true
        elif new_priority < node[0]:
            # Item was demoted, move it back in the queue.
            node[0] = new_priority
            _percolate_down(index + 1)
            return true
    
    # Implied else: do nothing, priority hasn't changed.
    return true
