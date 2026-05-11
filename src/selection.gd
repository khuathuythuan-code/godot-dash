## Selection.gd
## GDScript port của rust/src/selection.rs — dùng cho web build.
##
## CÁCH DÙNG:
## 1. Đặt file này vào res://src/Selection.gd
## 2. KHÔNG có class_name → không conflict với Rust .dll trên desktop
## 3. Đăng ký trong Project Settings > Autoload:
##      Name: SelectionGD
##      Path: res://src/Selection.gd
## 4. Trong Editor.gd, sửa _ready():
##      if ClassDB.class_exists("Selection"):
##          clipboard = ClassDB.instantiate("Selection")   # Rust (desktop)
##      else:
##          clipboard = SelectionGD.new()                  # GDScript (web)
##
## KHÔNG có class_name vì Rust .dll đã đăng ký class "Selection" trên desktop.
## Trên web, .dll không load → dùng file này qua autoload SelectionGD.

extends RefCounted


## Internal storage — dùng Array thay vì HashSet, tự enforce unique.
var _inner: Array[Node2D] = []

# ─────────────────────────────────────────────
# Static constructors
# ─────────────────────────────────────────────

## Empty Selection constant.
static func EMPTY() -> Variant:
	return SelectionGD.new()


## Tạo Selection từ Array[Node2D].
static func from_array(array: Array[Node2D]) -> Variant:
	var s: RefCounted = SelectionGD.new()
	for node in array:
		s.insert(node)
	return s


## Tạo Selection chứa đúng 1 Node2D.
static func from_object(object: Node2D) -> Variant:
	var s: RefCounted = SelectionGD.new()
	s.insert(object)
	return s

# ─────────────────────────────────────────────
# Conversion
# ─────────────────────────────────────────────

## Trả về Array[Node2D] từ selection.
func to_array() -> Array[Node2D]:
	return _inner.duplicate()


func _to_string() -> String:
	return "Selection %s" % [str(_inner)]

# ─────────────────────────────────────────────
# Basic operations
# ─────────────────────────────────────────────

## Số lượng phần tử.
func size() -> int:
	return _inner.size()


## Thêm node vào selection (bỏ qua nếu đã có).
func insert(object: Node2D) -> void:
	if not contains(object):
		_inner.append(object)


## Kiểm tra node có trong selection không.
func contains(object: Node2D) -> bool:
	for node in _inner:
		if node == object:
			return true
	return false


## Xóa node khỏi selection.
## Trả về true nếu node tồn tại và đã bị xóa.
func remove(object: Node2D) -> bool:
	for i in _inner.size():
		if _inner[i] == object:
			_inner.remove_at(i)
			return true
	return false


## Trả về phần tử đầu tiên, hoặc null nếu rỗng.
func first() -> Node2D:
	if _inner.is_empty():
		return null
	return _inner[0]


## Xóa toàn bộ phần tử.
func clear() -> void:
	_inner.clear()


## Kiểm tra selection có rỗng không.
func is_empty() -> bool:
	return _inner.is_empty()


## Tạo bản sao của selection (shallow copy — node không bị clone).
func clone() -> Variant:
	var s: RefCounted = SelectionGD.new()
	s._inner = _inner.duplicate()
	return s

# ─────────────────────────────────────────────
# Set operations
# ─────────────────────────────────────────────

## Trả về Selection mới chứa phần tử có trong self HOẶC other.
func union(other) -> Variant:
	var s: RefCounted = clone()
	var other_inner: Array = other._inner if other else []
	for node in other_inner:
		s.insert(node)
	return s


## Trả về Selection mới chứa phần tử có trong self VÀ other.
func intersection(other) -> Variant:
	var s: RefCounted = SelectionGD.new()
	for node in _inner:
		if other.contains(node):
			s.insert(node)
	return s


## Trả về Selection mới chứa phần tử có trong self NHƯNG KHÔNG có trong other.
func difference(other) -> Variant:
	var s: RefCounted = SelectionGD.new()
	for node in _inner:
		if not other.contains(node):
			s.insert(node)
	return s


## So sánh 2 selection — true nếu có cùng phần tử.
func is_identical(other) -> bool:
	var other_inner: Array = other._inner if other else []
	if _inner.size() != other_inner.size():
		return false
	for node in _inner:
		if not other.contains(node):
			return false
	return true


## True nếu self chứa ít nhất tất cả phần tử của other.
func is_superset(other) -> bool:
	var other_inner: Array = other._inner if other else []
	for node in other_inner:
		if not contains(node):
			return false
	return true


## True nếu other chứa ít nhất tất cả phần tử của self.
func is_subset(other) -> bool:
	return other.is_superset(self)

# ─────────────────────────────────────────────
# Functional operations (Array-like)
# ─────────────────────────────────────────────

## True nếu method.call(node) trả về true cho TẤT CẢ phần tử.
func all(method: Callable) -> bool:
	for node in _inner:
		if not method.call(node):
			return false
	return true


## True nếu method.call(node) trả về true cho ÍT NHẤT 1 phần tử.
func any(method: Callable) -> bool:
	for node in _inner:
		if method.call(node):
			return true
	return false


## Chạy method.call(node) cho từng phần tử.
## [param reverse] nếu true thì duyệt từ cuối về đầu.
func for_each(method: Callable, reverse: bool = false) -> void:
	if reverse:
		for i in range(_inner.size() - 1, -1, -1):
			method.call(_inner[i])
	else:
		for node in _inner:
			method.call(node)


## Map sang Selection mới (method phải trả về Node2D).
func map(method: Callable) -> Variant:
	var s: RefCounted = SelectionGD.new()
	for node in _inner:
		var result: Node2D = method.call(node)
		if result != null:
			s.insert(result)
	return s


## Map sang Array[Variant] (method có thể trả về bất kỳ).
func map_generic(method: Callable) -> Array:
	var result: Array = []
	for node in _inner:
		result.append(method.call(node))
	return result


## Map sang Dictionary {node: method.call(node)}.
func map_generic_dict(method: Callable) -> Dictionary:
	var result: Dictionary = {}
	for node in _inner:
		result[node] = method.call(node)
	return result


## Lọc ra Selection mới với các phần tử mà method.call(node) = true.
func filter(method: Callable) -> Variant:
	var s: RefCounted = SelectionGD.new()
	for node in _inner:
		if method.call(node):
			s.insert(node)
	return s


## Reduce — gom tất cả phần tử vào 1 giá trị.
## method.call(accum, node) → giá trị mới của accum.
func fold_generic(method: Callable, accum: Variant) -> Variant:
	var result: Variant = accum
	for node in _inner:
		result = method.call(result, node)
	return result
