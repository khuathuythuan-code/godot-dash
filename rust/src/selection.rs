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
        let new_inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .union(&rhs.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner: new_inner,
            first: self.first.clone(),
        })
    }
    #[func]
    fn intersection(&self, rhs: Gd<Self>) -> Gd<Self> {
        let new_inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .intersection(&rhs.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner: new_inner,
            first: self.first.clone(),
        })
    }
    #[func]
    fn difference(&mut self, rhs: Gd<Self>) -> Gd<Self> {
        let new_inner: HashSet<Gd<Node2D>> = self
            .inner
            .clone()
            .difference(&rhs.bind().inner)
            .cloned()
            .collect();
        Gd::from_object(Self {
            inner: new_inner,
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
}
