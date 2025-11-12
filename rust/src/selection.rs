use std::collections::HashSet;

use godot::prelude::*;

#[derive(GodotClass)]
/// A wrapper type for Rust's `HashSet`. Works like an [Array] of [Node2D] but all objects are
/// unique.
pub struct Selection {
    inner: HashSet<Gd<Node2D>>,
    first: Option<Gd<Node2D>>,
}

#[godot_api]
impl IRefCounted for Selection {
    fn init(_: Base<RefCounted>) -> Selection {
        Selection {
            inner: HashSet::new(),
            first: None,
        }
    }
    fn to_string(&self) -> GString {
        let into_array = self.to_array();
        GString::from(&format!("Selection {into_array}"))
    }
}

#[godot_api]
impl Selection {
    /// Empty [Selection] constant (GDExtension doesn't yet support registering constants that
    /// aren't [int]s)
    #[func(rename = EMPTY)]
    fn empty() -> Gd<Self> {
        Selection::new_gd()
    }
    #[func]
    /// Creates a [Selection] and fill it with the array's objects.
    fn from_array(array: Array<Gd<Node2D>>) -> Gd<Self> {
        Gd::from_object(Self {
            inner: array.iter_shared().collect(),
            first: array.front(),
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
        let inner: HashSet<Gd<Node2D>> = HashSet::from([object.clone()]);
        Gd::from_object(Self {
            inner,
            first: Some(object),
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
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .union(&other.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **and** in `other`.
    fn intersection(&self, other: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .intersection(&other.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **and not** in `other`.
    fn difference(&mut self, other: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .difference(&other.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    /// Adds an element to the selection.
    fn insert(&mut self, object: Gd<Node2D>) {
        self.inner.insert(object);
    }
    #[func]
    /// Check if an element exists in the selection.
    fn contains(&self, object: Gd<Node2D>) -> bool {
        self.inner.contains(&object)
    }
    #[func]
    /// Removes an element from the selection.
    /// Returns whether the element was present in the selection.
    fn remove(&mut self, object: Gd<Node2D>) -> bool {
        self.inner.remove(&object)
    }
    #[func]
    /// Returns the first element of the selection, or `null` if there is none.
    fn first(&self) -> Option<Gd<Node2D>> {
        self.first.clone()
    }
    #[func]
    /// Removes all elements from the selection.
    fn clear(&mut self) {
        self.inner.clear()
    }
    #[func]
    /// Creates a copy of the selection. The elements are unchanged.
    fn clone(&self) -> Gd<Self> {
        Gd::from_object(Self {
            inner: self.inner.clone(),
            first: self.first.clone(),
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
        self.inner
            .clone()
            .iter()
            .all(|node_ref| method.call(vslice![node_ref]).to::<bool>())
    }
    #[func]
    /// See [method Array.any].
    fn any(&self, method: Callable) -> bool {
        self.inner
            .clone()
            .iter()
            .any(|node_ref| method.call(vslice![node_ref]).to::<bool>())
    }
    #[func]
    /// Like [method Selection.map_generic], but returns another [Selection].
    /// This implies `method` needs to return a [Node2D].
    fn map(&self, method: Callable) -> Gd<Self> {
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .iter()
            .map(|node_ref| method.call(vslice![node_ref]).to::<Gd<Node2D>>())
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    /// See [method Array.map].
    fn map_generic(&self, method: Callable) -> Array<Variant> {
        self.inner
            .clone()
            .iter()
            .map(|node_ref| method.call(vslice![node_ref]))
            .collect()
    }
    #[func]
    /// Like [method Selection.map_generic], but it produces a [Dictionary] with, for each element, keys and values being `element` and `method.call(element)`.
    fn map_generic_dict(&self, method: Callable) -> Dictionary {
        // Typed dictioaries aren't
        // supported in godot-rust yet
        self.inner
            .clone()
            .iter()
            .map(|node_ref| (node_ref.clone(), method.call(vslice![node_ref])))
            .collect()
    }
    #[func]
    /// See [method Array.filter].
    /// Produces a new [Selection] with elements where `method.call(element) returns `true`.
    fn filter(&self, method: Callable) -> Gd<Self> {
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .iter()
            .filter(|node_ref| method.call(vslice![node_ref]).to::<bool>())
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    /// See [method Array.reduce].
    fn fold_generic(&self, method: Callable, accum: Variant) -> Variant {
        self.inner
            .clone()
            .iter()
            .fold(accum, |accum: Variant, node_ref| {
                method.call(vslice![accum, node_ref])
            })
    }
    #[func]
    /// Runs `method` on each element in the selection.
    fn for_each(&mut self, method: Callable) {
        self.inner.iter().for_each(|node_ref| {
            method.call(vslice![node_ref]);
        });
    }
}
