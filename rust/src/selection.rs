use godot::prelude::*;
use ordermap::OrderSet;

#[derive(GodotClass)]
/// A wrapper type for Rust's `HashSet`. Works like an [Array] of [Node2D]s but all objects are
/// unique.
pub struct Selection {
    inner: OrderSet<Gd<Node2D>>,
}

#[godot_api]
impl IRefCounted for Selection {
    fn init(_: Base<RefCounted>) -> Selection {
        Selection {
            inner: OrderSet::new(),
        }
    }
    fn to_string(&self) -> GString {
        let into_array = self.to_array();
        GString::from(&format!("Selection {into_array}"))
    }
}

#[godot_api]
impl Selection {
    /// Empty [Selection] constant (GDExtension doesn't yet support
    /// registering constants that aren't [int]s)
    #[func(rename = EMPTY)]
    fn empty() -> Gd<Self> {
        Selection::new_gd()
    }
    #[func]
    /// Creates a [Selection] and fill it with the array's objects.
    fn from_array(array: Array<Gd<Node2D>>) -> Gd<Self> {
        Gd::from_object(Self {
            inner: array.iter_shared().collect(),
        })
    }
    #[func]
    /// Creates a [Selection] containing this [Node2D].
    /// Shorthand for
    /// ```gdscript
    /// var selection := Selection.new()
    /// selection.insert(object)
    /// ```
    fn from_object(object: Gd<Node2D>) -> Gd<Self> {
        Gd::from_object(Self {
            inner: OrderSet::from([object]),
        })
    }
    #[func]
    /// Creates a typed [Array] of [Node2D]s with the objects of the selection.
    fn to_array(&self) -> Array<Gd<Node2D>> {
        Array::from_iter(self.inner.iter().cloned())
    }
    #[func]
    /// Returns the number of objects in this selection.
    fn size(&self) -> i64 {
        self.inner.len() as i64
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **or** in `other`.
    fn union(&self, other: Gd<Self>) -> Gd<Self> {
        let inner: OrderSet<Gd<Node2D>> = self.inner.union(&other.bind().inner).cloned().collect();
        Gd::from_object(Self { inner })
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **and** in `other`.
    fn intersection(&self, other: Gd<Self>) -> Gd<Self> {
        let inner: OrderSet<Gd<Node2D>> = self
            .inner
            .intersection(&other.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self { inner })
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **and not** in `other`.
    fn difference(&mut self, other: Gd<Self>) -> Gd<Self> {
        let inner: OrderSet<Gd<Node2D>> = self
            .inner
            .difference(&other.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self { inner })
    }
    #[func]
    /// Adds an element to the selection.
    fn insert(&mut self, object: Gd<Node2D>) {
        self.inner.insert(object);
    }
    #[func]
    /// Check if an element exists in the selection.
    fn contains(&self, object: Gd<Node2D>) -> bool {
        self.inner.iter().any(|node| node == &object)
    }
    #[func]
    /// Removes an element from the selection.
    /// Returns whether the element was present in the selection.
    fn remove(&mut self, object: Gd<Node2D>) -> bool {
        self.inner.remove(&object)
    }
    #[func]
    /// Returns the first element of the selection, or `null` if there is none.
    fn first(&mut self) -> Option<Gd<Node2D>> {
        self.inner.first().cloned()
    }
    #[func]
    /// Removes all elements from the selection.
    fn clear(&mut self) {
        self.inner.clear();
    }
    #[func]
    /// Creates a copy of the selection. The elements are unchanged.
    fn clone(&self) -> Gd<Self> {
        Gd::from_object(Self {
            inner: self.inner.clone(),
        })
    }
    #[func]
    /// See [method Array.is_empty].
    fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }
    #[func]
    /// Compares two [Selection]s. Returns `true` if the selections have the same elements.
    fn is_identical(&self, other: Gd<Self>) -> bool {
        self.inner == other.bind().inner
    }
    #[func]
    /// Compares two [Selection]s.
    /// Returns true if the set is a superset of another,
    /// i.e., `self` contains at least all the values in `other`.
    fn is_superset(&self, other: Gd<Self>) -> bool {
        self.inner.is_superset(&other.bind().inner)
    }
    #[func]
    /// Compares two [Selection]s.
    /// Returns true if the set is a subset of another,
    /// i.e., `other` contains at least all the values in `self`.
    fn is_subset(&self, other: Gd<Self>) -> bool {
        self.inner.is_subset(&other.bind().inner)
    }
    #[func]
    /// See [method Array.all].
    fn all(&self, method: Callable) -> bool {
        self.inner.iter().all(|node| {
            method
                .call(vslice![node.clone()])
                .try_to_relaxed::<bool>()
                .is_ok_and(|b| b)
        })
    }
    #[func]
    /// See [method Array.any].
    fn any(&self, method: Callable) -> bool {
        self.inner.iter().any(|node| {
            method
                .call(vslice![node.clone()])
                .try_to_relaxed::<bool>()
                .is_ok_and(|b| b)
        })
    }
    #[func]
    /// Like [method Selection.map_generic], but returns another [Selection].
    /// This implies `method` needs to return a [Node2D].
    fn map(&self, method: Callable) -> Gd<Self> {
        let inner: OrderSet<Gd<Node2D>> = self
            .inner
            .clone()
            .iter()
            .flat_map(|node| {
                let new_node_ref = method.call(vslice![node.clone()]).to::<Gd<Node2D>>();
                Some(new_node_ref)
            })
            .collect();
        Gd::from_object(Self { inner })
    }
    #[func]
    /// See [method Array.map].
    fn map_generic(&self, method: Callable) -> Array<Variant> {
        self.inner
            .clone()
            .into_iter()
            .flat_map(|node| Some(method.call(vslice![node])))
            .collect()
    }
    #[func]
    /// Like [method Selection.map_generic], but it produces a [Dictionary] with,
    /// for each element, keys and values being `element` and `method.call(element)`.
    fn map_generic_dict(&self, method: Callable) -> Dictionary<Gd<Node2D>, Variant> {
        self.inner
            .clone()
            .into_iter()
            .flat_map(|node| Some((node.clone(), method.call(vslice![node]))))
            .collect()
    }
    #[func]
    /// See [method Array.filter].
    /// Produces a new [Selection] with elements where `method.call(element) returns `true`.
    fn filter(&self, method: Callable) -> Gd<Self> {
        let inner: OrderSet<Gd<Node2D>> = self
            .inner
            .clone()
            .into_iter()
            .filter(|node| method.call(vslice![node.clone()]).to::<bool>())
            .collect();
        Gd::from_object(Self { inner })
    }
    #[func]
    /// See [method Array.reduce].
    fn fold_generic(&self, method: Callable, accum: Variant) -> Variant {
        self.inner
            .clone()
            .iter()
            .fold(accum, |accum: Variant, node| {
                method.call(vslice![accum, node.clone()])
            })
    }
    #[func]
    /// Runs `method` on each element in the selection.
    fn for_each(&mut self, method: Callable, #[opt(default = false)] reverse: bool) {
        if reverse {
            self.inner.iter().rev().for_each(|node| {
                method.call(vslice![node.clone()]);
            });
        } else {
            self.inner.iter().for_each(|node| {
                method.call(vslice![node.clone()]);
            });
        }
    }
}
