use std::collections::HashSet;

use godot::prelude::*;

#[derive(GodotClass)]
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
    #[func]
    fn from_array(array: Array<Gd<Node2D>>) -> Gd<Self> {
        Gd::from_object(Self {
            inner: array.iter_shared().collect(),
            first: array.front(),
        })
    }
    #[func]
    fn to_array(&self) -> Array<Gd<Node2D>> {
        Array::from_iter(self.inner.iter().cloned())
    }
    #[func]
    fn union(&self, rhs: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .union(&rhs.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    fn intersection(&self, rhs: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .intersection(&rhs.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    fn difference(&mut self, rhs: Gd<Self>) -> Gd<Self> {
        let inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .difference(&rhs.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner,
            first: self.first.clone(),
        })
    }
    #[func]
    fn insert(&mut self, object: Gd<Node2D>) {
        self.inner.insert(object);
    }
    #[func]
    fn contains(&self, object: Gd<Node2D>) -> bool {
        self.inner.contains(&object)
    }
    #[func]
    fn remove(&mut self, object: Gd<Node2D>) -> bool {
        self.inner.remove(&object)
    }
    #[func]
    fn first(&self) -> Option<Gd<Node2D>> {
        self.first.clone()
    }
    #[func]
    fn clear(&mut self) {
        self.inner.clear()
    }
    #[func]
    fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }
    #[func]
    fn is_identical(&self, rhs: Gd<Self>) -> bool {
        self.inner == rhs.bind().inner
    }
    #[func]
    fn is_superset(&self, rhs: Gd<Self>) -> bool {
        self.inner.is_superset(&rhs.bind().inner)
    }
    #[func]
    fn is_subset(&self, rhs: Gd<Self>) -> bool {
        self.inner.is_subset(&rhs.bind().inner)
    }
    #[func]
    fn map(&mut self, method: Callable) -> Gd<Self> {
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
    fn map_generic(&mut self, method: Callable) -> Array<Variant> {
        self.inner
            .clone()
            .iter()
            .map(|node_ref| method.call(vslice![node_ref]))
            .collect()
    }
    #[func]
    fn filter(&mut self, method: Callable) -> Gd<Self> {
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
    fn for_each(&mut self, method: Callable) {
        self.inner.iter().for_each(|node_ref| {
            method.call(vslice![node_ref]);
        });
    }
}
