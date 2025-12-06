use std::collections::HashSet;

use godot::{classes::Control, prelude::*, tools::get_autoload_by_name};

const EDITOR: &str = "Editor";
const EDITOR_ROOT: &str = "root";
const LEVEL_ROOT: &str = "level";

#[derive(GodotClass)]
/// A wrapper type for Rust's `HashSet`. Works like an [Array] of [Node2D] but all objects are
/// unique.
pub struct Selection {
    inner: HashSet<NodePath>,
    first: Option<NodePath>,
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
    /// Helper method to get the level root.
    /// Equivalent to `Editor.root.level` in GDScript.
    fn get_level_root() -> Gd<Node2D> {
        get_autoload_by_name::<Node>(EDITOR)
            .get(EDITOR_ROOT)
            .to::<Gd<Control>>()
            .get(LEVEL_ROOT)
            .to()
    }
    /// Empty [Selection] constant (GDExtension doesn't yet support
    /// registering constants that aren't [int]s)
    #[func(rename = EMPTY)]
    fn empty() -> Gd<Self> {
        Selection::new_gd()
    }
    #[func]
    /// Creates a [Selection] and fill it with the array's objects.
    fn from_array(array: Array<Gd<Node2D>>) -> Gd<Self> {
        let level_root = Self::get_level_root();
        Gd::from_object(Self {
            inner: array
                .iter_shared()
                .map(|node| level_root.get_path_to(&node))
                .collect(),
            first: array.front().map(|node| level_root.get_path_to(&node)),
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
        let level_root = Self::get_level_root();
        Gd::from_object(Self {
            inner: HashSet::from([level_root.get_path_to(&object)]),
            first: Some(level_root.get_path_to(&object)),
        })
    }
    #[func]
    /// Creates a typed [Array] of [Node2D]s with the objects of the selection.
    fn to_array(&self) -> Array<Gd<Node2D>> {
        let level_root = Self::get_level_root();
        Array::from_iter(
            self.inner
                .iter()
                .flat_map(|path| level_root.try_get_node_as(path)),
        )
    }
    #[func]
    /// Returns the number of objects in this selection.
    fn size(&self) -> i64 {
        self.inner.len() as i64
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **or** in `other`.
    fn union(&self, other: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<NodePath> = self.inner.union(&other.bind().inner).cloned().collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone().or(other.bind().first.clone()),
        })
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **and** in `other`.
    fn intersection(&self, other: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<NodePath> = self
            .inner
            .intersection(&other.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone().or(other.bind().first.clone()),
        })
    }
    #[func]
    /// Creates a new [Selection] with elements that are in `self` **and not** in `other`.
    fn difference(&mut self, other: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<NodePath> = self
            .inner
            .difference(&other.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone().or(other.bind().first.clone()),
        })
    }
    #[func]
    /// Adds an element to the selection.
    fn insert(&mut self, object: Gd<Node2D>) {
        let level_root = Self::get_level_root();
        self.inner.insert(level_root.get_path_to(&object));
        if self.first.is_none() {
            self.first = Some(level_root.get_path_to(&object))
        }
    }
    #[func]
    /// Check if an element exists in the selection.
    fn contains(&self, object: Gd<Node2D>) -> bool {
        let level_root = Self::get_level_root();
        self.inner.contains(&level_root.get_path_to(&object))
    }
    #[func]
    /// Removes an element from the selection.
    /// Returns whether the element was present in the selection.
    fn remove(&mut self, object: Gd<Node2D>) -> bool {
        let level_root = Self::get_level_root();
        self.inner.remove(&level_root.get_path_to(&object))
    }
    #[func]
    /// Returns the first element of the selection, or `null` if there is none.
    fn first(&self) -> Option<Gd<Node2D>> {
        let level_root = Self::get_level_root();
        self.first.clone().map(|path| level_root.get_node_as(&path))
    }
    #[func]
    /// Removes all elements from the selection.
    fn clear(&mut self) {
        self.inner.clear();
        self.first = None;
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
        let level_root = Self::get_level_root();
        self.inner.iter().all(|path| {
            level_root.get_node_or_null(path).is_some_and(|node| {
                method
                    .call(vslice![node])
                    .try_to_relaxed::<bool>()
                    .is_ok_and(|b| b)
            })
        })
    }
    #[func]
    /// See [method Array.any].
    fn any(&self, method: Callable) -> bool {
        let level_root = Self::get_level_root();
        self.inner.iter().any(|path| {
            level_root.get_node_or_null(path).is_some_and(|node| {
                method
                    .call(vslice![node])
                    .try_to_relaxed::<bool>()
                    .is_ok_and(|b| b)
            })
        })
    }
    #[func]
    /// Like [method Selection.map_generic], but returns another [Selection].
    /// This implies `method` needs to return a [Node2D].
    fn map(&self, method: Callable) -> Gd<Self> {
        let level_root = Self::get_level_root();
        let mut first: Option<NodePath> = None;
        let inner: HashSet<NodePath> = self
            .inner
            .clone()
            .iter()
            .flat_map(|path| {
                let node_ref = level_root.get_node_or_null(path)?;
                let new_node_ref = method.call(vslice![node_ref]).to::<Gd<Node2D>>();
                if let Some(first_ref) = self.first.clone()
                    && level_root.get_node_or_null(&first_ref)? == node_ref
                {
                    first = Some(level_root.get_path_to(&new_node_ref));
                }
                Some(level_root.get_path_to(&new_node_ref))
            })
            .collect();
        Gd::from_object(Self { inner, first })
    }
    #[func]
    /// See [method Array.map].
    fn map_generic(&self, method: Callable) -> Array<Variant> {
        let level_root = Self::get_level_root();
        self.inner
            .clone()
            .into_iter()
            .flat_map(|path| {
                let node = level_root.get_node_or_null(&path)?;
                Some(method.call(vslice![node]))
            })
            .collect()
    }
    #[func]
    /// Like [method Selection.map_generic], but it produces a [Dictionary] with,
    /// for each element, keys and values being `element` and `method.call(element)`.
    fn map_generic_dict(&self, method: Callable) -> VarDictionary {
        // Typed dictionaries aren't supported in godot-rust yet
        let level_root = Self::get_level_root();
        self.inner
            .clone()
            .into_iter()
            .flat_map(|path| {
                let node = level_root.get_node_or_null(&path)?;
                Some((node.clone(), method.call(vslice![node])))
            })
            .collect()
    }
    #[func]
    /// See [method Array.filter].
    /// Produces a new [Selection] with elements where `method.call(element) returns `true`.
    fn filter(&self, method: Callable) -> Gd<Self> {
        let level_root = Self::get_level_root();
        let inner: HashSet<NodePath> = self
            .inner
            .clone()
            .into_iter()
            .filter(|path| {
                level_root
                    .get_node_or_null(path)
                    .is_some_and(|node| method.call(vslice![node]).to::<bool>())
            })
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    /// See [method Array.reduce].
    fn fold_generic(&self, method: Callable, accum: Variant) -> Variant {
        let level_root = Self::get_level_root();
        self.inner
            .clone()
            .iter()
            .flat_map(|path| level_root.get_node_or_null(path))
            .fold(accum, |accum: Variant, node| {
                method.call(vslice![accum, node])
            })
    }
    #[func]
    /// Runs `method` on each element in the selection.
    fn for_each(&mut self, method: Callable) {
        let level_root = Self::get_level_root();
        self.inner
            .iter()
            .flat_map(|path| level_root.get_node_or_null(path))
            .for_each(|node_ref| {
                method.call(vslice![node_ref]);
            });
    }
}
