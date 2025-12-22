use godot::{classes::GDScript, prelude::*};

pub const EDITOR: &str = "Editor";
pub const EDITOR_ROOT: &str = "root";
pub const LEVEL_ROOT: &str = "level";

#[derive(Hash, PartialEq, Eq, Clone)]
pub struct PathRef(Gd<RefCounted>);

impl PathRef {
    pub fn from_ref(reference: Gd<Node2D>) -> Self {
        let mut script = load::<GDScript>("res://src/refcounted/PathRef.gd");
        let inner = script.instantiate(&[reference.to_variant()]).to();
        PathRef(inner)
    }
    pub fn into_ref(&mut self) -> Option<Gd<Node2D>> {
        self.0.call("to_ref", &[]).to()
    }
    pub fn get_ref(&self) -> Option<Gd<Node2D>> {
        self.0.get("_ref").to()
    }
}
