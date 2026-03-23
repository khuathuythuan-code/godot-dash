use std::hash::Hash;

use godot::{classes::GDScript, prelude::*};

pub const EDITOR: &str = "Editor";
pub const EDITOR_ROOT: &str = "root";
pub const LEVEL_ROOT: &str = "level";

#[derive(Eq, Clone)]
pub struct PathRef(Gd<RefCounted>);

impl PathRef {
    pub fn from_ref(reference: Gd<Node2D>) -> Self {
        let mut script = load::<GDScript>("res://src/refcounted/PathRef.gd");
        let inner = script.instantiate(&[reference.to_variant()]).to();
        PathRef(inner)
    }
    pub fn into_ref(&self) -> Option<Gd<Node2D>> {
        // Cloning a pointer is fine
        self.0.clone().call("to_ref", &[]).to()
    }
    pub fn get_ref(&self) -> Option<Gd<Node2D>> {
        self.0.get("_ref").to()
    }
}

impl Hash for PathRef {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.get_ref().hash(state);
    }
}

impl PartialEq for PathRef {
    fn eq(&self, other: &Self) -> bool {
        self.get_ref() == other.get_ref()
    }
}
